;;; cider-decompile-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "cider-decompile" "cider-decompile.el" (0 0
;;;;;;  0 0))
;;; Generated autoloads from cider-decompile.el

(autoload 'cider-decompile-func "cider-decompile" "\
Asks for the func name (FN-NAME) in the current namespace.and decompiles." t nil)

(autoload 'cider-decompile-ns-func "cider-decompile" "\
Asks for the func name (FN-NAME) in a specific namespace and decompiles it.
The FN-NAME should be prefixed with the namespace.

\(fn FN-NAME)" t nil)

(register-definition-prefixes "cider-decompile" '("cider-decompile"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; cider-decompile-autoloads.el ends here
