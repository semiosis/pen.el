;;; ebdb-wl.el --- EBDB interface to Wanderlust  -*- lexical-binding: t; -*-

;; Copyright (C) 2017-2023  Free Software Foundation, Inc.

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
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; EBDB's interface to the Wanderlust email client.

;;; Code:

(require 'ebdb-mua)

(autoload 'elmo-message-entity-field "ext:elmo-msgdb")
(autoload 'elmo-message-entity "ext:elmo")
(autoload 'wl-summary-message-number "ext:wl-summary")
(autoload 'wl-summary-set-message-buffer-or-redisplay "ext:wl-summary")

(defvar wl-current-summary-buffer)
(defvar wl-summary-buffer-elmo-folder)
(defvar wl-message-buffer)
(defvar wl-summary-mode-map)
(defvar wl-draft-mode-map)
(defvar wl-folder-buffer-name)
(defvar wl-highlight-signature-separator)
(defvar mime-view-mode-default-map)

(defgroup ebdb-mua-wl nil
  "Options for EBDB's interaction with Wanderlust."
  :group 'ebdb-mua)

(defcustom ebdb-wl-auto-update-p ebdb-mua-reader-update-p
  "Wl-specific value of `ebdb-mua-auto-update-p'."
  :type '(choice (const :tag "do nothing" nil)
                 (const :tag "search for existing records" existing)
                 (const :tag "update existing records" update)
                 (const :tag "query for update or record creation" query)
                 (const :tag "update or create automatically" create)
                 (function :tag "User-defined function")))

(defcustom ebdb-wl-window-size ebdb-default-window-size
  "Size of the EBDB buffer when popping up in Wanderlust.
Size should be specified as a float between 0 and 1.  Defaults to
the value of `ebdb-default-window-size'."
  :type 'float)

(cl-defmethod ebdb-mua-message-header ((header string)
				       &context (major-mode mime-view-mode))
  "Extract a message header in Wanderlust."
  (elmo-message-entity-field
   ;; It's possibly not safe to assume `wl-current-summary-buffer' is live?
   (with-current-buffer wl-current-summary-buffer
     (elmo-message-entity wl-summary-buffer-elmo-folder
			  (wl-summary-message-number)))
   (intern (downcase header)) 'string))

(cl-defmethod ebdb-mua-message-header ((header string)
				       &context (major-mode wl-summary-mode))
  "Extract a message header in Wanderlust."
  (elmo-message-entity-field
   ;; It's possibly not safe to assume `wl-current-summary-buffer' is live?
   (with-current-buffer wl-current-summary-buffer
     (elmo-message-entity wl-summary-buffer-elmo-folder
			  (wl-summary-message-number)))
   (intern (downcase header)) 'string))

(cl-defmethod ebdb-mua-prepare-article (&context (major-mode wl-summary-mode))
  (wl-summary-set-message-buffer-or-redisplay))

(cl-defmethod ebdb-make-buffer-name (&context (major-mode mime-view-mode))
  (format "*%s-Wl*" ebdb-buffer-name))

(cl-defmethod ebdb-make-buffer-name (&context (major-mode wl-summary-mode))
  (format "*%s-Wl*" ebdb-buffer-name))

(cl-defmethod ebdb-make-buffer-name (&context (major-mode wl-folder-mode))
  (format "*%s-Wl*" ebdb-buffer-name))

(cl-defmethod ebdb-make-buffer-name (&context (major-mode wl-draft-mode))
  (format "*%s-Wl-Draft*" ebdb-buffer-name))

(cl-defmethod ebdb-popup-window (&context (major-mode mime-view-mode))
  (list (get-buffer-window) ebdb-wl-window-size))

(defsubst ebdb-wl-goto-signature (&optional beginning)
  "Goto the signature in the current message buffer.
Leaves point at the end (or, with non-nil BEGINNING, the
beginning) of the signature separator."
  (re-search-forward
   (mapconcat
    #'identity
    (cons "\n==+\n" wl-highlight-signature-separator)
    "\\|")
   (point-max) t)
  (when beginning
    (goto-char (match-beginning 0)))
  (point))

(cl-defmethod ebdb-mua-article-body (&context (major-mode wl-summary-mode))
  (with-current-buffer wl-message-buffer
    (when (re-search-forward "^$" (point-max) t)
      (buffer-substring-no-properties
       (point)
       (or (ebdb-wl-goto-signature t)
	   (point-max))))))

(cl-defmethod ebdb-mua-article-signature (&context (major-mode wl-summary-mode))
  (with-current-buffer wl-message-buffer
    (when (re-search-forward "^$" (point-max) t)
      (or (and (ebdb-wl-goto-signature)
	       (buffer-substring-no-properties (point) (point-max)))
	  ""))))

(defun ebdb-wl-quit-window ()
  "Quit EBDB window when quitting WL summary buffer."
  ;; This runs in a hook, which are run in no buffer: we need to be in
  ;; a WL buffer in order to get back the correct EBDB buffer name.
  (with-current-buffer wl-folder-buffer-name
    (let ((win (get-buffer-window (ebdb-make-buffer-name))))
      (when win
	(quit-window nil win)))))

;;;###autoload
(defun ebdb-insinuate-wl ()
  "Hook EBDB into Wanderlust."
  (unless ebdb-db-list
    (ebdb-load))
  (define-key wl-summary-mode-map ";" ebdb-mua-keymap)
  (define-key mime-view-mode-default-map ";" ebdb-mua-keymap)
  (when ebdb-complete-mail
    (define-key wl-draft-mode-map (kbd "TAB") #'ebdb-complete-mail))
  (add-hook 'wl-summary-exit-hook #'ebdb-wl-quit-window))

;;;###autoload
(defun ebdb-wl-auto-update ()
  (ebdb-mua-auto-update ebdb-wl-auto-update-p))

(add-hook 'wl-folder-mode-hook #'ebdb-insinuate-wl)

(add-hook 'wl-summary-redisplay-hook #'ebdb-wl-auto-update)

(provide 'ebdb-wl)
;;; ebdb-wl.el ends here
