;;; lsp-r.el --- r support for lsp-mode -*- lexical-binding: t -*-
(require 'lsp-mode)

(defcustom lsp-r-executable-path "r-lsp"
  "Path to r executable."
  :group 'lsp-r
  :type 'string)
(setq lsp-r-executable-path "r-lsp")

(defcustom lsp-r-server-args '()
  "Extra arguments for the r language server."
  :group 'lsp-r
  :type '(repeat string))

(defun lsp-r--server-command ()
  "Generate the language server startup command."
  `(,lsp-r-executable-path ,@lsp-r-server-args))

(defvar lsp-r--config-options `())

(lsp-register-client
 (make-lsp-client :new-connection
                  (lsp-stdio-connection 'lsp-r--server-command)
                  :major-modes '(r-mode ess-r-mode)
                  :server-id 'r
                  :initialized-fn (lambda (workspace)
                                    (with-lsp-workspace workspace
                                      (lsp--set-configuration
                                       `(:r ,lsp-r--config-options))))))

(provide 'pen-lsp-r)
;;; lsp-r.el ends here
