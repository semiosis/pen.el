(require 'cua-base)

(define-key global-map (kbd "<M-f5>") 'cua-paste)

(cua-mode 1)

;; (define-key global-map (kbd "C-y") 'cua-paste)
;; (define-key global-map (kbd "C-y") nil)
;; (define-key pen-map (kbd "C-y") 'cua-paste)

(setq cua-enable-cua-keys nil)

(provide 'pen-cua)