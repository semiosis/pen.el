(setq w3m-session-crash-recovery nil)

(setq w3m-command (executable-find "w3m"))

(define-key w3m-mode-map (kbd "<up>") nil)
(define-key w3m-mode-map (kbd "<down>") nil)
(define-key w3m-mode-map (kbd "<left>") nil)
(define-key w3m-mode-map (kbd "<right>") nil)
(define-key w3m-mode-map (kbd "p") 'w3m-view-previous-page)
(define-key w3m-mode-map (kbd "n") 'w3m-view-this-url)

(provide 'pen-w3m)
