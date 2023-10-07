;;; lsp-python.el --- python support for lsp-mode -*- lexical-binding: t -*-
(require 'lsp-mode)

(defcustom lsp-python-executable-path "pylsp"
  "Path to python executable."
  :group 'lsp-python
  :type 'string)
(setq lsp-python-executable-path "pylsp")

(defcustom lsp-python-server-args '()
  "Extra arguments for the python language server."
  :group 'lsp-python
  :type '(repeat string))

(defun lsp-python--server-command ()
  "Generate the language server startup command."
  `(,lsp-python-executable-path ,@lsp-python-server-args))

(defvar lsp-python--config-options `())

(lsp-register-client
 (make-lsp-client :new-connection
                  (lsp-stdio-connection 'lsp-python--server-command)
                  :major-modes '(python-mode python-ts-mode)
                  :server-id 'python
                  :initialized-fn (λ (workspace)
                                    (with-lsp-workspace workspace
                                      (lsp--set-configuration
                                       `(:python ,lsp-python--config-options))))))

(provide 'pen-lsp-python)
;;; lsp-python.el ends here
