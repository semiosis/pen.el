;;; lsp-vimrc.el --- vimrc support for lsp-mode -*- lexical-binding: t -*-
(require 'lsp-mode)

(defcustom lsp-vimrc-executable-path "vimls"
  "Path to vimrc executable."
  :group 'lsp-vimrc
  :type 'string)
(setq lsp-vimrc-executable-path "vimls")

(defcustom lsp-vimrc-server-args '()
  "Extra arguments for the vimrc language server."
  :group 'lsp-vimrc
  :type '(repeat string))

(defun lsp-vimrc--server-command ()
  "Generate the language server startup command."
  `(,lsp-vimrc-executable-path ,@lsp-vimrc-server-args))

(defvar lsp-vimrc--config-options `())

(lsp-register-client
 (make-lsp-client :new-connection
                  (lsp-stdio-connection 'lsp-vimrc--server-command)
                  :major-modes '(vimrc-mode vimrcic-mode vimrc-ts-mode)
                  :server-id 'vimrc
                  :initialized-fn (λ (workspace)
                                    (with-lsp-workspace workspace
                                      (lsp--set-configuration
                                       `(:vimrc ,lsp-vimrc--config-options))))))

(provide 'pen-lsp-vimrc)
;;; lsp-vimrc.el ends here

;; (dolist (m '(vimrcic-mode vimrc-ts-mode))
;;   (add-to-list 'lsp-language-id-configuration `(,m . "vimrc")))
