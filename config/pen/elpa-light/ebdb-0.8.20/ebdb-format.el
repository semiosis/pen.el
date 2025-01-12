;;; ebdb-format.el --- Formatting/exporting EBDB records  -*- lexical-binding: t; -*-

;; Copyright (C) 2016-2023  Free Software Foundation, Inc.

;; Author: Eric Abrahamsen <eric@ericabrahamsen.net>

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

;; This file contains code for turning record objects into text,
;; somehow.  It provides the basic framework that is used for creating
;; the *EBDB* buffer as well as exporting to vcard, latex, and html
;; formats.

;; The basic idea is: a formatter object controls which record fields
;; are selected, and ultimately how they're output as text.  The
;; formatting routine first inserts the value of `ebdb-fmt-header',
;; then the value of `ebdb-fmt-record' for each record to be output,
;; then the value of `ebdb-fmt-footer'.

;; For each record, the method `ebdb-fmt-record' first collects its
;; fields using `ebdb-fmt-collect-fields', which are then sorted by
;; `ebdb-fmt-sort-fields', then processed with
;; `ebdb-fmt-process-fields' (this last means handling field
;; combination or collapse, etc).  Then it splits header fields from
;; body fields, and formats the header fields with
;; `ebdb-fmt-record-header', and the body fields with
;; `ebdb-fmt-compose-fields'.  It concats those two strings and
;; returns the result.

;; This file also provides the functions `ebdb-format-all-records' and
;; `ebdb-format-to-tmp-buffer', the difference being that the former
;; formats the whole database, and the latter only formats the
;; currently marked or displayed records.

;;; Code:

(require 'ebdb)

(declare-function csv-mode "ext:csv-mode")

(defcustom ebdb-format-buffer-name "*EBDB Format*"
  "Default name of buffer in which to display formatted records."
  :type 'string
  :group 'ebdb-record-display)

(defvar ebdb-formatter-tracker nil
  "Variable for holding all instantiated formatters.")

(defclass ebdb-formatter (eieio-instance-tracker)
  ((label
    :initarg :label
    :type string
    :initform "")
   (tracking-symbol :initform 'ebdb-formatter-tracker)
   (format-buffer-name
    :initarg :format-buffer-name
    :type string
    :initform `,ebdb-format-buffer-name)
   (coding-system
    :type symbol
    :initarg :coding-system
    ;; "`," is used to trick EIEIO into evaluating the form.
    :initform `,buffer-file-coding-system
    :documentation "The coding system for the formatted
    file/buffer/stream.")
   (post-format-function
    :type (or null function)
    :initarg :post-format-function
    :initform nil
    :documentation "A function to be called after formatting is
    complete.  Probably a major mode."))
  :abstract t
  :documentation "Abstract base class for EBDB formatters.
  Subclass this to produce real formatters.")

(defclass ebdb-formatter-freeform (ebdb-formatter)
  ((include
    :type list
    :initarg :include
    :initform nil
    :documentation "A list of field classes to include.")
   (exclude
    :type list
    :initarg :exclude
    :initform nil
    :documentation "A list of field classes to exclude.  This
    slot is only honored if \"include\" is nil.")
   (sort
    :type list
    :initarg :sort
    :initform '(ebdb-field-mail
		ebdb-field-phone ebdb-field-address "_" ebdb-field-notes)
    :documentation "How field instances should be sorted.  Field
    classes should be listed in their proper sort order.  A \"_\"
    placeholder indicates where all other fields should go." )
   (combine
    :type list
    :initarg :combine
    :initform nil
    :documentation "A list of field classes which should be
    output with all instances grouped together.")
   (collapse
    :type list
    :initarg :collapse
    :initform nil
    :documentation "A list of field classes which should be
    \"collapsed\". What this means is up to the formatter, but it
    generally indicates that most of the field contents will
    hidden unless the user takes some action, such as clicking or
    hitting <TAB>.  (Currently unimplemented.)")
   (header
    :type list
    :initarg :header
    :initform  '((ebdb-record-person ebdb-field-role ebdb-field-image)
		 (ebdb-record-organization ebdb-field-domain ebdb-field-role ebdb-field-image))
    :documentation "A list of field classes which will be output
    in the header of the record, grouped by record class type."))
  :abstract t
  :documentation "An abstract formatter for formats that can
  accept variable numbers and types of fields.")

(defclass ebdb-formatter-constrained (ebdb-formatter)
  ((fields
    :type list
    :initarg :fields
    :initform nil
    :documentation "A list of the record fields to output.
    Fields will be output in the order listed.")
   (field-missing
    :type (or string symbol function)
    :initarg :field-missing
    :initform "none"
    :documentation "How to handle missing fields.  Can be a
    string, which will be inserted in place of the missing field,
    a symbol, which will be raised as an error symbol, or a
    function, which will be called with three arguments: the
    formatter, the record, and the field spec."))
  :abstract t
  :documentation "An abstract formatter for formats that require
  an exact specification of fields.")

(defclass ebdb-formatter-tabular (ebdb-formatter-constrained)
  ((record-separator
    :type (or string character)
    :initarg :record-separator
    :initform "")
   (field-separator
    :type (or string character)
    :initarg :field-separator
    :initform ""))
  :documentation "A formatter for outputting records in tabular
  format.")

(cl-defmethod ebdb-string ((fmt ebdb-formatter))
  (slot-value fmt 'label))

(cl-defgeneric ebdb-fmt-header (fmt records)
  "Insert a string at the beginning of the list of records.")

(cl-defgeneric ebdb-fmt-footer (fmt records)
  "Insert a string at the end of the list of records.")

(cl-defgeneric ebdb-fmt-record (fmt record)
  "Handle the insertion of formatted RECORD.
This method collects all the fields for RECORD, splits them into
header and body fields, and then calls `ebdb-fmt-record-header'
and `ebdb-fmt-compose-fields'.")

(cl-defgeneric ebdb-fmt-record-header (fmt record fields)
  "Format a header for RECORD, using fields in FIELDS.")

(cl-defgeneric ebdb-fmt-collect-fields (fmt record &optional fields)
  "Return a list of RECORD's FIELDS to be formatted.")

(cl-defgeneric ebdb-fmt-process-fields (fmt record &optional fields)
  "Process the FIELDS belonging to RECORD.
This means grouping them into lists containing various formatting
information, mostly drawn from FMT's `combine' and `collapse'
slots.")

(cl-defgeneric ebdb-fmt-sort-fields (fmt record &optional fields)
  "Sort FIELDS belonging to RECORD according to FMT.")

(cl-defgeneric ebdb-fmt-compose-fields (fmt object &optional field-list depth)
  "Compose the lists produced by `ebdb-fmt-process-fields'.
The lists of class instances and formatting information are
turned into indented strings, and the entire block is returned as
a single string value.  Optional argument DEPTH is used when
recursively composing subfields of fields.")

(cl-defgeneric ebdb-fmt-field (fmt field style record)
  "Format FIELD value of RECORD.
This method only returns the string value of FIELD itself,
possibly with text properties attached.")

(cl-defgeneric ebdb-fmt-field-label (fmt field-or-class style &optional record)
  "Format a field label, using formatter FMT.
FIELD-OR-CLASS is a field class or a field instance, and STYLE is
a symbol indicating a style of some sort, such as \\='compact or
\\='expanded.")

;;; Basic method implementations

(cl-defmethod ebdb-fmt-header (_fmt _records)
  "")

(cl-defmethod ebdb-fmt-footer (_fmt _records)
  "")

(cl-defmethod ebdb-fmt-field-label ((_fmt ebdb-formatter)
				    (cls (subclass ebdb-field))
				    _style
				    &optional _record)
  (ebdb-field-readable-name cls))

(cl-defmethod ebdb-fmt-field-label ((_fmt ebdb-formatter)
				    (field ebdb-field)
				    _style
				    &optional _record)
  (ebdb-field-readable-name field))

(cl-defmethod ebdb-fmt-field-label ((_fmt ebdb-formatter)
				    (field ebdb-field-labeled)
				    _style
				    &optional _record)
  (ebdb-field-label field))

(cl-defmethod ebdb-fmt-field-label ((_fmt ebdb-formatter)
				    (field ebdb-field-labeled)
				    (_style (eql compact))
				    &optional _record)
  (ebdb-field-readable-name field))

(cl-defmethod ebdb-fmt-field ((fmt ebdb-formatter)
			      (field ebdb-field-labeled)
			      (_style (eql compact))
			      (record ebdb-record))
  (let ((label (slot-value field 'label)))
    ;; The compact style shouldn't output a default label, only use it
    ;; if the field in question really has one.
    (concat
     (when label
       (format "(%s) " label))
     (ebdb-fmt-field fmt field 'oneline record))))

(cl-defmethod ebdb-fmt-field ((_fmt ebdb-formatter)
			      (field ebdb-field)
			      (_style (eql oneline))
			      (_record ebdb-record))
  (car (split-string (ebdb-string field) "\n")))

(cl-defmethod ebdb-fmt-field ((fmt ebdb-formatter)
			      (field ebdb-field)
			      (_style (eql collapse))
			      (record ebdb-record))
  "For now, treat collapse the same as oneline."
  (ebdb-fmt-field fmt field 'oneline record))

(cl-defmethod ebdb-fmt-field ((_fmt ebdb-formatter)
			      (field ebdb-field)
			      _style
			      (_record ebdb-record))
  "The base implementation for FIELD simply returns the value of
  `ebdb-string'."
  (ebdb-string field))

(cl-defmethod ebdb-fmt-collect-fields ((fmt ebdb-formatter-freeform)
				       (record ebdb-record)
				       &optional field-list)
  "Collect all fields of RECORD, and filter according to FMT.
Returns RECORD's field as a simple list."
  ;; Remove the `name' slot entry from the list.
  (let ((fields (append
		 field-list
		 (mapcar #'cdr
			 (seq-remove
			  ;; The or (null (cdr elt)) is there to
			  ;; protect against an earlier bug with
			  ;; timestamps and creation-dates, it could
			  ;; be removed at some point.
			  (lambda (elt) (or (eql (car elt) 'name)
					    (null (cdr elt))))
 			  (ebdb-record-current-fields record nil t))))))
    (with-slots (exclude include) fmt
      (seq-filter
       (lambda (f)
	 (if include
	     (ebdb-foo-in-list-p f include)
	   (null (ebdb-foo-in-list-p f exclude))))
       fields))))

(cl-defmethod ebdb-fmt-collect-fields ((fmt ebdb-formatter-constrained)
				       (record ebdb-record))
  "Collect RECORD's fields according to FMT's `fields' slot.
Return as a vector of field instances, with nil in place of
missing fields."
  (let* ((fmt-fields (slot-value fmt 'fields))
	 (missing (slot-value fmt 'field-missing))
	 (fields (make-vector (length fmt-fields) nil)))
    (dotimes (i (length fields))
      (aset fields i (or (ebdb-record-field record (nth i fmt-fields))
			 (cons (nth i fmt-fields) missing))))
    fields))

(cl-defmethod ebdb-fmt-sort-fields ((_fmt ebdb-formatter-constrained)
				    (_record ebdb-record)
				    &optional fields)
  "Don't sort by default."
  fields)

(cl-defmethod ebdb-fmt-process-fields ((_fmt ebdb-formatter-constrained)
				       (_record ebdb-record)
				       &optional fields)
  "Process fields for the \"constrained\" formatter class.
At present, just makes sure that multiple field instances are
combined into a single string."
  fields)

(cl-defmethod ebdb-fmt-collect-fields ((fmt ebdb-formatter-freeform)
				       (record ebdb-record-organization)
				       &optional field-list)
  "Collect all role fields that point at this organization."
  (cl-call-next-method
   fmt record
   (append field-list (gethash (ebdb-record-uuid record) ebdb-org-hashtable))))

(cl-defmethod ebdb-fmt-collect-fields ((fmt ebdb-formatter-freeform)
				       (record ebdb-record-person)
				       &optional field-list)
  "Collect all relation fields that point at this person."
  (cl-call-next-method
   fmt record
   (append field-list (mapcar #'cdr (gethash (ebdb-record-uuid record)
					     ebdb-relation-hashtable)))))

(cl-defmethod ebdb-fmt-sort-fields ((fmt ebdb-formatter-freeform)
				    (_record ebdb-record)
				    field-list)
  "Sort FIELD-LIST using sort order from FMT.
First sorts all fields with `ebdb-field-compare', then sorts
again by the order of each field's class symbol in the \\='sort
slot of FMT."
  (let* ((sort-order (slot-value fmt 'sort))
	 (catchall (or (seq-position sort-order "_")
		       (length sort-order)))
	 ;; This sorts by class type, what we also want is, if the
	 ;; "plumbing" fields are present, to put them first.
	 (sorted (seq-sort #'ebdb-field-compare field-list)))

    (when sort-order
      (setq sorted
	    (seq-sort-by
	     (lambda (f)
	       (or (seq-position sort-order (eieio-object-class-name f))
		   catchall))
	     #'< sorted)))
    sorted))

(cl-defmethod ebdb-fmt-process-fields ((fmt ebdb-formatter-freeform)
				       (_record ebdb-record)
				       field-list)
  "Process FIELD-LIST for FMT.
At present that means handling the combine and collapse slots of
FMT.

This method assumes that fields in FIELD-LIST have already been
grouped by field class.

The return value is a list of alists.  Each alist has three keys:
\\='class, holding a class symbol, \\='style, holding either the symbol
`collapse' or the symbol `normal', and \\='inst, a list of all the
instances in this bundle.  The `combine' style works by putting
multiple instances in a single alist."
  (let (outlist f acc)
    (with-slots (combine collapse) fmt
      (when combine
	(while (setq f (pop field-list))
	  (if (null (ebdb-foo-in-list-p f combine))
	      (push f outlist)
	    (push f acc)
	    (while (and field-list (same-class-p (car field-list)
						 (eieio-object-class f)))
	      (push (setq f (pop field-list)) acc))
	    (push `((class . ,(eieio-object-class-name f))
		    (style . compact) (inst . ,(nreverse acc)))
		  outlist)
	    (setq acc nil)))
	(setq field-list (nreverse outlist)
	      outlist nil))
      (dolist (f field-list)
	(if (listp f)
	    (push f outlist)
	  (push (list (cons 'class (eieio-object-class-name f))
		      (cons 'inst (list f))
		      (cons 'style
			    (cond
			     ((ebdb-foo-in-list-p f collapse) 'collapse)
			     (t 'normal))))
		outlist)))
      (nreverse outlist))))

(cl-defmethod ebdb-fmt-record ((fmt ebdb-formatter-freeform)
			       (record ebdb-record))
  (pcase-let* ((header-classes (cdr (assoc (eieio-object-class-name record)
					   (slot-value fmt 'header))))
	       (record-uuid (ebdb-record-uuid record))
	       ((map header-fields body-fields)
		(seq-group-by
		 (lambda (f)
		   ;; FIXME: Consider doing the header/body split in
		   ;; `ebdb-fmt-process-fields', we've already got the
		   ;; formatter there.
		   (let ((cls (alist-get 'class f))
			 (inst (car (alist-get 'inst f))))
		    (if (child-of-class-p cls 'ebdb-field-role)
			;; This is all getting super hacky... If the
			;; role field is "to" some other record, put
			;; it in the header.  If it's "to" this
			;; record, put it in the body.
			(if (equal record-uuid (slot-value inst 'record-uuid))
			    'header-fields
			  'body-fields)
		      (if (ebdb-foo-in-list-p cls header-classes)
			  'header-fields
			'body-fields))))
		 (ebdb-fmt-process-fields
		  fmt record
		  (ebdb-fmt-sort-fields
		   fmt record
		   (ebdb-fmt-collect-fields
		    fmt record))))))
    (concat
     (ebdb-fmt-record-header fmt record header-fields)
     (ebdb-fmt-compose-fields fmt record body-fields 1))))

;; Tabular formatting

(cl-defmethod ebdb-fmt-record ((fmt ebdb-formatter-tabular)
			       (rec ebdb-record))
  (let ((fields (ebdb-fmt-process-fields
		 fmt rec
		 (ebdb-fmt-sort-fields
		  fmt rec
		  (ebdb-fmt-collect-fields
		   fmt rec))))
	(rec-sep (slot-value fmt 'record-separator)))
    (concat
     (ebdb-fmt-compose-fields fmt rec fields)
     rec-sep)))

(cl-defmethod ebdb-fmt-header ((fmt ebdb-formatter-tabular)
			       _records)
  (with-slots (fields field-separator record-separator) fmt
    (concat
     "Name"
     field-separator
     (mapconcat
      (lambda (f)
	(cond
	 ((stringp f) f)
	 ((or (class-p f)
	      (eieio-object-p f))
	  (ebdb-fmt-field-label fmt f 'normal))
	 ((symbolp f)
	  (symbol-name f))))
      fields
      field-separator))))

(cl-defmethod ebdb-fmt-compose-fields ((fmt ebdb-formatter-tabular)
				       (rec ebdb-record)
				       &optional field-list _depth)

  (with-slots (field-separator) fmt
    (concat
     (ebdb-record-name-string rec)
     field-separator
     (mapconcat
      (lambda (f)
	(if (eieio-object-p f)
	    (ebdb-fmt-field fmt f 'compact rec)
	  ;; See docs of 'field-missing slot of
	  ;; `ebdb-formatter-constrained' for explanation of the
	  ;; following behavior.
	  (pcase f
	    (`(,_ . ,(and (pred stringp) str)) str)
	    (`(,spec . ,(and (pred symbolp) sym))
	     (signal sym (list rec spec)))
	    (`(,spec . ,(and (pred functionp) fun))
	     (funcall fun fmt rec spec)))))
      field-list
      field-separator))))

(defclass ebdb-formatter-csv (ebdb-formatter-tabular)
  ((record-separator :initform "\n")
   (field-separator :initform ",")
   (post-format-function :initform (lambda ()
				     (when (fboundp 'csv-mode)
				       (csv-mode))))))

(cl-defmethod ebdb-fmt-field ((fmt ebdb-formatter-csv)
			      (_field ebdb-field)
			      _style
			      (_rec ebdb-record))
  "Quote field strings containing the separator."
  (let ((sep (slot-value fmt 'field-separator))
	(field (cl-call-next-method)))
    (if (and (stringp sep)
	     (string-match-p sep field))
	(format "\"%s\"" field)
      field)))

(cl-defmethod ebdb-fmt-header ((_fmt ebdb-formatter-csv)
			       _records)
  (concat (cl-call-next-method) "\n"))

(defcustom ebdb-default-csv-formatter
  (make-instance 'ebdb-formatter-csv :label "csv"
		 :fields '(mail-primary))
  "Default CSV formatter."
  :group 'ebdb
  :type 'ebdb-formatter-csv)

;;; Basic export routines

(defun ebdb-prompt-for-formatter ()
  (interactive)
  (let ((collection
	 (mapcar
	  (lambda (formatter)
	    (cons (slot-value formatter 'label) formatter))
	  ebdb-formatter-tracker)))
    (cdr (assoc (completing-read "Use formatter: " collection)
		collection))))

(provide 'ebdb-format)
;;; ebdb-format.el ends here
