;;; lsp-c.el --- c support for lsp-mode -*- lexical-binding: t -*-
(require 'lsp-mode)

(defcustom lsp-c-executable-path "clangd"
  "Path to c executable."
  :group 'lsp-c
  :type 'string)
(setq lsp-c-executable-path "clangd")

(defcustom lsp-c-server-args '()
  "Extra arguments for the c language server."
  :group 'lsp-c
  :type '(repeat string))

(defun lsp-c--server-command ()
  "Generate the language server startup command."
  `(,lsp-c-executable-path ,@lsp-c-server-args))

(defvar lsp-c--config-options `())

(lsp-register-client
 (make-lsp-client :new-connection
                  (lsp-stdio-connection 'lsp-c--server-command)
                  :major-modes '(c-mode c-ts-mode)
                  :server-id 'c
                  :initialized-fn (λ (workspace)
                                    (with-lsp-workspace workspace
                                      (lsp--set-configuration
                                       `(:c ,lsp-c--config-options))))))

(provide 'pen-lsp-c)
;;; lsp-c.el ends here
