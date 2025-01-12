;;; ebdb-rmail.el --- EBDB interface to Rmail        -*- lexical-binding: t; -*-

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

;; EBDB's interaction with the Rmail MUA.

;;; Code:

(require 'ebdb-com)
(require 'ebdb-mua)
(require 'rmail)
(require 'rmailsum)
(require 'mailheader)

(defgroup ebdb-mua-rmail nil
  "EBDB customization for rmail."
  :group 'ebdb-mua)

(defcustom ebdb-rmail-auto-update-p ebdb-mua-reader-update-p
  "Rmail-specific value of `ebdb-mua-auto-update-p'."
  :type '(choice (const :tag "do nothing" nil)
                 (const :tag "search for existing records" existing)
                 (const :tag "update existing records" update)
                 (const :tag "query for update or record creation" query)
                 (const :tag "update or create automatically" create)
                 (function :tag "User-defined function")))

(defcustom ebdb-rmail-window-size ebdb-default-window-size
  "Size of the EBDB buffer when popping up in rmail.
Size should be specified as a float between 0 and 1.  Defaults to
the value of `ebdb-default-window-size'."
  :type 'float)

(defun ebdb/rmail-new-flag ()
  "Returns t if the current message in buffer BUF is new."
  (rmail-message-labels-p rmail-current-message ", ?\\(unseen\\),"))

(defun ebdb/rmail-header (header)
  "Pull HEADER out of Rmail header."
  (with-current-buffer rmail-buffer
    (if (fboundp 'rmail-get-header)  ; Emacs 23
        (rmail-get-header header)
      (save-restriction
        (with-no-warnings (rmail-narrow-to-non-pruned-header))
        (mail-header (intern-soft (downcase header))
                     (mail-header-extract))))))

(cl-defmethod ebdb-mua-message-header ((header string)
				   &context (major-mode rmail-mode))
  (ebdb/rmail-header header))

(cl-defmethod ebdb-mua-message-header ((header string)
				   &context (major-mode rmail-summary-mode))
  (ebdb/rmail-header header))

(cl-defmethod ebdb-make-buffer-name (&context (major-mode rmail-mode))
  (format "*%s-Rmail*" ebdb-buffer-name))

(cl-defmethod ebdb-make-buffer-name (&context (major-mode rmail-summary-mode))
  (format "*%s-Rmail*" ebdb-buffer-name))

(cl-defmethod ebdb-popup-buffer (&context (major-mode rmail-summary-mode))
  (list (get-buffer-window) ebdb-rmail-window-size))

;;;###autoload
(defun ebdb-insinuate-rmail ()
  "Hook EBDB into RMAIL."
  (unless ebdb-db-list
    (ebdb-load))
  (define-key rmail-mode-map ";" ebdb-mua-keymap))

;;;###autoload
(defun ebdb-rmail-auto-update ()
  (ebdb-mua-auto-update ebdb-rmail-auto-update-p))

(add-hook 'rmail-mode-hook #'ebdb-insinuate-rmail)

(add-hook 'rmail-show-message-hook #'ebdb-rmail-auto-update)

(provide 'ebdb-rmail)
;;; ebdb-rmail.el ends here
