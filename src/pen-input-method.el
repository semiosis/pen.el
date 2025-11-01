(defun set-input-method-hebrew ()
  (interactive)
  (set-input-method 'hebrew-biblical-sil))

(defun set-input-method-japanese ()
  (interactive)
  (set-input-method 'japanese))

(defun set-input-method-greek ()
  (interactive)
  (set-input-method 'greek))

(defun set-input-method-default ()
  (interactive)
  (set-input-method 'rfc1345))

;; C-h in a keybinding is useful for showing possible keybindings, so can't use. Keep it free
(define-key global-map (kbd "C-x RET C-w") 'set-input-method-hebrew)
(define-key global-map (kbd "C-x RET C-h") nil)
(define-key global-map (kbd "C-x RET C-g") 'set-input-method-greek)
(define-key global-map (kbd "C-x RET C-j") 'set-input-method-japanese)
(define-key global-map (kbd "C-x RET C-d") 'set-input-method-default)
(define-key global-map (kbd "C-x RET C-e") 'set-input-method-default)

(provide 'pen-input-method)
