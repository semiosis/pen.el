;;; ebdb-snarf.el --- Creating or displaying records based on free-form pieces of text  -*- lexical-binding: t; -*-

;; Copyright (C) 2016-2023  Free Software Foundation, Inc.

;; Author: Eric Abrahamsen <eric@ericabrahamsen.net>
;; Keywords: mail

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This file provides functions for reading arbitrary bits of text,
;; interpreting them as records and fields, and then using them to
;; search/display/update/create records.

;; The main entry point is the interactive command `ebdb-snarf'.  It
;; figures out what text we're dealing with, puts the text in a temp
;; buffer, and calls three nested functions: `ebdb-snarf-collect',
;; which finds likely field-related strings in the buffer and groups
;; them, then `ebdb-snarf-collapse', which tries to match that
;; information to existing records, and finally `ebdb-snarf-query',
;; which queries the user about how to handle leftover
;; information. Any resulting records are then displayed.

;; The option `ebdb-snarf-routines' contains regexps that can be used
;; to construct field instances.  `ebdb-snarf-collect' uses the
;; elements of this list to search for relevant strings.

;; Country-specific internationalization libraries are highly
;; encouraged to add values to `ebdb-snarf-routines', locating field
;; information specific to that country/region/language.

;;; Code:

(require 'ebdb-com)

(defcustom ebdb-snarf-routines
  `((ebdb-field-mail "[[:blank:]([<\"]*\\([[:alnum:]][^[:space:]\":\n<[]+@[^]:[:space:])>\"\n]+[[:alnum:]]\\)")
    (ebdb-field-url ,(concat "\\("
			     (regexp-opt ebdb-url-valid-schemes)
			     "//[^ \n\t]+\\)"))
    (ebdb-field-phone "\\(\\+?[[:digit:]]\\{1,3\\}[ )-.]?[[:digit:] -.()]\\{6,\\}\\)"))

  "An alist of EBDB field classes and related regexps.
Each alist element is an EBDB field class symbol, followed by a
list of regular expressions that can be used to produce instances
of that class when passed to `ebdb-parse'.  Each regular
expression should contain at least one parenthetical group: the
`ebdb-parse' method of the class will receive the results of
\(match-string 1)."

  :group 'ebdb-snarf
  :type '(repeat (symbol string)))

