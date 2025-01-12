;;; notmuch-labeler-plug --- Plugs notmuch-labeler to notmuch interface
;;
;; Copyright (C) 2012 Damien Cassou
;;
;; Author: Damien Cassou <damien.cassou@gmail.com>
;; Url: https://github.com/DamienCassou/notmuch-labeler
;; GIT: https://github.com/DamienCassou/notmuch-labeler
;; Version: 0.1
;; Created: 2012-10-01
;; Keywords: emacs package elisp notmuch emails
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
;;; Code:

(require 'cl)

(defadvice notmuch-search-insert-field
  (around nml--search-insert-field activate)
  "Change presentation of labels in search results."
  (let ((field (ad-get-arg 0))
	(result (ad-get-arg 2)))
    (cond
     ((string-equal field "tags")
      (insert
       (format-mode-line
	(nml--present-labels
	 (nml--thread-labels-from-search
	  result
	  notmuch-search-query-string)))))
     ;; in all other cases use the default implementation in the
     ;; advised function
     (t ad-do-it))))

(defun nml--thread-labels-from-search (result &optional query)
  "Return the thread labels as returned by notmuch in RESULT."
  ;; only shows the labels that are not directly searched
  (let ((all-labels (plist-get result :tags)))
    (if (and query notmuch-labeler-hide-known-labels)
	(set-difference
	 all-labels
	 (nml--extract-labels-from-query
	  notmuch-search-query-string) :test 'string=)
      all-labels)))

(defadvice notmuch-show-build-buffer
  (after nml--show-build-buffer-update-header activate)
  "Make the header-line of `notmuch-show' present the labels."
  (nml--update-header-line (nml--show-thread-id)))

(defun nml--show-thread-id ()
  "Return the currently visited thread id."
  ;; `notmuch-show-thread-id' is of the form "thread:00001212" so we
  ;; have to extract the second part.
  (second (split-string notmuch-show-thread-id ":")))

(defun nml--update-header-line (thread-id)
  "Add the labels of THREAD-ID to header line."
  (setq header-line-format
	(cons
	 ;; subject of the thread:
	 (notmuch-show-strip-re (notmuch-show-get-subject))
	 ;; followed by labels:
	 (nml--present-labels
	  (nml--thread-labels-from-id thread-id)))))

(defun nml--thread-labels-from-id (thread-id)
  "Return the labels of thread whose id is THREAD-ID.
The thread labels are the union of the labels of emails in the
thread."
  (let ((labels-list
	 (notmuch-query-map-threads
	  (lambda (msg) (plist-get msg :tags))
	  (notmuch-query-get-threads
	   `(,(concat "thread:" thread-id))))))
    (case (length labels-list)
      (0 nil)
      (1 (car labels-list))
      (otherwise (reduce (lambda (l1 l2)
			   (union l1 l2 :test 'string=))
			 labels-list)))))


(defun nml--show-headerline-replace ()
  "Replace the default label representation in `notmuch-show'."
  (notmuch-show-mapc ;; for each email in notmuch-show...
   'nml--show-headerline-replace-one))

(defun nml--show-headerline-replace-one ()
  "Replace the default label representation of one email."
  (save-excursion
    (when (re-search-forward " ([^()]*)$" (line-end-position) t)
      (let ((inhibit-read-only t))
	(goto-char (match-beginning 0))
	(delete-region (match-beginning 0) (match-end 0))
	(insert
	 (format-mode-line
	  (nml--present-labels
	   (nml--message-labels-from-properties
	    (notmuch-show-get-message-properties)))))))))

(defadvice notmuch-show-update-tags
  (around nml--show-update-tags activate)
  "Change presentation of labels in each email."
  (save-excursion
    (goto-char (notmuch-show-message-top))
    (nml--show-headerline-replace-one))
  (nml--update-header-line (nml--show-thread-id)))

;; Show the list of labels on each email of notmuch show
(add-hook 'notmuch-show-hook 'nml--show-headerline-replace t)

(defun nml--message-labels-from-properties (properties)
  "Find the labels of a message from its PROPERTIES."
  (plist-get properties :tags))

(provide 'notmuch-labeler-plug)
;;; notmuch-labeler-plug.el ends here
