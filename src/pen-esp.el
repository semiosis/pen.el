;; ESP

;; j:pen-lsp-client

;; Extra Sensory Perception for your computer
;; Based on LSP (Language Server Protocol), ESP provides intelligent overlays
;; and commands for your current computing environment.

(defun pen-start-esp ()
  (interactive)
  (message "Starting ESP in current buffer...")
  (call-interactively 'lsp))

(provide 'pen-esp)
