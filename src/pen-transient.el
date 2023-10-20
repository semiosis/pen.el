;; (load-library "transient")

;; TODO Also have a transient to set

(defmacro transient-define-prefix (name arglist &rest args)
  "Define NAME as a transient prefix command.

ARGLIST are the arguments that command takes.
DOCSTRING is the documentation string and is optional.

These arguments can optionally be followed by key-value pairs.
Each key has to be a keyword symbol, either `:class' or a keyword
argument supported by the constructor of that class.  The
`transient-prefix' class is used if the class is not specified
explicitly.

GROUPs add key bindings for infix and suffix commands and specify
how these bindings are presented in the popup buffer.  At least
one GROUP has to be specified.  See info node `(transient)Binding
Suffix and Infix Commands'.

The BODY is optional.  If it is omitted, then ARGLIST is also
ignored and the function definition becomes:

  (lambda ()
    (interactive)
    (transient-setup \\='NAME))

If BODY is specified, then it must begin with an `interactive'
form that matches ARGLIST, and it must call `transient-setup'.
It may however call that function only when some condition is
satisfied; that is one of the reason why you might want to use
an explicit BODY.

All transients have a (possibly nil) value, which is exported
when suffix commands are called, so that they can consume that
value.  For some transients it might be necessary to have a sort
of secondary value, called a scope.  Such a scope would usually
be set in the commands `interactive' form and has to be passed
to the setup function:

  (transient-setup \\='NAME nil nil :scope SCOPE)

\(fn NAME ARGLIST [DOCSTRING] [KEYWORD VALUE]... GROUP... [BODY...])"
  (declare (debug ( &define name lambda-list
                    [&optional lambda-doc]
                    [&rest keywordp sexp]
                    [&rest vectorp]
                    [&optional ("interactive" interactive) def-body]))
           (indent defun)
           (doc-string 3))
  (pcase-let ((`(,class ,slots ,suffixes ,docstr ,body)
               (transient--expand-define-args args arglist)))
    `(progn
       (defalias ',name
         ,(if body
              `(lambda ,arglist ,@body)
            `(lambda ()
               (interactive)
               (transient-setup ',name))))
       (put ',name 'interactive-only t)
       (put ',name 'function-documentation ,docstr)
       (put ',name 'transient--prefix
            (,(or class 'transient-prefix) :command ',name ,@slots))
       (put ',name 'transient--layout
            (list ,@(cl-mapcan (lambda (s) (transient--parse-child name s))
                               suffixes)))

       ;; Add name to the end so I can execute and run a transient definition
       ',name)))

(defmacro transient-define-suffix (name arglist &rest args)
  "Define NAME as a transient suffix command.

ARGLIST are the arguments that the command takes.
DOCSTRING is the documentation string and is optional.

These arguments can optionally be followed by key-value pairs.
Each key has to be a keyword symbol, either `:class' or a
keyword argument supported by the constructor of that class.
The `transient-suffix' class is used if the class is not
specified explicitly.

The BODY must begin with an `interactive' form that matches
ARGLIST.  The infix arguments are usually accessed by using
`transient-args' inside `interactive'.

\(fn NAME ARGLIST [DOCSTRING] [KEYWORD VALUE]... BODY...)"
  (declare (debug ( &define name lambda-list
                    [&optional lambda-doc]
                    [&rest keywordp sexp]
                    ("interactive" interactive)
                    def-body))
           (indent defun)
           (doc-string 3))
  (pcase-let ((`(,class ,slots ,_ ,docstr ,body)
               (transient--expand-define-args args arglist)))
    `(progn
       (defalias ',name (lambda ,arglist ,@body))
       (put ',name 'interactive-only t)
       (put ',name 'function-documentation ,docstr)
       (put ',name 'transient--suffix
            (,(or class 'transient-suffix) :command ',name ,@slots))
       ;; Add name to the end so I can execute and run a transient definition
       ',name)))

(defalias 'tdp 'transient-define-prefix)
(defalias 'tds 'transient-define-suffix)

(defun pen-create-transient (name kvps searchfun kwsearchfun)
  (let ((sym (intern (concat name "-transient")))
        (args
         (vconcat (list "Arguments")
                  (append
                   (let ((c 0))
                     (cl-loop for p in kvps do
                              (setq c (1+ c))
                              collect
                              (list (str c) p (concat "--" p "="))))
                   (let ((c 0))
                     (cl-loop for p in kvps do
                              (setq c (1+ c))
                              collect
                              (list
                               (concat "-" (str c))
                               (concat "not" p)
                               (concat "--not-" p "=")))))))
        (actions
         (vconcat
          (list "Actions"
                (list "r" "Run" searchfun)
                (list "d" "Run as filter" kwsearchfun)
                (list "d" "Run as filter" kwsearchfun)))))
    (eval `(define-transient-command ,sym ()
             ,(concat (s-capitalize name) " transient")
             ,args
             ,actions))))

;; (pen-create-transient
;;  "pf initial"
;;  vars
;;  'pen-github-transient-search
;;  'pen-github-transient-search-with-keywords)

(defun pen-github-transient-search (&optional args)
  (interactive
   (list (transient-args 'github-transient)))
  (let ((query (pen-cl-sn (concat "gen-github-query " (mapconcat 'pen-q args " ") " main") :chomp t)))
    (eegh query)))

(defun pen-github-transient-search-with-keywords (&optional args)
  (interactive
   (list (transient-args 'github-transient)))
  (let* ((keywords (read-string-hist "gh keywords:"))
         (query (pen-cl-sn (concat "gen-github-query " (mapconcat 'pen-q args " ") " " (sor keywords "main")) :chomp t)))
    (eegh query)))

(defset pen-github-key-value-predicates
  ;; prefix with - to invert i.e. -inurl:
  (list ;; "ext"
   "repo"
   "extension"
   "path"
   "filename"
   "followers"
   "language"
   "license"))

;; (pen-create-transient "github" pen-github-key-value-predicates 'pen-github-transient-search 'pen-github-transient-search-with-keywords)
(define-key pen-map (kbd "H-? h") 'github-transient)

;; https://github.com/magit/transient/wiki/Developer-Quick-Start-Guide

(tdp transient-toys-hello ()
  "Say hello"
  [("h" "hello" (lambda () (interactive) (message "hello")))])

;; (transient-toys-hello)

(defun transient-toys--wave ()
  "Wave at the user"
  (interactive)
  (message (propertize
            (format "Waves at %s" (current-time-string))
            'face 'success)))

;; (comment
;;  (tdp transient-toys-wave ()
;;    "Wave at the user"
;;    [("w" "wave" transient-toys--wave)])

;;  (transient-toys-wave))

;; Transient set to t means the suffix wont exit
(tdp transient-toys-wave ()
  "Wave at the user"
  ["Group 1"
   ("o" "wave once" transient-toys--wave :transient t)
   ("P" "wave a little" transient-toys--wave :transient t)]
  [("L" "wave a lot" transient-toys--wave :transient t)]
  ["Group 3"
   (transient-toys--wave :transient nil :key "wf" :description "wave furiously")])

;; Stacked groups
(tdp transient-toys-wave ()
  "Wave at the user"
  ["Top Group" ("wo" "wave one" transient-toys--wave)]
  ["Bottom Group" ("wt" "wave two" transient-toys--wave)])

;; Side by side (adjacent) groups
(tdp transient-toys-wave ()
  "Wave at the user"
  [["Left Group" ("wo" "wave one" transient-toys--wave)]
   ["Right Group" ("wt" "wave two" transient-toys--wave)]])

(tdp transient-toys-wave ()
  "Wave at the user"
  ["Group One"
   ("wo" "wave one" transient-toys--wave)
   ("we" "wave emotionally" transient-toys--wave)]

  ["Group Two"
   ("ws" "wave some" transient-toys--wave)
   ("wb" "wave better" transient-toys--wave)]

  [["Group Three" ("wt" "wave two" transient-toys--wave)]
   ["Group Four" ("wa" "wave all" transient-toys--wave)]])

(require 'cl-lib)

;; Dynamic lables
(tdp transient-toys-wave ()
  "Wave at the user"
  ["Group One"
   ("o" "wave one" transient-toys--wave)
   ("e" "wave emotionally" transient-toys--wave)]

  [:description current-time-string
                ("ws" transient-toys--wave
                 :description (lambda ()
                                (format "Wave at %s" (current-time-string))))
                ("wb" "wave better" transient-toys--wave)]

  [[:description (lambda () (format "Group %s" (cl-gensym)))
                 ("wt" "wave two" transient-toys--wave)]
   [:description (lambda () (format "Group %s" (cl-gensym)))
                 ("wa" "wave all" transient-toys--wave)]])

;; Arguments
(tdp transient-toys-wave ()
  "Wave at the user"

  [["Arguments"
    ("-s" "switch" "--switch")
    ("-a" "argument" "--argument=")
    ("t" "toggle" "--toggle")
    ("v" "value" "--value=")]

   ["More Arguments"
    ("-f" "argument with forced classs" "--forced-class " :class transient-option)
    ("I" "argument with inline" ("-i" "--inline-shortarg="))
    ("S" "inline shortarg switch" ("-n" "--inline-shortarg-switch"))]]

  ["Commands"
   ("ws" "wave some" transient-toys--wave)
   ("wb" "wave better" transient-toys--wave)])

;; default values
(tdp transient-toys-wave ()
  "Wave at the user"

  :value '("--toggle" "--value=default")

  ["Arguments"
   ("-s" "switch" "--switch")
   ("-a" "argument" "--argument=")
   ("t" "toggle" "--toggle")
   ("v" "value" "--value=")]

  ["Commands"
   ("ws" "wave some" transient-toys--wave)
   ("wb" "wave better" transient-toys--wave)])

;; (transient-toys-wave)

(tds transient-toys--wave ()
  "Wave at the user"
  :transient t
  :key "C-w"
  :description "wave"
  (interactive)
  
  (message
   (pen-colour-success
    (format "Waves at %s" (current-time-string)))))

(tdp transient-toys-wave ()
  "Wave at the user"
  [(transient-toys--wave)])

;; (transient-toys-wave)

(provide 'pen-transient)
