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

(defmacro ilambda/code (args code &optional task)
  `(lambda ,args
     `(let ((arglist
             (mapcar
              (lambda (a)
                (list a (eval a)))
              args)))
        (ieval
         (defun test ()
           (let ,arglist
             ,code))
         (defun double-number ,args
           (x * x))))))

(defun ilambda/code-test ()
  (interactive)
  (etv (ilambda/code () (+ 5 5))))

(defun ilambda/code-test-2 ()
  (interactive)
  (etv (ilambda/code (x) (+ x 5))))

(comment
 (defmacro ilambda/code (args code &optional task)
   `(lambda ,args
      `(let ((arglist
              (mapcar
               (lambda (a)
                 (list a (eval a)))
               args)))
         (ieval
          (defun test ()
            (let ,arglist
              ,code))
          (defun double-number ,args
            (x * x)))))))

;; Use a comment for the task before the call to the lambda.
;; Return an evalled string.
(defmacro ilambda/task (args task)
  `(ieval
    (double-number 5)
    (defun double-number ,args
      (x * x))))

(defmacro ilambda (args code-or-task &optional task)
  "define ilambda"
  ((cond
    ((stringp code-or-task)
     `(ilambda/task ,args ,code-or-task ,task))
    ((listp code-or-task)
     `(ilambda/code ,args ,code-or-task)))))

(defalias 'iλ 'ilambda)

(idefun double (a)
        "this function doubles its input")

(defun ilist (n type-of-thing)
  (interactive (list (read-string-hist "ilist n: ")
                     (read-string-hist "ilist type-of-thing: ")))
  (pen-single-generation (pf-list-of/2 (str n) (str type-of-thing) :no-select-result t)))

(defun test-ilist ()
  (interactive)
  (etv (pps (ilist 10 "tennis players"))))

(defmacro ieval (expression &optional code)
  "Imaginarily evaluate the expression, given the code and return a real result."
  (let* ((code-str
          (cond
           ((stringp code) code)
           ((listp code) (pps code))))
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
      (eval-string result))))

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