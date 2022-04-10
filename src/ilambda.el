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

(defcustom iλ-thin nil
  "thin-client mode toggle"
  :type 'boolean
  :group 'pen
  :initialize (lambda(_sym _exp)
                (custom-initialize-default _sym nil)))
(defalias 'ilambda-thin 'iλ-thin)

(defun iλ-list (n type)
  (pen-single-generation
   (pen-fn-list-of/2 (str n) (str type)
                 :no-select-result t
                 :client iλ-thin)))

;; TODO Add docfuns
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

;; (imacro red-with-addition (l))

(defmacro imacro/3 (name args docstr)
  "Does not evaluate. It merely generates code."
  (let* ((argstr (s-join " " (mapcar 'pen-slugify-basic (mapcar 'str args))))
         (bodystr
          (car
           (pen-single-generation
            (pen-fn-imagine-an-emacs-function/3
             (str name)
             argstr
             docstr
             :include-prompt t
             :no-select-result t
             :client iλ-thin))))
         (body (eval-string (concat "'" bodystr))))
    `(progn ,body)))

;; If it fails, try again but this time with edit capability
(defmacro imacro/2 (name args)
  "Does not evaluate. It merely generates code."
  (let* ((argstr (s-join " " (mapcar 'pen-slugify-basic (mapcar 'str args))))
         (bodystr
          (car
           (eval
            `(pen-single-generation
              (pen-fn-imagine-an-emacs-function/2
               (str ',name)
               ,argstr
               :include-prompt t
               :no-select-result t
               :client iλ-thin)))))
         (body
          (try (eval-string (concat "'" bodystr))
               (eval-string (pen-eipec (concat "'" bodystr))))))
    `(progn ,body)))

(defmacro imacro/1 (name)
  "Does not evaluate. It merely generates code."
  (let* ((bodystr
          (car
           (pen-single-generation
            (pen-fn-imagine-an-emacs-function/1
             (str name)
             :include-prompt t
             :no-select-result t
             :client iλ-thin))))
         (body (eval-string (concat "'" bodystr))))
    `(progn ,body)))

(defun string-empty-or-nil-p (s)
  (or (not s)
      (string-empty-p s)))

(defun string-not-empty-nor-nil-p (s)
  (not (string-empty-or-nil-p s)))

