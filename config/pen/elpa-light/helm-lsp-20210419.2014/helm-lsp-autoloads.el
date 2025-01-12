;;; helm-lsp-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "helm-lsp" "helm-lsp.el" (0 0 0 0))
;;; Generated autoloads from helm-lsp.el

(autoload 'helm-lsp-workspace-symbol "helm-lsp" "\
`helm' for lsp workspace/symbol.
When called with prefix ARG the default selection will be symbol at point.

\(fn ARG)" t nil)

(autoload 'helm-lsp-global-workspace-symbol "helm-lsp" "\
`helm' for lsp workspace/symbol for all of the current workspaces.
When called with prefix ARG the default selection will be symbol at point.

\(fn ARG)" t nil)

(autoload 'helm-lsp-code-actions "helm-lsp" "\
Show lsp code actions using helm." t nil)

(autoload 'helm-lsp-diagnostics "helm-lsp" "\
Diagnostics using `helm'

\(fn ARG)" t nil)

(register-definition-prefixes "helm-lsp" '("helm-lsp-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; helm-lsp-autoloads.el ends here
