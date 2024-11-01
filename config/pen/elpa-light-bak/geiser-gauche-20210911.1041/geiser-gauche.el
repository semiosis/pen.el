;;; geiser-gauche.el --- Gauche scheme support for Geiser -*- lexical-binding:t -*-

;; Copyright (C) 2020 András Simonyi

;; Author: András Simonyi <andras.simonyi@gmail.com>
;; Maintainer: András Simonyi <andras.simonyi@gmail.com>
;; URL: https://gitlab.com/emacs-geiser/gauche
;; Keywords: languages, gauche, scheme, geiser
;; Package-Requires: ((emacs "26.1") (geiser "0.11.2"))
;; Version: 0.0.2
;; SPDX-License-Identifier: BSD-3-Clause

;; This file is not part of GNU Emacs.

;;; Commentary:

;; geiser-gauche adds Gauche Scheme support to the `geiser' package

;;; Code:

(require 'info-look)
(require 'cl-lib)
(require 'compile)

(require 'geiser-syntax)
(require 'geiser-custom)
(require 'geiser-eval)
(require 'geiser-log)
(require 'geiser-impl)
(require 'geiser)


;;; Customization

(defgroup geiser-gauche nil
  "Customization for Geiser's Gauche flavour."
  :group 'geiser)

(geiser-custom--defcustom geiser-gauche-binary "gosh"
  "Name to use to call the Gauche executable when starting a REPL."
  :type '(choice string (repeat string))
  :group 'geiser-gauche)

(geiser-custom--defcustom geiser-gauche-extra-command-line-parameters '("-i")
  "Additional parameters to supply to the Gauche binary."
  :type '(repeat string)
  :group 'geiser-gauche)

(geiser-custom--defcustom geiser-gauche-case-sensitive-p t
  "Non-nil means keyword highlighting is case-sensitive."
  :type 'boolean
  :group 'geiser-gauche)

(geiser-custom--defcustom geiser-gauche-extra-keywords nil
  "Extra keywords highlighted in Gauche scheme buffers."
  :type '(repeat string)
  :group 'geiser-gauche)

(geiser-custom--defcustom geiser-gauche-manual-lookup-nodes
    '("gauche-refe")
  "List of info nodes that, when present, are used for manual lookups"
  :type '(repeat string)
  :group 'geiser-gauche)

(geiser-custom--defcustom geiser-gauche-manual-lookup-other-window-p t
  "Non-nil means pop up the Info buffer in another window."
  :type 'boolean
  :group 'geiser-gauche)


;;; Utils

(defconst geiser-gauche--load-dir (file-name-directory load-file-name)
  "The directory from which geiser-gauche was loaded.")

(defun geiser-gauche--symbol-begin (_module)
  "Return the beginning position of the symbol at point."
  (save-excursion (skip-syntax-backward "^'-()>") (point)))


;;; Guess whether buffer is Gauche

(defconst geiser-gauche--guess-re
  (regexp-opt '("gauche" "gosh")))

(defun geiser-gauche--guess ()
  "Guess whether the current buffer edits Gauche code or REPL."
  (save-excursion
    (goto-char (point-min))
    (re-search-forward geiser-gauche--guess-re nil t)))


;;; Keywords and syntax

(defconst geiser-gauche--binding-forms
  '("and-let" "and-let1" "let1" "if-let1" "rlet1" "receive" "fluid-let" "let-values"
    "^" "^a" "^b" "^c" "^d" "^e" "^f" "^g" "^h" "^i" "^j" "^k" "^l" "^m" "^n" "^o" "^p" "^q"
    "^r" "^s" "^t" "^v" "^x" "^y" "^z" "^w" "^_" "rec"))

(defconst geiser-gauche--binding-forms*
  '("and-let*" "let*-values" ))

(defconst geiser-gauche--builtin-keywords
  '("and-let"
    "and-let1"
    "assume"
    "cut"
    "cute"
    "define-constant"
    "define-enum"
    "define-in-module"
    "define-inline"
    "define-type"
    "dotimes"
    "dolist"
    "ecase"
    "fluid-let"
    "if-let1"
    "let1"
    "let-keywords"
    "let-optionals"
    "let-optionals*"
    "let-values"
    "receive"
    "rec"
    "rlet1"
    "select-module"
    "use"
    "with-input-from-pipe"
    "^" "^a" "^b" "^c" "^d" "^e" "^f" "^g" "^h" "^i" "^j" "^k" "^l" "^m" "^n" "^o" "^p" "^q"
    "^r" "^s" "^t" "^v" "^x" "^y" "^z" "^w" "^_"
    "with-error-handler"
    "with-error-to-port"
    "with-exception-handler"
    "with-exception-handler"
    "with-input-conversion"
    "with-input-from-file"
    "with-input-from-port"
    "with-input-from-process"
    "with-input-from-string"
    "with-iterator"
    "with-lock-file"
    "with-locking-mutex"
    "with-module"
    "with-output-conversion"
    "with-output-to-file"
    "with-output-to-port"
    "with-output-to-process"
    "with-output-to-string"
    "with-port-locking"
    "with-ports"
    "with-profiler"
    "with-random-data-seed"
    "with-signal-handlers"
    "with-string-io"
    "with-time-counter"))

(defun geiser-gauche--keywords ()
  "Add geiser-specific keywords to the default ones."
  (append
   (geiser-syntax--simple-keywords geiser-gauche-extra-keywords)
   (geiser-syntax--simple-keywords geiser-gauche--builtin-keywords)))

(geiser-syntax--scheme-indent
 (case-lambda: 0)
 (let1 1))


;;; REPL

(defconst geiser-gauche--prompt-regexp "gosh\\(\\[[^(]+\\]\\)?> ")

(defconst geiser-gauche--minimum-version "0.9.6")

(defconst geiser-gauche--exit-command
  "(exit)")

(defun geiser-gauche--binary ()
  "Return the runnable Gauche binary name without path."
  (if (listp geiser-gauche-binary)
      (car geiser-gauche-binary)
    geiser-gauche-binary))

(defun geiser-gauche--parameters ()
  "Return a list with all parameters needed to start Gauche Scheme."
  `(,@geiser-gauche-extra-command-line-parameters
    "-l" ,(expand-file-name "geiser-gauche.scm" geiser-gauche--load-dir)
    ,@(and (listp geiser-gauche-binary) (cdr geiser-gauche-binary))))

