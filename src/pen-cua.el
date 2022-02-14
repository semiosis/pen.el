(require 'cua-base)
(define-key global-map (kbd "<M-f5>") 'cua-paste)
(define-key global-map (kbd "<C-y>") 'cua-paste)
(setq cua-enable-cua-keys nil)

(provide 'pen-cua)