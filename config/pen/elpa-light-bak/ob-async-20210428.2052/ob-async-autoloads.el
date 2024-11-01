;;; ob-async-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "ob-async" "ob-async.el" (0 0 0 0))
;;; Generated autoloads from ob-async.el

(defalias 'org-babel-execute-src-block:async 'ob-async-org-babel-execute-src-block)

(autoload 'ob-async-org-babel-execute-src-block "ob-async" "\
Like org-babel-execute-src-block, but run asynchronously.

Original docstring for org-babel-execute-src-block:

Execute the current source code block.  Insert the results of
execution into the buffer.  Source code execution and the
collection and formatting of results can be controlled through a
variety of header arguments.

With prefix argument ARG, force re-execution even if an existing
result cached in the buffer would otherwise have been returned.

Optionally supply a value for INFO in the form returned by
`org-babel-get-src-block-info'.

Optionally supply a value for PARAMS which will be merged with
the header arguments specified at the front of the source code
block.

\(fn &optional ORIG-FUN ARG INFO PARAMS)" t nil)

(register-definition-prefixes "ob-async" '("ob-async-"))

;;;***

;;;### (autoloads nil nil ("ob-async-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; ob-async-autoloads.el ends here
