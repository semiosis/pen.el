;;; bbdb-notmuch.el --- BBDB interface to notmuch -*- lexical-binding: t -*-

;; Copyright (C) 2022  Free Software Foundation, Inc.

;; This file is part of the Insidious Big Brother Database (aka BBDB),

;; BBDB is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; BBDB is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with BBDB.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; This file contains the BBDB interface to notmuch.
;; See the BBDB info manual for documentation.

;;; Code:

(require 'bbdb)
(when t     ;Don't require during compilation, since elpa-notmuch might not be installed!
  (require 'notmuch-show)
  (require 'notmuch-tree))

(defvar notmuch-show-mode-map)
(defvar notmuch-tree-mode-map)

;;;###autoload
(defun bbdb/notmuch-header (header)
  "Find and return the value of HEADER in the current buffer.
Return nil if HEADER is not in the message.  This function works
in notmuch-show-mode and notmuch-tree-mode buffers."
  (let ((ps (if (derived-mode-p 'notmuch-tree-mode)
                (notmuch-tree-get-message-properties)
              (notmuch-show-get-message-properties)))
        (hdk (cond ((stringp header)
                    (intern (format ":%s" (capitalize header))))
                   ((keywordp header) header))))
    (plist-get (plist-get ps :headers) hdk)))

;;;###autoload
(defun bbdb-insinuate-notmuch ()
  "Hook BBDB into notmuch.
Do not call this in your init file.  Use `bbdb-initialize'."
  (dolist (m (list notmuch-show-mode-map notmuch-tree-mode-map))
    (define-key m ":" 'bbdb-mua-display-sender)
    (define-key m ";" 'bbdb-mua-edit-field-sender)))

;;; bbdb-notmuch.el ends here
