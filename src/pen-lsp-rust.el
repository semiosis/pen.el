;;; lsp-rust.el --- rust support for lsp-mode -*- lexical-binding: t -*-
(require 'lsp-mode)

(defcustom lsp-rust-executable-path "rust-analyzer"
  "Path to rust executable."
  :group 'lsp-rust
  :type 'string)
(setq lsp-rust-executable-path "rust-analyzer")

(defcustom lsp-rust-server-args '()
  "Extra arguments for the rust language server."
  :group 'lsp-rust
  :type '(repeat string))

(defun lsp-rust--server-command ()
  "Generate the language server startup command."
  `(,lsp-rust-executable-path ,@lsp-rust-server-args))

(defvar lsp-rust--config-options `())

(lsp-register-client
 (make-lsp-client :new-connection
                  (lsp-stdio-connection 'lsp-rust--server-command)
                  :major-modes '(rust-mode rustic-mode rust-ts-mode)
                  :server-id 'rust
                  :initialized-fn (λ (workspace)
                                    (with-lsp-workspace workspace
                                      (lsp--set-configuration
                                       `(:rust ,lsp-rust--config-options))))))

(provide 'pen-lsp-rust)
;;; lsp-rust.el ends here