(defun geiser-gauche--version (binary)
  "Return the version of a Gauche BINARY."
  (let ((v (process-lines binary "-V")))
    (if (< 1 (length v))
	;; Multiline version info is (hopefully) a sexp.
	(cadr (read (cadr v)))
      ;; One line is a free-text version description string.
      (let ((s (car v))
	    (start (string-match "version" (car v))))
	(substring s (+ start 8) (+ start 13))))))

(defun geiser-gauche--startup (_remote)
  "Initialize a Gauche REPL."
  (let ((geiser-log-verbose-p t))
    (compilation-setup t)
    (geiser-eval--send/wait "(newline)")))


;;; Evaluation

(defun geiser-gauche--geiser-procedure (proc &rest args)
  "String to send to the REPL to execute geiser PROC with ARGS."
  (cl-case proc
    ;; Autodoc and symbol-location makes use of the {{cur-module}} cookie to
    ;; pass current module information
    ((autodoc symbol-location completions)
     (format "(eval '(geiser:%s %s {{cur-module}}) (find-module 'geiser))"
	     proc (mapconcat #'identity args " ")))
    ;; Eval and compile are (module) context sensitive
    ((eval compile)
     (let ((module (cond ((string-equal "'()" (car args))
			  "'()")
			 ((and (car args))
			  (concat "'" (car args)))
			 (t
			  "#f")))
	   (form (mapconcat #'identity (cdr args) " ")))
       ;; The {{cur-module}} cookie is replaced by the current module for
       ;; commands that need it
       (replace-regexp-in-string
	"{{cur-module}}"
	(if (string= module "'#f")
	    (format "'%s" (geiser-gauche--get-module))
	  module)
	(format "(eval '(geiser:eval %s '%s) (find-module 'geiser))" module form))))
    ;; The rest of the commands are all evaluated in the geiser module
    (t
     (let ((form (mapconcat #'identity args " ")))
       (format "(eval '(geiser:%s %s) (find-module 'geiser))" proc form)))))


;;; Module handling

(defconst geiser-gauche--module-re
  "(define-module +\\([[:alnum:].-]+\\)"
  "Regex for locating the module defined in a scheme source.")

(defun geiser-gauche--get-current-repl-module ()
  "Return the current REPL module's name as a string."
  (substring
   (geiser-eval--send/result
    '(list (list (quote result) (write-to-string (current-module)))))
   9 -1))

(defun geiser-gauche--get-module (&optional module)
  "Return the current module as a symbol.
If optional MODULE is non-nil then return its normalized symbol
form."
  (cond ((null module)
         (save-excursion
           (geiser-syntax--pop-to-top)
           (if (or (re-search-backward geiser-gauche--module-re nil t)
                   (looking-at geiser-gauche--module-re)
                   (re-search-forward geiser-gauche--module-re nil t))
               (geiser-gauche--get-module (match-string-no-properties 1))
	     ;; Return the REPL module as fallback
             (geiser-gauche--get-module
	      (geiser-gauche--get-current-repl-module)))))
	((symbolp module) module)
        ((listp module) module)
        ((stringp module)
         (condition-case nil
             (car (geiser-syntax--read-from-string module))
           (error :f)))
        (t :f)))

(defun geiser-gauche--enter-command (module)
  "Return a scheme expression string to enter MODULE."
  (format "(select-module %s)" module))

(defun geiser-gauche--import-command (module)
  "Return a scheme expression string to import MODULE."
  (format "(import %s)" module))


;;; Error display

(defun geiser-gauche--display-error (_module key msg)
  "Display evaluation error information KEY and MSG."
  (when key
    (insert key)
    (save-excursion
      (goto-char (point-min))
      (re-search-forward "report-error err #f")
      (kill-whole-line 2)))
  (when msg
    (insert msg))
  (if (and msg (string-match "\\(.+\\)$" msg)) (match-string 1 msg) key))


;;; Manual lookup
;; code adapted from the Guile implementation

(defun geiser-gauche--info-spec (&optional nodes)
  "Return an info docspec list for NODES."
  (let* ((nrx "^[       ]+-+ [^:]+:[    ]*")
         (drx "\\b")
         (res (when (Info-find-file "gauche-refe" t)
                `(("(gauche-refe)Function and Syntax Index" nil ,nrx ,drx)))))
    (dolist (node (or nodes geiser-gauche-manual-lookup-nodes) res)
      (when (Info-find-file node t)
        (mapc (lambda (idx)
                (add-to-list 'res
                             (list (format "(%s)%s" node idx) nil nrx drx)))
              '("Module Index" "Class Index" "Variable Index"))))))

(info-lookup-add-help :topic 'symbol :mode 'geiser-gauche-mode
                      :ignore-case nil
                      :regexp "[^()`',\"        \n]+"
                      :doc-spec (geiser-gauche--info-spec))

(defun geiser-gauche--manual-look-up (id _mod)
  "Look up ID in the Gauche info manual."
  (let ((info-lookup-other-window-flag
         geiser-gauche-manual-lookup-other-window-p))
    (info-lookup-symbol (symbol-name id) 'geiser-gauche-mode))
  (when geiser-gauche-manual-lookup-other-window-p
    (switch-to-buffer-other-window "*info*"))
  (search-forward (format "%s" id) nil t))


;;; Implementation definition

(define-geiser-implementation gauche
  (unsupported-procedures '(callers callees generic-methods))
  (binary geiser-gauche--binary)
  (arglist geiser-gauche--parameters)
  (version-command geiser-gauche--version)
  (minimum-version geiser-gauche--minimum-version)
  (repl-startup geiser-gauche--startup)
  (prompt-regexp geiser-gauche--prompt-regexp)
  (debugger-prompt-regexp nil)
  (marshall-procedure geiser-gauche--geiser-procedure)
  (find-module geiser-gauche--get-module)
  (enter-command geiser-gauche--enter-command)
  (exit-command geiser-gauche--exit-command)
  (import-command geiser-gauche--import-command)
  (find-symbol-begin geiser-gauche--symbol-begin)
  (display-error geiser-gauche--display-error)
  (binding-forms geiser-gauche--binding-forms)
  (binding-forms* geiser-gauche--binding-forms*)
  (external-help geiser-gauche--manual-look-up)
  (check-buffer geiser-gauche--guess)
  (keywords geiser-gauche--keywords)
  (case-sensitive geiser-gauche-case-sensitive-p))

(geiser-implementation-extension 'gauche "scm")


;;; Autoloads

;;;###autoload
(geiser-activate-implementation 'gauche)

;;;###autoload
(autoload 'run-gauche "geiser-gauche" "Start a Geiser Gauche Scheme REPL." t)

;;;###autoload
(autoload 'switch-to-gauche "geiser-gauche"
  "Start a Geiser Gauche Scheme REPL, or switch to a running one." t)

(provide 'geiser-gauche)

;;; geiser-gauche.el ends here
