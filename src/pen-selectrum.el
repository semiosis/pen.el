(require 'marginalia)
(require 'selectrum)

;; (straight-use-package 'selectrum)

;; Actually, I'm not a huge fan of selectrum currently
;; (selectrum-mode +1)

(defun pen-selectrum-copy-current-candidate ()
  (interactive)
  (xc (selectrum-get-current-candidate)))

(define-key selectrum-minibuffer-map (kbd "<next>") 'selectrum-next-page)
(define-key selectrum-minibuffer-map (kbd "<prior>") 'selectrum-previous-page)

(define-key selectrum-minibuffer-map (kbd "M-p") 'selectrum-previous-candidate)
(define-key selectrum-minibuffer-map (kbd "M-n") 'selectrum-next-candidate)
(define-key selectrum-minibuffer-map (kbd "M-c") 'pen-selectrum-copy-current-candidate)

(provide 'pen-selectrum)
