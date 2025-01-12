;;; org-journal-list.el --- Org mode Journal List -*- lexical-binding: t -*-

;; Copyright © 2011-2019 Huy Tran <huytd189@gmail.com>

;; Author: Huy Tran <huytd189@gmail.com> 
;; Version: 1.0
;; URL: https://github.com/huytd/org-journal-list
;; Package-Requires: ((emacs "25"))

;;; Commentary:

;; This package does not provide any key binding. You will
;; have to do it yourself.
;; For example, to bind Super-J as a keystroke to open journal
;; list, do this:
;;   (global-set-key (kbd "s-j") 'org-journal-list--start)

;;; Code:
(require 'cl-extra)

(defgroup org-journal-list nil
  "Customization group for org-journal-list."
  :prefix "org-journal-list-"
  :group 'org
  :link '(url-link :tag "GitHub" "https://github.com/huytd/org-journal-list"))

(defcustom org-journal-list-display-alist
  '((side . left)
    (window-width . 40)
    (slot . -1))
  "Alist used to display notes buffer."
  :type 'alist)

(defcustom org-journal-list-default-directory
  "~/notes/journal/"
  "Default directory of your journal."
  :type 'directory)

(defcustom org-journal-list-default-suffix
  ".journal.org"
  "Default suffix of your journal files."
  :type 'string)

(defcustom org-journal-list-create-temp-buffer
  nil
  "Start journal list with a temp buffer instead of a prefixed file name."
  :type 'boolean)

(defcustom org-journal-list-create-list-buffer
  t
  "Start journal list with a list of notes on the right."
  :type 'boolean)

(defun org-journal-list--read-file (path)
  "Read all org files in a given PATH."
  (with-temp-buffer
    (insert-file-contents path nil 0 256)
    (split-string (buffer-string) "\n" t)))

(defun org-journal-list--read-first-few-lines (list)
  "Read the first few lines of the documents as a given LIST."
  (cond ((>= (length list) 6) (cl-subseq list 1 5))
        ((>= (length list) 1) (nthcdr 1 list))
        (t list)))

(defun org-journal-list--read-journal-heads (path)
  "Read the specific note at PATH as a list, returning the first few lines."
  (mapconcat (function (lambda (line) (format "  %s" line)))
             (org-journal-list--read-first-few-lines (org-journal-list--read-file path)) "\n"))

(defun org-journal-list--remove-default-directory-in-path (path)
  "Remove the default directory in PATH when printing, if there is one."
  (replace-regexp-in-string (regexp-quote org-journal-list-default-directory) "" path nil 'literal))

(defun org-journal-list--format-item-string (item)
  "Generate the string for each ITEM on the sidebar."
  (format "* [[file:%s][%s]]\n%s\n%s"
          item
          (org-journal-list--remove-default-directory-in-path item)
          (org-journal-list--read-journal-heads item)
          (make-string 35 ?━)))

(defun org-journal-list--create-and-open-temp-buffer ()
  "Create and open a new empty buffer."
  (interactive)
  (let ((temp-buffer (get-buffer-create "*new note*")))
    (with-current-buffer temp-buffer
      (org-mode)
      (cd org-journal-list-default-directory)
      (switch-to-buffer temp-buffer))))

(defun org-journal-list--start ()
  "Start org-journal-list mode, this function should be binded to a keystroke."
  (interactive)
  (if org-journal-list-create-list-buffer
      (let ((journal-list-buffer (get-buffer-create (generate-new-buffer-name "*journals*"))))
        (with-current-buffer journal-list-buffer
          (org-mode)
          (let ((file-list (directory-files-recursively org-journal-list-default-directory "\\.org$" t)))
            (let ((file-list-text (mapcar 'org-journal-list--format-item-string file-list)))
              (insert (mapconcat 'identity file-list-text "\n"))
              (goto-char (point-min))
              (read-only-mode t))))
        (display-buffer-in-side-window journal-list-buffer org-journal-list-display-alist)))
  (if org-journal-list-create-temp-buffer
      (org-journal-list--create-and-open-temp-buffer)
    (find-file (concat org-journal-list-default-directory (format-time-string "%Y-%m-%d") org-journal-list-default-suffix))))

(provide 'org-journal-list)
;;; org-journal-list.el ends here
