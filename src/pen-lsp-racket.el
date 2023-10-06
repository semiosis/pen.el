;;; lsp-racket.el --- Racket support for lsp-mode -*- lexical-binding: t -*-
(require 'lsp-mode)

(defcustom lsp-racket-executable-path "racket"
  "Path to Racket executable."
  :group 'lsp-racket
  :type 'string)

(defcustom lsp-racket-server-args '()
  "Extra arguments for the Racket language server."
  :group 'lsp-racket
  :type '(repeat string))

(defun lsp-racket--server-command ()
  "Generate the language server startup command."
  `(,lsp-racket-executable-path "--lib" "racket-langserver" ,@lsp-racket-server-args))

(defvar lsp-racket--config-options `())

(lsp-register-client
 (make-lsp-client :new-connection
                  (lsp-stdio-connection 'lsp-racket--server-command)
                  :major-modes '(racket-mode)
                  :server-id 'racket
                  :initialized-fn (λ (workspace)
                                    (with-lsp-workspace workspace
                                      (lsp--set-configuration
                                       `(:racket ,lsp-racket--config-options))))))

(provide 'pen-lsp-racket)
;;; lsp-racket.el ends here