(defcustom ebdb-snarf-name-re
  (list "\\(?:[[:upper:]][[:lower:]'-]+[,.[:blank:]]*\\)\\{2,\\}")

  "A list of regular expressions matching names.
This is a separate option from `ebdb-snarf-routines' because
snarfing doesn't search for names separately, only in conjunction
with other field types.

Regular expressions in this list should not include parenthetical
groups."

  :group 'ebdb-snarf
  :type '(repeat string))

;;;###autoload
(defun ebdb-snarf (&optional string start end recs ret)
  "Snarf text and attempt to display/update/create a record from it.
If STRING is given, snarf the string.  If START and END are given
in addition to STRING, assume they are 0-based indices into it.
If STRING is nil but START and END are given, assume they are
buffer positions, and snarf the region between.  If all three
arguments are nil, snarf the entire current buffer.

If RECORDS is present, it is a list of records that we assume may
be relevant to snarfed field data.

If RET is non-nil, return the records.  Otherwise display them."
  (interactive)
  (let* ((str
	  (cond ((use-region-p)
		 (buffer-substring-no-properties
		  (region-beginning) (region-end)))
		((and (or start end) string)
		 (substring string start end))
		((and start end (null string))
		 (buffer-substring-no-properties start end))
		(string
		 string)
		(t
		 (buffer-string))))
	 (records
	  (ebdb-snarf-query
	   (ebdb-snarf-collapse
	    (ebdb-snarf-collect str recs)))))

    (if (null ret)
	(if records
	    (ebdb-display-records records nil t nil (list (selected-window)))
	  (message "No snarfable data found"))
      records)))

(defun ebdb-snarf-collect (str &optional records)
  "Collect EBDB record information from string STR.
This function will find everything that looks like field
information, and do its best to organize it into likely groups.
If RECORDS is given, it should be a list of records that we think
have something to do with the text in the string.

This function returns a list of vectors.  Each vector contains
three elements: a record, a list of name-class instances, and a
list of other field instances.  Any of the three elements can be
nil."
  (let ((case-fold-search nil)
	;; BUNDLES is the list of vectors.  If RECORDS is given, then
	;; we have something to start with.
	(bundles (when records
		   (mapcar (lambda (r)
			     (vector r nil nil))
			   records)))
	;; We are looking for text like this:

	;; John Bob <john@bob.com>

	;; Try calling John Bob: (555) 555-5555

	;; John Bob
	;; John@bob.com
	;; (555) 555-5555
	;; 1111 Upsidedown Drive
	;; Nowhere, Massachusetts, 55555

	;; (Also see the snarfing tests in ebdb-test.el.)

	;; The tactic is: Make a big regexp that finds a big blob of
	;; probable field data.  Once there's a hit, search
	;; *backwards* for a name, and *forwards* for more fields.
	;; All contiguous field data is grouped into the same bundle.

	;; Snarfing mail message data is very common, it would be nice
	;; to somehow disregard left-hand quotation characters and
	;; indentation.  See `mail-citation-prefix-regexp'.  A problem
	;; for another day.
	(big-re
	 (concat
	  "\\(?:"
	  (mapconcat
	   (lambda (r)
	     (if (stringp (cadr r))
		 (cadr r)
	       (mapconcat #'identity (cadr r) "\\|")))
	   ebdb-snarf-routines
	   "\\|*")
	  "\\)+"))
	(name-re (concat
		  "\"?\\("
		  (mapconcat #'identity
			     ebdb-snarf-name-re "\\|")
		  "\\)[-\n\" ,:]*"))
	field seen-fields)

    (with-temp-buffer
      ;; Snarfing mail buffers is very common, try deleting citation
      ;; prefixes from the buffer first.
      (insert (replace-regexp-in-string
	       (concat "^" mail-citation-prefix-regexp "[[:blank:]]+")
	       "" str))
      (goto-char (point-min))
      ;; SOMETHING from the big-re matched.
      (while (re-search-forward big-re nil t)
	(goto-char (match-beginning 0))
	(let* ((bound (match-end 0))
	       (name (save-excursion
		       (when (re-search-backward
			      name-re
                              (line-beginning-position
                               (when (bolp) 0))
			      t)
			 ;; If something goes wrong with the
			 ;; name, don't worry about it.
			 (ignore-errors
			   (ebdb-parse
			    'ebdb-field-name
			    (string-trim (match-string-no-properties 0)))))))
	       (bundle (or (and
			    name
			    ;; If NAME matches one of the records that
			    ;; are already in BUNDLES, then assume we
			    ;; should be working with that record.
			    (catch 'match
			      (dolist (b bundles)
				(when (and (aref b 0)
					   (ebdb-record-search
					    (aref b 0)
					    'ebdb-field-name
					    (ebdb-string name)))
				  (throw 'match b)))))
			   (make-vector 3 nil))))

	  (when (and name (null (aref bundle 0)))
	    (push name (aref bundle 1)))

	  ;; Now find out exactly what matched, and make a field.
	  (dolist (class ebdb-snarf-routines)
	    (dolist (re (cdr class))
	      (save-excursion
		(while (re-search-forward re bound t)
		  (condition-case nil
		      (progn
			;; Discard field if it's been found already.
			(setq field (ebdb-parse (car class)
						(match-string-no-properties 1)))
			(unless (member field seen-fields)
			  (push field (aref bundle 2))
			  (push field seen-fields)))

		    ;; If a regular expression matches but the result is
		    ;; unparseable, that means the regexp is bad and should be
		    ;; changed.  Later, report these errors if `ebdb-debug' is
		    ;; true.
		    (ebdb-unparseable nil))))))
	  (when (or (aref bundle 0) (aref bundle 1) (aref bundle 2))
	    (push bundle bundles))
	  (goto-char bound))))
    bundles))

(defun ebdb-snarf-collapse (input)
  "Process INPUT, which is a list of bundled field information.
INPUT is probably produced by `ebdb-snarf-collect'.  It should be
a list of vectors, each with three elements: a single record, a
list of name field instances, and a list of other field
instances.  Any of the three elements can be nil.

Compare each bundle against the database, and where possible find
existing records that match information in the bundle.  Discard
redundant fields, or fields that are incompatible with the record
they're grouped with.  Return the same list of (possibly altered)
vectors, usually to `ebdb-snarf-query'."
  (let (output rec)
    (pcase-dolist (`[,record ,names ,fields] input)
      (let (out-fields out-names)
	(unless record
	  (when (setq rec (car-safe
			   (ebdb-search
			    (ebdb-records)
			    (mapcar
			     (lambda (f)
			       (list (eieio-object-class-name f)
				     (ebdb-string f)))
			     (append fields names)))))
	    (setq record rec)))
	(if record
	    (progn
	      ;; If there's a record, make sure the record can accept
	      ;; the fields and names, and doesn't already have them.
	      (dolist (f fields)
		(condition-case nil
		    (when (and (car-safe (ebdb-record-field-slot-query
					  (eieio-object-class record)
					  `(nil . ,(eieio-object-class f))))
			       (null (ebdb-record-search
				      record
				      (eieio-object-class f)
				      (ebdb-string f))))
		      (push f out-fields))
		  (ebdb-unacceptable-field nil)))
	      (dolist (name names)
		(unless (ebdb-record-search
			 record 'ebdb-field-name (ebdb-string name))
		  (push name out-names))))
	  ;; If no record, dump all the fields and names into the
	  ;; query process.
	  (setq out-names names
		out-fields fields))
	(push (vector record out-names out-fields) output)))
    output))

(defun ebdb-snarf-query (input)
  "Query the user about handling INPUT.
INPUT is a list of vectors of bundled information representing
records.

Ask about field instances that we haven't been able to handle
automatically."
  (let (leftovers records record)
    (pcase-dolist (`[,record ,names ,fields] input)
      (unless record
	;; There's no record, query-create a new one.
	(when (yes-or-no-p
	       (format "Create new record%s? "
		       (if (or fields names)
			   (format " for fields %s"
				   (mapconcat #'ebdb-string
					      (append fields names)
					      "/"))
			 "")))
	  ;; Which name do we use?
	  (let* ((name-alist
		  (when names
		    (mapcar (lambda (n)
			      (cons (ebdb-string n)
				    n))
			    names)))
		 (name
		  ;; I hate completing read.
		  (cond ((= 1 (length name-alist))
			 (cdar name-alist))
			(name-alist
			 (cdr
			  (assoc-string
			   (completing-read
			    "Use name: "
			    name-alist)
			   name-alist)))
			(t nil)))
		 (db (ebdb-prompt-for-db nil t)))
	    (setq record
		  (make-instance
		   (slot-value db 'record-class)
		   :name (ebdb-read
			  ebdb-default-name-class nil
			  name)))
	    (when name
	      (setq names (delq name names)))
	    (run-hook-with-args 'ebdb-create-hook record)
	    (run-hook-with-args 'ebdb-change-hook record)
	    (ebdb-db-add-record db record)
	    (ebdb-init-record record))))
      (if record
	  ;; We have a record, which of the fields and names should we
	  ;; add to it?
	  (progn (dolist (elt fields)
		   (if (yes-or-no-p (format "Add %s to %s? "
					    (ebdb-string elt)
					    (ebdb-string record)))
		       (condition-case nil
			   (progn
			     (ebdb-record-insert-field
			      record elt)
			     (ebdb-init-field elt record))
			 (ebdb-unacceptable-field nil))
		     (push elt leftovers)))
		 (dolist (n names)
		   (if (yes-or-no-p (format "Add %s as an aka for %s? "
					    (ebdb-string n)
					    (ebdb-string record)))
		       (progn (ebdb-record-insert-field
			       record n 'aka)
			      (ebdb-init-field n record))
		     (push n leftovers)))
		 (run-hook-with-args 'ebdb-after-change-hook record))
	;; We have no record, dump all the fields into LEFTOVERS.
	(setq leftovers (append fields names leftovers)
	      fields nil
	      names nil))
      (when record
	(push record records)))
    ;; Handle fields in LEFTOVERS.
    (dolist (f (delete-dups leftovers))
      (when (setq record
		  (cond ((yes-or-no-p
			  (format "Add %s to existing record? "
				  (ebdb-string f)))
			 (ebdb-prompt-for-record))
			((yes-or-no-p
			  (format "Add %s to new record? "
				  (ebdb-string f)))
			 (let* ((db (ebdb-prompt-for-db nil t))
				(rec (ebdb-read
				      (slot-value db 'record-class))))
			   (run-hook-with-args 'ebdb-create-hook rec)
			   (run-hook-with-args 'ebdb-change-hook rec)
			   (ebdb-init-record
			    (ebdb-db-add-record db rec))))
			(t nil)))
	(condition-case nil
	    (progn
	      (ebdb-record-insert-field record f)
	      (ebdb-init-field f record)
	      (push record records))
	  (ebdb-unacceptable-field nil))))
    records))

(provide 'ebdb-snarf)
;;; ebdb-snarf.el ends here
