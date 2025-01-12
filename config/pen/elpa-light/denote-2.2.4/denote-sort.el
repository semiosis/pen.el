;;; denote-sort.el ---  Sort Denote files based on a file name component -*- lexical-binding: t -*-

;; Copyright (C) 2023  Free Software Foundation, Inc.

;; Author: Protesilaos Stavrou <info@protesilaos.com>
;; Maintainer: Denote Development <~protesilaos/denote@lists.sr.ht>
;; URL: https://git.sr.ht/~protesilaos/denote
;; Mailing-List: https://lists.sr.ht/~protesilaos/denote

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Sort Denote files based on their file name components, namely, the
;; signature, title, or keywords.

;;; Code:

(require 'denote)

(defgroup denote-sort nil
  "Sort Denote files based on a file name component."
  :group 'denote
  :link '(info-link "(denote) Top")
  :link '(url-link :tag "Homepage" "https://protesilaos.com/emacs/denote"))

(defvar denote-sort-comparison-function #'string-collate-lessp
  "String comparison function used by `denote-sort-files' subroutines.")

(defvar denote-sort-components '(title keywords signature identifier)
  "List of sorting keys applicable for `denote-sort-files' and related.")

;; NOTE 2023-12-04: We can have compound sorting algorithms such as
;; title+signature, but I want to keep this simple for the time being.
;; Let us first hear from users to understand if there is a real need
;; for such a feature.
(defmacro denote-sort--define-lessp (component)
  "Define function to sort by COMPONENT."
  (let ((retrieve-fn (intern (format "denote-retrieve-filename-%s" component))))
    `(defun ,(intern (format "denote-sort-%s-lessp" component)) (file1 file2)
       ,(format
         "Return smallest between FILE1 and FILE2 based on their %s.
The comparison is done with `denote-sort-comparison-function' between the
two title values."
         component)
       (let* ((one (,retrieve-fn file1))
              (two (,retrieve-fn file2))
              (one-empty-p (string-empty-p one))
              (two-empty-p (string-empty-p two)))
         (cond
          (one-empty-p nil)
          ((and (not one-empty-p) two-empty-p) one)
          (t (funcall denote-sort-comparison-function one two)))))))

;; TODO 2023-12-04: Subject to the above NOTE, we can also sort by
;; directory and by file length.
(denote-sort--define-lessp title)
(denote-sort--define-lessp keywords)
(denote-sort--define-lessp signature)

;;;###autoload
(defun denote-sort-files (files component &optional reverse)
  "Returned sorted list of Denote FILES.

With COMPONENT as a symbol among `denote-sort-components',
sort files based on the corresponding file name component.

With COMPONENT as a nil value keep the original date-based
sorting which relies on the identifier of each file name.

With optional REVERSE as a non-nil value, reverse the sort order."
  (let* ((files-to-sort (copy-sequence files))
         (sort-fn (when component
                    (pcase component
                      ('title #'denote-sort-title-lessp)
                      ('keywords #'denote-sort-keywords-lessp)
                      ('signature #'denote-sort-signature-lessp))))
         (sorted-files (if sort-fn (sort files sort-fn) files-to-sort)))
    (if reverse
        (reverse sorted-files)
      sorted-files)))

(defun denote-sort-get-directory-files (files-matching-regexp sort-by-component &optional reverse omit-current)
  "Return sorted list of files in variable `denote-directory'.

With FILES-MATCHING-REGEXP as a string limit files to those
matching the given regular expression.

With SORT-BY-COMPONENT as a symbol among `denote-sort-components',
pass it to `denote-sort-files' to sort by the corresponding file
name component.

With optional REVERSE as a non-nil value, reverse the sort order.

With optional OMIT-CURRENT, do not include the current file in
the list."
  (denote-sort-files
   (denote-directory-files files-matching-regexp omit-current)
   sort-by-component
   reverse))

