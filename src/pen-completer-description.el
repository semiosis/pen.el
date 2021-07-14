;; http://github.com/semiosis/completers

(define-derived-mode completer-description-mode yaml-mode "Completer"
  "Completer description mode")

(add-to-list 'auto-mode-alist '("\\.completer\\'" . completer-description-mode))

(provide 'pen-completer-description)