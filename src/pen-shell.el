(require 'shell)

(defun shell-show-env ()
  (interactive)
  (ifi-etv (shell-eval-command "echo 5")))

(define-key shell-mode-map (kbd "C-c M-e") 'shell-show-env)

(provide 'pen-shell)
