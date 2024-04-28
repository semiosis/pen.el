;;; lsp-latex.el --- Latex support for lsp-mode -*- lexical-binding: t -*-
(require 'lsp-mode)

(defcustom lsp-latex-executable-path "texlab"
  "Path to Latex executable."
  :group 'lsp-latex
  :type 'string)

(defcustom lsp-latex-server-args '()
  "Extra arguments for the Latex language server."
  :group 'lsp-latex
  :type '(repeat string))

(defun lsp-latex--server-command ()
  "Generate the language server startup command."
  `(,lsp-latex-executable-path ,@lsp-latex-server-args))

(defvar lsp-latex--config-options `())

(lsp-register-client
 (make-lsp-client :new-connection
                  (lsp-stdio-connection 'lsp-latex--server-command)
                  :major-modes '(latex-mode)
                  :server-id 'latex
                  :initialized-fn (lambda (workspace)
                                    (with-lsp-workspace workspace
                                      (lsp--set-configuration
                                       `(:latex ,lsp-latex--config-options))))))

(provide 'pen-lsp-latex)
;;; lsp-latex.el ends here
