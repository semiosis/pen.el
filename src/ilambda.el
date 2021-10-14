;; Basic imaginary programming functions
;; Add these to the thesis

;; idefun
;; ieval
;; ilambda
;; ifilter
;; itransform
;; imacro

(defmacro defimacro (name &rest body)
  "Define imacro"
  (cond
   ((= 0 (length body))
    `(imacro/1
      ,name))
   ((= 1 (length body))
    `(imacro/2
      ,name
      ,(car body)))
   ((= 2 (length body))
    `(imacro/3
      ,name
      ,(car body)
      ,(cadr body)))))
(defalias 'imacro 'defimacro)

(defun test-imacro-1 ()
  (interactive)
  (imacro/1 get-real-component-from-imaginary-number))

(defmacro imacro/3 (name args docstr)
  "Does not evaluate. It merely generates code."
  (let* ((argstr (apply 'pen-cmd (mapcar 'slugify (mapcar 'str args))))
         (bodystr
          (car
           (pen-single-generation
            (pf-imagine-an-emacs-function/3
             name
             argstr
             docstr
             :include-prompt t
             :no-select-result t))))
         (body (eval-string (concat "'" bodystr))))
    `(progn ,body)))

(defmacro imacro/2 (name args)
  "Does not evaluate. It merely generates code."
  (let* ((argstr (apply 'pen-cmd (mapcar 'slugify (mapcar 'str args))))
         (bodystr
          (car
           (pen-single-generation
            (pf-imagine-an-emacs-function/2
             name
             argstr
             :include-prompt t
             :no-select-result t))))
         (body (eval-string (concat "'" bodystr))))
    `(progn ,body)))

(defmacro imacro/1 (name)
  "Does not evaluate. It merely generates code."
  (let* ((bodystr
          (car
           (pen-single-generation
            (pf-imagine-an-emacs-function/1
             name
             :include-prompt t
             :no-select-result t))))
         (body (eval-string (concat "'" bodystr))))
    `(progn ,body)))

(comment
 (mapcar
  (lambda (a)
    (list a (eval a)))
  args))

(defmacro idefun (name-sym args &optional code-or-task task-or-code)
  "Define an imaginary function"
  (cond
   ((and (stringp name-sym)
         (not code-or-task))
    (progn
      (setq code-or-task name-sym)
      (setq name-sym (intern (s-replace-regexp "-$" "" (slugify (str name-sym)))))))
   ((and (symbolp name-sym)
         (not code-or-task))
    (setq code-or-task (pen-snc "unsnakecase" (symbol-name name-sym)))))
  `(defalias ',name-sym
     (function ,(eval
                 `(ilambda ,args ,code-or-task ,task-or-code ,name-sym)))))
(defalias 'ifun 'idefun)

(comment
 (idefun idoubleit (x)
         "double it"))

(defmacro ilambda (args code-or-task &optional task-or-code name-sym)
  "Define an imaginary lambda (iλ)"
  (let ((task (if (stringp code-or-task)
                  code-or-task
                task-or-code))
        (code (if (listp code-or-task)
                  code-or-task
                task-or-code)))
    (cond
     ((and code
           (sor task))
      `(ilambda/task-code ,args ,task ,code ,name-sym))
     ((sor task)
      `(ilambda/task ,args ,task ,name-sym))
     ((listp code-or-task)
      `(ilambda/code ,args ,code ,name-sym)))))

(defalias 'iλ 'ilambda)

(defmacro ilambda/task (args task &optional name-sym)
  (let* ((slug (s-replace-regexp "-$" "" (slugify (eval task))))
         (fsym (or name-sym
                   (intern slug))))
    `(lambda ,args
       (eval
        ;; imagined by an LM
        `(ieval/m
          ;; An function and a function call
          (,',fsym ,,@args)
          ,,(concat ";; " task))))))
(defalias 'iλ/task 'ilambda/task)

(comment
 (ilambda (n) "generate fibonacci sequence"))

(comment
 (funcall (ilambda/task (n) "generate fibonacci sequence") 5))

(defun test-generate-fib ()
  (interactive)
  (idefun generate-fib-sequence (n))
  (etv (generate-fib-sequence 5)))

(defmacro ilambda/task-code (args task code &optional name-sym)
  (let* ((slug (s-replace-regexp "-$" "" (slugify (eval task))))
         (fsym (or
                name-sym
                (intern slug))))
    `(lambda ,args
       (eval
        ;; imagined by an LM
        `(ieval/m
          ;; An function and a function call
          (,',fsym ,,@args)
          (defun ,',fsym ,',args
            ,,task
            ,',code))))))
(defalias 'iλ/task-code 'ilambda/task-code)

(defmacro ilambda/code (args code &optional name-sym)
  (let ((fsym (or name-sym
                  'main)))
    `(lambda ,args
       (eval
        ;; imagined by an LM
        `(ieval/m
          ;; An function and a function call
          (,',fsym ,,@args)
          (defun ,',fsym (,',@args)
            ,',code))))))
(defalias 'iλ/code 'ilambda/code)

;; Create the lambda to be generated first, and then create ilambda
(comment
 (lambda (x)
   (let ((x (eval x)))
     (eval
      `(ieval/m
        (f ,x)
        (defun f (x)
          (x * x)))))))

(defun test-ilambda/code ()
  (interactive)
  (etv
   (mapcar
    ;; wrapped up in a lambda
    (lambda (x)
      (eval
       ;; imagined by an LM
       `(ieval/m
         ;; An function and a function call
         (main ,x)
         (defun main (x)
           (* x x)))))
    '(4))))

(defun ilambda/code-test-1 ()
  (interactive)
  (etv (mapcar (ilambda/task (x) "double it")
               '(12 4))))

(defun ilambda/code-test-2 ()
  (interactive)
  (etv (mapcar (ilambda/code (x)
                             (+ x 5))
               '(4))))

(defun ilambda/code-test-3 ()
  (interactive)
  (etv (mapcar (ilambda/task-code (x)
                                  "add five"
                                  (+ x 5))
               '(8))))

(defun ilist (n type-of-thing)
  (interactive (list (read-string-hist "ilist n: ")
                     (read-string-hist "ilist type-of-thing: ")))
  (pen-single-generation (pf-list-of/2 (str n) (str type-of-thing) :no-select-result t)))

(defun test-ilist ()
  (interactive)
  (etv (pp-to-string (ilist 10 "tennis players in no particular order"))))

(defun test-ilist-cs ()
  (interactive)
  (etv (pp-to-string (ilist 10 "computer science algorithms in no particular order"))))

(defmacro ieval/m (expression &optional code-sexp-or-raw)
  "Imaginarily evaluate the expression, given the code-sexp-or-raw and return a real result."
  (let* ((code-str
          (cond
           ((stringp code-sexp-or-raw) code-sexp-or-raw)
           ((listp code-sexp-or-raw) (pp-to-string code-sexp-or-raw))))
         (expression-str
          (cond
           ((stringp expression) expression)
           ((listp expression) (concat "'" (pp-oneline expression)))))
         (result (car
                  (pen-single-generation
                   (pf-imagine-evaluating-emacs-lisp/2
                    code-str expression-str
                    :no-select-result t :select-only-match t)))))
    (ignore-errors
      (setq result (eval-string (concat "''" result))))
    result))

(defun ieval (expression &optional code-sexp-or-raw)
  "Imaginarily evaluate the expression, given the code-sexp-or-raw and return a real result."
  (eval `(ieval/m ,expression ,code-sexp-or-raw)))

(defun test-ieval-1 ()
  (interactive)
  (etv (ieval
        '(double-number 5)
        '(defun double-number (x)
           (x * x)))))

(defun test-ieval-2 ()
  (interactive)
  (etv (ieval/m
        (double-number 5)
        (defun double-number (x)
          (x * x)))))

(defun test-imacro ()
  ;; (defimacro my/subtract)

  (defimacro my/itimes (a b c)
    "multiply three complex numbers")
  (defimacro my/itimes (a b c)))

(comment
 (itest "has 5 elements" '(a b c d)))

(comment
 (itest (lambda (l) '(= 5 (length l))) '(a b c d)))

;; TODO Have an NL predicate and also an expression predicate
(defmacro itest/m (predicate value)
  `(ieval
    `(my/test ,',value)
    `(defun my/test (x)
       (apply ,',predicate
              x))))

(defun itest (predicate value)
  (eval `(itest/m ,predicate ,value)))

(defun test-itest-1 ()
  (interactive)
  (etv
   (itest '(lambda (l) '(= 5 (length l)))
          '(a b c d))))

(defun test-itest-2 ()
  (interactive)
  (etv
   (itest/m (lambda (l) '(= 4 (length l)))
            '(a b c d))))

;; TODO Have

(defun iequals (predicate value)
  (eval `(itest/m ,predicate ,value)))

(provide 'ilambda)