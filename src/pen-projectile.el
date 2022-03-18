(require 'projectile)

(defun my:projectile-ag-regex (arg)
  "Uses regex to search by default."
  (interactive "P")
  (setq current-prefix-arg (not arg))
  (call-interactively 'projectile-ag))

(add-hook 'prog-mode-hook 'projectile-mode)

(define-key projectile-mode-map (kbd "H-J") 'handle-projectfile)

(provide 'pen-projectile)