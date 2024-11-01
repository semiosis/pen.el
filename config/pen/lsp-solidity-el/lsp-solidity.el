;;; lsp-solidity.el --- Solidity support for lsp-mode -*- lexical-binding: t -*-
(require 'lsp-mode)

(defcustom lsp-solidity-executable-path "solc"
  "Path to solc executable."
  :group 'lsp-solidity
  :type 'string)

(defcustom lsp-solidity-server-args '()
  "Extra arguments for the Solidity language server."
  :group 'lsp-solidity
  :type '(repeat string))

(defun lsp-solidity--server-command ()
  "Generate the language server startup command."
  `(,lsp-solidity-executable-path "--lsp" ,@lsp-solidity-server-args))

(defvar lsp-solidity--config-options `())

(lsp-register-client
 (make-lsp-client :new-connection
                  (lsp-stdio-connection 'lsp-solidity--server-command)
                  :major-modes '(solidity-mode)
                  :server-id 'solidity
                  :initialized-fn (lambda (workspace)
                                    (with-lsp-workspace workspace
                                      (lsp--set-configuration
                                       `(:solidity ,lsp-solidity--config-options))))))

(provide 'lsp-solidity)
;;; lsp-solidity.el ends here