(require 'shell)

(setq explicit-shell-file-name "pash")

(setq shell-kill-buffer-on-exit t)

(defun shell-show-env ()
  (interactive)
  (ifi-etv (shell-eval-command "echo 5")))

(comment
 ;; shell (not eshell)
 (defun shell-run-command (cmd)
   (interactive (list (read-string-hist "shell$ ")))
   (shell)
   (with-current-buffer "*shell*"
     (eshell-return-to-prompt)
     (eshell-kill-input)
     ;; (kill-line)
     (insert cmd)
     (eshell-send-input))))

(define-key shell-mode-map (kbd "C-c M-e") 'shell-show-env)

(provide 'pen-shell)
