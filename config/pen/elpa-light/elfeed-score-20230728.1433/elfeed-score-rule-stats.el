;;; elfeed-score-rule-stats.el --- Maintain statistics on `elfeed-score' rules  -*- lexical-binding: t -*-

;; Copyright (C) 2021-2023 Michael Herstine <sp1ff@pobox.com>

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package maintains statistics on `elfeed-score' rules, such as
;; how many times a particular rule has matched and when it last
;; matched.  This information *used* to be a part of the rule itself,
;; which led to a situation where state in memory could drift
;; out-of-sync with that on disk (see
;; <https://github.com/sp1ff/elfeed-score/issues/13> and
;; <https://www.unwoundstack.com/blog/elfeed-score-state.html>).

;; Today, we maintain that state here, in struct
;; `elfeed-score-rule-stats'.  Instances of this struct are maintained
;; in a hash table `elfeed-score-rule-stats--table' whose keys are the
;; rules and whose values are `elfeed-score-rule-stats' instances.

;; This neatly splits our state: the source-of-truth for rules is the
;; usual score file, whereas the source-of-truth for stats is the
;; in-memory hash table.  We write the hash table out to memory
;; periodically for durability's sake, but here is no chance for the
;; two to interfere with one another.

;; The reader may be tempted to change the hash table to make the
;; :weakness setting 'key, so as to automate clean-up when rules
;; change.  That would be a mistake: that causes entries to be
;; cleaned-up based on *physical* identity of the keys.  Imagine
;; reading in a previously serialized hash table-- because no one else
;; will have references to those particular rule instances, the table
;; is liable to be cleaned up at any moment.

;; This, of course, makes it incumbent on the user of this package to
;; periodically clean-up the hash table (by invoking
;; `elfeed-score-rule-stats-clean').

;;; Code:
(require 'elfeed)

(require 'elfeed-score-log)

(defcustom elfeed-score-rule-stats-file
  (concat (expand-file-name user-emacs-directory) "elfeed.stats")
  "Location at which to persist scoring rules statistics."
  :group 'elfeed-score
  :type 'file)

(defcustom elfeed-score-rule-stats-dirty-threshold 64
  "Maximum # of in-memory stats updates before flushing to file.

Set this variable to nil to inhibit flushing when starting an
operation that will update many statistics with a let form."
  :group 'elfeed-score
  :type 'integer)

(defconst elfeed-score-rule-stats-current-format 1
  "The most recent stats file format version.")

(cl-defstruct (elfeed-score-rule-stats
               ;; Disable the default ctor (the name violates Emacs
               ;; package naming conventions)
               (:constructor nil)
               (:constructor elfeed-score-rule-stats--create (&key hits date)))
  "Statistics regarding `elfeed-score' rules."
  (hits 0 :type 'integer)
  (date nil :type 'float))

(cl-defstruct (elfeed-score-rule-udf-stats
               (:include elfeed-score-rule-stats)
               (:constructor nil)
               (:constructor elfeed-score-rule-udf-stats--create (&key hits date errors)))
  "UDF rule-specific stats."
  (errors 0 :type integer))

(defun elfeed-score-rule-stats--make-table ()
  "Create an empty hash table mapping rules to statistics."
  (make-hash-table :test 'equal :weakness nil))

(defvar elfeed-score-rule-stats--table
  (elfeed-score-rule-stats--make-table)
  "Hash table mapping `elfeed-score' rules to stat instances.

The hash table's :weakness is set to 'key, meaning that when
rules disappear their hash table entries will be reaped
automatically.")

(defun elfeed-score-rule-stats-read (stats-file)
  "Charge the in-memory stats from STATS-FILE."
  (interactive
   (list
    (read-file-name "stats file: " nil elfeed-score-rule-stats-file t
                    elfeed-score-rule-stats-file)))
  (let* ((plist
          (car
           (read-from-string
            (with-temp-buffer
              (insert-file-contents stats-file)
              (buffer-string)))))
         (version (plist-get plist :version)))
    (if (not (eq version elfeed-score-rule-stats-current-format))
        (error "Unknown (or missing) stats file format version: %s" version))
    (setq elfeed-score-rule-stats--table (plist-get plist :stats))
    (elfeed-score-log 'info "Read stats for %d rules from disk."
                      (hash-table-count elfeed-score-rule-stats--table))))

(defun elfeed-score-rule-stats--sexp-to-file (sexp file-name &optional preamble)
  "Write SEXP to FILE-NAME with optional PREAMBLE.

This is a utility function for persisting LISP S-expressions to
file.  If possible, it will write SEXP to a temporary file in the
same directory as FILE-NAME and then rename the temporary file to
replace the original.  Since the move operation is usually atomic
\(so long as both the source & the target are on the same
filesystem) any error leaves the original untouched, and there is
never any instant where the file is nonexistent.

This implementation will first check that the target file is
writable and signal an error if it is not.  Note that it will not
attempt to make an existing file writable temporarily.

It will then check that there is only one hard link to it.  If
FILE-NAME has more than one name, then this implementation falls
back to writing directly to the target file.

Finally, it will write SEXP to a temporary file in the same
directory and then rename it to FILENAME.  This implementation is
heavily derivative of `basic-save-buffer-2'."

  (if (not (file-writable-p file-name))
	    (let ((dir (file-name-directory file-name)))
	      (if (not (file-directory-p dir))
	          (if (file-exists-p dir)
		            (error "%s is not a directory" dir)
              (make-directory dir t))
	        (if (not (file-exists-p file-name))
		          (error "Directory %s write-protected" dir)
            (error "Attempt to save to a file that you aren't allowed to write")))))
  (if (not
       (and
        (file-exists-p file-name)
        (> (file-nlinks file-name) 1)))
      ;; We're good-- write to temp file & rename
      (let* ((dir (file-name-directory file-name))
             (tempname
              (make-temp-file
			         (expand-file-name "tmp" dir))))
        (write-region
         (format
          "%s%s"
          (or preamble "")
          (let ((print-level nil)
                (print-length nil))
            (pp-to-string sexp)))
         nil tempname nil nil file-name)
        (rename-file tempname file-name t))
    ;; We're not good-- fall back to writing directly.
    (write-region
         (format
          "%s%s"
          (or preamble "")
          (let ((print-level nil)
                (print-length nil))
            (pp-to-string sexp)))
         nil file-name)))

(defvar elfeed-score-rule-stats--dirty-stats 0
  "Current count of in-memory stats changes.")

(defun elfeed-score-rule-stats-write (stats-file)
  "Write the in-memory stats to STATS-FILE.

If STATS-FILE doesn't exist, it will be created.  If any parent
directories in its path don't exist, and the caller has
permission to create them, they will be created."
  (interactive
   (list
    (read-file-name "stats file: " nil elfeed-score-rule-stats-file t
                    elfeed-score-rule-stats-file)))
  (elfeed-score-rule-stats--sexp-to-file
   (list
    :version elfeed-score-rule-stats-current-format
    :stats elfeed-score-rule-stats--table)
   stats-file
   ";;; Elfeed score rule stats file DO NOT EDIT       -*- lisp -*-\n")
  (setq elfeed-score-rule-stats--dirty-stats 0)
  (elfeed-score-log 'info "Wrote stats for %d rules to disk."
                    (hash-table-count elfeed-score-rule-stats--table)))

(defun elfeed-score-rule-stats--incr-dirty ()
  "Increment the dirty count & maybe flush."
  (setq elfeed-score-rule-stats--dirty-stats (1+ elfeed-score-rule-stats--dirty-stats))
  ;; Time to flush in-memory stats to disk?
  (if (and elfeed-score-rule-stats-dirty-threshold
           (>= elfeed-score-rule-stats--dirty-stats
               elfeed-score-rule-stats-dirty-threshold)
           elfeed-score-rule-stats-file)
      (progn
        (elfeed-score-rule-stats-write elfeed-score-rule-stats-file))))

(defun elfeed-score-rule-stats-on-match (rule &optional time)
  "Record the fact that RULE has matched at time TIME."

  (let ((entry (or (gethash rule elfeed-score-rule-stats--table)
                   (elfeed-score-rule-stats--create)))
        (time (or time (float-time))))
    (setf (elfeed-score-rule-stats-hits entry) (1+ (elfeed-score-rule-stats-hits entry)))
    (setf (elfeed-score-rule-stats-date entry) time)
    (puthash rule entry elfeed-score-rule-stats--table)
    (elfeed-score-rule-stats--incr-dirty)))

(defun elfeed-score-rule-stats-on-udf-error (rule)
  "Record the fact that UDF RULE has errored."
  (let ((entry (or (gethash rule elfeed-score-rule-stats--table)
                   (elfeed-score-rule-udf-stats--create))))
    (setf (elfeed-score-rule-udf-stats-errors entry)
          (1+ (elfeed-score-rule-udf-stats-errors entry)))
    (puthash rule entry elfeed-score-rule-stats--table)
    (elfeed-score-rule-stats--incr-dirty)))

;; I go back & forth on the contract for this method-- if `rule' isn't
;; a key in the hash table, should I return nil, or return a
;; default-constructed stats table? At this point, I'm going with nil,
;; to be as explicit as possible.
(defun elfeed-score-rule-stats-get (rule)
  "Retrieve the statistics for RULE.

Returns nil if RULE isn't in the table."
  (gethash rule elfeed-score-rule-stats--table))

(defun elfeed-score-rule-stats-get-with-default (rule)
  "Retrieve the statistics for RULE.

Returns a default-constructed stats object if RULE isn't in the table."
  (or (gethash rule elfeed-score-rule-stats--table)
      (elfeed-score-rule-stats--create)))

(defun elfeed-score-rule-stats-set (rule stats)
  "Record stats STATS for RULE."
  (puthash rule stats elfeed-score-rule-stats--table))

;; NB Unlike other scoring operations, we don't inhibit the periodic
;; flushing of score files to disk during updates.  We could set
;; `elfeed-score-rule-stats-dirty-threshold' to nil in
;; `elfeed-update-init-hooks' & restore it here, but I'm uncomfortable
;; with the risk that the update may be interrupted somehow, leaving
;; `elfeed-score-rule-stats-dirty-threshold' "stuck" from then on.

(defun elfeed-score-rule-stats-update-hook (_url)
  "Write stats when an elfeed update is complete."
  (when (and (eq (elfeed-queue-count-total) 0)
             elfeed-score-rule-stats-file)
    (elfeed-score-rule-stats-write elfeed-score-rule-stats-file)))

(defun elfeed-score-rule-stats-clean (rules)
  "Remove hash for anything not in RULES."

  ;; This is not super efficient-- O(n^2). I suppose the in-memory
  ;; datastructures are due for a re-think.

  ;; Do this in two passes, since I'm not sure what will happen
  ;; if I modify the hash table while traversing it.
  (let ((to-be-killed))
    (maphash
     (lambda (key _value)
       (unless (member key rules)
         (setq to-be-killed (cons key to-be-killed))))
     elfeed-score-rule-stats--table)
    (elfeed-score-log 'info "Ejecting statistics for %d stale rules."
                      (length to-be-killed))
    (cl-mapcar
     (lambda (key)
       (remhash key elfeed-score-rule-stats--table))
     to-be-killed)))

(provide 'elfeed-score-rule-stats)
;;; elfeed-score-rule-stats.el ends here
