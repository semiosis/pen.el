(require 'cl-macs)
(require 'select)

;; This doesn't work for the terminal version though
;; after copy Ctrl+c in Linux X11, you can paste by `yank' in emacs
(setq x-select-enable-clipboard t)

;; after mouse selection in X11, you can paste by `yank' in emacs
(setq x-select-enable-primary t)

(setq select-enable-clipboard t)
(setq select-enable-primary t)

;; this isn't working
;; I just want the clipboard to work
(setq x-select-enable-primary t)
(setq x-select-enable-clipboard t)

;; This prevents selections (while using the GUI) from affecting the clipboard.
;; It also makes the GUI function more like the terminal.
(defun gui-set-selection (&rest args))

(ignore-errors
  (xclip-mode 1)
  )

(setq interprogram-paste-function 'x-cut-buffer-or-selection-value)


;; This appears to do a much better job that simpleclip

;; CUA OS copypasta even in ncurses mode
(case system-type
  ('darwin (unless window-system
             (setq interprogram-cut-function
                   (lambda (text &optional push)
                     (let* ((process-connection-type nil)
                            (pbproxy (start-process "pbcopy" "pbcopy" "/usr/bin/pbcopy")))
                       (process-send-string pbproxy text)
                       (process-send-eof pbproxy))))))
  ('gnu/linux (progn
                (setq x-select-enable-clipboard t)
                (defun xsel-cut-function (text &optional push)
                  (with-temp-buffer
                    (insert text)
                    (call-process-region (point-min) (point-max) "xsel" nil 0 nil "--clipboard" "--input")))
                (defun xsel-paste-function()

                  (let ((xsel-output (shell-command-to-string "xsel --clipboard --output")))
                    (unless (string= (car kill-ring) xsel-output)
                      xsel-output )))
                (setq interprogram-cut-function 'xsel-cut-function)
                (setq interprogram-paste-function 'xsel-paste-function))))

(advice-add 'gui-get-primary-selection :around #'ignore-errors-around-advice)
(advice-add 'insert-for-yank :around #'ignore-errors-around-advice)

(provide 'pen-clipboard)