;;; graphql-mode-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "graphql-mode" "graphql-mode.el" (0 0 0 0))
;;; Generated autoloads from graphql-mode.el

(autoload 'graphql-mode "graphql-mode" "\
A major mode to edit GraphQL schemas.

\(fn)" t nil)

(add-to-list 'auto-mode-alist '("\\.graphql\\'" . graphql-mode))

(add-to-list 'auto-mode-alist '("\\.gql\\'" . graphql-mode))

(register-definition-prefixes "graphql-mode" '("graphql-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; graphql-mode-autoloads.el ends here
