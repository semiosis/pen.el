;; http://github.com/semiosis/interpreters

(define-derived-mode ii-description-mode yaml-mode "Imaginary interpreter"
  "Prompt description mode")

(add-to-list 'auto-mode-alist '("\\.ii\\'" . ii-description-mode))

(provide 'pen-ii-description)