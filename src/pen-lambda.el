;; Strangely, even these aliases caused lots of problems
;; perhaps if I want to use λ then I should change the emacs C code
;; (defalias 'λ 'lambda)
;; (defalias 'y 'lambda)

;; Or, perhaps this will work
(defmacro λ (&rest cdr)
  (declare (doc-string 2) (indent defun)
           (debug (&define lambda-list lambda-doc
                           [&optional ("interactive" interactive)]
                           def-body)))
  ;; Note that this definition should not use backquotes; subr.el should not
  ;; depend on backquote.el.
  (list 'function (cons 'lambda cdr)))

(defmacro y (&rest cdr)
  (declare (doc-string 2) (indent defun)
           (debug (&define lambda-list lambda-doc
                           [&optional ("interactive" interactive)]
                           def-body)))
  ;; Note that this definition should not use backquotes; subr.el should not
  ;; depend on backquote.el.
  (list 'function (cons 'lambda cdr)))

(defmacro lm (&rest body)
  "Interactive lambda with no arguments."
  `(lambda () (interactive) ,@body))

(provide 'pen-lambda)
