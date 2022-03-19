(require 'lispy)

;; (add-hook 'emacs-lisp-mode-hook '(lambda () (lispy-mode 1)))

(advice-add 'lispy-mark-symbol :around #'ignore-errors-around-advice)
(advice-add 'kill-ring-save :around #'ignore-errors-around-advice)

(defun pen-elisp-expand-macro-or-copy ()
  (interactive)
  (if mark-active
      (xc)
    (call-interactively 'macrostep-expand)))

(define-key emacs-lisp-mode-map (kbd "M-w") #'pen-elisp-expand-macro-or-copy)

(provide 'pen-elisp)