(defun string-first-nonnil-nonempty-string (&rest ss)
  "Get the first non-nil string."
  (let ((result))
    (catch 'bbb
      (dolist (p ss)
        (if (string-not-empty-nor-nil-p p)
            (progn
              (setq result p)
              (throw 'bbb result)))))
    result))
(defalias 'sor 'string-first-nonnil-nonempty-string)

(defun chomp (str)
  "Chomp (remove tailing newline from) STR."
  (replace-regexp-in-string "\n\\'" "" str))

(defun pen-sn-basic (cmd &optional stdin dir)
  (interactive)

  (let ((output))
    (if (not cmd)
        (setq cmd "false"))

    (if (not dir)
        (setq dir default-directory))

    (let ((default-directory dir))
      (if (or
           (and (variable-p 'sh-update)
                (eval 'sh-update))
           (>= (prefix-numeric-value current-prefix-arg) 16))
          (setq cmd (concat "export UPDATE=y; " cmd)))

      (setq tf (make-temp-file "elisp_bash"))
      (setq tf_exit_code (make-temp-file "elisp_bash_exit_code"))

      (setq final_cmd (concat "( cd " (pen-q dir) "; " cmd " 2>/dev/null ) > " tf))

      (shut-up-c
       (with-temp-buffer
         (insert (or stdin ""))
         (shell-command-on-region (point-min) (point-max) final_cmd)))
      (setq output (slurp-file tf))
      (ignore-errors
        (progn (f-delete tf)
               (f-delete tf_exit_code)))
      output)))

(defmacro pen-single-generation (&rest body)
  "This wraps around pen function calls to make them only create one generation"
  `(eval
    `(let ((pen-single-generation-b t)
           (n-collate 1)
           (n-completions 1)
           ;; This is needed because the engine can also force n-completions
           (force-n-completions 1))
       ,',@body)))

(defun pen-slugify-basic (input &optional joinlines length)
  "Slugify input"
  (interactive)
  (let ((slug
         (if joinlines
             (pen-sn-basic "tr '\n' - | slugify" input)
           (pen-sn-basic "slugify" input))))
    (if length
        (substring slug 0 (- length 1))
      slug)))

(defmacro idefun (name-sym &optional args task-or-code &rest more-code)
  "Define an imaginary function"

  (if (stringp name-sym)
      (setq name-sym (intern (replace-regexp-in-string "-$" "" (pen-slugify-basic (str name-sym))))))

  (if (and (symbolp name-sym)
           (not task-or-code))
      (setq task-or-code (chomp (pen-sn-basic "unsnakecase" (symbol-name name-sym)))))

  `(defalias ',name-sym
     (function ,(eval
                 `(ilambda ,args ,task-or-code ,more-code :name-sym ,name-sym)))))
(defalias 'ifun 'idefun)

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

    (cond
     ;; This isn't usually called unless an ilambda
     ;; because task is set from defun
     ((and
       name-sym
       (or (not (or code task))
           (and (not (or args code))
                task)))
      `(ilambda/name ,name-sym))

     ;; task is implicitly set
     ((and name-sym (not (or code task)))
      `(ilambda/name-args ,name-sym ,args))

     ((and (sor task) code)
      `(ilambda/task-code ,args ,task ,code ,name-sym))

     ((and (sor task) (not code))
      `(ilambda/args-task ,args ,task ,name-sym))

     ((and (not task) code)
      (progn
        ;; (tv "code")
        `(ilambda/code ,args ,code ,name-sym))))))

(defalias 'iλ 'ilambda)

(defmacro ilambda/args-task (args task &optional name-sym)
  (let* ((slug (replace-regexp-in-string "-$" "" (pen-slugify-basic (eval task))))
         (fsym (or name-sym
                   (intern slug))))
    `(lambda ,args
       (eval
        ;; imagined by an LM
        `(ieval/m
          ;; An function and a function call
          ,(list ',fsym ,@args)
          ;; (,',fsym ,@,args)
          ,,(concat ";; " task "\n"
                    ";; arguments: " (pp-oneline args)))))))
(defalias 'iλ/task 'ilambda/args-task)


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
  (pen-single-generation
   (pen-fn-list-of/2
    (str n)
    (str type-of-thing)
    :no-select-result t
    :client iλ-thin)))

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
                   (pen-fn-imagine-evaluating-emacs-lisp/2
                    code-str expression-str
                    :no-select-result t
                    :select-only-match t
                    :prompt-hist-id
                    (if code-str
                        (concat "ieval/m-" (sha1 code-str))
                      "ieval/m")
                    :client iλ-thin)))))
    (ignore-errors
      (setq result (eval-string (concat "''" result))))
    result))

(defun ieval (expression &optional code-sexp-or-raw)
  "Imaginarily evaluate the expression, given the code-sexp-or-raw and return a real result."
  (eval `(ieval/m ,expression ,code-sexp-or-raw)))

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

;; assertions create prompt examples which are prepended
;; This should work by running an actual
;; prompt function, but giving it the result it's
;; supposed to return, and also indicating that
;; it be saved to a list of assertions, which are provided to a function
;; when prompting.
(defmacro iassert (value funcsym &rest args)
  "Add examples to a prompt function"

  ;; pen-train-function can take more examples per parameter set
  `(pen-train-function
    (,funcsym ,@args)
    (list ,value)))

(comment
 ;; Using =ilambda=, run real functions that do things.
 ;; Don't just use pure imaginary functions

 (defun internet-is-connected-p ()
   (eval (imacro internet-connected-p)))

 (im internet-is-connected-p ())

 ;; imacro lambda for ilambda
 (defmacro ilm (name &rest body)
   "
example: (ilm internet-is-connected-p ())
"
   `(progn
      (eval (imacro ,@body) ,@body)))

 ;; Some alternative identifiers
 ;; I chose gamma because it's an upside-down lambda
 (defalias 'γ 'ilm)
 (defalias 'ilmacro 'ilm)
 (defalias 'imaginary-lambda-macro 'ilm)
 (defalias 'imaginarily 'ilm))

;; (imacro sqrt (a))

(provide 'ilambda)
