(require 'comint)

(define-key comint-mode-map (kbd "C-j") 'comint-accumulate)
(define-key comint-mode-map (kbd "C-a") 'comint-bol)
(define-key comint-mode-map (kbd "C-e") 'end-of-line)

(provide 'pen-comint)