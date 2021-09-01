(require 'lsp-mode)

(defcustom pen-lsp-executable-path "pen-lsp"
  "Path to pen executable."
  :group 'pen-lsp
  :type 'string)

(defcustom pen-lsp-server-args '()
  "Extra arguments for the pen language server."
  :group 'pen-lsp
  :type '(repeat string))

(defun pen-lsp--server-command ()
  "Generate the language server startup command."
  ;; `(,pen-lsp-executable-path "--lib" "pen-langserver" ,@pen-lsp-server-args)
  `(,pen-lsp-executable-path ,@pen-lsp-server-args))

(defvar pen-lsp--config-options `())

(lsp-register-client
 (make-lsp-client :new-connection
                  (lsp-stdio-connection 'pen-lsp--server-command)
                  :major-modes '(pen-mode)
                  :server-id 'pen
                  :initialized-fn (lambda (workspace)
                                    (with-lsp-workspace workspace
                                      (lsp--set-configuration
                                       `(:pen ,pen-lsp--config-options))))))

(provide 'pen-lsp)
;;; pen-lsp.el ends here