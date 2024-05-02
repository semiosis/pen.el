;; EPL stands for Emacs-Lisp ProLog/Problog
;; It should be able to generate both prolog and problog

;; e:/volumes/home/shane/notes/ws/problog/scratch/earthquake.problog
;; e:$EMACSD/pen.el/src/pen-epl-test.epl

(add-to-list 'auto-mode-alist '("\\.epl\\'" . emacs-lisp-mode))

;; I'm going to stick with macros, instead of using functions
;; in order to make this entirely code-generation.
;; Also, stick to a single syntax for each macro.

;; TODO Make a single macro for defining facts, pfacts and afacts
;; that uses pcase to decide which
(defmacro problog-f (&rest args)
  (pcase args
    (`(add ,x ,y) (+ (evaluate x env)
                     (evaluate y env)))
    (`(call ,fun ,arg) (funcall (evaluate fun env)
                                (evaluate arg env)))
    (`(fn ,arg ,body) (lambda (val)
                        (evaluate body (cons (cons arg val)
                                             env))))
    ((pred numberp) args)
    ((pred symbolp) (cdr (assq args env)))
    (_ (error "Syntax error: %S" args)))

  (comment
   (e/awk1
    (problog-sentencify
     (problog-function-sexp-to-string name-or-func-call)))))

(defmacro problog-fact (pred-func-name &rest parameters)
  "Fact"
  (let ((name-or-func-call
         (cons pred-func-name parameters)))
    (e/awk1
     (problog-sentencify
      (problog-function-sexp-to-string name-or-func-call)))))
(defalias 'head 'problog-fact)
(defalias 'fact 'problog-fact)

(defmacro problog-pfact (name-or-func-call &optional probability &rest parameters)
  "Probabilistic fact"

  (cond ((and
          (and probability
               (not (numberp probability)))
          parameters)
         (progn
           (setq parameters (append (list probability) parameters))
           (setq probability 1)))
        
        ((and
          probability
          (not (numberp probability))
          (not parameters))
         (setq parameters (list probability)))

        ((not probability)
         (setq probability 1)))
  
  `(problog-afact ,probability ,name-or-func-call ,@parameters))
(defalias 'pfact 'problog-pfact)

;; This is very much like pfact
(defmacro problog-afact (probability pred-func-name &rest parameters)
  "A probabilistic fact with the first argument the probability"
  (let ((name-or-func-call
         (if parameters
             (append (list pred-func-name) parameters)
           pred-func-name)))
    (e/awk1
     (problog-sentencify
      (if (equal probability 1)
          (problog-function-sexp-to-string name-or-func-call)
        (concat (str probability)
                "::" (problog-function-sexp-to-string name-or-func-call)))))))
(defalias 'afact 'problog-afact)

(defmacro problog-facts (&rest facts)
  (apply 'e/awk1
         (cl-loop for f in facts collect
                  (eval
                   `(problog-fact
                     ,(car f)
                     ,(cadr f))))))
(defalias 'facts 'problog-facts)

(defmacro problog-pfacts (&rest pfacts)
  "pfact: name-or-func-call probability &rest parameters

(pfacts
    ;; Suppose there is a burglary in our house with probability 0.7
    ;; and an earthquake with probability 0.2.
    (burglary 0.7)
    (earthquake 0.2))
"
  (apply 'e/awk1
         (cl-loop for f in pfacts collect
                  (eval
                   `(problog-pfact
                     ,@f)))))
(defalias 'pfacts 'problog-pfacts)

(defmacro problog-afacts (&rest afacts)
  "afact: probability name-or-func-call &rest parameters

(afacts
    ;; Suppose there is a burglary in our house with probability 0.7
    ;; and an earthquake with probability 0.2.
    (burglary 0.7)
    (earthquake 0.2))
"
  (apply 'e/awk1
         (cl-loop for f in afacts collect
                  (eval
                   `(problog-afact
                     ,@f)))))
(defalias 'afacts 'problog-afacts)

(defun problog-function-sexp-to-string (e)
  (cond ((consp e)
         (cond
          ;; This may not work for complex not statements
          ((and (= (length e) 2)
                (equal (car e) 'not)
                (symbolp (cadr e)))
           (problog-backslash-not (concat "+" (str (cadr e)))))

          ;; This compresses not functions such as this
          ;; (rule (overrun_exception Time)
          ;;       (attempted_flap_position Time Pos)
          ;;       (not legal_flap_position Pos))
          ((and (> (length e) 2)
                (equal (car e) 'not)
                (symbolp (cadr e)))
           (concat (problog-backslash-not (concat "+" (str (cadr e))))
                   "("
                   (s-join "," (mapcar 'str (cddr e)))
                   ")"))

          ;; (head (not (p_alarm2 A B)) 0.8)
          ((and (= (length e) 2)
                (equal (car e) 'not)
                (consp (cadr e)))
           (concat (problog-backslash-not (concat "+" (str (caadr e))))
                   "("
                   (s-join "," (mapcar 'str (cdadr e)))
                   ")"))

          ((> (length e) 1)
           ;; Calling problog-function-sexp-to-string again here
           ;; allows to handle a (not factname) sexp.
           ;; e.g
           ;; (rule (overrun_exception Time)
           ;;       (attempted_flap_position Time Pos)
           ;;       ((not legal_flap_position) Pos))
           (concat (str (problog-function-sexp-to-string (car e)))
                   "("
                   (s-join "," (mapcar 'str (cdr e)))
                   ")"))

          ((= (length e) 1)
           (problog-function-sexp-to-string (car e)))))
        ((stringp e) (problog-backslash-not e))
        ((symbolp e) (problog-backslash-not (str e)))
        (t (problog-backslash-not (str e)))))

(defun problog-backslash-not (s)
  (if (re-match-p "^+" s)
      (concat "\\" s)
    s))

;; head/tail notation [H|Tail]
;; http://www.cs.trincoll.edu/$HOMEram/cpsc352/notes/prolog/search.html
(defmacro problog-rule (head probability-or-fact &rest facts)
  ;; Inside here, for each thing inside here,
  ;; multiply all the numbers together and put them at the start
  (let ((prob 1))
    (if (numberp probability-or-fact)
        (setq prob probability-or-fact)
      (setq facts (append (list probability-or-fact) facts)))

    (setq prob (-reduce '* (-filter 'numberp (append (list prob) facts))))

    (setq facts (-filter (lambda (e) (not (numberp e))) facts))
    
    (setq facts
          (mapcar (lambda (p)
                    (setq p (problog-function-sexp-to-string p))
                    (problog-backslash-not p))
                  facts))

    (setq head (problog-function-sexp-to-string head))
    (e/awk1
     (problog-sentencify
      (concat
       (if (equal 1 prob)
           head
         (concat (number-to-string prob) "::" head))
       " :- ")
      (s-join ", " facts)))))

(defalias 'rule 'problog-rule)

;; implies is like rule
;; implies/rule/clause
(defmacro problog-implies (lhs-facts rhs-facts)
  (setq lhs-facts (cdr (macroexpand
                        `(problog-expand ,@lhs-facts))))
  (setq rhs-facts (cdr (macroexpand
                        `(problog-expand ,@rhs-facts))))

  `(problog-sentencify
    (problog-chomp ,lhs-facts)
    " :- "
    (problog-chomp ,rhs-facts)))
(defalias 'implies 'problog-implies)
(defalias 'clause 'problog-implies)

(defmacro problog-rules (head-name &rest rule-predicates-lists)
  ;; (setq head-name (str head-name))

  (apply 'e/awk1
         (cl-loop for rpl in rule-predicates-lists collect
                  (eval
                   `(problog-rule
                     ,head-name
                     ,@rpl)))))

(defalias 'rules 'problog-rules)
(defalias 'prules 'problog-rules)
(defalias 'clauses 'problog-rules)
(defalias 'pclauses 'problog-rules)

(defmacro problog-evidence (factname t-or-nil)
  (setq factname (problog-function-sexp-to-string factname))
  (concat "evidence(" factname "," (if t-or-nil "true"
                                     "false")
          ")."))

(defalias 'evidence 'problog-evidence)

;; Make it so that by default, top-level sexps
;; work this way
(defmacro problog-goal (&rest factname)
  (setq factname (problog-function-sexp-to-string factname))
  (concat "goal(" factname ")."))
(defalias 'goal 'problog-goal)

(defmacro problog-query (&rest factname)
  (setq factname (problog-function-sexp-to-string factname))
  (concat "query(" factname ")."))
(defalias 'query 'problog-query)

(defmacro problog-is (&rest factname)
  (setq factname (problog-function-sexp-to-string factname))
  (concis "is(" factname ")."))
(defalias 'pb-is 'problog-is)

(defmacro problog-at (&rest factname)
  (setq factname (problog-function-sexp-to-string factname))
  (concat "at(" factname ")."))
(defalias 'pb-at 'problog-at)

(defmacro problog-verbatim (&rest factname)
  factname)
(defalias 'verbatim 'problog-verbatim)

;; TODO Make a macroexpand for renaming the first element of sexps
;; to add problog-

(defun problog-chomp (s)
  (--> s
       (s-replace-regexp ".$" "" it)
       (chomp it)))

(defun problog-sentencify (&rest ss)
  (eval `(concat ,@ss ".")))

(defmacro problog-or (&rest facts)
  (let* ((factstrings (mapcar
                       (lambda (f)
                         (--> f
                              (eval it)
                              (problog-chomp it)))
                       facts)))
    `(problog-sentencify
      (s-join "; " ',factstrings))))
(defalias 'pb-or 'problog-or)

(defmacro problog-and (&rest facts)
  (let* ((factstrings (mapcar
                       (lambda (f)
                         (--> f
                              (eval it)
                              (s-replace-regexp ".$" "" it)
                              (chomp it)))
                       facts)))
    `(problog-sentencify
      (s-join ", "
              ',factstrings))))
(defalias 'pb-and 'problog-and)

(comment
 (etv
  (s-replace-regexp ">(\\([^,]+\\),\\([^)]+\\))" "\\1 > \\2" "flap_position(Time,Pos) :- >(Time,0), attempted_flap_position(Time,Pos), legal_flap_position(Pos).")))

(defmacro problog-expand (&rest body)
  (comment
   `(pen-ms "s/(\\(rules\\?\\|facts\\?\\|display\\|<\\|>\\|%%\\|%\\|or\\|and\\|play\\|eval\\|evidence\\|query\\) /(problog-\\1 /"
            ,@body))

  `(pen-mf
    ,(lambda (s)
       (--> s
            (sed "s/(\\(rules\\?\\|facts\\?\\|display\\|%%\\|%\\|or\\|and\\|play\\|eval\\|evidence\\|query\\) /(problog-\\1 /g" it)))
    ,@body))

(defun problog-final-pp (problog-code-string)
  "This runs on generated problog code"
  (--> problog-code-string
       (identity it)
       ;; This is too much of a hack
       ;; I need to preprocess it, rather than postprocess it.
       ;; (s-replace-regexp "\\([><]\\|is\\)(\\([^,]+\\),\\([^)]+\\))" "\\2 \\1 \\3" it)
       ))

;; i.e. This is broken
;; (s-replace-regexp "\\([><]\\|is\\)(\\([^,]+\\),\\([^)]+\\))" "\\2 \\1 \\3" "attempted_flap_position(Time,Pos) :- >(Time,0), is(Prev,Time-1), flap_position(Prev,Old), \\+goal(Old), use_actuator(Time,A), actuator_strength(A,AS), goal(GP), is(AE,sign(GP-Old)*AS), wind_effect(Time,WE), is(Pos,Old + AE + WE).")

(defalias 'problog 'problog-expand)

(defmacro ifietv-tsv-mode (&rest body)
  ""
  `(let ((result ,@body))
     (if (interactive-p)
         (pen-etv
          (pen-snc
           "pen-tabulate"
           (concat "Fact\tProbability\n"
                   (s-replace-regexp
                    "^ +" ""
                    result)))
          'tsv-mode)
       result)))
(defalias 'ifi-etv-tsv-mode 'ifietv-tsv-mode)

(defun problog-eval (s)
  (interactive (list (read-string-hist "problog code: ")))
  (ifi-etv-tsv-mode
   (pen-snc "problog" (problog-final-pp s))
   ;; s
   ))

(defmacro problog-play-or-display (&rest body)
  "Normally, generate and run the problog, and display the results.
With C-u, show the problog code"
  `(if (>= (prefix-numeric-value current-prefix-arg) 4)
       (problog-display ,@body)
     (problog-play ,@body)))

(defmacro problog-play (&rest body)
  (setq body (cdr (macroexpand
                   `(problog-expand ,@body))))

  `(ifi-etv-tsv-mode
    (problog-eval
     (awk1 ,@body)
     ;; (if (interactive-p)
     ;;     (tv
     ;;      (awk1 ,@body))
     ;;   (awk1 ,@body))
     )))

(defmacro problog-display (&rest body)
  (setq body (cdr (macroexpand
                   `(problog-expand ,@body))))
  `(let
       ((result (problog-final-pp
                 (awk1
                  ,@body))))
     (if
         (interactive-p)
         (pen-etv result
                  'problog-mode)
       result)))

(defmacro problog-% (&rest body)
  (let ((commentstring
         (s-replace-regexp "^" "% "
                           (s-join " " (mapcar
                                        (lambda (f)
                                          (--> f
                                               (str it)
                                               (chomp it)))
                                        body)))))
    commentstring))
(defalias 'problog-%% 'problog-%)
(defalias '%% 'problog-%)

(provide 'pen-epl)
