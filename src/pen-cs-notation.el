(defun expr-sexp-normalise (form env)
  (pcase form
    (`(add ,x ,y)       (+ (expr-sexp-normalise x env)
                           (expr-sexp-normalise y env)))
    (`(call ,fun ,arg)  (funcall (expr-sexp-normalise fun env)
                                 (expr-sexp-normalise arg env)))
    (`(fn ,arg ,body)   (lambda (val)
                          (expr-sexp-normalise body (cons (cons arg val)
                                               env))))
    ((pred numberp)     form)
    ((pred symbolp)     (cdr (assq form env)))
    (_                  (error "Syntax error: %S" form))))

(defun transform-expr-into-sexp ()
  (interactive)
  (ifi-etv
   (let* ((expr "sign(GP-Old)*AS)")
          (expr "is(AE,sign(GP-Old)*AS)"))

     ;; How to parse fun(expr) ?
     ;; Maybe I should use pcase (i.e. pattern-matching).

     expr)))

(provide 'pen-cs-notation)
