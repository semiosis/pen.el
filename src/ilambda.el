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

(defmacro imacro/3 (name args docstr)
  "Does not evaluate. It merely generates code."
  (let* ((argstr (apply 'cmd (mapcar 'slugify (mapcar 'str args))))
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
  (let* ((argstr (apply 'cmd (mapcar 'slugify (mapcar 'str args))))
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

(defmacro idefun (name-sym args code-or-task &optional task-or-code)
  "Define an imaginary function"
  `(defalias ',name-sym
     (function ,(eval
                 `(ilambda ,args ,code-or-task ,task-or-code)))))

(comment
 (idefun idoubleit (x)
         "double it"))

(defmacro ilambda (args code-or-task &optional task-or-code)
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
      `(ilambda/task-code ,args ,task ,code))
     ((sor task)
      `(ilambda/task ,args ,task))
     ((listp code-or-task)
      `(ilambda/code ,args ,code)))))

(defalias 'iλ 'ilambda)

(defmacro ilambda/task (args task)
  (let* ((slug (slugify (eval task)))
         (fsym (intern slug)))
    `(lambda ,args
       (let ((vals (mapcar 'eval ',args)))
         (eval
          ;; imagined by an LM
          `(ieval
            ;; An function and a function call
            (,',fsym ,@vals)
            ,,(concat ";; " task)))))))

(defmacro ilambda/task-code (args task code)
  (let* ((slug (slugify (eval task)))
         (fsym (intern slug)))
    `(lambda ,args
       (let ((vals (mapcar 'eval ',args)))
         (eval
          ;; imagined by an LM
          `(ieval
            ;; An function and a function call
            (,',fsym ,@vals)
            (defun ,',fsym ,',args
              ,,task
              ,',code)))))))

(defmacro ilambda/code (args code)
  `(lambda ,args
     (let ((vals (mapcar 'eval ',args)))
       (eval
        ;; imagined by an LM
        `(ieval
          ;; An function and a function call
          (main ,@vals)
          (defun main (,',@args)
            ,',code))))))

;; Create the lambda to be generated first, and then create ilambda
(comment
 (lambda (x)
   (let ((x (eval x)))
     (eval
      `(ieval
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
       `(ieval
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
  (etv (pps (ilist 10 "tennis players"))))

(defmacro ieval (expression &optional code-sexp-or-raw)
  "Imaginarily evaluate the expression, given the code-sexp-or-raw and return a real result."
  (let* ((code-str
          (cond
           ((stringp code-sexp-or-raw) code-sexp-or-raw)
           ((listp code-sexp-or-raw) (pps code-sexp-or-raw))))
         (expression-str
          (cond
           ((stringp expression) expression)
           ((listp expression) (pp-oneline expression))))
         (result (car
                  (pen-single-generation
                   (pf-imagine-evaluating-emacs-lisp/2
                    code-str expression-str
                    :no-select-result t :select-only-match t)))))
    (ignore-errors
      (eval-string (concat "''" result)))))

(defun test-ieval ()
  (ieval
   (double-number 5)
   (defun double-number (x)
     (x * x))))

(defun test-imacro ()
  ;; (defimacro my/subtract)

  (defimacro my/itimes (a b c)
    "multiply three complex numbers")
  (defimacro my/itimes (a b c)))

(provide 'ilambda)