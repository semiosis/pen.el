;;; ebdb-complete.el --- Completion functionality for EBDB      -*- lexical-binding: t; -*-

;; Copyright (C) 2017-2023  Free Software Foundation, Inc.

;; Author: Feng Shu <tumashu@163.com>
;; Maintainer: Eric Abrahamsen <eric@ericabrahamsen.net>
;; Keywords: mail, convenience

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

;; This file contains the function `ebdb-complete' which pops
;; up a full EBDB window as email-chooser, typically in mail
;; composition buffers.

;; The simplest installation method is to call:

;; (ebdb-complete-enable)

;; This will bind TAB in message-mode and mail-mode to
;; `ebdb-complete', which will pop up a full EBDB buffer as a contact
;; chooser.
;;
;; This can also be done manually, e.g.:
;;
;; (define-key ebdb-mode-map "q" 'ebdb-complete-bury-ebdb-buffer)
;; (define-key ebdb-mode-map "\C-c\C-c" 'ebdb-complete-push-mail)
;; (define-key ebdb-mode-map (kbd "RET") 'ebdb-complete-push-mail-and-bury-ebdb-buffer)
;; (define-key message-mode-map "\t" 'ebdb-complete-message-tab)
;; (define-key mail-mode-map "\t" 'ebdb-complete-message-tab)

;;; Code:
(require 'ebdb-com)
(require 'message)
(require 'sendmail)

;;;###autoload

(defvar ebdb-complete-info (make-hash-table)
  "A hashtable recording buffer, buffer-window and window-point")

(defun ebdb-complete-push-mail (records &optional _ arg)
  "Push email-address(es) of `records' to buffer in `ebdb-complete-info'."
  (interactive (list (ebdb-do-records) nil
                     (or (consp current-prefix-arg)
                         current-prefix-arg)))
  (setq records (ebdb-record-list records))
  (if (not records)
      (message "No records")
    (let ((to (mapconcat
               (lambda (r)
                 (ebdb-dwim-mail r (ebdb-record-one-mail r arg)))
               records ", "))
          (buffer (gethash :buffer ebdb-complete-info)))
      (when buffer
        (with-current-buffer buffer
          (when (not (string= "" to))
            (when (save-excursion
                    (let* ((end (point))
                           (begin (line-beginning-position))
                           (string (buffer-substring-no-properties
                                    begin end)))
                      (and (string-match-p "@" string)
                           (not (string-match-p ", *$" string)))))
              (insert ", "))
            (insert to)
            (message "%s, will be push to buffer: \"%s\"" to buffer))
          (puthash :window-point (point) ebdb-complete-info))))))

(define-obsolete-function-alias
  'ebdb-complete-quit-window
  #'ebdb-complete-bury-ebdb-buffer "1.0.0")

(defun ebdb-complete-bury-ebdb-buffer ()
  "Hide EBDB buffer and switch to message buffer.
Before switch, this command will do some clean jobs."
  (interactive)
  ;; Hide header line in EBDB window.
  (with-current-buffer (ebdb-make-buffer-name)
    (setq header-line-format nil))
  ;; Hide ebdb buffer and update window point in Message window.
  (let ((buffer (gethash :buffer ebdb-complete-info))
        (window (gethash :window ebdb-complete-info))
        (window-point (gethash :window-point ebdb-complete-info)))
    (when (and (buffer-live-p buffer)
               (numberp window-point))
      (switch-to-buffer buffer)
      (set-window-point
       (if (window-live-p window)
           window
         (get-buffer-window))
       window-point)))
  ;; Clean hashtable `ebdb-complete-info'
  (setq ebdb-complete-info (clrhash ebdb-complete-info)))

(define-obsolete-function-alias
  'ebdb-complete-push-mail-and-quit-window
  #'ebdb-complete-push-mail-and-bury-ebdb-buffer "1.0.0")

(defun ebdb-complete-push-mail-and-bury-ebdb-buffer ()
  "Push email-address to Message window and hide EBDB buffer."
  (interactive)
  (if (gethash :buffer ebdb-complete-info)
      (progn (call-interactively 'ebdb-complete-push-mail)
             (ebdb-complete-bury-ebdb-buffer))
    (message "Invalid push buffer, Do nothing!!")))

(defun ebdb-complete-grab-word ()
  "Grab word at point, which used to build search string."
  (buffer-substring
   (point)
   (save-excursion
     (skip-syntax-backward "w_")
     (point))))

;;;###autoload
(defun ebdb-complete ()
  "Open EBDB window as an email-address selector,
if Word at point is found, EBDB will search this word
and show search results in EBDB window. This command
only useful in Message buffer."
  (interactive)
  (let ((buffer (current-buffer))
        prefix-string)
    ;; Update `ebdb-complete-info'
    (if (or (derived-mode-p 'message-mode)
            (derived-mode-p 'mail-mode))
        (progn
          (setq prefix-string (ebdb-complete-grab-word))
          (puthash :buffer buffer ebdb-complete-info)
          (puthash :window (get-buffer-window) ebdb-complete-info)
          (puthash :window-point (point) ebdb-complete-info))
      (setq ebdb-complete-info (clrhash ebdb-complete-info)
            prefix-string nil))
    ;; Call ebdb
    (if (and prefix-string (> (length prefix-string) 0))
        (progn
          (delete-char (- 0 (length prefix-string)))
          (puthash :window-point (point) ebdb-complete-info)
          (ebdb (ebdb-search-style) prefix-string))
      (if (save-excursion
            (let* ((end (point))
                   (begin (line-beginning-position))
                   (string (buffer-substring-no-properties
                            begin end)))
              (string-match-p "@.*>$" string)))
          ;; When point at "email@email.com><I>",
          ;; launch `ebdb-complete-mail'.
          (let ((ebdb-complete-mail-allow-cycling t))
            (message "Cycling current user's email address!")
            (ebdb-complete-mail)
            ;; Close ebdb-buffer's window when complete with
            ;; `ebdb-complete-mail'
            (let ((window (get-buffer-window (ebdb-make-buffer-name))))
              (if (window-live-p window)
                  (quit-window nil window))))
        (ebdb (ebdb-search-style) "")))
    ;; Update `header-line-format'
    (when (or (derived-mode-p 'message-mode)
              (derived-mode-p 'mail-mode))
      (with-current-buffer (ebdb-make-buffer-name)
        (setq header-line-format
              (format
               (substitute-command-keys
                (concat
                 "## Type `\\[ebdb-complete-push-mail]' or `\\[ebdb-complete-push-mail-and-bury-ebdb-buffer]' "
                 "to push email to buffer \"%s\". ##"))
               (buffer-name buffer)))))))

(defun ebdb-complete-message-tab ()
  "A command which will be bound to TAB key in message-mode,
when in message headers, this command will launch `ebdb-complete',
when in message body, this command will indent regular text."
  (interactive)
  (cond
   ;; Type TAB launch ebdb-complete when in header.
   ((and (save-excursion
           (let ((point (point)))
             (message-goto-body)
             (> (point) point)))
         (not (looking-back "^\\(Subject\\|From\\): *.*"
                            (line-beginning-position)))
         (not (looking-back "^" (line-beginning-position))))
    (ebdb-complete))
   (message-tab-body-function (funcall message-tab-body-function))
   (t (funcall (or (lookup-key text-mode-map "\t")
                   (lookup-key global-map "\t")
                   'indent-relative)))))

(defun ebdb-complete-keybinding-setup ()
  "Setup ebdb-complete Keybindings."
  (define-key ebdb-mode-map "q" #'ebdb-complete-bury-ebdb-buffer)
  (define-key ebdb-mode-map "\C-c\C-c" #'ebdb-complete-push-mail)
  (define-key ebdb-mode-map (kbd "RET") #'ebdb-complete-push-mail-and-bury-ebdb-buffer))

;;;###autoload
(defun ebdb-complete-enable ()
  "Enable ebdb-complete, it will rebind TAB key in `message-mode-map'."
  (interactive)
  (require 'message)
  (add-hook 'ebdb-mode-hook #'ebdb-complete-keybinding-setup)
  (define-key message-mode-map "\t" #'ebdb-complete-message-tab)
  (define-key mail-mode-map "\t" #'ebdb-complete-message-tab)
  (message "ebdb-complete: Override EBDB keybindings: `q', `C-c C-c' and `RET'"))

(provide 'ebdb-complete)

;; Local Variables:
;; coding: utf-8-unix
;; End:

;;; ebdb-complete.el ends here
