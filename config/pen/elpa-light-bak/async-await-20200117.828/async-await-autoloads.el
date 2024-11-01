;;; async-await-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "async-await" "async-await.el" (0 0 0 0))
;;; Generated autoloads from async-await.el

(autoload 'async-defun "async-await" "\
Define NAME as a Async Function which return Promise.
ARGLIST should take the same form as an argument list for a `defun'.
BODY should be a list of Lisp expressions.

 (defun wait-async (n)
   (promise-new (lambda (resolve _reject)
                  (run-at-time n
                               nil
                               (lambda ()
                                 (funcall resolve n))))))

 (async-defun foo-async ()
   (print (await (wait-async 0.5)))
   (message \"---\")

   (print (await (wait-async 1.0)))
   (message \"---\")

   (print (await (wait-async 1.5)))
   (message \"---\")

   (message \"await done\"))

 (foo-async)

\(fn NAME ARGLIST &rest BODY)" nil t)

(function-put 'async-defun 'doc-string-elt '3)

(function-put 'async-defun 'lisp-indent-function '2)

(autoload 'async-lambda "async-await" "\
Return a lambda Async Function which return Promise.
ARGLIST should take the same form as an argument list for a `defun'.
BODY should be a list of Lisp expressions.

 (defun wait-async (n)
   (promise-new (lambda (resolve _reject)
                  (run-at-time n
                               nil
                               (lambda ()
                                 (funcall resolve n))))))

 (setq foo-async (async-lambda ()
                   (print (await (wait-async 0.5)))
                   (message \"---\")

                   (print (await (wait-async 1.0)))
                   (message \"---\")

                   (print (await (wait-async 1.5)))
                   (message \"---\")

                   (message \"await done\")))

 (funcall foo-async)

\(fn ARGLIST &rest BODY)" nil t)

(function-put 'async-lambda 'doc-string-elt '2)

(function-put 'async-lambda 'lisp-indent-function 'defun)

(autoload 'async-await-advice-make-autoload "async-await" "\
Advice function for `make-autoload'.
FN is original function and ARGS is list of arguments.
See \"For complex cases\" section in `make-autoload'.

\(fn FN &rest ARGS)" nil nil)

(advice-add 'make-autoload :around #'async-await-advice-make-autoload)

(register-definition-prefixes "async-await" '("async-await-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; async-await-autoloads.el ends here
