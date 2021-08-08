;; http://github.com/semiosis/engines

(define-derived-mode engine-description-mode yaml-mode "Engine"
  "Engine description mode")

(add-to-list 'auto-mode-alist '("\\.engine\\'" . engine-description-mode))

(provide 'pen-engine-description)