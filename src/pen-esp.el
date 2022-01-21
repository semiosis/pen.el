(defun pen-start-esp ()
  (interactive)
  (message "Starting ESP in current buffer...")
  (call-interactively 'lsp))

(provide 'pen-esp)