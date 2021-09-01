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

;; Set up for text-mode currently

(lsp-register-client
 (make-lsp-client :new-connection
                  (lsp-stdio-connection 'pen-lsp--server-command)
                  :major-modes '(text-mode)
                  :server-id 'pen
                  :initialized-fn (lambda (workspace)
                                    (with-lsp-workspace workspace
                                      (lsp--set-configuration
                                       `(:pen ,pen-lsp--config-options))))))

(add-hook 'text-mode-hook #'lsp)

;; This is for the language server to know what language I'm using
(add-to-list 'lsp-language-id-configuration '(text-mode . "text"))

(provide 'pen-lsp)
;;; pen-lsp.el ends here