;;; lsp-go.el --- go support for lsp-mode -*- lexical-binding: t -*-
(require 'lsp-mode)

(defcustom lsp-go-executable-path "gopls"
  "Path to go executable."
  :group 'lsp-go
  :type 'string)
(setq lsp-go-executable-path "gopls")

(defcustom lsp-go-server-args '()
  "Extra arguments for the go language server."
  :group 'lsp-go
  :type '(repeat string))

(defun lsp-go--server-command ()
  "Generate the language server startup command."
  `(,lsp-go-executable-path ,@lsp-go-server-args))

(defvar lsp-go--config-options `())

(lsp-register-client
 (make-lsp-client :new-connection
                  (lsp-stdio-connection 'lsp-go--server-command)
                  :major-modes '(go-mode go-ts-mode)
                  :server-id 'go
                  :initialized-fn (λ (workspace)
                                    (with-lsp-workspace workspace
                                      (lsp--set-configuration
                                       `(:go ,lsp-go--config-options))))))

(provide 'lsp-go)
;;; lsp-go.el ends here
