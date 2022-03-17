(define-key pen-map (kbd "M-l E .") (df edit-pen-editing (find-file (f-join pen-src-dir "pen-editing.el"))))
(define-key pen-map (kbd "M-l E d") (df deselect-i (deactivate-mark)))
(define-key pen-map (kbd "M-l E r") (df reselect-i (reselect-last-region)))

;; Don't do this until I can be bothered sorting out all the quirks
;; (setq kill-whole-line t)
(setq kill-whole-line nil)

(column-number-mode 1)


;; Ignore split window horizontally
(setq split-width-threshold nil)
(setq split-width-threshold 160)

;; Default Encoding
(prefer-coding-system 'utf-8-unix)
(set-locale-environment "en_US.UTF-8")
(set-default-coding-systems 'utf-8-unix)
(set-selection-coding-system 'utf-8-unix)
(set-buffer-file-coding-system 'utf-8-unix)
(set-clipboard-coding-system 'utf-8) ; included by set-selection-coding-system
(set-keyboard-coding-system 'utf-8) ; configured by prefer-coding-system
(set-terminal-coding-system 'utf-8) ; configured by prefer-coding-system
(setq buffer-file-coding-system 'utf-8) ; utf-8-unix
(setq save-buffer-coding-system 'utf-8-unix) ; nil
(setq process-coding-system-alist
  (cons '("grep" utf-8 . utf-8) process-coding-system-alist))

;; Quiet Startup
(setq inhibit-startup-screen t)
(setq inhibit-startup-message t)
(setq inhibit-startup-echo-area-message t)
(setq initial-scratch-message nil)

(defun display-startup-echo-area-message ()
  (message ""))

(setq frame-title-format nil)
(setq ring-bell-function 'ignore)
(setq uniquify-buffer-name-style 'post-forward-angle-brackets) ; Show path if names are same
(setq adaptive-fill-regexp "[ t]+|[ t]*([0-9]+.|*+)[ t]*")
(setq adaptive-fill-first-line-regexp "^* *$")
(setq sentence-end "\\([。、！？]\\|……\\|[,.?!][]\"')}]*\\($\\|[ \t]\\)\\)[ \t\n]*")
(setq sentence-end-double-space nil)
(setq delete-by-moving-to-trash t)    ; Deleting files go to OS's trash folder
(setq make-backup-files nil)          ; Forbide to make backup files
(setq auto-save-default nil)          ; Disable auto save
(setq set-mark-command-repeat-pop t)  ; Repeating C-SPC after popping mark pops it again
(setq track-eol t)			; Keep cursor at end of lines.
(setq line-move-visual nil)		; To be required by track-eol
;; (setq-default kill-whole-line t)
                                        ; Kill line including '\n'
(setq-default indent-tabs-mode nil)   ; use space
(defalias 'yes-or-no-p #'y-or-n-p)

(when (functionp 'mac-auto-ascii-mode)
  (mac-auto-ascii-mode 1))

;; Delete selection if insert someting
(use-package delsel
  :ensure nil
  :hook (after-init . delete-selection-mode))

;; Automatically reload files was modified by external program
(use-package autorevert
  :ensure nil
  :diminish
  :hook (after-init . global-auto-revert-mode))

;; I do not like hungry delete.
;; It's responsible for deleting more than one character when hitting backspace or C-h
;; ;; Hungry deletion
;; (use-package hungry-delete
;;   :diminish
;;   :hook (after-init . global-hungry-delete-mode)
;;   :config (setq-default hungry-delete-chars-to-skip " \t\f\v"))


(defun quoted-insert-nooctal (args)
  (interactive "P")
  (let* ((overwrite-mode 'overwrite-mode-textual))

    (setq current-prefix-arg args)
    (call-interactively 'quoted-insert)))

;; Now the following message does not appear
;; Please answer y or n. A command is running in the default buffer. Use
;; a new buffer? (y or n)
(setq async-shell-command-buffer 'new-buffer)

(define-key global-map (kbd "C-q") #'quoted-insert-nooctal)

(provide 'pen-editing)
