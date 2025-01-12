;;; ebdb-mu4e.el --- EBDB interface for mu4e         -*- lexical-binding: t; -*-

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

;; EBDB interface to mu4e.  This file was copied from bbdb-mu4e.el,
;; originally written by David Sterratt.

;;; Code:

(require 'ebdb-mua)
(require 'ebdb-message)
(if t (require 'mu4e-view))

(defvar mu4e~view-buffer-name)
(defvar mu4e-view-mode-map)
(declare-function message-field-value "message")

(defgroup ebdb-mua-mu4e nil
  "Mu4e-specific EBDB customizations."
  :group 'ebdb-mua)

(defcustom ebdb-mu4e-auto-update-p ebdb-mua-reader-update-p
  "Mu4e-specific value of `ebdb-mua-auto-update-p'."
  :type '(choice (const :tag "do nothing" nil)
                 (const :tag "search for existing records" existing)
                 (const :tag "update existing records" update)
                 (const :tag "query for update or record creation" query)
                 (const :tag "update or create automatically" create)
                 (function :tag "User-defined function")))

(defcustom ebdb-mu4e-window-size ebdb-default-window-size
  "Size of the EBDB buffer when popping up in mu4e.
Size should be specified as a float between 0 and 1.  Defaults to
the value of `ebdb-default-window-size'."
  :type 'float)

;; Tackle `mu4e-headers-mode' later

(cl-defmethod ebdb-mua-message-header ((header string)
				       &context (major-mode mu4e-view-mode))
  (set-buffer (if (bound-and-true-p mu4e-view-use-old)
              mu4e~view-buffer-name
              gnus-article-buffer))
  (message-field-value header))

(cl-defmethod ebdb-make-buffer-name (&context (major-mode mu4e-view-mode))
  "Produce a EBDB buffer name associated with mu4e mode."
  (format "*%s-mu4e*" ebdb-buffer-name))

(cl-defmethod ebdb-popup-window (&context (major-mode mu4e-view-mode))
  (list (get-buffer-window) ebdb-mu4e-window-size))

;;;###autoload
(defun ebdb-insinuate-mu4e ()
  "Hook EBDB into mu4e."
  ;; Tackle headers later
  (unless ebdb-db-list
    (ebdb-load))
  (define-key mu4e-view-mode-map ";" ebdb-mua-keymap)
  (add-hook 'message-sent-hook
	    (lambda ()
	      (let ((win (get-buffer-window (ebdb-message-buffer-name))))
		(when (and win
			   (window-live-p win))
		  (quit-window nil win))))))

;; Why wasn't `ebdb-mua-auto-update' ever hooked in to mu4e?

(add-hook 'mu4e-main-mode-hook #'ebdb-insinuate-mu4e)

(provide 'ebdb-mu4e)
;;; ebdb-mu4e.el ends here
