(define-derived-mode verse-description-mode yaml-mode "Verse"
  "Verse description mode")

(add-to-list 'auto-mode-alist '("\\.verse\\'" . verse-description-mode))

(provide 'pen-metaverses)