(defun denote-sort-get-links (files-matching-regexp sort-by-component current-file-type id-only &optional reverse)
  "Return sorted typographic list of links for FILES-MATCHING-REGEXP.

With FILES-MATCHING-REGEXP as a string, match files stored in the
variable `denote-directory'.

With SORT-BY-COMPONENT as a symbol among `denote-sort-components',
sort FILES-MATCHING-REGEXP by the given Denote file name
component.  If SORT-BY-COMPONENT is nil or an unknown non-nil
value, default to the identifier-based sorting.

With CURRENT-FILE-TYPE as a symbol among those specified in
`denote-file-type' (or the `car' of each element in
`denote-file-types'), format the link accordingly.  With a nil or
unknown non-nil value, default to the Org notation.

With ID-ONLY as a non-nil value, produce links that consist only
of the identifier, thus deviating from CURRENT-FILE-TYPE.

With optional REVERSE as a non-nil value, reverse the sort order."
  (denote-link--prepare-links
   (denote-sort-get-directory-files files-matching-regexp sort-by-component reverse)
   current-file-type
   id-only))

(defvar denote-sort--component-hist nil
  "Minibuffer history of `denote-sort-component-prompt'.")

(defun denote-sort-component-prompt ()
  "Prompt `denote-sort-files' for sorting key among `denote-sort-components'."
  (let ((default (car denote-sort--component-hist)))
    (intern
     (completing-read
      (format-prompt "Sort by file name component" default)
      denote-sort-components nil :require-match
      nil 'denote-sort--component-hist default))))

(defvar-local denote-sort--dired-buffer nil
  "Buffer object of current `denote-sort-dired'.")

;;;###autoload
(defun denote-sort-dired (files-matching-regexp sort-by-component reverse)
  "Produce Dired dired-buffer with sorted files from variable `denote-directory'.
When called interactively, prompt for FILES-MATCHING-REGEXP,
SORT-BY-COMPONENT, and REVERSE.

1. FILES-MATCHING-REGEXP limits the list of Denote files to
   those matching the provided regular expression.

2. SORT-BY-COMPONENT sorts the files by their file name
   component (one among `denote-sort-components').

3. REVERSE is a boolean to reverse the order when it is a non-nil value.

When called from Lisp, the arguments are a string, a keyword, and
a non-nil value, respectively."
  (interactive
   (list
    (denote-files-matching-regexp-prompt)
    (denote-sort-component-prompt)
    (y-or-n-p "Reverse sort? ")))
  (if-let ((default-directory (denote-directory))
           (files (denote-sort-get-directory-files files-matching-regexp sort-by-component reverse))
           ;; NOTE 2023-12-04: Passing the FILES-MATCHING-REGEXP as
           ;; buffer-name produces an error if the regexp contains a
           ;; wildcard for a directory. I can reproduce this in emacs
           ;; -Q and am not sure if it is a bug. Anyway, I will report
           ;; it upstream, but even if it is fixed we cannot use it
           ;; for now (whatever fix will be available for Emacs 30+).
           (denote-sort-dired-buffer-name (format "Denote sort `%s' by `%s'" files-matching-regexp sort-by-component))
           (buffer-name (format "Denote sort by `%s' at %s" sort-by-component (format-time-string "%T"))))
      (let ((dired-buffer (dired (cons buffer-name (mapcar #'file-relative-name files)))))
        (setq denote-sort--dired-buffer dired-buffer)
        (with-current-buffer dired-buffer
          (setq-local revert-buffer-function
                      (lambda (&rest _)
                        (kill-buffer dired-buffer)
                        (denote-sort-dired files-matching-regexp sort-by-component reverse))))
        ;; Because of the above NOTE, I am printing a message.  Not
        ;; what I want, but it is better than nothing...
        (message denote-sort-dired-buffer-name))
    (message "No matching files for: %s" files-matching-regexp)))

(provide 'denote-sort)
;;; denote-sort.el ends here
