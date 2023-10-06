;;; lsp-common-lisp.el --- Common-Lisp support for lsp-mode -*- lexical-binding: t -*-
(require 'lsp-mode)

(defcustom lsp-common-lisp-executable-path "cl-lsp"
  "Path to Common-Lisp executable."
  :group 'lsp-common-lisp
  :type 'string)

(defcustom lsp-common-lisp-server-args '()
  "Extra arguments for the Common-Lisp language server."
  :group 'lsp-common-lisp
  :type '(repeat string))

(defun lsp-common-lisp--server-command ()
  "Generate the language server startup command."
  `(,lsp-common-lisp-executable-path
    ;; "--lib" "common-lisp-langserver"
    ,@lsp-common-lisp-server-args))

(defvar lsp-common-lisp--config-options `())

(lsp-register-client
 (make-lsp-client :new-connection
                  (lsp-stdio-connection 'lsp-common-lisp--server-command)
                  :major-modes '(lisp-mode)
                  :server-id 'common-lisp
                  :initialized-fn (λ (workspace)
                                    (with-lsp-workspace workspace
                                      (lsp--set-configuration
                                       `(:common-lisp ,lsp-common-lisp--config-options))))))

(provide 'pen-lsp-common-lisp)
;;; lsp-common-lisp.el ends here
