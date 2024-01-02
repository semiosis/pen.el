(require 'magit-section)

(advice-add 'magit-section-maybe-paint-visibility-ellipses :around #'ignore-errors-around-advice)

(define-key magit-section-mode-map (kbd "M-a") 'magit-section-up)
;; (define-key magit-section-mode-map (kbd "M-E") 'magit-section-backward-sibling)
(define-key magit-section-mode-map (kbd "M-E") 'magit-section-backward)
;; (define-key magit-section-mode-map (kbd "M-e") 'magit-section-forward-sibling)
(define-key magit-section-mode-map (kbd "M-e") 'magit-section-forward)

(provide 'pen-magit-section)
