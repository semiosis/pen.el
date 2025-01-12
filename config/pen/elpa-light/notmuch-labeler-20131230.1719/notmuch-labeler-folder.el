;;; notmuch-labeler-folder --- Use folder information instead of labels
;;
;; Copyright (C) 2012 Damien Cassou
;;
;; Author: Damien Cassou <damien.cassou@gmail.com>
;; Url: https://github.com/DamienCassou/notmuch-labeler
;; GIT: https://github.com/DamienCassou/notmuch-labeler
;; Version: 0.1
;; Created: 2012-10-09
;; Keywords: emacs package elisp notmuch emails folders
;;
;; This file is NOT part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or (at
;; your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program ; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.
;;; Commentary:
;;
;; Use this package when you use folders to tag your emails instead of
;; notmuch labels. This is for example useful when using Gmail because
;; Gmail labels are presented as IMAP folders.
;;
;;; Code:

(require 'cl)

(defcustom notmuch-labeler-folder-base "~/Mail/"
  "Base directory where your emails are located.
This directory must primarily consist of subdirectories
containing emails."
  :group 'notmuch-labeler)

(defun nmlf--base ()
  "Check and return the user's base email directory."
  (if (file-directory-p (expand-file-name notmuch-labeler-folder-base))
      (expand-file-name notmuch-labeler-folder-base)
    (error "You have to set `notmuch-labeler-folder-base' to your base email directory")))

(defun nmlf--folder (name)
  "Return the full path of the email folder NAME."
  (expand-file-name name (nmlf--base)))

(defun nmlf--file-folder (file)
  "Return the folder containing the email in FILE.
FILE must be a full pathname and FILE must be within a
subdirectory of `notmuch-labeler-folder-base'."
  (let ((path (file-relative-name file (nmlf--base))))
    (substring path 0 (string-match "/" path))))

(defun nmlf--folder-p (folder)
  "Check that the FOLDER is an email folder in `nmlf--base'."
  (let ((full-folder (nmlf--folder folder)))
    (and
     (file-directory-p full-folder)
     (file-directory-p (expand-file-name "cur" full-folder))
     (file-directory-p (expand-file-name "new" full-folder)))))

(defun nmlf--all-folders ()
  "Return the list of all folders."
  (remove-if-not 'nmlf--folder-p
		 (set-difference
		  (directory-files (nmlf--base))
		  '("." ".." ".notmuch")
		  :test #'string-equal)))


(defun nmlf--search-files (query)
  "Show in a JSON buffer the files matching QUERY.
See `nmlf--files' to get a list of files instead of a JSON
buffer."
  (let ((buffer (get-buffer-create (notmuch-search-buffer-title query))))
    (switch-to-buffer buffer)
    ;; Don't track undo information for this buffer
    (set 'buffer-undo-list t)
    (erase-buffer)
    (goto-char (point-min))
    (call-process
     notmuch-command
     nil ;; input
     buffer  ;; output
     nil ;; show progress
     "search"
     "--format=json"
     "--output=files"
     query)))

(defun nmlf--files (query)
  "Return the file paths of messages found by QUERY."
  (save-window-excursion
    (nmlf--search-files query)
    (goto-char (point-min))
    (let* ((json-array-type 'list)
	   (files (json-read)))
      (kill-buffer)
      files)))

(defun nmlf--files-folders (files)
  "Return the folders containing FILES."
  (remove-duplicates
   (mapcar 'nmlf--file-folder files)
   :test 'string-equal))

(defun nmlf--query-folders (query)
  "Return the folders containing emails matching QUERY."
  (nmlf--files-folders (nmlf--files query)))

(defun nmlf--thread-folders (thread-id)
  "Return the folders containing emails of THREAD-ID.
The thread folders are the union of the folders of emails in the
thread."
  (nmlf--query-folders (concat "thread:" thread-id)))

(defun nmlf--email-folders (mail-id)
  "Return the folders containing emails with MAIL-ID."
  (nmlf--query-folders (concat "id:" mail-id)))

(defun nmlf--goto-folder (folder)
  "Search and list emails in FOLDER."
  (notmuch-search (concat "folder:\"" folder "\"")))

(defun nmlf--result-folders (result)
  (if (plist-member result :id)
      (nmlf--email-folders (plist-get result :id))
    (nmlf--thread-folders (plist-get result :thread))))

(defun nmlf--result-in-folder-p (result folder)
  "Check that RESULT contains at least an email in FOLDER."
  (member* folder (nmlf--result-folders result) :test 'string=))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; The following definitions erase existing ones of notmuch-label
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defadvice nml--goto-target
  (around nmlf--goto-folder activate)
  "REDEFINTION: Show the list of mails in folder TARGET."
  (let ((target (ad-get-arg 0)))
    (nmlf--goto-folder target)))

(defadvice nml--thread-labels-from-search
  (around nmlf--thread-folders-from-search activate)
  "REDEFINITION: Return the thread folders from RESULT."
  (let ((result (ad-get-arg 0)))
    (setq ad-return-value (nmlf--result-folders result))))

(defadvice nml--thread-labels-from-id
  (around nmlf--thread-folders-from-id activate)
  "Return the folders containing emails of THREAD-ID."
  (let ((thread-id (ad-get-arg 0)))
    (setq ad-return-value
	  (nmlf--thread-folders thread-id))))

(defadvice nml--message-labels-from-properties
  (around nmlf--message-folders-from-properties activate)
  "Find the folders of an email from its PROPERTIES."
  (let ((properties (ad-get-arg 0)))
    (setq ad-return-value
	  (nmlf--email-folders (plist-get properties :id)))))

(provide 'notmuch-labeler-folder)

;;; notmuch-labeler-folder.el ends here
