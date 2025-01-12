;;; ebdb-mhe.el --- EBDB interface to mh-e           -*- lexical-binding: t; -*-

;; Copyright (C) 2016-2023  Free Software Foundation, Inc.

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

;; EBDB interface to mh-e.  This was copied from the file bbdb-mhe.el,
;; written by Todd Kaufman with contributions from Fritz Knabe and
;; Jack Repenning.

;;; Code:

(require 'ebdb-com)
(require 'ebdb-mua)
(require 'mh-e)
(if (fboundp 'mh-version)
    (require 'mh-comp))              ; For mh-e 4.x

(defgroup ebdb-mua-mhe nil
  "EBDB customizations for mhe."
  :group 'ebdb-mua)

(defcustom ebdb-mhe-auto-update-p ebdb-mua-reader-update-p
  "Mh-e-specific value of `ebdb-mua-auto-update-p'."
  :type '(choice (const :tag "do nothing" nil)
                 (const :tag "search for existing records" existing)
                 (const :tag "update existing records" update)
                 (const :tag "query for update or record creation" query)
                 (const :tag "update or create automatically" create)
                 (function :tag "User-defined function")))

(defcustom ebdb-mhe-window-size ebdb-default-window-size
  "Size of the EBDB buffer when popping up in mh-e.
Size should be specified as a float between 0 and 1.  Defaults to
the value of `ebdb-default-window-size'."
  :type 'float)

;; A simplified `mail-fetch-field'.  We could use instead (like rmail):
;; (mail-header (intern-soft (downcase header)) (mail-header-extract))
(defun ebdb/mh-header (header)
  "Find and return the value of HEADER in the current buffer.
Returns the empty string if HEADER is not in the message."
  (let ((case-fold-search t))
    (if mh-show-buffer (set-buffer mh-show-buffer))
    (goto-char (point-min))
    ;; This will be fooled if HEADER appears in the body of the message.
    ;; Also, it fails if HEADER appears more than once.
    (cond ((not (re-search-forward header nil t)) "")
          ((looking-at "[\t ]*$") "")
          (t (re-search-forward "[ \t]*\\([^ \t\n].*\\)$" nil t)
             (let ((start (match-beginning 1)))
               (while (progn (forward-line 1)
                             (looking-at "[ \t]")))
               (backward-char 1)
               (buffer-substring-no-properties start (point)))))))

(cl-defmethod ebdb-make-buffer-name (&context (major-mode mhe-mode))
  "Produce a EBDB buffer name associated with mh-hmode."
  (format "*%s-MHE*" ebdb-buffer-name))

(cl-defmethod ebdb-make-buffer-name (&context (major-mode mhe-summary-mode))
  "Produce a EBDB buffer name associated with mh-hmode."
  (format "*%s-MHE*" ebdb-buffer-name))

(cl-defmethod ebdb-make-buffer-name (&context (major-mode mhe-folder-mode))
  "Produce a EBDB buffer name associated with mh-hmode."
  (format "*%s-MHE*" ebdb-buffer-name))

(cl-defmethod ebdb-popup-buffer (&context (major-mode mhe-summary-mode))
  (list (get-buffer-window) ebdb-mhe-window-size))

(cl-defmethod ebdb-mua-message-header ((header string)
				       &context (major-mode mhe-mode))
  (ebdb/mh-header header))

(cl-defmethod ebdb-mua-message-header ((header string)
				   &context (major-mode mhe-summary-mode))
  (ebdb/mh-header header))

(cl-defmethod ebdb-mua-message-header ((header string)
				   &context (major-mode mhe-folder-mode))
  (ebdb/mh-header header))

(cl-defmethod ebdb-mua-prepare-article (&context (major-mode mhe-mode))
  (mh-show))

(cl-defmethod ebdb-mua-prepare-article (&context (major-mode mhe-summary-mode))
  (mh-show))

(cl-defmethod ebdb-mua-prepare-article (&context (major-mode mhe-folder-mode))
  (mh-show))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Use EBDB for interactive spec of MH-E commands

(advice-add 'mh-send :before #'ebdb--mh-send-completion)
(defun ebdb--mh-send-completion (&rest _)
  (interactive
   (list (ebdb-completing-read-mails "To: ")
         (ebdb-completing-read-mails "Cc: ")
         (read-string "Subject: ")))
  nil)

(advice-add 'mh-send-other-window :before #'ebdb--mh-send-completion)

(advice-add 'mh-forward :before #'ebdb--mh-forward-completion)
(defun ebdb--mh-forward-completion (&rest _)
  (interactive
   (list (ebdb-completing-read-mails "To: ")
         (ebdb-completing-read-mails "Cc: ")
         (if current-prefix-arg
             (mh-read-seq-default "Forward" t)
           (mh-get-msg-num t))))
  nil)

(advice-add 'mh-redistribute :before #'ebdb--mh-redistribute-completion)
(defun ebdb--mh-redistribute-completion (&rest _)
  (interactive
   (list (ebdb-completing-read-mails "Redist-To: ")
         (ebdb-completing-read-mails "Redist-Cc: ")
         (mh-get-msg-num t)))
  nil)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;###autoload
(defun ebdb-insinuate-mh ()
  "Hook EBDB into MH-E."
  (unless ebdb-db-list
    (ebdb-load))
  (define-key mh-folder-mode-map ";" ebdb-mua-keymap)
  (when ebdb-complete-mail
    (define-key mh-letter-mode-map "\M-;" #'ebdb-complete-mail)
    (define-key mh-letter-mode-map "\e\t" #'ebdb-complete-mail)))

;;;###autoload
(defun ebdb-mhe-auto-update ()
  (ebdb-mua-auto-update ebdb-mhe-auto-update-p))

(add-hook 'mh-show-hook #'ebdb-mhe-auto-update)

(add-hook 'mh-folder-mode-hook #'ebdb-insinuate-mh)

(provide 'ebdb-mhe)
;;; ebdb-mhe.el ends here
