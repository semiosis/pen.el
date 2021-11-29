;; Basic imaginary programming functions
;; Add these to the thesis

;; idefun
;; ieval
;; ilambda
;; ifilter
;; itransform
;; imacro

(require 'cl)

(defmacro comment (&rest body) nil)

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

;; (comment
;;  (mapcar
;;   (lambda (a)
;;     (list a (eval a)))
;;   args))

(defmacro idefun (name-sym &optional args task-or-code &rest more-code)
  "Define an imaginary function"

  (if (stringp name-sym)
      (setq name-sym (intern (s-replace-regexp "-$" "" (slugify (str name-sym))))))

  (if (and (symbolp name-sym)
           (not task-or-code))
      (setq task-or-code (pen-snc "unsnakecase" (symbol-name name-sym))))

  `(defalias ',name-sym
     (function ,(eval
                 `(ilambda ,args ,task-or-code ,more-code :name-sym ,name-sym)))))
(defalias 'ifun 'idefun)

;; (comment
;;  (idefun idoubleit (x)
;;          "double it"))

(cl-defmacro ilambda (&optional args task-or-code more-code &key name-sym)
  "Define an imaginary lambda (iλ)"
  (let* ((task)
         (code '()))

    (if (stringp task-or-code)
        (setq task task-or-code)
      (setq code task-or-code))

    (if (listp task-or-code)
        (setq code task-or-code))

    (if more-code
        (setq code `(progn ,@(append code more-code)))
      code)

    ;; (tv (concat "code:" code))
    ;; (tv (concat "task:" task))

    (setq task nil)

    (cond
     ;; This isn't usually called unless an ilambda
     ;; because task is set from defun
     ((not (or args code task))
      (progn
        ;; (tv "name")
        `(ilambda/name ,name-sym)))

     ;; task is implicitly set
     ((and name-sym args (not (or code task)))
      (progn
        ;; (tv "name-args")
        `(ilambda/name-args ,name-sym ,args)))

     ((and args (sor task) code)
      (progn
        ;; (tv "task-code")
        `(ilambda/task-code ,args ,task ,code ,name-sym)))

     ((and args (sor task) (not code))
      (progn
        ;; (tv "args-task")
        `(ilambda/args-task ,args ,task ,name-sym)))

     ;; ((and args (not task) code)
     ;;  (progn
     ;;    ;; (tv "code")
     ;;    `(ilambda/code ,args ,code ,name-sym)))
     )))

(defalias 'iλ 'ilambda)

(defmacro ilambda/args-task (args task &optional name-sym)
  (let* ((slug (s-replace-regexp "-$" "" (slugify (eval task))))
         (fsym (or name-sym
                   (intern slug))))
    `(lambda ,args
       (eval
        ;; imagined by an LM
        `(ieval/m
          ;; An function and a function call
          ,(list ',fsym ,@args)
          ;; (,',fsym ,@,args)
          ,,(concat ";; " task))))))
(defalias 'iλ/task 'ilambda/args-task)
;; (apply (ilambda/args-task (a b c) "add a b and c") '(1 2 3))

;; (idefun add-two-numbers (a b))

;; (idefun add-two-numbers (a b))

;; (idefun add-two-numbers)
;; (add-two-numbers 2 3)

;; (idefun add-two-numbers (a b))

;; (idefun add-two-numbers (a b)
;;         "add a to b")
;; (add-two-numbers 5 3)


;; (comment
;;  (ilambda (n) "generate fibonacci sequence"))

;; (comment
;;  (funcall (ilambda/args-task (n) "generate fibonacci sequence") 5))

;; (defun test-generate-fib ()
;;   (interactive)
;;   (idefun generate-fib-sequence (n))
;;   (pen-etv (generate-fib-sequence 5)))



(defmacro ilambda/task-code (args task code &optional name-sym)
  (let ((fsym (or name-sym
                  'main)))
    `(lambda ,args
       (eval
        ;; imagined by an LM
        `(ieval/m
          ;; An function and a function call
          ,(list ',fsym ,@args)
          ;; (,',fsym ,@,args)
          (defun ,',fsym (,@args)
            ,,task
            ,',code))))))
(defalias 'iλ/task-code 'ilambda/task-code)

(apply (ilambda/task-code (a b) "add two numbers" (+ a b)) '(3 5))


(defmacro ilambda/name (&optional name-sym)
  (let ((fsym (or name-sym
                  'main)))
    `(lambda (&rest body)
       (eval
        ;; imagined by an LM
        `(ieval/m
          ;; An function and a function call
          (,',fsym ,@body)
          ,,(concat ";; Run function " (symbol-name name-sym)))))))
(defalias 'iλ/name 'ilambda/name)

;; (comment
;;  (idefun things-to-hex-colors)
;;  (idefun thing-to-hex-color (thing))
;;  (things-to-hex-colors "watermelon" "apple")
;;  (pen-etv (upd (things-to-hex-colors "watermelon" "apple"))))

;; (comment
;;  (ieval/m
;;   (thing-to-hex-color thing)
;;   ";; thing to hex color"))

(defmacro ilambda/name-args (name-sym args)
  (let ((fsym (or name-sym
                  'main)))
    `(lambda ,args
       (eval
        ;; imagined by an LM
        `(ieval/m
          ;; An function and a function call
          ,(list ',fsym ,@args)
          ,,(concat ";; Run function " (symbol-name name-sym)))))))

;; (idefun append-lists (a b))
;; (append-lists '(a b c) '(d e f))
;; ;; (ilambda (a b))
;; (idefun list-multiply)
;; (list-multiply 2 (append-lists '(1 1) '(10 10)))
;; (idefun lists-multiply (a b))
;; (lists-multiply '(1 1) '(10 10))

(defmacro ilambda/code (args code &optional name-sym)
  (let ((fsym (or name-sym
                  'main)))
    `(lambda ,args
       (eval
        ;; imagined by an LM
        `(ieval/m
           ;; An function and a function call
           ,(list ',fsym ,@args)
           (defun ,',fsym ,',args
             ,',code))))))
(defalias 'iλ/code 'ilambda/code)

;; (apply (ilambda/code (a b) (+ a b)) '(1 2))

;; (ilambda/code (a b) (+ a b))

;; Create the lambda to be generated first, and then create ilambda
;; (comment
;;  (lambda (x)
;;    (let ((x (eval x)))
;;      (eval
;;       `(ieval/m
;;         (f ,x)
;;         (defun f (x)
;;           (x * x)))))))

(defun test-ilambda/code ()
  (interactive)
  (pen-etv
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
  (pen-etv (mapcar (ilambda/args-task (x) "double it")
               '(12 4))))

(defun ilambda/code-test-2 ()
  (interactive)
  (pen-etv (mapcar (ilambda/code (x)
                             (+ x 5))
               '(4))))

(defun ilambda/code-test-3 ()
  (interactive)
  (pen-etv (mapcar (ilambda/task-code (x)
                                  "add five"
                                  (+ x 5))
               '(8))))

(defun ilist (n type-of-thing)
  (interactive (list (read-string-hist "ilist n: ")
                     (read-string-hist "ilist type-of-thing: ")))
  (pen-single-generation (pf-list-of/2 (str n) (str type-of-thing) :no-select-result t)))

(defun test-ilist ()
  (interactive)
  (pen-etv (pp-to-string (ilist 10 "tennis players in no particular order"))))

(defun test-ilist-cs ()
  (interactive)
  (pen-etv (pp-to-string (ilist 10 "computer science algorithms in no particular order"))))

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

;; (defun test-ieval-1 ()
;;   (interactive)
;;   (pen-etv (ieval
;;         '(double-number 5)
;;         '(defun double-number (x)
;;            (x * x)))))

;; (defun test-ieval-2 ()
;;   (interactive)
;;   (pen-etv (ieval/m
;;         (double-number 5)
;;         (defun double-number (x)
;;           (x * x)))))

;; (defun test-imacro ()
;;   ;; (defimacro my/subtract)

;;   (defimacro my/itimes (a b c)
;;     "multiply three complex numbers")
;;   (defimacro my/itimes (a b c)))

;; (comment
;;  (itest "has 5 elements" '(a b c d)))

;; (comment
;;  (itest (lambda (l) '(= 5 (length l))) '(a b c d)))

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
  (pen-etv
   (itest '(lambda (l) (= 5 (length l)))
          '(a b c d))))

(defun test-itest-2 ()
  (interactive)
  (pen-etv
   (itest/m (lambda (l) (= 4 (length l)))
            '(a b c d))))

;; Interestingly, these tests do not work very well
;; 𝑖λ seems only suited for code when it comes to elisp
(defun test-itest-3 () (interactive) (pen-etv (itest/m (lambda (thing) (= "Charles Lutwidge Dodgson" thing)) "Lewis Carroll")))
(defun test-itest-4 () (interactive) (pen-etv (itest/m (lambda (thing) (= "J. R. R. Tolkien" thing)) "Lewis Carroll")))
(defun test-itest-5 () (interactive) (pen-etv (itest/m 'is-jrr-tolkien-p "Lewis Carroll")))
(defun test-itest-6 () (interactive) (pen-etv (itest/m 'is-jrr-tolkien-p "J. R. R. Tolkien")))

(defun test-itest-4 ()
  (interactive)
  (pen-etv
   (itest/m (lambda (thing)
              (= "An Egyptian king who ruled during the First Dynasty"
                 thing))
            "Semerkhet")))

(defun test-itest-4 ()
  (interactive)
  (pen-etv
   (itest/m (lambda (thing) (same-person "Moses" thing))
            "Joseph")))

(defmacro iequal/m (predicate value)
  `(ieval
    `(my/test ,',value)
    `(defun my/test (x)
       (apply ,',predicate
              x))))

(defun iequal (a b)
  (eval `(iequal/m ,predicate ,value)))

(defun test-equals-1 ()
  (interactive)
  (pen-etv
   (iequal '(lambda (l) '(= 5 (length l)))
            '(a b c d))))

;; (idefun pen-add (a b) "add two numbers")

;; (idefun pen-add (a b) "add two numbers")

(provide 'ilambda)