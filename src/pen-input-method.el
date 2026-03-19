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

(defun set-input-method-apl ()
  (interactive)
  (set-input-method 'APL-Z))

(defun set-input-method-around-advice (proc &rest args)
  (message "set-input-method called with args %S" args)
  (let ((res (apply proc args)))
    (message "set-input-method returned %S" res)
    res))
(advice-add 'set-input-method :around #'set-input-method-around-advice)
;; (advice-remove 'set-input-method #'set-input-method-around-advice)

(defun pen-set-input-method ()
  (interactive)
  (if (>= (prefix-numeric-value current-prefix-arg) 4)
      ;; Use tmux to start sending a new key binding
      (tsk "C-x C-m")
    (call-interactively 'set-input-method)))

;; C-h in a keybinding is useful for showing possible keybindings, so can't use. Keep it free
(define-key global-map (kbd "C-c C-k") 'pen-set-input-method)
(define-key global-map (kbd "C-x RET C-h") nil)
(define-key global-map (kbd "C-x RET w") 'set-input-method-hebrew)
(define-key global-map (kbd "C-x RET g") 'set-input-method-greek)
(define-key global-map (kbd "C-x RET a") 'set-input-method-apl)
(define-key global-map (kbd "C-x RET j") 'set-input-method-japanese)
(define-key global-map (kbd "C-x RET d") 'set-input-method-default)
(define-key global-map (kbd "C-x RET e") 'set-input-method-default)

(provide 'pen-input-method)
