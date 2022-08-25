(require 'marginalia)
(require 'selectrum)

;; (straight-use-package 'selectrum)

;; Actually, I'm not a huge fan of selectrum currently
;; (selectrum-mode +1)

(define-key selectrum-minibuffer-map (kbd "<next>") 'selectrum-next-page)
(define-key selectrum-minibuffer-map (kbd "<prior>") 'selectrum-previous-page)

(provide 'pen-selectrum)
