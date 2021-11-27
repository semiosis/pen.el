(require 'lispy)

;; (add-hook 'emacs-lisp-mode-hook '(lambda () (lispy-mode 1)))

(advice-add 'lispy-mark-symbol :around #'ignore-errors-around-advice)
(advice-add 'kill-ring-save :around #'ignore-errors-around-advice)

(provide 'pen-elisp)