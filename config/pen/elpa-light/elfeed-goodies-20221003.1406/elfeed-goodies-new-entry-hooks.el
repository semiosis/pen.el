;;; elfeed-goodies-new-entry-hooks.el --- new-entry hooks for Elfeed goodies
;;
;; Copyright (c) 2015 Gergely Nagy
;;
;; Author: Gergely Nagy
;; URL: https://github.com/algernon/elfeed-goodies
;;
;; This file is NOT part of GNU Emacs.
;;
;;; License: GPLv3+
;;; Commentary:
;; Contains functions that will be added too `elfeed-new-entry-hook' on setup.
;;
;;; Code:

(require 'elfeed-goodies)
(require 'cl-lib)
(require 'mm-url)

(defcustom elfeed-goodies/html-decode-title-tags '()
  "Decode HTML entities in the titles of entries tagged with any of these tags."
  :group 'elfeed-goodies
  :type '(repeat symbol))

(defun elfeed-goodies/html-decode-title (entry)
  "Take ENTRY decode title, and set ENTRY title to decoded version."
  (let ((tags (elfeed-deref (elfeed-entry-tags entry))))
    (if (or (equal elfeed-goodies/html-decode-title-tags '(:all))
            (cl-intersection tags elfeed-goodies/html-decode-title-tags))
        (let* ((original (elfeed-deref (elfeed-entry-title entry)))
               (replace (mm-url-decode-entities-string original)))
          (setf (elfeed-entry-title entry) replace)))))

(defun elfeed-goodies/parse-author (_type entry db-entry)
  "Take TYPE (ignored), ENTRY, DB-ENTRY, extract and replace author in DB-ENTRY."
  (let* ((author-name (xml-query '(author name *) entry)))
    (setf (elfeed-meta db-entry :author) author-name)))

(provide 'elfeed-goodies-new-entry-hooks)

;;; elfeed-goodies-new-entry-hooks.el ends here
