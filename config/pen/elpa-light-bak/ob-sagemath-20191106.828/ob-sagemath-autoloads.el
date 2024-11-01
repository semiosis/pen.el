;;; ob-sagemath-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "ob-sagemath" "ob-sagemath.el" (0 0 0 0))
;;; Generated autoloads from ob-sagemath.el

(autoload 'ob-sagemath-execute-async "ob-sagemath" "\
Execute current src code block. With prefix argument, evaluate all code in a
buffer.

\(fn ARG)" t nil)

(autoload 'org-babel-execute:sage "ob-sagemath" "\


\(fn BODY PARAMS)" nil nil)

(register-definition-prefixes "ob-sagemath" '("ob-sagemath-" "org-babel-header-args:sage"))

;;;***

;;;### (autoloads nil nil ("ob-sagemath-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; ob-sagemath-autoloads.el ends here
