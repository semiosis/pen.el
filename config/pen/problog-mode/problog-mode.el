(defvar problog-mode-version "1.22"
  "problog mode version number.")

(require 'comint)

(eval-when-compile
  (require 'font-lock)
  ;; We need imenu everywhere because of the predicate index!
  (require 'imenu)
  ;)
  (require 'shell)
  )

(require 'easymenu)
(require 'align)

(eval-when-compile
  (or (fboundp 'use-region-p)
      (defsubst use-region-p () (region-exists-p))))

(defgroup problog nil
  "Editing and running problog and Mercury files."
  :group 'languages)

(defgroup problog-faces nil
  "problog mode specific faces."
  :group 'font-lock)

(defgroup problog-indentation nil
  "problog mode indentation configuration."
  :group 'problog)

(defgroup problog-font-lock nil
  "problog mode font locking patterns."
  :group 'problog)

(defgroup problog-keyboard nil
  "problog mode keyboard flags."
  :group 'problog)

(defgroup problog-inferior nil
  "Inferior problog mode options."
  :group 'problog)

(defgroup problog-other nil
  "Other problog mode options."
  :group 'problog)


;;-------------------------------------------------------------------
;; User configurable variables
;;-------------------------------------------------------------------

;; General configuration

(defcustom problog-system nil
  "problog interpreter/compiler used.
The value of this variable is nil or a symbol.
If it is a symbol, it determines default values of other configuration
variables with respect to properties of the specified problog
interpreter/compiler.

Currently recognized symbol values are:
eclipse - Eclipse problog
mercury - Mercury
sicstus - SICStus problog
swi     - SWI problog
gnu     - GNU problog"
  :version "24.1"
  :group 'problog
  :type '(choice (const :tag "SICStus" :value sicstus)
                 (const :tag "SWI problog" :value swi)
                 (const :tag "GNU problog" :value gnu)
                 (const :tag "ECLiPSe problog" :value eclipse)
                 ;; Mercury shouldn't be needed since we have a separate
                 ;; major mode for it.
                 (const :tag "Default" :value nil)))
(make-variable-buffer-local 'problog-system)

;; NB: This alist can not be processed in problog-mode-variables to
;; create a problog-system-version-i variable since it is needed
;; prior to the call to problog-mode-variables.
(defcustom problog-system-version
  '((sicstus  (3 . 6))
    (swi      (0 . 0))
    (mercury  (0 . 0))
    (eclipse  (3 . 7))
    (gnu      (0 . 0)))
  ;; FIXME: This should be auto-detected instead of user-provided.
  "Alist of problog system versions.
The version numbers are of the format (Major . Minor)."
  :version "24.1"
  :type '(repeat (list (symbol :tag "System")
                       (cons :tag "Version numbers" (integer :tag "Major")
                             (integer :tag "Minor"))))
  :risky t
  :group 'problog)

;; Indentation

(defcustom problog-indent-width 4
  "The indentation width used by the editing buffer."
  :group 'problog-indentation
  :type 'integer
  :safe 'integerp)

(defcustom problog-left-indent-regexp "\\(;\\|\\*?->\\)"
  "Regexp for `problog-electric-if-then-else-flag'."
  :version "24.1"
  :group 'problog-indentation
  :type 'regexp
  :safe 'stringp)

(defcustom problog-paren-indent-p nil
  "If non-nil, increase indentation for parenthesis expressions.
The second and subsequent line in a parenthesis expression other than
a compound term can either be indented `problog-paren-indent' to the
right (if this variable is non-nil) or in the same way as for compound
terms (if this variable is nil, default)."
  :version "24.1"
  :group 'problog-indentation
  :type 'boolean
  :safe 'booleanp)

(defcustom problog-paren-indent 4
  "The indentation increase for parenthesis expressions.
Only used in ( If -> Then ; Else) and ( Disj1 ; Disj2 ) style expressions."
  :version "24.1"
  :group 'problog-indentation
  :type 'integer
  :safe 'integerp)

(defcustom problog-parse-mode 'beg-of-clause
  "The parse mode used (decides from which point parsing is done).
Legal values:
`beg-of-line'   - starts parsing at the beginning of a line, unless the
                  previous line ends with a backslash.  Fast, but has
                  problems detecting multiline /* */ comments.
`beg-of-clause' - starts parsing at the beginning of the current clause.
                  Slow, but copes better with /* */ comments."
  :version "24.1"
  :group 'problog-indentation
  :type '(choice (const :value beg-of-line)
                 (const :value beg-of-clause)))

;; Font locking

(defcustom problog-keywords
  '((eclipse
     ("use_module" "begin_module" "module_interface" "dynamic"
      "external" "export" "dbgcomp" "nodbgcomp" "compile"))
    (mercury
     ("all" "else" "end_module" "equality" "external" "fail" "func" "if"
      "implementation" "import_module" "include_module" "inst" "instance"
      "interface" "mode" "module" "not" "pragma" "pred" "some" "then" "true"
      "type" "typeclass" "use_module" "where"))
    (sicstus
     ("block" "dynamic" "mode" "module" "multifile" "meta_predicate"
      "parallel" "public" "sequential" "volatile"))
    (swi
     ("discontiguous" "dynamic" "ensure_loaded" "export" "export_list" "import"
      "meta_predicate" "module" "module_transparent" "multifile" "require"
      "use_module" "volatile"))
    (gnu
     ("built_in" "char_conversion" "discontiguous" "dynamic" "ensure_linked"
      "ensure_loaded" "foreign" "include" "initialization" "multifile" "op"
      "public" "set_problog_flag"))
    (t
     ;; FIXME: Shouldn't we just use the union of all the above here?
     ("dynamic" "module")))
  "Alist of problog keywords which is used for font locking of directives."
  :version "24.1"
  :group 'problog-font-lock
  ;; Note that "(repeat string)" also allows "nil" (repeat-count 0).
  ;; This gets processed by problog-find-value-by-system, which
  ;; allows both the car and the cdr to be a list to eval.
  ;; Though the latter must have the form '(eval ...)'.
  ;; Of course, none of this is documented...
  :type '(repeat (list (choice symbol sexp) (choice (repeat string) sexp)))
  :risky t)

(defcustom problog-types
  '((mercury
     ("char" "float" "int" "io__state" "string" "univ"))
    (t nil))
  "Alist of problog types used by font locking."
  :version "24.1"
  :group 'problog-font-lock
  :type '(repeat (list (choice symbol sexp) (choice (repeat string) sexp)))
  :risky t)

(defcustom problog-mode-specificators
  '((mercury
     ("bound" "di" "free" "ground" "in" "mdi" "mui" "muo" "out" "ui" "uo"))
    (t nil))
  "Alist of problog mode specificators used by font locking."
  :version "24.1"
  :group 'problog-font-lock
  :type '(repeat (list (choice symbol sexp) (choice (repeat string) sexp)))
  :risky t)

(defcustom problog-determinism-specificators
  '((mercury
     ("cc_multi" "cc_nondet" "det" "erroneous" "failure" "multi" "nondet"
      "semidet"))
    (t nil))
  "Alist of problog determinism specificators used by font locking."
  :version "24.1"
  :group 'problog-font-lock
  :type '(repeat (list (choice symbol sexp) (choice (repeat string) sexp)))
  :risky t)

(defcustom problog-directives
  '((mercury
     ("^#[0-9]+"))
    (t nil))
  "Alist of problog source code directives used by font locking."
  :version "24.1"
  :group 'problog-font-lock
  :type '(repeat (list (choice symbol sexp) (choice (repeat string) sexp)))
  :risky t)


;; Keyboard

(defcustom problog-hungry-delete-key-flag nil
  "Non-nil means delete key consumes all preceding spaces."
  :version "24.1"
  :group 'problog-keyboard
  :type 'boolean)

(defcustom problog-electric-dot-flag nil
  "Non-nil means make dot key electric.
Electric dot appends newline or inserts head of a new clause.
If dot is pressed at the end of a line where at least one white space
precedes the point, it inserts a recursive call to the current predicate.
If dot is pressed at the beginning of an empty line, it inserts the head
of a new clause for the current predicate.  It does not apply in strings
and comments.
It does not apply in strings and comments."
  :version "24.1"
  :group 'problog-keyboard
  :type 'boolean)

(defcustom problog-electric-dot-full-predicate-template nil
  "If nil, electric dot inserts only the current predicate's name and `('
for recursive calls or new clause heads.  Non-nil means to also
insert enough commas to cover the predicate's arity and `)',
and dot and newline for recursive calls."
  :version "24.1"
  :group 'problog-keyboard
  :type 'boolean)

(defcustom problog-electric-underscore-flag nil
  "Non-nil means make underscore key electric.
Electric underscore replaces the current variable with underscore.
If underscore is pressed not on a variable then it behaves as usual."
  :version "24.1"
  :group 'problog-keyboard
  :type 'boolean)

(defcustom problog-electric-if-then-else-flag nil
  "Non-nil makes `(', `>' and `;' electric
to automatically indent if-then-else constructs."
  :version "24.1"
  :group 'problog-keyboard
  :type 'boolean)

(defcustom problog-electric-colon-flag nil
  "Makes `:' electric (inserts `:-' on a new line).
If non-nil, pressing `:' at the end of a line that starts in
the first column (i.e., clause heads) inserts ` :-' and newline."
  :version "24.1"
  :group 'problog-keyboard
  :type 'boolean)

(defcustom problog-electric-dash-flag nil
  "Makes `-' electric (inserts a `-->' on a new line).
If non-nil, pressing `-' at the end of a line that starts in
the first column (i.e., DCG heads) inserts ` -->' and newline."
  :version "24.1"
  :group 'problog-keyboard
  :type 'boolean)

(defcustom problog-old-sicstus-keys-flag nil
  "Non-nil means old SICStus problog mode keybindings are used."
  :version "24.1"
  :group 'problog-keyboard
  :type 'boolean)

;; Inferior mode

(defcustom problog-program-name
  `(((getenv "Eproblog") (eval (getenv "Eproblog")))
    (eclipse "eclipse")
    (mercury nil)
    (sicstus "sicstus")
    (swi ,(if (not (executable-find "swipl")) "pl" "swipl"))
    (gnu "gproblog")
    (t ,(let ((names '("problog" "gproblog" "swipl" "pl")))
 	  (while (and names
 		      (not (executable-find (car names))))
 	    (setq names (cdr names)))
 	  (or (car names) "problog"))))
  "Alist of program names for invoking an inferior problog with `run-problog'."
  :group 'problog-inferior
  :type '(alist :key-type (choice symbol sexp)
                :value-type (group (choice string (const nil) sexp)))
  :risky t)
(defun problog-program-name ()
  (problog-find-value-by-system problog-program-name))

(defcustom problog-program-switches
  '((sicstus ("-i"))
    (t nil))
  "Alist of switches given to inferior problog run with `run-problog'."
  :version "24.1"
  :group 'problog-inferior
  :type '(repeat (list (choice symbol sexp) (choice (repeat string) sexp)))
  :risky t)
(defun problog-program-switches ()
  (problog-find-value-by-system problog-program-switches))

(defcustom problog-consult-string
  '((eclipse "[%f].")
    (mercury nil)
    (sicstus (eval (if (problog-atleast-version '(3 . 7))
                       "problog:zap_file(%m,%b,consult,%l)."
                     "problog:zap_file(%m,%b,consult).")))
    (swi "[%f].")
    (gnu     "[%f].")
    (t "reconsult(%f)."))
  "Alist of strings defining predicate for reconsulting.

Some parts of the string are replaced:
`%f' by the name of the consulted file (can be a temporary file)
`%b' by the file name of the buffer to consult
`%m' by the module name and name of the consulted file separated by colon
`%l' by the line offset into the file.  This is 0 unless consulting a
     region of a buffer, in which case it is the number of lines before
     the region."
  :group 'problog-inferior
  :type '(alist :key-type (choice symbol sexp)
                :value-type (group (choice string (const nil) sexp)))
  :risky t)

(defun problog-consult-string ()
  (problog-find-value-by-system problog-consult-string))

(defcustom problog-compile-string
  '((eclipse "[%f].")
    (mercury "mmake ")
    (sicstus (eval (if (problog-atleast-version '(3 . 7))
                       "problog:zap_file(%m,%b,compile,%l)."
                     "problog:zap_file(%m,%b,compile).")))
    (swi "[%f].")
    (t "compile(%f)."))
  "Alist of strings and lists defining predicate for recompilation.

Some parts of the string are replaced:
`%f' by the name of the compiled file (can be a temporary file)
`%b' by the file name of the buffer to compile
`%m' by the module name and name of the compiled file separated by colon
`%l' by the line offset into the file.  This is 0 unless compiling a
     region of a buffer, in which case it is the number of lines before
     the region.

If `problog-program-name' is non-nil, it is a string sent to a problog process.
If `problog-program-name' is nil, it is an argument to the `compile' function."
  :group 'problog-inferior
  :type '(alist :key-type (choice symbol sexp)
                :value-type (group (choice string (const nil) sexp)))
  :risky t)

(defun problog-compile-string ()
  (problog-find-value-by-system problog-compile-string))

(defcustom problog-eof-string "end_of_file.\n"
  "String or alist of strings that represent end of file for problog.
If nil, send actual operating system end of file."
  :group 'problog-inferior
  :type '(choice string
                 (const nil)
                 (alist :key-type (choice symbol sexp)
                        :value-type (group (choice string (const nil) sexp))))
  :risky t)

(defcustom problog-prompt-regexp
  '((eclipse "^[a-zA-Z0-9()]* *\\?- \\|^\\[[a-zA-Z]* [0-9]*\\]:")
    (sicstus "| [ ?][- ] *")
    (swi "^\\(\\[[a-zA-Z]*\\] \\)?[1-9]?[0-9]*[ ]?\\?- \\|^| +")
    (gnu "^| \\?-")
    (t "^|? *\\?-"))
  "Alist of prompts of the problog system command line."
  :version "24.1"
  :group 'problog-inferior
  :type '(alist :key-type (choice symbol sexp)
                :value-type (group (choice string (const nil) sexp)))
  :risky t)

(defun problog-prompt-regexp ()
  (problog-find-value-by-system problog-prompt-regexp))

;; (defcustom problog-continued-prompt-regexp
;;   '((sicstus "^\\(| +\\|     +\\)")
;;     (t "^|: +"))
;;   "Alist of regexps matching the prompt when consulting `user'."
;;   :group 'problog-inferior
;;   :type '(alist :key-type (choice symbol sexp)
;;                :value-type (group (choice string (const nil) sexp)))
;;   :risky t)

(defcustom problog-debug-on-string "debug.\n"
  "Predicate for enabling debug mode."
  :version "24.1"
  :group 'problog-inferior
  :type 'string)

(defcustom problog-debug-off-string "nodebug.\n"
  "Predicate for disabling debug mode."
  :version "24.1"
  :group 'problog-inferior
  :type 'string)

(defcustom problog-trace-on-string "trace.\n"
  "Predicate for enabling tracing."
  :version "24.1"
  :group 'problog-inferior
  :type 'string)

(defcustom problog-trace-off-string "notrace.\n"
  "Predicate for disabling tracing."
  :version "24.1"
  :group 'problog-inferior
  :type 'string)

(defcustom problog-zip-on-string "zip.\n"
  "Predicate for enabling zip mode for SICStus."
  :version "24.1"
  :group 'problog-inferior
  :type 'string)

(defcustom problog-zip-off-string "nozip.\n"
  "Predicate for disabling zip mode for SICStus."
  :version "24.1"
  :group 'problog-inferior
  :type 'string)

(defcustom problog-use-standard-consult-compile-method-flag t
  "Non-nil means use the standard compilation method.
Otherwise the new compilation method will be used.  This
utilizes a special compilation buffer with the associated
features such as parsing of error messages and automatically
jumping to the source code responsible for the error.

Warning: the new method is so far only experimental and
does contain bugs.  The recommended setting for the novice user
is non-nil for this variable."
  :version "24.1"
  :group 'problog-inferior
  :type 'boolean)


;; Miscellaneous

(defcustom problog-imenu-flag t
  "Non-nil means add a clause index menu for all problog files."
  :version "24.1"
  :group 'problog-other
  :type 'boolean)

(defcustom problog-imenu-max-lines 3000
  "The maximum number of lines of the file for imenu to be enabled.
Relevant only when `problog-imenu-flag' is non-nil."
  :version "24.1"
  :group 'problog-other
  :type 'integer)

(defcustom problog-info-predicate-index
  "(sicstus)Predicate Index"
  "The info node for the SICStus predicate index."
  :version "24.1"
  :group 'problog-other
  :type 'string)

(defcustom problog-underscore-wordchar-flag nil
  "Non-nil means underscore (_) is a word-constituent character."
  :version "24.1"
  :group 'problog-other
  :type 'boolean)
(make-obsolete-variable 'problog-underscore-wordchar-flag
                        'superword-mode "24.4")

(defcustom problog-use-sicstus-sd nil
  "If non-nil, use the source level debugger of SICStus 3#7 and later."
  :version "24.1"
  :group 'problog-other
  :type 'boolean)

(defcustom problog-char-quote-workaround nil
  "If non-nil, declare 0 as a quote character to handle 0'<char>.
This is really kludgy, and unneeded (i.e. obsolete) in Emacs>=24."
  :version "24.1"
  :group 'problog-other
  :type 'boolean)
(make-obsolete-variable 'problog-char-quote-workaround nil "24.1")


;;-------------------------------------------------------------------
;; Internal variables
;;-------------------------------------------------------------------

;;(defvar problog-temp-filename "")   ; Later set by `problog-temporary-file'

(defvar problog-mode-syntax-table
  ;; The syntax accepted varies depending on the implementation used.
  ;; Here are some of the differences:
  ;; - SWI-problog accepts nested /*..*/ comments.
  ;; - Edinburgh-style problogs take <radix>'<number> for non-decimal number,
  ;;   whereas ISO-style problogs use 0[obx]<number> instead.
  ;; - In atoms \x<hex> sometimes needs a terminating \ (ISO-style)
  ;;   and sometimes not.
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?_ (if problog-underscore-wordchar-flag "w" "_") table)
    (modify-syntax-entry ?+ "." table)
    (modify-syntax-entry ?- "." table)
    (modify-syntax-entry ?= "." table)
    (modify-syntax-entry ?< "." table)
    (modify-syntax-entry ?> "." table)
    (modify-syntax-entry ?| "." table)
    (modify-syntax-entry ?\' "\"" table)

    ;; Any better way to handle the 0'<char> construct?!?
    (when (and problog-char-quote-workaround
               (not (fboundp 'syntax-propertize-rules)))
      (modify-syntax-entry ?0 "\\" table))

    (modify-syntax-entry ?% "<" table)
    (modify-syntax-entry ?\n ">" table)
    (if (featurep 'xemacs)
        (progn
          (modify-syntax-entry ?* ". 67" table)
          (modify-syntax-entry ?/ ". 58" table)
          )
      ;; Emacs wants to see this it seems:
      (modify-syntax-entry ?* ". 23b" table)
      (modify-syntax-entry ?/ ". 14" table)
      )
    table))

(defconst problog-atom-char-regexp
  "[[:alnum:]_$]"
  "Regexp specifying characters which constitute atoms without quoting.")
(defconst problog-atom-regexp
  (format "[[:lower:]$]%s*" problog-atom-char-regexp))

(defconst problog-left-paren "[[({]"     ;FIXME: Why not \\s(?
  "The characters used as left parentheses for the indentation code.")
(defconst problog-right-paren "[])}]"    ;FIXME: Why not \\s)?
  "The characters used as right parentheses for the indentation code.")

(defconst problog-quoted-atom-regexp
  "\\(^\\|[^0-9]\\)\\('\\([^\n']\\|\\\\'\\)*'\\)"
  "Regexp matching a quoted atom.")
(defconst problog-string-regexp
  "\\(\"\\([^\n\"]\\|\\\\\"\\)*\"\\)"
  "Regexp matching a string.")
(defconst problog-head-delimiter "\\(:-\\|\\+:\\|-:\\|\\+\\?\\|-\\?\\|-->\\)"
  "A regexp for matching on the end delimiter of a head (e.g. \":-\").")

(defvar problog-compilation-buffer "*problog-compilation*"
  "Name of the output buffer for problog compilation/consulting.")

(defvar problog-temporary-file-name nil)
(defvar problog-keywords-i nil)
(defvar problog-types-i nil)
(defvar problog-mode-specificators-i nil)
(defvar problog-determinism-specificators-i nil)
(defvar problog-directives-i nil)
(defvar problog-eof-string-i nil)
;; (defvar problog-continued-prompt-regexp-i nil)
(defvar problog-help-function-i nil)

(defvar problog-align-rules
  (eval-when-compile
    (mapcar
     (lambda (x)
       (let ((name (car x))
             (sym  (cdr x)))
         `(,(intern (format "problog-%s" name))
           (regexp . ,(format "\\(\\s-*\\)%s\\(\\s-*\\)" sym))
           (tab-stop . nil)
           (modes . '(problog-mode))
           (group . (1 2)))))
     '(("dcg" . "-->") ("rule" . ":-") ("simplification" . "<=>")
       ("propagation" . "==>")))))

;; SMIE support

(require 'smie)

(defconst problog-operator-chars "-\\\\#&*+./:<=>?@\\^`~")

(defun problog-smie-forward-token ()
  ;; FIXME: Add support for 0'<char>, if needed after adding it to
  ;; syntax-propertize-functions.
  (forward-comment (point-max))
  (buffer-substring-no-properties
   (point)
   (progn (cond
           ((looking-at "[!;]") (forward-char 1))
           ((not (zerop (skip-chars-forward problog-operator-chars))))
           ((not (zerop (skip-syntax-forward "w_'"))))
           ;; In case of non-ASCII punctuation.
           ((not (zerop (skip-syntax-forward ".")))))
          (point))))

(defun problog-smie-backward-token ()
  ;; FIXME: Add support for 0'<char>, if needed after adding it to
  ;; syntax-propertize-functions.
  (forward-comment (- (point-max)))
  (buffer-substring-no-properties
   (point)
   (progn (cond
           ((memq (char-before) '(?! ?\; ?\,)) (forward-char -1))
           ((not (zerop (skip-chars-backward problog-operator-chars))))
           ((not (zerop (skip-syntax-backward "w_'"))))
           ;; In case of non-ASCII punctuation.
           ((not (zerop (skip-syntax-backward ".")))))
          (point))))

(defconst problog-smie-grammar
  ;; Rather than construct the operator levels table from the BNF,
  ;; we directly provide the operator precedences from GNU problog's
  ;; manual (7.14.10 op/3).  The only problem is that GNU problog's
  ;; manual uses precedence levels in the opposite sense (higher
  ;; numbers bind less tightly) than SMIE, so we use negative numbers.
  '(("." -10000 -10000)
    ("?-" nil -1200)
    (":-" -1200 -1200)
    ("-->" -1200 -1200)
    ("discontiguous" nil -1150)
    ("dynamic" nil -1150)
    ("meta_predicate" nil -1150)
    ("module_transparent" nil -1150)
    ("multifile" nil -1150)
    ("public" nil -1150)
    ("|" -1105 -1105)
    (";" -1100 -1100)
    ("*->" -1050 -1050)
    ("->" -1050 -1050)
    ("," -1000 -1000)
    ("\\+" nil -900)
    ("=" -700 -700)
    ("\\=" -700 -700)
    ("=.." -700 -700)
    ("==" -700 -700)
    ("\\==" -700 -700)
    ("@<" -700 -700)
    ("@=<" -700 -700)
    ("@>" -700 -700)
    ("@>=" -700 -700)
    ("is" -700 -700)
    ("=:=" -700 -700)
    ("=\\=" -700 -700)
    ("<" -700 -700)
    ("=<" -700 -700)
    (">" -700 -700)
    (">=" -700 -700)
    (":" -600 -600)
    ("+" -500 -500)
    ("-" -500 -500)
    ("/\\" -500 -500)
    ("\\/" -500 -500)
    ("*" -400 -400)
    ("/" -400 -400)
    ("//" -400 -400)
    ("rem" -400 -400)
    ("mod" -400 -400)
    ("<<" -400 -400)
    (">>" -400 -400)
    ("**" -200 -200)
    ("^" -200 -200)
    ;; Prefix
    ;; ("+" 200 200)
    ;; ("-" 200 200)
    ;; ("\\" 200 200)
    (:smie-closer-alist (t . "."))
    )
  "Precedence levels of infix operators.")

(defun problog-smie-rules (kind token)
  (pcase (cons kind token)
    (`(:elem . basic) problog-indent-width)
    ;; The list of arguments can never be on a separate line!
    (`(:list-intro . ,_) t)
    ;; When we don't know how to indent an empty line, assume the most
    ;; likely token will be ";".
    (`(:elem . empty-line-token) ";")
    (`(:after . ".") '(column . 0)) ;; To work around smie-closer-alist.
    ;; Allow indentation of if-then-else as:
    ;;    (   test
    ;;    ->  thenrule
    ;;    ;   elserule
    ;;    )
    (`(:before . ,(or `"->" `";"))
     (and (smie-rule-bolp) (smie-rule-parent-p "(") (smie-rule-parent 0)))
    (`(:after . ,(or `"->" `"*->"))
     ;; We distinguish
     ;;
     ;;     (a ->
     ;;          b;
     ;;      c)
     ;; and
     ;;     (    a ->
     ;;          b
     ;;     ;    c)
     ;;
     ;; based on the space between the open paren and the "a".
     (unless (and (smie-rule-parent-p "(" ";")
                  (save-excursion
                    (smie-indent-forward-token)
                    (smie-backward-sexp 'halfsexp)
                    (if (smie-rule-parent-p "(")
                        (not (eq (char-before) ?\())
                      (smie-indent-backward-token)
                      (smie-rule-bolp))))
       problog-indent-width))
    (`(:after . ";")
     ;; Align with same-line comment as in:
     ;;   ;   %% Toto
     ;;       foo
     (and (smie-rule-bolp)
          (looking-at ";[ \t]*\\(%\\)")
          (let ((offset (- (save-excursion (goto-char (match-beginning 1))
                                           (current-column))
                           (current-column))))
            ;; Only do it for small offsets, since the comment may actually be
            ;; an "end-of-line" comment at comment-column!
            (if (<= offset problog-indent-width) offset))))
    (`(:after . ",")
     ;; Special indent for:
     ;;    foopredicate(x) :- !,
     ;;        toto.
     (and (eq (char-before) ?!)
          (save-excursion
            (smie-indent-backward-token) ;Skip !
            (equal ":-" (car (smie-indent-backward-token))))
          (smie-rule-parent problog-indent-width)))
    (`(:after . ":-")
     (if (bolp)
         (save-excursion
           (smie-indent-forward-token)
           (skip-chars-forward " \t")
           (if (eolp)
               problog-indent-width
             (min problog-indent-width (current-column))))
       problog-indent-width))
    (`(:after . "-->") problog-indent-width)))


;;-------------------------------------------------------------------
;; problog mode
;;-------------------------------------------------------------------

;; Example: (problog-atleast-version '(3 . 6))
(defun problog-atleast-version (version)
  "Return t if the version of the current problog system is VERSION or later.
VERSION is of the format (Major . Minor)"
  ;; Version.major < major or
  ;; Version.major = major and Version.minor <= minor
  (let* ((thisversion (problog-find-value-by-system problog-system-version))
         (thismajor (car thisversion))
         (thisminor (cdr thisversion)))
    (or (< (car version) thismajor)
        (and (= (car version) thismajor)
             (<= (cdr version) thisminor)))
    ))

(define-abbrev-table 'problog-mode-abbrev-table ())

;; Because this can `eval' its arguments, any variable that gets
;; processed by it should be marked as :risky.
(defun problog-find-value-by-system (alist)
  "Get value from ALIST according to `problog-system'."
  (let ((system (or problog-system
                    (let ((infbuf (problog-inferior-buffer 'dont-run)))
                      (when infbuf
                        (buffer-local-value 'problog-system infbuf))))))
    (if (listp alist)
        (let (result
              id)
          (while alist
            (setq id (car (car alist)))
            (if (or (eq id system)
                    (eq id t)
                    (and (listp id)
                         (eval id)))
                (progn
                  (setq result (car (cdr (car alist))))
                  (if (and (listp result)
                           (eq (car result) 'eval))
                      (setq result (eval (car (cdr result)))))
                  (setq alist nil))
              (setq alist (cdr alist))))
          result)
      alist)))

(defconst problog-syntax-propertize-function
  (when (fboundp 'syntax-propertize-rules)
    (syntax-propertize-rules
     ;; GNU problog only accepts 0'\' rather than 0'', but the only
     ;; possible meaning of 0'' is rather clear.
     ("\\<0\\(''?\\)"
      (1 (unless (save-excursion (nth 8 (syntax-ppss (match-beginning 0))))
           (string-to-syntax "_"))))
     ;; We could check that we're not inside an atom, but I don't think
     ;; that 'foo 8'z could be a valid syntax anyway, so why bother?
     ("\\<[1-9][0-9]*\\('\\)[0-9a-zA-Z]" (1 "_"))
     ;; Supposedly, ISO-problog wants \NNN\ for octal and \xNNN\ for hexadecimal
     ;; escape sequences in atoms, so be careful not to let the terminating \
     ;; escape a subsequent quote.
     ("\\\\[x0-7][0-9a-fA-F]*\\(\\\\\\)" (1 "_"))
     )))

(defun problog-mode-variables ()
  "Set some common variables to problog code specific values."
  (setq-local local-abbrev-table problog-mode-abbrev-table)
  (setq-local paragraph-start (concat "[ \t]*$\\|" page-delimiter)) ;'%%..'
  (setq-local paragraph-separate paragraph-start)
  (setq-local paragraph-ignore-fill-prefix t)
  (setq-local normal-auto-fill-function 'problog-do-auto-fill)
  (setq-local comment-start "%")
  (setq-local comment-end "")
  (setq-local comment-add 1)
  (setq-local comment-start-skip "\\(?:/\\*+ *\\|%+ *\\)")
  (setq-local parens-require-spaces nil)
  ;; Initialize problog system specific variables
  (dolist (var '(problog-keywords problog-types problog-mode-specificators
                 problog-determinism-specificators problog-directives
                 problog-eof-string
                 ;; problog-continued-prompt-regexp
                 problog-help-function))
    (set (intern (concat (symbol-name var) "-i"))
         (problog-find-value-by-system (symbol-value var))))
  (when (null (problog-program-name))
    (setq-local compile-command (problog-compile-string)))
  (setq-local font-lock-defaults
              '(problog-font-lock-keywords nil nil ((?_ . "w"))))
  (setq-local syntax-propertize-function problog-syntax-propertize-function)

  (smie-setup problog-smie-grammar #'problog-smie-rules
              :forward-token #'problog-smie-forward-token
              :backward-token #'problog-smie-backward-token))

(defun problog-mode-keybindings-common (map)
  "Define keybindings common to both problog modes in MAP."
  (define-key map "\C-c?" 'problog-help-on-predicate)
  (define-key map "\C-c/" 'problog-help-apropos)
  (define-key map "\C-c\C-d" 'problog-debug-on)
  (define-key map "\C-c\C-t" 'problog-trace-on)
  (define-key map "\C-c\C-z" 'problog-zip-on)
  (define-key map "\C-c\r" 'run-problog))

(defun problog-mode-keybindings-edit (map)
  "Define keybindings for problog mode in MAP."
  (define-key map "\M-a" 'problog-beginning-of-clause)
  (define-key map "\M-e" 'problog-end-of-clause)
  (define-key map "\M-q" 'problog-fill-paragraph)
  (define-key map "\C-c\C-a" 'align)
  (define-key map "\C-\M-a" 'problog-beginning-of-predicate)
  (define-key map "\C-\M-e" 'problog-end-of-predicate)
  (define-key map "\M-\C-c" 'problog-mark-clause)
  (define-key map "\M-\C-h" 'problog-mark-predicate)
  (define-key map "\C-c\C-n" 'problog-insert-predicate-template)
  (define-key map "\C-c\C-s" 'problog-insert-predspec)
  (define-key map "\M-\r" 'problog-insert-next-clause)
  (define-key map "\C-c\C-va" 'problog-variables-to-anonymous)
  (define-key map "\C-c\C-v\C-s" 'problog-view-predspec)

  ;; If we're running SICStus, then map C-c C-c e/d to enabling
  ;; and disabling of the source-level debugging facilities.
  ;(if (and (eq problog-system 'sicstus)
  ;         (problog-atleast-version '(3 . 7)))
  ;    (progn
  ;      (define-key map "\C-c\C-ce" 'problog-enable-sicstus-sd)
  ;      (define-key map "\C-c\C-cd" 'problog-disable-sicstus-sd)
  ;      ))

  (if problog-old-sicstus-keys-flag
      (progn
        (define-key map "\C-c\C-c" 'problog-consult-predicate)
        (define-key map "\C-cc" 'problog-consult-region)
        (define-key map "\C-cC" 'problog-consult-buffer)
        (define-key map "\C-c\C-k" 'problog-compile-predicate)
        (define-key map "\C-ck" 'problog-compile-region)
        (define-key map "\C-cK" 'problog-compile-buffer))
    (define-key map "\C-c\C-p" 'problog-consult-predicate)
    (define-key map "\C-c\C-r" 'problog-consult-region)
    (define-key map "\C-c\C-b" 'problog-consult-buffer)
    (define-key map "\C-c\C-f" 'problog-consult-file)
    (define-key map "\C-c\C-cp" 'problog-compile-predicate)
    (define-key map "\C-c\C-cr" 'problog-compile-region)
    (define-key map "\C-c\C-cb" 'problog-compile-buffer)
    (define-key map "\C-c\C-cf" 'problog-compile-file))

  ;; Inherited from the old problog.el.
  (define-key map "\e\C-x" 'problog-consult-region)
  (define-key map "\C-c\C-l" 'problog-consult-file)
  (define-key map "\C-c\C-z" 'run-problog))

(defun problog-mode-keybindings-inferior (_map)
  "Define keybindings for inferior problog mode in MAP."
  ;; No inferior mode specific keybindings now.
  )

(defvar problog-mode-map
  (let ((map (make-sparse-keymap)))
    (problog-mode-keybindings-common map)
    (problog-mode-keybindings-edit map)
    map))


(defvar problog-mode-hook nil
  "List of functions to call after the problog mode has initialized.")

;;;###autoload
(define-derived-mode problog-mode prog-mode "problog"
  "Major mode for editing problog code.

Blank lines and `%%...' separate paragraphs.  `%'s starts a comment
line and comments can also be enclosed in /* ... */.

If an optional argument SYSTEM is non-nil, set up mode for the given system.

To find out what version of problog mode you are running, enter
`\\[problog-mode-version]'.

Commands:
\\{problog-mode-map}"
  (setq mode-name (concat "problog"
                          (cond
                           ((eq problog-system 'eclipse) "[ECLiPSe]")
                           ((eq problog-system 'sicstus) "[SICStus]")
                           ((eq problog-system 'swi) "[SWI]")
                           ((eq problog-system 'gnu) "[GNU]")
                           (t ""))))
  (problog-mode-variables)
  (dolist (ar problog-align-rules) (add-to-list 'align-rules-list ar))
  (add-hook 'post-self-insert-hook #'problog-post-self-insert nil t)
  ;; `imenu' entry moved to the appropriate hook for consistency.
  (when problog-electric-dot-flag
    (setq-local electric-indent-chars
                (cons ?\. electric-indent-chars)))

  ;; Load SICStus debugger if suitable
  (if (and (eq problog-system 'sicstus)
           (problog-atleast-version '(3 . 7))
           problog-use-sicstus-sd)
      (problog-enable-sicstus-sd))

  (problog-menu))

(defvar mercury-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map problog-mode-map)
    map))

;;;###autoload
(define-derived-mode mercury-mode problog-mode "problog[Mercury]"
  "Major mode for editing Mercury programs.
Actually this is just customized `problog-mode'."
  (setq-local problog-system 'mercury))


;;-------------------------------------------------------------------
;; Inferior problog mode
;;-------------------------------------------------------------------

(defvar problog-inferior-mode-map
  (let ((map (make-sparse-keymap)))
    (problog-mode-keybindings-common map)
    (problog-mode-keybindings-inferior map)
    (define-key map [remap self-insert-command]
      'problog-inferior-self-insert-command)
    map))

(defvar problog-inferior-mode-hook nil
  "List of functions to call after the inferior problog mode has initialized.")

(defvar problog-inferior-error-regexp-alist
  '(;; GNU problog used to not follow the GNU standard format.
    ;; ("^\\(.*?\\):\\([0-9]+\\) error: .*(char:\\([0-9]+\\)" 1 2 3)
    ;; SWI-problog.
    ("^\\(?:\\?- *\\)?\\(\\(?:ERROR\\|\\(W\\)arning\\): *\\(.*?\\):\\([1-9][0-9]*\\):\\(?:\\([0-9]*\\):\\)?\\)\\(?:$\\| \\)"
     3 4 5 (2 . nil) 1)
    ;; GNU-problog now uses the GNU standard format.
    gnu))

(defun problog-inferior-self-insert-command ()
  "Insert the char in the buffer or pass it directly to the process."
  (interactive)
  (let* ((proc (get-buffer-process (current-buffer)))
         (pmark (and proc (marker-position (process-mark proc)))))
    ;; FIXME: the same treatment would be needed for SWI-problog, but I can't
    ;; seem to find any way for Emacs to figure out when to use it because
    ;; SWI doesn't include a " ? " or some such recognizable marker.
    (if (and (eq problog-system 'gnu)
             pmark
             (null current-prefix-arg)
             (eobp)
             (eq (point) pmark)
             (save-excursion
               (goto-char (- pmark 3))
               ;; FIXME: check this comes from the process's output, maybe?
               (looking-at " \\? ")))
        ;; This is GNU problog waiting to know whether you want more answers
        ;; or not (or abort, etc...).  The answer is a single char, not
        ;; a line, so pass this char directly rather than wait for RET to
        ;; send a whole line.
        (comint-send-string proc (string last-command-event))
      (call-interactively 'self-insert-command))))

(declare-function compilation-shell-minor-mode "compile" (&optional arg))
(defvar compilation-error-regexp-alist)

(define-derived-mode problog-inferior-mode comint-mode "Inferior problog"
  "Major mode for interacting with an inferior problog process.

The following commands are available:
\\{problog-inferior-mode-map}

Entry to this mode calls the value of `problog-mode-hook' with no arguments,
if that value is non-nil.  Likewise with the value of `comint-mode-hook'.
`problog-mode-hook' is called after `comint-mode-hook'.

You can send text to the inferior problog from other buffers
using the commands `send-region', `send-string' and \\[problog-consult-region].

Commands:
Tab indents for problog; with argument, shifts rest
 of expression rigidly with the current line.
Paragraphs are separated only by blank lines and `%%'. `%'s start comments.

Return at end of buffer sends line as input.
Return not at end copies rest of line to end and sends it.
\\[comint-delchar-or-maybe-eof] sends end-of-file as input.
\\[comint-kill-input] and \\[backward-kill-word] are kill commands,
imitating normal Unix input editing.
\\[comint-interrupt-subjob] interrupts the shell or its current subjob if any.
\\[comint-stop-subjob] stops, likewise.
\\[comint-quit-subjob] sends quit signal, likewise.

To find out what version of problog mode you are running, enter
`\\[problog-mode-version]'."
  (require 'compile)
  (setq comint-input-filter 'problog-input-filter)
  (setq mode-line-process '(": %s"))
  (problog-mode-variables)
  (setq comint-prompt-regexp (problog-prompt-regexp))
  (setq-local shell-dirstack-query "pwd.")
  (setq-local compilation-error-regexp-alist
              problog-inferior-error-regexp-alist)
  (compilation-shell-minor-mode)
  (problog-inferior-menu))

(defun problog-input-filter (str)
  (cond ((string-match "\\`\\s *\\'" str) nil) ;whitespace
        ((not (derived-mode-p 'problog-inferior-mode)) t)
        ((= (length str) 1) nil)        ;one character
        ((string-match "\\`[rf] *[0-9]*\\'" str) nil) ;r(edo) or f(ail)
        (t t)))

;; This statement was missing in Emacs 24.1, 24.2, 24.3.
(define-obsolete-function-alias 'switch-to-problog 'run-problog "24.1")
;;;###autoload
(defun run-problog (arg)
  "Run an inferior problog process, input and output via buffer *problog*.
With prefix argument ARG, restart the problog process if running before."
  (interactive "P")
  ;; FIXME: It should be possible to interactively specify the command to use
  ;; to run problog.
  (if (and arg (get-process "problog"))
      (progn
        (process-send-string "problog" "halt.\n")
        (while (get-process "problog") (sit-for 0.1))))
  (let ((buff (buffer-name)))
    (if (not (string= buff "*problog*"))
        (problog-goto-problog-process-buffer))
    ;; Load SICStus debugger if suitable
    (if (and (eq problog-system 'sicstus)
             (problog-atleast-version '(3 . 7))
             problog-use-sicstus-sd)
        (problog-enable-sicstus-sd))
    (problog-mode-variables)
    (problog-ensure-process)
    ))

(defun problog-inferior-guess-flavor (&optional ignored)
  (setq-local problog-system
              (when (or (numberp problog-system) (markerp problog-system))
                (save-excursion
                  (goto-char (1+ problog-system))
                  (cond
                   ((looking-at "GNU problog") 'gnu)
                   ((looking-at "Welcome to SWI-problog\\|%.*\\<swi_") 'swi)
                   ((looking-at ".*\n") nil) ;There's at least one line.
                   (t problog-system)))))
  (when (symbolp problog-system)
    (remove-hook 'comint-output-filter-functions
                 'problog-inferior-guess-flavor t)
    (when problog-system
      (setq comint-prompt-regexp (problog-prompt-regexp))
      (if (eq problog-system 'gnu)
          (setq-local comint-process-echoes t)))))

(defun problog-ensure-process (&optional wait)
  "If problog process is not running, run it.
If the optional argument WAIT is non-nil, wait for problog prompt specified by
the variable `problog-prompt-regexp'."
  (if (null (problog-program-name))
      (error "This problog system has defined no interpreter."))
  (if (comint-check-proc "*problog*")
      ()
    (with-current-buffer (get-buffer-create "*problog*")
      (problog-inferior-mode)

      ;; The "INFERIOR=yes" hack is for SWI-problog 7.2.3 and earlier,
      ;; which assumes it is running under Emacs if either INFERIOR=yes or
      ;; if EMACS is set to a nonempty value.  The EMACS setting is
      ;; obsolescent, so set INFERIOR.  Newer versions of SWI-problog should
      ;; know about INSIDE_EMACS (which replaced EMACS) and should not need
      ;; this hack.
      (let ((process-environment
	     (if (getenv "INFERIOR")
		 process-environment
	       (cons "INFERIOR=yes" process-environment))))
	(apply 'make-comint-in-buffer "problog" (current-buffer)
	       (problog-program-name) nil (problog-program-switches)))

      (unless problog-system
        ;; Setup auto-detection.
        (setq-local
         problog-system
         ;; Force re-detection.
         (let* ((proc (get-buffer-process (current-buffer)))
                (pmark (and proc (marker-position (process-mark proc)))))
           (cond
            ((null pmark) (1- (point-min)))
            ;; The use of insert-before-markers in comint.el together with
            ;; the potential use of comint-truncate-buffer in the output
            ;; filter, means that it's difficult to reliably keep track of
            ;; the buffer position where the process's output started.
            ;; If possible we use a marker at "start - 1", so that
            ;; insert-before-marker at `start' won't shift it.  And if not,
            ;; we fall back on using a plain integer.
            ((> pmark (point-min)) (copy-marker (1- pmark)))
            (t (1- pmark)))))
        (add-hook 'comint-output-filter-functions
                  'problog-inferior-guess-flavor nil t))
      (if wait
          (progn
            (goto-char (point-max))
            (while
                (save-excursion
                  (not
                   (re-search-backward
                    (concat "\\(" (problog-prompt-regexp) "\\)" "\\=")
                    nil t)))
              (sit-for 0.1)))))))

(defun problog-inferior-buffer (&optional dont-run)
  (or (get-buffer "*problog*")
      (unless dont-run
        (problog-ensure-process)
        (get-buffer "*problog*"))))

(defun problog-process-insert-string (process string)
  "Insert STRING into inferior problog buffer running PROCESS."
  ;; Copied from elisp manual, greek to me
  (with-current-buffer (process-buffer process)
    ;; FIXME: Use window-point-insertion-type instead.
    (let ((moving (= (point) (process-mark process))))
      (save-excursion
        ;; Insert the text, moving the process-marker.
        (goto-char (process-mark process))
        (insert string)
        (set-marker (process-mark process) (point)))
      (if moving (goto-char (process-mark process))))))

;;------------------------------------------------------------
;; Old consulting and compiling functions
;;------------------------------------------------------------

(declare-function compilation-forget-errors "compile" ())
(declare-function compilation-fake-loc "compile"
                  (marker file &optional line col))

(defun problog-old-process-region (compilep start end)
  "Process the region limited by START and END positions.
If COMPILEP is non-nil then use compilation, otherwise consulting."
   (problog-ensure-process)
   ;(let ((tmpfile problog-temp-filename)
   (let ((tmpfile (problog-temporary-file))
         ;(process (get-process "problog"))
         (first-line (1+ (count-lines
                          (point-min)
                          (save-excursion
                            (goto-char start)
                            (point))))))
     (write-region start end tmpfile)
     (setq start (copy-marker start))
     (with-current-buffer (problog-inferior-buffer)
       (compilation-forget-errors)
       (compilation-fake-loc start tmpfile))
     (process-send-string
      "problog" (problog-build-problog-command
                compilep tmpfile (problog-bsts buffer-file-name)
                first-line))
     (problog-goto-problog-process-buffer)))

(defun problog-old-process-predicate (compilep)
  "Process the predicate around point.
If COMPILEP is non-nil then use compilation, otherwise consulting."
  (problog-old-process-region
   compilep (problog-pred-start) (problog-pred-end)))

(defun problog-old-process-buffer (compilep)
  "Process the entire buffer.
If COMPILEP is non-nil then use compilation, otherwise consulting."
  (problog-old-process-region compilep (point-min) (point-max)))

(defun problog-old-process-file (compilep)
  "Process the file of the current buffer.
If COMPILEP is non-nil then use compilation, otherwise consulting."
  (save-some-buffers)
  (problog-ensure-process)
  (with-current-buffer (problog-inferior-buffer)
    (compilation-forget-errors))
    (process-send-string
     "problog" (problog-build-problog-command
             compilep buffer-file-name
             (problog-bsts buffer-file-name)))
  (problog-goto-problog-process-buffer))


;;------------------------------------------------------------
;; Consulting and compiling
;;------------------------------------------------------------

;; Interactive interface functions, used by both the standard
;; and the experimental consultation and compilation functions
(defun problog-consult-file ()
  "Consult file of current buffer."
  (interactive)
  (if problog-use-standard-consult-compile-method-flag
      (problog-old-process-file nil)
    (problog-consult-compile-file nil)))

(defun problog-consult-buffer ()
  "Consult buffer."
  (interactive)
  (if problog-use-standard-consult-compile-method-flag
      (problog-old-process-buffer nil)
    (problog-consult-compile-buffer nil)))

(defun problog-consult-region (beg end)
  "Consult region between BEG and END."
  (interactive "r")
  (if problog-use-standard-consult-compile-method-flag
      (problog-old-process-region nil beg end)
    (problog-consult-compile-region nil beg end)))

(defun problog-consult-predicate ()
  "Consult the predicate around current point."
  (interactive)
  (if problog-use-standard-consult-compile-method-flag
      (problog-old-process-predicate nil)
    (problog-consult-compile-predicate nil)))

(defun problog-compile-file ()
  "Compile file of current buffer."
  (interactive)
  (if problog-use-standard-consult-compile-method-flag
      (problog-old-process-file t)
    (problog-consult-compile-file t)))

(defun problog-compile-buffer ()
  "Compile buffer."
  (interactive)
  (if problog-use-standard-consult-compile-method-flag
      (problog-old-process-buffer t)
    (problog-consult-compile-buffer t)))

(defun problog-compile-region (beg end)
  "Compile region between BEG and END."
  (interactive "r")
  (if problog-use-standard-consult-compile-method-flag
      (problog-old-process-region t beg end)
    (problog-consult-compile-region t beg end)))

(defun problog-compile-predicate ()
  "Compile the predicate around current point."
  (interactive)
  (if problog-use-standard-consult-compile-method-flag
      (problog-old-process-predicate t)
    (problog-consult-compile-predicate t)))

(defun problog-buffer-module ()
  "Select problog module name appropriate for current buffer.
Bases decision on buffer contents (-*- line)."
  ;; Look for -*- ... module: MODULENAME; ... -*-
  (let (beg end)
    (save-excursion
      (goto-char (point-min))
      (skip-chars-forward " \t")
      (and (search-forward "-*-" (line-end-position) t)
           (progn
             (skip-chars-forward " \t")
             (setq beg (point))
             (search-forward "-*-" (line-end-position) t))
           (progn
             (forward-char -3)
             (skip-chars-backward " \t")
             (setq end (point))
             (goto-char beg)
             (and (let ((case-fold-search t))
                    (search-forward "module:" end t))
                  (progn
                    (skip-chars-forward " \t")
                    (setq beg (point))
                    (if (search-forward ";" end t)
                        (forward-char -1)
                      (goto-char end))
                    (skip-chars-backward " \t")
                    (buffer-substring beg (point)))))))))

(defun problog-build-problog-command (compilep file buffername
                                    &optional first-line)
  "Make problog command for FILE compilation/consulting.
If COMPILEP is non-nil, consider compilation, otherwise consulting."
  (let* ((compile-string
          ;; FIXME: If the process is not running yet, the auto-detection of
          ;; problog-system won't help here, so we should make sure
          ;; we first run problog and then build the command.
          (if compilep (problog-compile-string) (problog-consult-string)))
         (module (problog-buffer-module))
         (file-name (concat "'" (problog-bsts file) "'"))
         (module-name (if module (concat "'" module "'")))
         (module-file (if module
                          (concat module-name ":" file-name)
                        file-name))
         strbeg strend
         (lineoffset (if first-line
                         (- first-line 1)
                       0)))

    ;; Assure that there is a buffer name
    (if (not buffername)
        (error "The buffer is not saved"))

    (if (not (string-match "\\`'.*'\\'" buffername)) ; Add quotes
        (setq buffername (concat "'" buffername "'")))
    (while (string-match "%m" compile-string)
      (setq strbeg (substring compile-string 0 (match-beginning 0)))
      (setq strend (substring compile-string (match-end 0)))
      (setq compile-string (concat strbeg module-file strend)))
    ;; FIXME: The code below will %-expand any %[fbl] that appears in
    ;; module-file.
    (while (string-match "%f" compile-string)
      (setq strbeg (substring compile-string 0 (match-beginning 0)))
      (setq strend (substring compile-string (match-end 0)))
      (setq compile-string (concat strbeg file-name strend)))
    (while (string-match "%b" compile-string)
      (setq strbeg (substring compile-string 0 (match-beginning 0)))
      (setq strend (substring compile-string (match-end 0)))
      (setq compile-string (concat strbeg buffername strend)))
    (while (string-match "%l" compile-string)
      (setq strbeg (substring compile-string 0 (match-beginning 0)))
      (setq strend (substring compile-string (match-end 0)))
      (setq compile-string (concat strbeg (format "%d" lineoffset) strend)))
    (concat compile-string "\n")))

;; The rest of this page is experimental code!

;; Global variables for process filter function
(defvar problog-process-flag nil
  "Non-nil means that a problog task (i.e. a consultation or compilation job)
is running.")
(defvar problog-consult-compile-output ""
  "Hold the unprocessed output from the current problog task.")
(defvar problog-consult-compile-first-line 1
  "The number of the first line of the file to consult/compile.
Used for temporary files.")
(defvar problog-consult-compile-file nil
  "The file to compile/consult (can be a temporary file).")
(defvar problog-consult-compile-real-file nil
  "The file name of the buffer to compile/consult.")

(defvar compilation-parse-errors-function)

(defun problog-consult-compile (compilep file &optional first-line)
  "Consult/compile FILE.
If COMPILEP is non-nil, perform compilation, otherwise perform CONSULTING.
COMMAND is a string described by the variables `problog-consult-string'
and `problog-compile-string'.
Optional argument FIRST-LINE is the number of the first line in the compiled
region.

This function must be called from the source code buffer."
  (if problog-process-flag
      (error "Another problog task is running."))
  (problog-ensure-process t)
  (let* ((buffer (get-buffer-create problog-compilation-buffer))
         (real-file buffer-file-name)
         (command-string (problog-build-problog-command compilep file
                                                      real-file first-line))
         (process (get-process "problog")))
    (with-current-buffer buffer
      (delete-region (point-min) (point-max))
      ;; FIXME: Wasn't this supposed to use problog-inferior-mode?
      (compilation-mode)
      ;; FIXME: This doesn't seem to cooperate well with new(ish) compile.el.
      ;; Setting up font-locking for this buffer
      (setq-local font-lock-defaults
                  '(problog-font-lock-keywords nil nil ((?_ . "w"))))
      (if (eq problog-system 'sicstus)
          ;; FIXME: This looks really problematic: not only is this using
          ;; the old compilation-parse-errors-function, but
          ;; problog-parse-sicstus-compilation-errors only accepts one argument
          ;; whereas compile.el calls it with 2 (and did so at least since
          ;; Emacs-20).
          (setq-local compilation-parse-errors-function
                      'problog-parse-sicstus-compilation-errors))
      (setq buffer-read-only nil)
      (insert command-string "\n"))
    (display-buffer buffer)
    (setq problog-process-flag t
          problog-consult-compile-output ""
          problog-consult-compile-first-line (if first-line (1- first-line) 0)
          problog-consult-compile-file file
          problog-consult-compile-real-file (if (string=
                                                file buffer-file-name)
                                               nil
                                             real-file))
    (with-current-buffer buffer
      (goto-char (point-max))
      (add-function :override (process-filter process)
                    #'problog-consult-compile-filter)
      (process-send-string "problog" command-string)
      ;; (problog-build-problog-command compilep file real-file first-line))
      (while (and problog-process-flag
                  (accept-process-output process 10)) ; 10 secs is ok?
        (sit-for 0.1)
        (unless (get-process "problog")
          (setq problog-process-flag nil)))
      (insert (if compilep
                  "\nCompilation finished.\n"
                "\nConsulted.\n"))
      (remove-function (process-filter process)
                       #'problog-consult-compile-filter))))

(defvar compilation-error-list)

(defun problog-parse-sicstus-compilation-errors (limit)
  "Parse the problog compilation buffer for errors.
Argument LIMIT is a buffer position limiting searching.
For use with the `compilation-parse-errors-function' variable."
  (setq compilation-error-list nil)
  (message "Parsing SICStus error messages...")
  (let (filepath dir file errorline)
    (while
        (re-search-backward
         "{\\([a-zA-Z ]* ERROR\\|Warning\\):.* in line[s ]*\\([0-9]+\\)"
         limit t)
      (setq errorline (string-to-number (match-string 2)))
      (save-excursion
        (re-search-backward
         "{\\(consulting\\|compiling\\|processing\\) \\(.*\\)\\.\\.\\.}"
         limit t)
        (setq filepath (match-string 2)))

      ;; ###### Does this work with SICStus under Windows
      ;; (i.e. backslashes and stuff?)
      (if (string-match "\\(.*/\\)\\([^/]*\\)$" filepath)
          (progn
            (setq dir (match-string 1 filepath))
            (setq file (match-string 2 filepath))))

      (setq compilation-error-list
            (cons
             (cons (save-excursion
                     (beginning-of-line)
                     (point-marker))
                   (list (list file dir) errorline))
             compilation-error-list)
            ))
    ))

(defun problog-consult-compile-filter (process output)
  "Filter function for problog compilation PROCESS.
Argument OUTPUT is a name of the output file."
  ;;(message "start")
  (setq problog-consult-compile-output
        (concat problog-consult-compile-output output))
  ;;(message "pccf1: %s" problog-consult-compile-output)
  ;; Iterate through the lines of problog-consult-compile-output
  (let (outputtype)
    (while (and problog-process-flag
                (or
                 ;; Trace question
                 (progn
                   (setq outputtype 'trace)
                   (and (eq problog-system 'sicstus)
                        (string-match
                         "^[ \t]*[0-9]+[ \t]*[0-9]+[ \t]*Call:.*? "
                         problog-consult-compile-output)))

                 ;; Match anything
                 (progn
                   (setq outputtype 'normal)
                   (string-match "^.*\n" problog-consult-compile-output))
                   ))
      ;;(message "outputtype: %s" outputtype)

      (setq output (match-string 0 problog-consult-compile-output))
      ;; remove the text in output from problog-consult-compile-output
      (setq problog-consult-compile-output
            (substring problog-consult-compile-output (length output)))
      ;;(message "pccf2: %s" problog-consult-compile-output)

      ;; If temporary files were used, then we change the error
      ;; messages to point to the original source file.
      ;; FIXME: Use compilation-fake-loc instead.
      (cond

       ;; If the problog process was in trace mode then it requires
       ;; user input
       ((and (eq problog-system 'sicstus)
             (eq outputtype 'trace))
        (let ((input (concat (read-string output) "\n")))
          (process-send-string process input)
          (setq output (concat output input))))

       ((eq problog-system 'sicstus)
        (if (and problog-consult-compile-real-file
                 (string-match
                  "\\({.*:.* in line[s ]*\\)\\([0-9]+\\)-\\([0-9]+\\)" output))
            (setq output (replace-match
                          ;; Adds a {processing ...} line so that
                          ;; `problog-parse-sicstus-compilation-errors'
                          ;; finds the real file instead of the temporary one.
                          ;; Also fixes the line numbers.
                          (format "Added by Emacs: {processing %s...}\n%s%d-%d"
                                  problog-consult-compile-real-file
                                  (match-string 1 output)
                                  (+ problog-consult-compile-first-line
                                     (string-to-number
                                      (match-string 2 output)))
                                  (+ problog-consult-compile-first-line
                                     (string-to-number
                                      (match-string 3 output))))
                          t t output)))
        )

       ((eq problog-system 'swi)
        (if (and problog-consult-compile-real-file
                 (string-match (format
                                "%s\\([ \t]*:[ \t]*\\)\\([0-9]+\\)"
                                problog-consult-compile-file)
                               output))
            (setq output (replace-match
                          ;; Real filename + text + fixed linenum
                          (format "%s%s%d"
                                  problog-consult-compile-real-file
                                  (match-string 1 output)
                                  (+ problog-consult-compile-first-line
                                     (string-to-number
                                      (match-string 2 output))))
                          t t output)))
        )

       (t ())
       )
      ;; Write the output in the *problog-compilation* buffer
      (insert output)))

  ;; If the prompt is visible, then the task is finished
  (if (string-match (problog-prompt-regexp) problog-consult-compile-output)
      (setq problog-process-flag nil)))

(defun problog-consult-compile-file (compilep)
  "Consult/compile file of current buffer.
If COMPILEP is non-nil, compile, otherwise consult."
  (let ((file buffer-file-name))
    (if file
        (progn
          (save-some-buffers)
          (problog-consult-compile compilep file))
      (problog-consult-compile-region compilep (point-min) (point-max)))))

(defun problog-consult-compile-buffer (compilep)
  "Consult/compile current buffer.
If COMPILEP is non-nil, compile, otherwise consult."
  (problog-consult-compile-region compilep (point-min) (point-max)))

(defun problog-consult-compile-region (compilep beg end)
  "Consult/compile region between BEG and END.
If COMPILEP is non-nil, compile, otherwise consult."
  ;(let ((file problog-temp-filename)
  (let ((file (problog-bsts (problog-temporary-file)))
        (lines (count-lines 1 beg)))
    (write-region beg end file nil 'no-message)
    (write-region "\n" nil file t 'no-message)
    (problog-consult-compile compilep file
                            (if (bolp) (1+ lines) lines))
    (delete-file file)))

(defun problog-consult-compile-predicate (compilep)
  "Consult/compile the predicate around current point.
If COMPILEP is non-nil, compile, otherwise consult."
  (problog-consult-compile-region
   compilep (problog-pred-start) (problog-pred-end)))


;;-------------------------------------------------------------------
;; Font-lock stuff
;;-------------------------------------------------------------------

;; Auxiliary functions

(defun problog-font-lock-object-matcher (bound)
  "Find SICStus objects method name for font lock.
Argument BOUND is a buffer position limiting searching."
  (let (point
        (case-fold-search nil))
    (while (and (not point)
                (re-search-forward "\\(::[ \t\n]*{\\|&\\)[ \t]*"
                                   bound t))
      (while (or (re-search-forward "\\=\n[ \t]*" bound t)
                 (re-search-forward "\\=%.*" bound t)
                 (and (re-search-forward "\\=/\\*" bound t)
                      (re-search-forward "\\*/[ \t]*" bound t))))
      (setq point (re-search-forward
                   (format "\\=\\(%s\\)" problog-atom-regexp)
                   bound t)))
    point))

(defsubst problog-face-name-p (facename)
  ;; Return t if FACENAME is the name of a face.  This method is
  ;; necessary since facep in XEmacs only returns t for the actual
  ;; face objects (while it's only their names that are used just
  ;; about anywhere else) without providing a predicate that tests
  ;; face names.  This function (including the above commentary) is
  ;; borrowed from cc-mode.
  (memq facename (face-list)))

;; Set everything up
(defun problog-font-lock-keywords ()
  "Set up font lock keywords for the current problog system."
  ;;(when window-system
  (require 'font-lock)

  ;; Define problog faces
  (defface problog-redo-face
    '((((class grayscale)) (:italic t))
      (((class color)) (:foreground "darkorchid"))
      (t (:italic t)))
    "problog mode face for highlighting redo trace lines."
    :group 'problog-faces)
  (defface problog-exit-face
    '((((class grayscale)) (:underline t))
      (((class color) (background dark)) (:foreground "green"))
      (((class color) (background light)) (:foreground "ForestGreen"))
      (t (:underline t)))
    "problog mode face for highlighting exit trace lines."
    :group 'problog-faces)
  (defface problog-exception-face
    '((((class grayscale)) (:bold t :italic t :underline t))
      (((class color)) (:bold t :foreground "black" :background "Khaki"))
      (t (:bold t :italic t :underline t)))
    "problog mode face for highlighting exception trace lines."
    :group 'problog-faces)
  (defface problog-warning-face
    '((((class grayscale)) (:underline t))
      (((class color) (background dark)) (:foreground "blue"))
      (((class color) (background light)) (:foreground "MidnightBlue"))
      (t (:underline t)))
    "Face name to use for compiler warnings."
    :group 'problog-faces)
  (defface problog-builtin-face
    '((((class color) (background light)) (:foreground "Purple"))
      (((class color) (background dark)) (:foreground "Cyan"))
      (((class grayscale) (background light))
       :foreground "LightGray" :bold t)
      (((class grayscale) (background dark)) (:foreground "DimGray" :bold t))
      (t (:bold t)))
    "Face name to use for compiler warnings."
    :group 'problog-faces)
  (defvar problog-warning-face
    (if (problog-face-name-p 'font-lock-warning-face)
        'font-lock-warning-face
      'problog-warning-face)
    "Face name to use for built in predicates.")
  (defvar problog-builtin-face
    (if (problog-face-name-p 'font-lock-builtin-face)
        'font-lock-builtin-face
      'problog-builtin-face)
    "Face name to use for built in predicates.")
  (defvar problog-redo-face 'problog-redo-face
    "Face name to use for redo trace lines.")
  (defvar problog-exit-face 'problog-exit-face
    "Face name to use for exit trace lines.")
  (defvar problog-exception-face 'problog-exception-face
    "Face name to use for exception trace lines.")

  ;; Font Lock Patterns
  (let (
        ;; "Native" problog patterns
        (head-predicates
         (list (format "^\\(%s\\)\\((\\|[ \t]*:-\\)" problog-atom-regexp)
               1 font-lock-function-name-face))
                                       ;(list (format "^%s" problog-atom-regexp)
                                       ;      0 font-lock-function-name-face))
        (head-predicates-1
         (list (format "\\.[ \t]*\\(%s\\)" problog-atom-regexp)
               1 font-lock-function-name-face) )
        (variables
         '("\\<\\([_A-Z][a-zA-Z0-9_]*\\)"
           1 font-lock-variable-name-face))
        (important-elements
         (list (if (eq problog-system 'mercury)
                   "[][}{;|]\\|\\\\[+=]\\|<?=>?"
                 "[][}{!;|]\\|\\*->")
               0 'font-lock-keyword-face))
        (important-elements-1
         '("[^-*]\\(->\\)" 1 font-lock-keyword-face))
        (predspecs                      ; module:predicate/cardinality
         (list (format "\\<\\(%s:\\|\\)%s/[0-9]+"
                       problog-atom-regexp problog-atom-regexp)
               0 font-lock-function-name-face 'prepend))
        (keywords                       ; directives (queries)
         (list
          (if (eq problog-system 'mercury)
              (concat
               "\\<\\("
               (regexp-opt problog-keywords-i)
               "\\|"
               (regexp-opt
                problog-determinism-specificators-i)
               "\\)\\>")
            (concat
             "^[?:]- *\\("
             (regexp-opt problog-keywords-i)
             "\\)\\>"))
          1 problog-builtin-face))
        ;; SICStus specific patterns
        (sicstus-object-methods
         (if (eq problog-system 'sicstus)
             '(problog-font-lock-object-matcher
               1 font-lock-function-name-face)))
        ;; Mercury specific patterns
        (types
         (if (eq problog-system 'mercury)
             (list
              (regexp-opt problog-types-i 'words)
              0 'font-lock-type-face)))
        (modes
         (if (eq problog-system 'mercury)
             (list
              (regexp-opt problog-mode-specificators-i 'words)
              0 'font-lock-constant-face)))
        (directives
         (if (eq problog-system 'mercury)
             (list
              (regexp-opt problog-directives-i 'words)
              0 'problog-warning-face)))
        ;; Inferior mode specific patterns
        (prompt
         ;; FIXME: Should be handled by comint already.
         (list (problog-prompt-regexp) 0 'font-lock-keyword-face))
        (trace-exit
         ;; FIXME: Add to compilation-error-regexp-alist instead.
         (cond
          ((eq problog-system 'sicstus)
           '("[ \t]*[0-9]+[ \t]+[0-9]+[ \t]*\\(Exit\\):"
             1 problog-exit-face))
          ((eq problog-system 'swi)
           '("[ \t]*\\(Exit\\):[ \t]*([ \t0-9]*)" 1 problog-exit-face))
          (t nil)))
        (trace-fail
         ;; FIXME: Add to compilation-error-regexp-alist instead.
         (cond
          ((eq problog-system 'sicstus)
           '("[ \t]*[0-9]+[ \t]+[0-9]+[ \t]*\\(Fail\\):"
             1 problog-warning-face))
          ((eq problog-system 'swi)
           '("[ \t]*\\(Fail\\):[ \t]*([ \t0-9]*)" 1 problog-warning-face))
          (t nil)))
        (trace-redo
         ;; FIXME: Add to compilation-error-regexp-alist instead.
         (cond
          ((eq problog-system 'sicstus)
           '("[ \t]*[0-9]+[ \t]+[0-9]+[ \t]*\\(Redo\\):"
             1 problog-redo-face))
          ((eq problog-system 'swi)
           '("[ \t]*\\(Redo\\):[ \t]*([ \t0-9]*)" 1 problog-redo-face))
          (t nil)))
        (trace-call
         ;; FIXME: Add to compilation-error-regexp-alist instead.
         (cond
          ((eq problog-system 'sicstus)
           '("[ \t]*[0-9]+[ \t]+[0-9]+[ \t]*\\(Call\\):"
             1 font-lock-function-name-face))
          ((eq problog-system 'swi)
           '("[ \t]*\\(Call\\):[ \t]*([ \t0-9]*)"
             1 font-lock-function-name-face))
          (t nil)))
        (trace-exception
         ;; FIXME: Add to compilation-error-regexp-alist instead.
         (cond
          ((eq problog-system 'sicstus)
           '("[ \t]*[0-9]+[ \t]+[0-9]+[ \t]*\\(Exception\\):"
             1 problog-exception-face))
          ((eq problog-system 'swi)
           '("[ \t]*\\(Exception\\):[ \t]*([ \t0-9]*)"
             1 problog-exception-face))
          (t nil)))
        (error-message-identifier
         ;; FIXME: Add to compilation-error-regexp-alist instead.
         (cond
          ((eq problog-system 'sicstus)
           '("{\\([A-Z]* ?ERROR:\\)" 1 problog-exception-face prepend))
          ((eq problog-system 'swi)
           '("^[[]\\(WARNING:\\)" 1 problog-builtin-face prepend))
          (t nil)))
        (error-whole-messages
         ;; FIXME: Add to compilation-error-regexp-alist instead.
         (cond
          ((eq problog-system 'sicstus)
           '("{\\([A-Z]* ?ERROR:.*\\)}[ \t]*$"
             1 font-lock-comment-face append))
          ((eq problog-system 'swi)
           '("^[[]WARNING:[^]]*[]]$" 0 font-lock-comment-face append))
          (t nil)))
        (error-warning-messages
         ;; FIXME: Add to compilation-error-regexp-alist instead.
         ;; Mostly errors that SICStus asks the user about how to solve,
         ;; such as "NAME CLASH:" for example.
         (cond
          ((eq problog-system 'sicstus)
           '("^[A-Z ]*[A-Z]+:" 0 problog-warning-face))
          (t nil)))
        (warning-messages
         ;; FIXME: Add to compilation-error-regexp-alist instead.
         (cond
          ((eq problog-system 'sicstus)
           '("\\({ ?\\(Warning\\|WARNING\\) ?:.*}\\)[ \t]*$"
             2 problog-warning-face prepend))
          (t nil))))

    ;; Make font lock list
    (delq
     nil
     (cond
      ((eq major-mode 'problog-mode)
       (list
        head-predicates
        head-predicates-1
        variables
        important-elements
        important-elements-1
        predspecs
        keywords
        sicstus-object-methods
        types
        modes
        directives))
      ((eq major-mode 'problog-inferior-mode)
       (list
        prompt
        error-message-identifier
        error-whole-messages
        error-warning-messages
        warning-messages
        predspecs
        trace-exit
        trace-fail
        trace-redo
        trace-call
        trace-exception))
      ((eq major-mode 'compilation-mode)
       (list
        error-message-identifier
        error-whole-messages
        error-warning-messages
        warning-messages
        predspecs))))
    ))



(defun problog-find-unmatched-paren ()
  "Return the column of the last unmatched left parenthesis."
  (save-excursion
    (goto-char (or (nth 1 (syntax-ppss)) (point-min)))
    (current-column)))


(defun problog-paren-balance ()
  "Return the parenthesis balance of the current line.
A return value of N means N more left parentheses than right ones."
  (save-excursion
    (car (parse-partial-sexp (line-beginning-position)
                             (line-end-position)))))

(defun problog-electric--if-then-else ()
  "Insert spaces after the opening parenthesis, \"then\" (->) and \"else\" (;) branches.
Spaces are inserted if all preceding objects on the line are
whitespace characters, parentheses, or then/else branches."
  (when problog-electric-if-then-else-flag
    (save-excursion
      (let ((regexp (concat "(\\|" problog-left-indent-regexp))
            (pos (point))
            level)
        (beginning-of-line)
        (skip-chars-forward " \t")
        ;; Treat "( If -> " lines specially.
        ;;(setq incr (if (looking-at "(.*->")
        ;;               2
        ;;             problog-paren-indent))

        ;; work on all subsequent "->", "(", ";"
        (and (looking-at regexp)
             (= pos (match-end 0))
             (indent-according-to-mode))
        (while (looking-at regexp)
          (goto-char (match-end 0))
          (setq level (+ (problog-find-unmatched-paren) problog-paren-indent))

          ;; Remove old white space
          (let ((start (point)))
            (skip-chars-forward " \t")
            (delete-region start (point)))
          (indent-to level)
          (skip-chars-forward " \t"))
        ))
    (when (save-excursion
            (backward-char 2)
            (looking-at "\\s ;\\|\\s (\\|->")) ; (looking-at "\\s \\((\\|;\\)"))
      (skip-chars-forward " \t"))
    ))

;;;; Comment filling

(defun problog-comment-limits ()
  "Return the current comment limits plus the comment type (block or line).
The comment limits are the range of a block comment or the range that
contains all adjacent line comments (i.e. all comments that starts in
the same column with no empty lines or non-whitespace characters
between them)."
  (let ((here (point))
        lit-limits-b lit-limits-e lit-type beg end
        )
    (save-restriction
      ;; Widen to catch comment limits correctly.
      (widen)
      (setq end (line-end-position)
            beg (line-beginning-position))
      (save-excursion
        (beginning-of-line)
        (setq lit-type (if (search-forward-regexp "%" end t) 'line 'block))
                        ;    (setq lit-type 'line)
                        ;(if (search-forward-regexp "^[ \t]*%" end t)
                        ;    (setq lit-type 'line)
                        ;  (if (not (search-forward-regexp "%" end t))
                        ;      (setq lit-type 'block)
                        ;    (if (not (= (forward-line 1) 0))
                        ;        (setq lit-type 'block)
                        ;      (setq done t
                        ;            ret (problog-comment-limits)))
                        ;    ))
        (if (eq lit-type 'block)
            (progn
              (goto-char here)
              (when (looking-at "/\\*") (forward-char 2))
              (when (and (looking-at "\\*") (> (point) (point-min))
                         (forward-char -1) (looking-at "/"))
                (forward-char 1))
              (when (save-excursion (search-backward "/*" nil t))
                (list (save-excursion (search-backward "/*") (point))
                      (or (search-forward "*/" nil t) (point-max)) lit-type)))
          ;; line comment
          (setq lit-limits-b (- (point) 1)
                lit-limits-e end)
          (condition-case nil
              (if (progn (goto-char lit-limits-b)
                         (looking-at "%"))
                  (let ((col (current-column)) done)
                    (setq beg (point)
                          end lit-limits-e)
                    ;; Always at the beginning of the comment
                    ;; Go backward now
                    (beginning-of-line)
                    (while (and (zerop (setq done (forward-line -1)))
                                (search-forward-regexp "^[ \t]*%"
                                                       (line-end-position) t)
                                (= (+ 1 col) (current-column)))
                      (setq beg (- (point) 1)))
                    (when (= done 0)
                      (forward-line 1))
                    ;; We may have a line with code above...
                    (when (and (zerop (setq done (forward-line -1)))
                               (search-forward "%" (line-end-position) t)
                               (= (+ 1 col) (current-column)))
                      (setq beg (- (point) 1)))
                    (when (= done 0)
                      (forward-line 1))
                    ;; Go forward
                    (goto-char lit-limits-b)
                    (beginning-of-line)
                    (while (and (zerop (forward-line 1))
                                (search-forward-regexp "^[ \t]*%"
                                                       (line-end-position) t)
                                (= (+ 1 col) (current-column)))
                      (setq end (line-end-position)))
                    (list beg end lit-type))
                (list lit-limits-b lit-limits-e lit-type)
                )
            (error (list lit-limits-b lit-limits-e lit-type))))
        ))))

(defun problog-guess-fill-prefix ()
  ;; fill 'txt entities?
  (when (save-excursion
          (end-of-line)
          (nth 4 (syntax-ppss)))
    (let* ((bounds (problog-comment-limits))
           (cbeg (car bounds))
           (type (nth 2 bounds))
           beg end)
      (save-excursion
        (end-of-line)
        (setq end (point))
        (beginning-of-line)
        (setq beg (point))
        (if (and (eq type 'line)
                 (> cbeg beg)
                 (save-excursion (not (search-forward-regexp "^[ \t]*%"
                                                             cbeg t))))
            (progn
              (goto-char cbeg)
              (search-forward-regexp "%+[ \t]*" end t)
              (problog-replace-in-string (buffer-substring beg (point))
                                        "[^ \t%]" " "))
          ;(goto-char beg)
          (if (search-forward-regexp "^[ \t]*\\(%+\\|\\*+\\|/\\*+\\)[ \t]*"
                                     end t)
              (problog-replace-in-string (buffer-substring beg (point)) "/" " ")
            (beginning-of-line)
            (when (search-forward-regexp "^[ \t]+" end t)
              (buffer-substring beg (point)))))))))

(defun problog-fill-paragraph ()
  "Fill paragraph comment at or after point."
  (interactive)
  (let* ((bounds (problog-comment-limits))
         (type (nth 2 bounds)))
    (if (eq type 'line)
        (let ((fill-prefix (problog-guess-fill-prefix)))
          (fill-paragraph nil))
      (save-excursion
        (save-restriction
          ;; exclude surrounding lines that delimit a multiline comment
          ;; and don't contain alphabetic characters, like "/*******",
          ;; "- - - */" etc.
          (save-excursion
            (backward-paragraph)
            (unless (bobp) (forward-line))
            (if (string-match "^/\\*[^a-zA-Z]*$" (thing-at-point 'line))
                (narrow-to-region (point-at-eol) (point-max))))
          (save-excursion
            (forward-paragraph)
            (forward-line -1)
            (if (string-match "^[^a-zA-Z]*\\*/$" (thing-at-point 'line))
                (narrow-to-region (point-min) (point-at-bol))))
          (let ((fill-prefix (problog-guess-fill-prefix)))
            (fill-paragraph nil))))
      )))

(defun problog-do-auto-fill ()
  "Carry out Auto Fill for problog mode.
In effect it sets the `fill-prefix' when inside comments and then calls
`do-auto-fill'."
  (let ((fill-prefix (problog-guess-fill-prefix)))
    (do-auto-fill)
    ))

(defalias 'problog-replace-in-string
  (if (fboundp 'replace-in-string)
      #'replace-in-string
    (lambda (str regexp newtext &optional literal)
      (replace-regexp-in-string regexp newtext str nil literal))))

;;-------------------------------------------------------------------
;; Online help
;;-------------------------------------------------------------------

(defvar problog-help-function
  '((mercury nil)
    (eclipse problog-help-online)
    ;; (sicstus problog-help-info)
    (sicstus problog-find-documentation)
    (swi problog-help-online)
    (t problog-help-online))
  "Alist for the name of the function for finding help on a predicate.")
(put 'problog-help-function 'risky-local-variable t)

(defun problog-help-on-predicate ()
  "Invoke online help on the atom under cursor."
  (interactive)

  (cond
   ;; Redirect help for SICStus to `problog-find-documentation'.
   ((eq problog-help-function-i 'problog-find-documentation)
    (problog-find-documentation))

   ;; Otherwise, ask for the predicate name and then call the function
   ;; in problog-help-function-i
   (t
    (let* ((word (problog-atom-under-point))
           (predicate (read-string
                       (format "Help on predicate%s: "
                               (if word
                                   (concat " (default " word ")")
                                 ""))
                       nil nil word))
           ;;point
           )
      (if problog-help-function-i
          (funcall problog-help-function-i predicate)
        (error "Sorry, no help method defined for this problog system."))))
   ))


(autoload 'Info-goto-node "info" nil t)
(declare-function Info-follow-nearest-node "info" (&optional FORK))

(defun problog-help-info (predicate)
  (let ((buffer (current-buffer))
        oldp
        (str (concat "^\\* " (regexp-quote predicate) " */")))
    (pop-to-buffer nil)
    (Info-goto-node problog-info-predicate-index)
    (if (not (re-search-forward str nil t))
        (error "Help on predicate `%s' not found." predicate))

    (setq oldp (point))
    (if (re-search-forward str nil t)
        ;; Multiple matches, ask user
        (let ((max 2)
              n)
          ;; Count matches
          (while (re-search-forward str nil t)
            (setq max (1+ max)))

          (goto-char oldp)
          (re-search-backward "[^ /]" nil t)
          (recenter 0)
          (setq n (read-string  ;; was read-input, which is obsolete
                   (format "Several matches, choose (1-%d): " max) "1"))
          (forward-line (- (string-to-number n) 1)))
      ;; Single match
      (re-search-backward "[^ /]" nil t))

    ;; (Info-follow-nearest-node (point))
    (problog-Info-follow-nearest-node)
    (re-search-forward (concat "^`" (regexp-quote predicate)) nil t)
    (beginning-of-line)
    (recenter 0)
    (pop-to-buffer buffer)))

(defun problog-Info-follow-nearest-node ()
  (if (featurep 'xemacs)
      (Info-follow-nearest-node (point))
    (Info-follow-nearest-node)))

(defun problog-help-online (predicate)
  (problog-ensure-process)
  (process-send-string "problog" (concat "help(" predicate ").\n"))
  (display-buffer "*problog*"))

(defun problog-help-apropos (string)
  "Find problog apropos on given STRING.
This function is only available when `problog-system' is set to `swi'."
  (interactive "sApropos: ")
  (cond
   ((eq problog-system 'swi)
    (problog-ensure-process)
    (process-send-string "problog" (concat "apropos(" string ").\n"))
    (display-buffer "*problog*"))
   (t
    (error "Sorry, no problog apropos available for this problog system."))))

(defun problog-atom-under-point ()
  "Return the atom under or left to the point."
  (save-excursion
    (let ((nonatom_chars "[](){},. \t\n")
          start)
      (skip-chars-forward (concat "^" nonatom_chars))
      (skip-chars-backward nonatom_chars)
      (skip-chars-backward (concat "^" nonatom_chars))
      (setq start (point))
      (skip-chars-forward (concat "^" nonatom_chars))
      (buffer-substring-no-properties start (point))
      )))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Help function with completion
;; Stolen from Per Mildner's SICStus debugger mode and modified

(defun problog-find-documentation ()
  "Go to the Info node for a predicate in the SICStus Info manual."
  (interactive)
  (let ((pred (problog-read-predicate)))
    (problog-goto-predicate-info pred)))

(defvar problog-info-alist nil
  "Alist with all builtin predicates.
Only for internal use by `problog-find-documentation'")

;; Very similar to problog-help-info except that that function cannot
;; cope with arity and that it asks the user if there are several
;; functors with different arity. This function also uses
;; problog-info-alist for finding the info node, rather than parsing
;; the predicate index.
(defun problog-goto-predicate-info (predicate)
  "Go to the info page for PREDICATE, which is a PredSpec."
  (interactive)
  (string-match "\\(.*\\)/\\([0-9]+\\).*$" predicate)
  (let ((buffer (current-buffer))
        (name (match-string 1 predicate))
        (arity (string-to-number (match-string 2 predicate)))
        ;oldp
        ;(str (regexp-quote predicate))
        )
    (pop-to-buffer nil)

    (Info-goto-node
     problog-info-predicate-index) ;; We must be in the SICStus pages
    (Info-goto-node (car (cdr (assoc predicate problog-info-alist))))

    (problog-find-term (regexp-quote name) arity "^`")

    (recenter 0)
    (pop-to-buffer buffer))
)

(defun problog-read-predicate ()
  "Read a PredSpec from the user.
Returned value is a string \"FUNCTOR/ARITY\".
Interaction supports completion."
  (let ((default (problog-atom-under-point)))
    ;; If the predicate index is not yet built, do it now
    (if (not problog-info-alist)
        (problog-build-info-alist))
    ;; Test if the default string could be the base for completion.
    ;; Discard it if not.
    (if (eq (try-completion default problog-info-alist) nil)
        (setq default nil))
    ;; Read the PredSpec from the user
    (completing-read
     (if (zerop (length default))
         "Help on predicate: "
       (concat "Help on predicate (default " default "): "))
     problog-info-alist nil t nil nil default)))

(defun problog-build-info-alist (&optional verbose)
  "Build an alist of all builtins and library predicates.
Each element is of the form (\"NAME/ARITY\" . (INFO-NODE1 INFO-NODE2 ...)).
Typically there is just one Info node associated with each name
If an optional argument VERBOSE is non-nil, print messages at the beginning
and end of list building."
  (if verbose
      (message "Building info alist..."))
  (setq problog-info-alist
        (let ((l ())
              (last-entry (cons "" ())))
          (save-excursion
            (save-window-excursion
              ;; select any window but the minibuffer (as we cannot switch
              ;; buffers in minibuffer window.
              ;; I am not sure this is the right/best way
              (if (active-minibuffer-window)  ; nil if none active
                  (select-window (next-window)))
              ;; Do this after going away from minibuffer window
              (save-window-excursion
                (info))
              (Info-goto-node problog-info-predicate-index)
              (goto-char (point-min))
              (while (re-search-forward
                      "^\\* \\(.+\\)/\\([0-9]+\\)\\([^\n:*]*\\):" nil t)
                (let* ((name (match-string 1))
                       (arity (string-to-number (match-string 2)))
                       (comment (match-string 3))
                       (fa (format "%s/%d%s" name arity comment))
                       info-node)
                  (beginning-of-line)
                  ;; Extract the info node name
                  (setq info-node (progn
                                    (re-search-forward ":[ \t]*\\([^:]+\\).$")
                                    (match-string 1)
                                   ))
                  ;; ###### Easier? (from Milan version 0.1.28)
                  ;; (setq info-node (Info-extract-menu-node-name))
                  (if (equal fa (car last-entry))
                      (setcdr last-entry (cons info-node (cdr last-entry)))
                    (setq last-entry (cons fa (list info-node))
                          l (cons last-entry l)))))
              (nreverse l)
              ))))
  (if verbose
      (message "Building info alist... done.")))


;;-------------------------------------------------------------------
;; Miscellaneous functions
;;-------------------------------------------------------------------

;; For Windows. Change backslash to slash. SICStus handles either
;; path separator but backslash must be doubled, therefore use slash.
(defun problog-bsts (string)
  "Change backslashes to slashes in STRING."
  (let ((str1 (copy-sequence string))
        (len (length string))
        (i 0))
    (while (< i len)
      (if (char-equal (aref str1 i) ?\\)
          (aset str1 i ?/))
      (setq i (1+ i)))
    str1))

;;(defun problog-temporary-file ()
;;  "Make temporary file name for compilation."
;;  (make-temp-name
;;   (concat
;;    (or
;;     (getenv "TMPDIR")
;;     (getenv "TEMP")
;;     (getenv "TMP")
;;     (getenv "SYSTEMP")
;;     "/tmp")
;;    "/prolcomp")))
;;(setq problog-temp-filename (problog-bsts (problog-temporary-file)))

(defun problog-temporary-file ()
  "Make temporary file name for compilation."
  (if problog-temporary-file-name
      ;; We already have a file, erase content and continue
      (progn
        (write-region "" nil problog-temporary-file-name nil 'silent)
        problog-temporary-file-name)
    ;; Actually create the file and set `problog-temporary-file-name'
    ;; accordingly.
    (setq problog-temporary-file-name
          (make-temp-file "prolcomp" nil ".pl"))))

(defun problog-goto-problog-process-buffer ()
  "Switch to the problog process buffer and go to its end."
  (switch-to-buffer-other-window "*problog*")
  (goto-char (point-max))
)

(declare-function pltrace-on "ext:pltrace" ())

(defun problog-enable-sicstus-sd ()
  "Enable the source level debugging facilities of SICStus 3.7 and later."
  (interactive)
  (require 'pltrace)  ; Load the SICStus debugger code
  ;; Turn on the source level debugging by default
  (add-hook 'problog-inferior-mode-hook 'pltrace-on)
  (if (not problog-use-sicstus-sd)
      (progn
        ;; If there is a *problog* buffer, then call pltrace-on
        (if (get-buffer "*problog*")
            (pltrace-on))
        (setq problog-use-sicstus-sd t)
        )))

(declare-function pltrace-off "ext:pltrace" (&optional remove-process-filter))

(defun problog-disable-sicstus-sd ()
  "Disable the source level debugging facilities of SICStus 3.7 and later."
  (interactive)
  (require 'pltrace)
  (setq problog-use-sicstus-sd nil)
  ;; Remove the hook
  (remove-hook 'problog-inferior-mode-hook 'pltrace-on)
  ;; If there is a *problog* buffer, then call pltrace-off
  (if (get-buffer "*problog*")
      (pltrace-off)))

(defun problog-toggle-sicstus-sd ()
  ;; FIXME: Use define-minor-mode.
  "Toggle the source level debugging facilities of SICStus 3.7 and later."
  (interactive)
  (if problog-use-sicstus-sd
      (problog-disable-sicstus-sd)
    (problog-enable-sicstus-sd)))

(defun problog-debug-on (&optional arg)
  "Enable debugging.
When called with prefix argument ARG, disable debugging instead."
  (interactive "P")
  (if arg
      (problog-debug-off)
    (problog-process-insert-string (get-process "problog")
                                  problog-debug-on-string)
    (process-send-string "problog" problog-debug-on-string)))

(defun problog-debug-off ()
  "Disable debugging."
  (interactive)
  (problog-process-insert-string (get-process "problog")
                                problog-debug-off-string)
  (process-send-string "problog" problog-debug-off-string))

(defun problog-trace-on (&optional arg)
  "Enable tracing.
When called with prefix argument ARG, disable tracing instead."
  (interactive "P")
  (if arg
      (problog-trace-off)
    (problog-process-insert-string (get-process "problog")
                                  problog-trace-on-string)
    (process-send-string "problog" problog-trace-on-string)))

(defun problog-trace-off ()
  "Disable tracing."
  (interactive)
  (problog-process-insert-string (get-process "problog")
                                problog-trace-off-string)
  (process-send-string "problog" problog-trace-off-string))

(defun problog-zip-on (&optional arg)
  "Enable zipping (for SICStus 3.7 and later).
When called with prefix argument ARG, disable zipping instead."
  (interactive "P")
  (if (not (and (eq problog-system 'sicstus)
                (problog-atleast-version '(3 . 7))))
      (error "Only works for SICStus 3.7 and later"))
  (if arg
      (problog-zip-off)
    (problog-process-insert-string (get-process "problog")
                                  problog-zip-on-string)
    (process-send-string "problog" problog-zip-on-string)))

(defun problog-zip-off ()
  "Disable zipping (for SICStus 3.7 and later)."
  (interactive)
  (problog-process-insert-string (get-process "problog")
                                problog-zip-off-string)
  (process-send-string "problog" problog-zip-off-string))

;; (defun problog-create-predicate-index ()
;;   "Create an index for all predicates in the buffer."
;;   (let ((predlist '())
;;         clauseinfo
;;         object
;;         pos
;;         )
;;     (goto-char (point-min))
;;     ;; Replace with problog-clause-start!
;;     (while (re-search-forward "^.+:-" nil t)
;;       (setq pos (match-beginning 0))
;;       (setq clauseinfo (problog-clause-info))
;;       (setq object (problog-in-object))
;;       (setq predlist (append
;;                       predlist
;;                       (list (cons
;;                              (if (and (eq problog-system 'sicstus)
;;                                       (problog-in-object))
;;                                  (format "%s::%s/%d"
;;                                          object
;;                                          (nth 0 clauseinfo)
;;                                          (nth 1 clauseinfo))
;;                                (format "%s/%d"
;;                                        (nth 0 clauseinfo)
;;                                        (nth 1 clauseinfo)))
;;                              pos
;;                              ))))
;;       (problog-end-of-predicate))
;;     predlist))

(defun problog-get-predspec ()
  (save-excursion
    (let ((state (problog-clause-info))
          (object (problog-in-object)))
      (if (or (equal (nth 0 state) "")
              (nth 4 (syntax-ppss)))
          nil
        (if (and (eq problog-system 'sicstus)
                 object)
            (format "%s::%s/%d"
                    object
                    (nth 0 state)
                    (nth 1 state))
          (format "%s/%d"
                  (nth 0 state)
                  (nth 1 state)))
        ))))

;; For backward compatibility. Stolen from custom.el.
(or (fboundp 'match-string)
    ;; Introduced in Emacs 19.29.
    (defun match-string (num &optional string)
  "Return string of text matched by last search.
NUM specifies which parenthesized expression in the last regexp.
 Value is nil if NUMth pair didn't match, or there were less than NUM pairs.
Zero means the entire text matched by the whole regexp or whole string.
STRING should be given if the last search was by `string-match' on STRING."
  (if (match-beginning num)
      (if string
          (substring string (match-beginning num) (match-end num))
        (buffer-substring (match-beginning num) (match-end num))))))

(defun problog-pred-start ()
  "Return the starting point of the first clause of the current predicate."
  ;; FIXME: Use SMIE.
  (save-excursion
    (goto-char (problog-clause-start))
    ;; Find first clause, unless it was a directive
    (if (and (not (looking-at "[:?]-"))
             (not (looking-at "[ \t]*[%/]"))  ; Comment

             )
        (let* ((pinfo (problog-clause-info))
               (predname (nth 0 pinfo))
               (arity (nth 1 pinfo))
               (op (point)))
          (while (and (re-search-backward
                       (format "^%s\\([(\\.]\\| *%s\\)"
                               predname problog-head-delimiter) nil t)
                      (= arity (nth 1 (problog-clause-info)))
                      )
            (setq op (point)))
          (if (eq problog-system 'mercury)
              ;; Skip to the beginning of declarations of the predicate
              (progn
                (goto-char (problog-beginning-of-clause))
                (while (and (not (eq (point) op))
                            (looking-at
                             (format ":-[ \t]*\\(pred\\|mode\\)[ \t]+%s"
                                     predname)))
                  (setq op (point))
                  (goto-char (problog-beginning-of-clause)))))
          op)
      (point))))

(defun problog-pred-end ()
  "Return the position at the end of the last clause of the current predicate."
  ;; FIXME: Use SMIE.
  (save-excursion
    (goto-char (problog-clause-end))     ; If we are before the first predicate.
    (goto-char (problog-clause-start))
    (let* ((pinfo (problog-clause-info))
          (predname (nth 0 pinfo))
          (arity (nth 1 pinfo))
          oldp
          (notdone t)
          (op (point)))
      (if (looking-at "[:?]-")
          ;; This was a directive
          (progn
            (if (and (eq problog-system 'mercury)
                     (looking-at
                      (format ":-[ \t]*\\(pred\\|mode\\)[ \t]+\\(%s+\\)"
                              problog-atom-regexp)))
                ;; Skip predicate declarations
                (progn
                  (setq predname (buffer-substring-no-properties
                                  (match-beginning 2) (match-end 2)))
                  (while (re-search-forward
                          (format
                           "\n*\\(:-[ \t]*\\(pred\\|mode\\)[ \t]+\\)?%s[( \t]"
                           predname)
                          nil t))))
            (goto-char (problog-clause-end))
            (setq op (point)))
        ;; It was not a directive, find the last clause
        (while (and notdone
                    (re-search-forward
                     (format "^%s\\([(\\.]\\| *%s\\)"
                             predname problog-head-delimiter) nil t)
                    (= arity (nth 1 (problog-clause-info))))
          (setq oldp (point))
          (setq op (problog-clause-end))
          (if (>= oldp op)
              ;; End of clause not found.
              (setq notdone nil)
            ;; Continue while loop
            (goto-char op))))
      op)))

(defun problog-clause-start (&optional not-allow-methods)
  "Return the position at the start of the head of the current clause.
If NOTALLOWMETHODS is non-nil then do not match on methods in
objects (relevant only if `problog-system' is set to `sicstus')."
  (save-excursion
    (let ((notdone t)
          (retval (point-min)))
      (end-of-line)

      ;; SICStus object?
      (if (and (not not-allow-methods)
               (eq problog-system 'sicstus)
               (problog-in-object))
          (while (and
                  notdone
                  ;; Search for a head or a fact
                  (re-search-backward
                   ;; If in object, then find method start.
                   ;; "^[ \t]+[a-z$].*\\(:-\\|&\\|:: {\\|,\\)"
                   "^[ \t]+[a-z$].*\\(:-\\|&\\|:: {\\)" ; The comma causes
                                        ; problems since we cannot assume
                                        ; that the line starts at column 0,
                                        ; thus we don't know if the line
                                        ; is a head or a subgoal
                   (point-min) t))
            (if (>= (problog-paren-balance) 0) ; To no match on "   a) :-"
                ;; Start of method found
                (progn
                  (setq retval (point))
                  (setq notdone nil)))
            )                                ; End of while

        ;; Not in object
        (while (and
                notdone
                ;; Search for a text at beginning of a line
                ;; ######
                ;; (re-search-backward "^[a-z$']" nil t))
                (let ((case-fold-search nil))
                  (re-search-backward "^\\([[:lower:]$']\\|[:?]-\\)"
                                      nil t)))
          (let ((bal (problog-paren-balance)))
            (cond
             ((> bal 0)
              ;; Start of clause found
              (progn
                (setq retval (point))
                (setq notdone nil)))
             ((and (= bal 0)
                   (looking-at
                    (format ".*\\(\\.\\|%s\\|!,\\)[ \t]*\\(%%.*\\|\\)$"
                            problog-head-delimiter)))
              ;; Start of clause found if the line ends with a '.' or
              ;; a problog-head-delimiter
              (progn
                (setq retval (point))
                (setq notdone nil))
              )
             (t nil) ; Do nothing
             ))))

        retval)))

(defun problog-clause-end (&optional not-allow-methods)
  "Return the position at the end of the current clause.
If NOTALLOWMETHODS is non-nil then do not match on methods in
objects (relevant only if `problog-system' is set to `sicstus')."
  (save-excursion
    (beginning-of-line) ; Necessary since we use "^...." for the search.
    (if (re-search-forward
         (if (and (not not-allow-methods)
                  (eq problog-system 'sicstus)
                  (problog-in-object))
             (format
              "^\\(%s\\|%s\\|[^\n'\"%%]\\)*&[ \t]*\\(\\|%%.*\\)$\\|[ \t]*}"
              problog-quoted-atom-regexp problog-string-regexp)
           (format
            "^\\(%s\\|%s\\|[^\n'\"%%]\\)*\\.[ \t]*\\(\\|%%.*\\)$"
            problog-quoted-atom-regexp problog-string-regexp))
         nil t)
        (if (and (nth 8 (syntax-ppss))
                 (not (eobp)))
            (progn
              (forward-char)
              (problog-clause-end))
          (point))
      (point))))

(defun problog-clause-info ()
  "Return a (name arity) list for the current clause."
  (save-excursion
    (goto-char (problog-clause-start))
    (let* ((op (point))
           (predname
            (if (looking-at problog-atom-char-regexp)
                (progn
                  (skip-chars-forward "^ (\\.")
                  (buffer-substring op (point)))
              ""))
           (arity 0))
      ;; Retrieve the arity.
      (if (looking-at problog-left-paren)
          (let ((endp (save-excursion
                        (forward-list) (point))))
            (setq arity 1)
            (forward-char 1)            ; Skip the opening paren.
            (while (progn
                     (skip-chars-forward "^[({,'\"")
                     (< (point) endp))
              (if (looking-at ",")
                  (progn
                    (setq arity (1+ arity))
                    (forward-char 1)    ; Skip the comma.
                    )
                ;; We found a string, list or something else we want
                ;; to skip over.
                (forward-sexp 1))
              )))
      (list predname arity))))

(defun problog-in-object ()
  "Return object name if the point is inside a SICStus object definition."
  ;; Return object name if the last line that starts with a character
  ;; that is neither white space nor a comment start
  (save-excursion
    (if (save-excursion
          (beginning-of-line)
          (looking-at "\\([^\n ]+\\)[ \t]*::[ \t]*{"))
        ;; We were in the head of the object
        (match-string 1)
      ;; We were not in the head
      (if (and (re-search-backward "^[a-z$'}]" nil t)
               (looking-at "\\([^\n ]+\\)[ \t]*::[ \t]*{"))
          (match-string 1)
        nil))))

(defun problog-beginning-of-clause ()
  "Move to the beginning of current clause.
If already at the beginning of clause, move to previous clause."
  (interactive)
  (let ((point (point))
        (new-point (problog-clause-start)))
    (if (and (>= new-point point)
             (> point 1))
        (progn
          (goto-char (1- point))
          (goto-char (problog-clause-start)))
      (goto-char new-point)
      (skip-chars-forward " \t"))))

;; (defun problog-previous-clause ()
;;   "Move to the beginning of the previous clause."
;;   (interactive)
;;   (forward-char -1)
;;   (problog-beginning-of-clause))

(defun problog-end-of-clause ()
  "Move to the end of clause.
If already at the end of clause, move to next clause."
  (interactive)
  (let ((point (point))
        (new-point (problog-clause-end)))
    (if (and (<= new-point point)
             (not (eq new-point (point-max))))
        (progn
          (goto-char (1+ point))
          (goto-char (problog-clause-end)))
      (goto-char new-point))))

;; (defun problog-next-clause ()
;;   "Move to the beginning of the next clause."
;;   (interactive)
;;   (problog-end-of-clause)
;;   (forward-char)
;;   (problog-end-of-clause)
;;   (problog-beginning-of-clause))

(defun problog-beginning-of-predicate ()
  "Go to the nearest beginning of predicate before current point.
Return the final point or nil if no such a beginning was found."
  ;; FIXME: Hook into beginning-of-defun.
  (interactive)
  (let ((op (point))
        (pos (problog-pred-start)))
    (if pos
        (if (= op pos)
            (if (not (bobp))
                (progn
                  (goto-char pos)
                  (backward-char 1)
                  (setq pos (problog-pred-start))
                  (if pos
                      (progn
                        (goto-char pos)
                        (point)))))
          (goto-char pos)
          (point)))))

(defun problog-end-of-predicate ()
  "Go to the end of the current predicate."
  ;; FIXME: Hook into end-of-defun.
  (interactive)
  (let ((op (point)))
    (goto-char (problog-pred-end))
    (if (= op (point))
        (progn
          (forward-line 1)
          (problog-end-of-predicate)))))

(defun problog-insert-predspec ()
  "Insert the predspec for the current predicate."
  (interactive)
  (let* ((pinfo (problog-clause-info))
         (predname (nth 0 pinfo))
         (arity (nth 1 pinfo)))
    (insert (format "%s/%d" predname arity))))

(defun problog-view-predspec ()
  "Insert the predspec for the current predicate."
  (interactive)
  (let* ((pinfo (problog-clause-info))
         (predname (nth 0 pinfo))
         (arity (nth 1 pinfo)))
    (message "%s/%d" predname arity)))

(defun problog-insert-predicate-template ()
  "Insert the template for the current clause."
  (interactive)
  (let* ((n 1)
         oldp
         (pinfo (problog-clause-info))
         (predname (nth 0 pinfo))
         (arity (nth 1 pinfo)))
    (insert predname)
    (if (> arity 0)
        (progn
          (insert "(")
 	  (when problog-electric-dot-full-predicate-template
 	    (setq oldp (point))
 	    (while (< n arity)
 	      (insert ",")
 	      (setq n (1+ n)))
 	    (insert ")")
 	    (goto-char oldp))
          ))
  ))

(defun problog-insert-next-clause ()
  "Insert newline and the name of the current clause."
  (interactive)
  (insert "\n")
  (problog-insert-predicate-template))

(defun problog-insert-module-modeline ()
  "Insert a modeline for module specification.
This line should be first in the buffer.
The module name should be written manually just before the semi-colon."
  (interactive)
  (insert "%%% -*- Module: ; -*-\n")
  (backward-char 6))

(defalias 'problog-uncomment-region
  (if (fboundp 'uncomment-region) #'uncomment-region
    (lambda (beg end)
      "Uncomment the region between BEG and END."
      (interactive "r")
      (comment-region beg end -1))))

(defun problog-indent-predicate ()
  "Indent the current predicate."
  (interactive)
  (indent-region (problog-pred-start) (problog-pred-end) nil))

(defun problog-indent-buffer ()
  "Indent the entire buffer."
  (interactive)
  (indent-region (point-min) (point-max) nil))

(defun problog-mark-clause ()
  "Put mark at the end of this clause and move point to the beginning."
  (interactive)
  (let ((pos (point)))
    (goto-char (problog-clause-end))
    (forward-line 1)
    (beginning-of-line)
    (set-mark (point))
    (goto-char pos)
    (goto-char (problog-clause-start))))

(defun problog-mark-predicate ()
  "Put mark at the end of this predicate and move point to the beginning."
  (interactive)
  (goto-char (problog-pred-end))
  (let ((pos (point)))
    (forward-line 1)
    (beginning-of-line)
    (set-mark (point))
    (goto-char pos)
    (goto-char (problog-pred-start))))

(defun problog-electric--colon ()
  "If `problog-electric-colon-flag' is non-nil, insert the electric `:' construct.
That is, insert space (if appropriate), `:-' and newline if colon is pressed
at the end of a line that starts in the first column (i.e., clause heads)."
  (when (and problog-electric-colon-flag
             (eq (char-before) ?:)
             (not current-prefix-arg)
             (eolp)
             (not (memq (char-after (line-beginning-position))
                        '(?\s ?\t ?\%))))
    (unless (memq (char-before (1- (point))) '(?\s ?\t))
      (save-excursion (forward-char -1) (insert " ")))
    (insert "-\n")
    (indent-according-to-mode)))

(defun problog-electric--dash ()
  "If `problog-electric-dash-flag' is non-nil, insert the electric `-' construct.
that is, insert space (if appropriate), `-->' and newline if dash is pressed
at the end of a line that starts in the first column (i.e., DCG heads)."
  (when (and problog-electric-dash-flag
             (eq (char-before) ?-)
             (not current-prefix-arg)
             (eolp)
             (not (memq (char-after (line-beginning-position))
                        '(?\s ?\t ?\%))))
    (unless (memq (char-before (1- (point))) '(?\s ?\t))
      (save-excursion (forward-char -1) (insert " ")))
    (insert "->\n")
    (indent-according-to-mode)))

(defun problog-electric--dot ()
  "Make dot electric, if `problog-electric-dot-flag' is non-nil.
When invoked at the end of nonempty line, insert dot and newline.
When invoked at the end of an empty line, insert a recursive call to
the current predicate.
When invoked at the beginning of line, insert a head of a new clause
of the current predicate."
  ;; Check for situations when the electricity should not be active
  (if (or (not problog-electric-dot-flag)
          (not (eq (char-before) ?\.))
          current-prefix-arg
          (nth 8 (syntax-ppss))
          ;; Do not be electric in a floating point number or an operator
          (not
           (save-excursion
             (forward-char -1)
             (skip-chars-backward " \t")
             (let ((num (> (skip-chars-backward "0-9") 0)))
               (or (bolp)
                   (memq (char-syntax (char-before))
                         (if num '(?w ?_) '(?\) ?w ?_)))))))
          ;; Do not be electric if inside a parenthesis pair.
          (not (= (car (syntax-ppss))
                  0))
          )
      nil ;;Not electric.
    (cond
     ;; Beginning of line
     ((save-excursion (forward-char -1) (bolp))
      (delete-region (1- (point)) (point)) ;Delete the dot that called us.
      (problog-insert-predicate-template))
     ;; At an empty line with at least one whitespace
     ((save-excursion
        (beginning-of-line)
        (looking-at "[ \t]+\\.$"))
      (delete-region (1- (point)) (point)) ;Delete the dot that called us.
      (problog-insert-predicate-template)
      (when problog-electric-dot-full-predicate-template
 	(save-excursion
 	  (end-of-line)
 	  (insert ".\n"))))
     ;; Default
     (t
      (insert "\n"))
     )))

(defun problog-electric--underscore ()
  "Replace variable with an underscore.
If `problog-electric-underscore-flag' is non-nil and the point is
on a variable then replace the variable with underscore and skip
the following comma and whitespace, if any."
  (when problog-electric-underscore-flag
    (let ((case-fold-search nil))
      (when (and (not (nth 8 (syntax-ppss)))
                 (eq (char-before) ?_)
                 (save-excursion
                   (skip-chars-backward "[:alpha:]_")
                   (looking-at "\\_<[_[:upper:]][[:alnum:]_]*\\_>")))
        (replace-match "_")
        (skip-chars-forward ", \t\n")))))

(defun problog-post-self-insert ()
  (pcase last-command-event
    (`?_ (problog-electric--underscore))
    (`?- (problog-electric--dash))
    (`?: (problog-electric--colon))
    ((or `?\( `?\; `?>) (problog-electric--if-then-else))
    (`?. (problog-electric--dot))))

(defun problog-find-term (functor arity &optional prefix)
  "Go to the position at the start of the next occurrence of a term.
The term is specified with FUNCTOR and ARITY.  The optional argument
PREFIX is the prefix of the search regexp."
  (let* (;; If prefix is not set then use the default "\\<"
         (prefix (if (not prefix)
                     "\\<"
                   prefix))
         (regexp (concat prefix functor))
         (i 1))

    ;; Build regexp for the search if the arity is > 0
    (if (= arity 0)
        ;; Add that the functor must be at the end of a word. This
        ;; does not work if the arity is > 0 since the closing )
        ;; is not a word constituent.
        (setq regexp (concat regexp "\\>"))
      ;; Arity is > 0, add parens and commas
      (setq regexp (concat regexp "("))
      (while (< i arity)
        (setq regexp (concat regexp ".+,"))
        (setq i (1+ i)))
      (setq regexp (concat regexp ".+)")))

    ;; Search, and return position
    (if (re-search-forward regexp nil t)
        (goto-char (match-beginning 0))
      (error "Term not found"))
    ))

(defun problog-variables-to-anonymous (beg end)
  "Replace all variables within a region BEG to END by anonymous variables."
  (interactive "r")
  (save-excursion
    (let ((case-fold-search nil))
      (goto-char end)
      (while (re-search-backward "\\<[A-Z_][a-zA-Z_0-9]*\\>" beg t)
        (progn
          (replace-match "_")
          (backward-char)))
      )))

;;(defun problog-regexp-dash-continuous-chars (chars)
;;  (let ((ints (mapcar #'problog-char-to-int (string-to-list chars)))
;;        (beg 0)
;;        (end 0))
;;    (if (null ints)
;;        chars
;;      (while (and (< (+ beg 1) (length chars))
;;                  (not (or (= (+ (nth beg ints) 1) (nth (+ beg 1) ints))
;;                           (= (nth beg ints) (nth (+ beg 1) ints)))))
;;        (setq beg (+ beg 1)))
;;      (setq beg (+ beg 1)
;;            end beg)
;;      (while (and (< (+ end 1) (length chars))
;;                  (or (= (+ (nth end ints) 1) (nth (+ end 1) ints))
;;                      (= (nth end ints) (nth (+ end 1) ints))))
;;        (setq end (+ end 1)))
;;      (if (equal (substring chars end) "")
;;          (substring chars 0 beg)
;;        (concat (substring chars 0 beg) "-"
;;                (problog-regexp-dash-continuous-chars (substring chars end))))
;;    )))

;;(defun problog-condense-character-sets (regexp)
;;  "Condense adjacent characters in character sets of REGEXP."
;;  (let ((next -1))
;;    (while (setq next (string-match "\\[\\(.*?\\)\\]" regexp (1+ next)))
;;      (setq regexp (replace-match (problog-dash-letters (match-string 1 regexp))
;;				  t t regexp 1))))
;;  regexp)

;;-------------------------------------------------------------------
;; Menu stuff (both for the editing buffer and for the inferior
;; problog buffer)
;;-------------------------------------------------------------------

;; GNU Emacs ignores `easy-menu-add' so the order in which the menus
;; are defined _is_ important!

(easy-menu-define
  problog-menu-help (list problog-mode-map problog-inferior-mode-map)
  "Help menu for the problog mode."
  ;; FIXME: Does it really deserve a whole menu to itself?
  `(,(if (featurep 'xemacs) "Help"
       ;; Not sure it's worth the trouble.  --Stef
       ;; (add-to-list 'menu-bar-final-items
       ;;         (easy-menu-intern "problog-Help"))
       "problog-help")
    ["On predicate" problog-help-on-predicate problog-help-function-i]
    ["Apropos" problog-help-apropos (eq problog-system 'swi)]
    "---"
    ["Describe mode" describe-mode t]))

(easy-menu-define
  problog-edit-menu-runtime problog-mode-map
  "Runtime problog commands available from the editing buffer"
  ;; FIXME: Don't use a whole menu for just "Run Mercury".  --Stef
  `("System"
    ;; Runtime menu name.
    ,@(unless (featurep 'xemacs)
        '(:label (cond ((eq problog-system 'eclipse) "ECLiPSe")
                       ((eq problog-system 'mercury) "Mercury")
                       (t "System"))))

    ;; Consult items, NIL for mercury.
    ["Consult file" problog-consult-file
     :included (not (eq problog-system 'mercury))]
    ["Consult buffer" problog-consult-buffer
     :included (not (eq problog-system 'mercury))]
    ["Consult region" problog-consult-region :active (use-region-p)
     :included (not (eq problog-system 'mercury))]
    ["Consult predicate" problog-consult-predicate
     :included (not (eq problog-system 'mercury))]

    ;; Compile items, NIL for everything but SICSTUS.
    ,(if (featurep 'xemacs) "---"
       ["---" nil :included (eq problog-system 'sicstus)])
    ["Compile file" problog-compile-file
     :included (eq problog-system 'sicstus)]
    ["Compile buffer" problog-compile-buffer
     :included (eq problog-system 'sicstus)]
    ["Compile region" problog-compile-region :active (use-region-p)
     :included (eq problog-system 'sicstus)]
    ["Compile predicate" problog-compile-predicate
     :included (eq problog-system 'sicstus)]

    ;; Debug items, NIL for Mercury.
    ,(if (featurep 'xemacs) "---"
       ["---" nil :included (not (eq problog-system 'mercury))])
    ;; FIXME: Could we use toggle or radio buttons?  --Stef
    ["Debug" problog-debug-on :included (not (eq problog-system 'mercury))]
    ["Debug off" problog-debug-off
     ;; In SICStus, these are pairwise disjunctive,
     ;; so it's enough with a single "off"-command
     :included (not (memq problog-system '(mercury sicstus)))]
    ["Trace" problog-trace-on :included (not (eq problog-system 'mercury))]
    ["Trace off" problog-trace-off
     :included (not (memq problog-system '(mercury sicstus)))]
    ["Zip" problog-zip-on :included (and (eq problog-system 'sicstus)
                                        (problog-atleast-version '(3 . 7)))]
    ["All debug off" problog-debug-off
     :included (eq problog-system 'sicstus)]
    ["Source level debugging"
     problog-toggle-sicstus-sd
     :included (and (eq problog-system 'sicstus)
                    (problog-atleast-version '(3 . 7)))
     :style toggle
     :selected problog-use-sicstus-sd]

    "---"
    ["Run" run-problog
     :suffix (cond ((eq problog-system 'eclipse) "ECLiPSe")
                   ((eq problog-system 'mercury) "Mercury")
                   (t "problog"))]))

(easy-menu-define
  problog-edit-menu-insert-move problog-mode-map
  "Commands for problog code manipulation."
  '("problog"
    ["Comment region" comment-region (use-region-p)]
    ["Uncomment region" problog-uncomment-region (use-region-p)]
    ["Add comment/move to comment" indent-for-comment t]
    ["Convert variables in region to '_'" problog-variables-to-anonymous
     :active (use-region-p) :included (not (eq problog-system 'mercury))]
    "---"
    ["Insert predicate template" problog-insert-predicate-template t]
    ["Insert next clause head" problog-insert-next-clause t]
    ["Insert predicate spec" problog-insert-predspec t]
    ["Insert module modeline" problog-insert-module-modeline t]
    "---"
    ["Beginning of clause" problog-beginning-of-clause t]
    ["End of clause" problog-end-of-clause t]
    ["Beginning of predicate" problog-beginning-of-predicate t]
    ["End of predicate" problog-end-of-predicate t]
    "---"
    ["Indent line" indent-according-to-mode t]
    ["Indent region" indent-region (use-region-p)]
    ["Indent predicate" problog-indent-predicate t]
    ["Indent buffer" problog-indent-buffer t]
    ["Align region" align (use-region-p)]
    "---"
    ["Mark clause" problog-mark-clause t]
    ["Mark predicate" problog-mark-predicate t]
    ["Mark paragraph" mark-paragraph t]
    ))

(defun problog-menu ()
  "Add the menus for the problog editing buffers."

  (easy-menu-add problog-edit-menu-insert-move)
  (easy-menu-add problog-edit-menu-runtime)

  ;; Add predicate index menu
  (setq-local imenu-create-index-function
              'imenu-default-create-index-function)
  ;;Milan (this has problems with object methods...)  ###### Does it? (Stefan)
  (setq-local imenu-prev-index-position-function
              #'problog-beginning-of-predicate)
  (setq-local imenu-extract-index-name-function #'problog-get-predspec)

  (if (and problog-imenu-flag
           (< (count-lines (point-min) (point-max)) problog-imenu-max-lines))
      (imenu-add-to-menubar "Predicates"))

  (easy-menu-add problog-menu-help))

(easy-menu-define
  problog-inferior-menu-all problog-inferior-mode-map
  "Menu for the inferior problog buffer."
  `("problog"
    ;; Runtime menu name.
    ,@(unless (featurep 'xemacs)
        '(:label (cond ((eq problog-system 'eclipse) "ECLiPSe")
                       ((eq problog-system 'mercury) "Mercury")
                       (t "problog"))))

    ;; Debug items, NIL for Mercury.
    ,(if (featurep 'xemacs) "---"
       ["---" nil :included (not (eq problog-system 'mercury))])
    ;; FIXME: Could we use toggle or radio buttons?  --Stef
    ["Debug" problog-debug-on :included (not (eq problog-system 'mercury))]
    ["Debug off" problog-debug-off
     ;; In SICStus, these are pairwise disjunctive,
     ;; so it's enough with a single "off"-command
     :included (not (memq problog-system '(mercury sicstus)))]
    ["Trace" problog-trace-on :included (not (eq problog-system 'mercury))]
    ["Trace off" problog-trace-off
     :included (not (memq problog-system '(mercury sicstus)))]
    ["Zip" problog-zip-on :included (and (eq problog-system 'sicstus)
                                        (problog-atleast-version '(3 . 7)))]
    ["All debug off" problog-debug-off
     :included (eq problog-system 'sicstus)]
    ["Source level debugging"
     problog-toggle-sicstus-sd
     :included (and (eq problog-system 'sicstus)
                    (problog-atleast-version '(3 . 7)))
     :style toggle
     :selected problog-use-sicstus-sd]

    ;; Runtime.
    "---"
    ["Interrupt problog" comint-interrupt-subjob t]
    ["Quit problog" comint-quit-subjob t]
    ["Kill problog" comint-kill-subjob t]))


(defun problog-inferior-menu ()
  "Create the menus for the problog inferior buffer.
This menu is dynamically created because one may change systems during
the life of an Emacs session."
  (easy-menu-add problog-inferior-menu-all)
  (easy-menu-add problog-menu-help))

(defun problog-mode-version ()
  "Echo the current version of problog mode in the minibuffer."
  (interactive)
  (message "Using problog mode version %s" problog-mode-version))

(provide 'problog)

;;; problog.el ends here
