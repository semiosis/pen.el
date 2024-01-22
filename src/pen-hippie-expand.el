(require 'hippie-exp)
(require 'hippie-exp-ext)

(remove-from-list 'hippie-expand-try-functions-list 'yas-hippie-try-expand)

(setq hippie-expand-try-functions-list '(try-expand-dabbrev try-expand-dabbrev-all-buffers try-expand-dabbrev-from-kill try-complete-file-name-partially try-complete-file-name try-expand-all-abbrevs try-expand-list try-expand-line try-complete-lisp-symbol-partially try-complete-lisp-symbol))

(defun pen-hippie-expand ()
  (interactive)
  (if
      (and
       (major-mode-p 'emacs-lisp-mode)
       (or (string-equal " " (thing-at-point 'char))
           (string-equal ")" (thing-at-point 'char)))
       (not (thing-at-point 'symbol)))
      (try
       (call-interactively 'elisp-complete-interactive-arg)
       (call-interactively 'hippie-expand))
    (call-interactively 'hippie-expand)))

(provide 'pen-hippie-expand)
