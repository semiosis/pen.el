(define-derived-mode person-description-mode yaml-mode "Person"
  "Person description mode")

(add-to-list 'auto-mode-alist '("\\.person\\'" . person-description-mode))

(provide 'pen-personalities)