;;; geiser-chez.el --- Chez and Geiser talk to each other  -*- lexical-binding: t; -*-

;; Author: Peter <craven@gmx.net>
;; Maintainer: Jose A Ortega Ruiz <jao@gnu.org>
;; Keywords: languages, chez, scheme, geiser
;; Homepage: https://gitlab.com/emacs-geiser/chez
;; Package-Requires: ((emacs "26.1") (geiser "0.19"))
;; SPDX-License-Identifier: BSD-3-Clause
;; Package-Version: 20230707.1334
;; Package-Revision: 605a81ff7b2d

;;; Commentary:

;; This package provides support for Chez scheme in geiser.

;;; Code:

(require 'geiser)

(require 'geiser-connection)
(require 'geiser-syntax)
(require 'geiser-custom)
(require 'geiser-base)
(require 'geiser-eval)
(require 'geiser-edit)
(require 'geiser-log)
(require 'geiser-impl)
(require 'geiser-repl)

(require 'compile)
(require 'info-look)

(eval-when-compile (require 'cl-lib))

;;; Customization

(defgroup geiser-chez nil
  "Customization for Geiser's Chez Scheme flavour."
  :group 'geiser)

(geiser-custom--defcustom geiser-chez-binary
    "scheme"
  "Name to use to call the Chez Scheme executable when starting a REPL."
  :type '(choice string (repeat string)))

(geiser-custom--defcustom geiser-chez-init-file "~/.chez-geiser"
  "Initialization file with user code for the Chez REPL.

Do mind that this file is local to running process, so remote
process will use an init file at this location in the remote
host."
  :type 'string)

(geiser-custom--defcustom geiser-chez-extra-command-line-parameters '()
  "Additional parameters to supply to the Chez binary."
  :type '(repeat string))

(geiser-custom--defcustom geiser-chez-extra-keywords '()
  "Extra keywords highlighted in Chez Scheme buffers."
  :type '(repeat string))

(define-obsolete-variable-alias 'geiser-chez-debug-on-exception-p
  'geiser-chez-debug-on-exception "0.18")

(geiser-custom--defcustom geiser-chez-debug-on-exception nil
  "Whether to automatically enter the debugger when an evaluation throws."
  :type 'boolean)

(geiser-custom--defcustom geiser-chez-browse-function #'eww
  "Function used to open HTML pages for the manuals."
  :type 'function)

(geiser-custom--defcustom geiser-chez-csug-url
    "https://cisco.github.io/ChezScheme/csug9.5/"
  "Base URL for the Chez Scheme User's Guide HTML documents.

Set it to a local file URI such as
`file:///usr/share/doc/chezscheme-doc/html/' for quicker offline
access."
  :type 'string)

(geiser-custom--defcustom geiser-chez-tspl-url
    "https://scheme.com/tspl4/"
  "Base URL for the The Scheme Programming Language HTML version.

Set it to a local file URI such as
`file:///usr/share/doc/tlsp/html/' for quicker offline access."
  :type 'string)

(defconst geiser-chez-minimum-version "9.4")

;;; REPL support

(defun geiser-chez--binary ()
  "Return path to Chez scheme binary."
  (if (listp geiser-chez-binary)
      (car geiser-chez-binary)
    geiser-chez-binary))

(defvar geiser-chez-scheme-dir
  (expand-file-name "src" (file-name-directory load-file-name))
  "Directory where the Chez scheme geiser modules are installed.")

(defun geiser-chez--init-files ()
  "Possibly remote init file(s), when they exist, as a list."
  (let* ((file (and (stringp geiser-chez-init-file)
                    (expand-file-name geiser-chez-init-file)))
         (file (and file (concat (file-remote-p default-directory) file))))
    (if (and file (file-exists-p file))
        (list file)
      (geiser-log--info "Init file not readable (%s)" file)
      nil)))

(defun geiser-chez--module-file (file)
  "Copy, if needed, the given scheme file to its remote destination.
Return its local name."
  (let ((local (expand-file-name (concat "geiser/" file) geiser-chez-scheme-dir)))
    (if (file-remote-p default-directory)
        (let* ((temporary-file-directory (temporary-file-directory))
               (temp-dir (make-temp-file "geiser" t))
               (remote (concat (file-name-as-directory temp-dir) "geiser.ss")))
          (with-temp-buffer
            (insert-file-contents local)
            (write-file remote))
          (file-local-name remote))
      local)))

(defun geiser-chez--module-files ()
  "List of (possibly copied to a tramped remote) scheme files used by chez."
  (mapcar #'geiser-chez--module-file '("geiser-data.ss" "geiser.ss")))

(defun geiser-chez--parameters ()
  "Return a list with all parameters needed to start Chez Scheme."
  (append (cons "--compile-imported-libraries" (geiser-chez--init-files))
          (geiser-chez--module-files)
          geiser-chez-extra-command-line-parameters))

(defconst geiser-chez--prompt-regexp "> ")
(defconst geiser-chez--debugger-prompt-regexp "debug> $\\|break> $\\|.+: $")

(defun geiser-chez--version (binary)
  "Use BINARY to find Chez scheme version."
  (car (process-lines binary "--version")))

(defun geiser-chez--startup (_remote)
  "Startup function."
  t)

;;; Evaluation support

(defsubst geiser-chez--geiser-eval (str)
  (format "(eval '%s (environment '(geiser)))" str))

(defconst geiser-chez--ge (geiser-chez--geiser-eval "geiser:ge:eval"))
(defconst geiser-chez--ev (geiser-chez--geiser-eval "geiser:eval"))
(defconst geiser-chez--load (geiser-chez--geiser-eval "geiser:load-file"))

(defun geiser-chez--geiser-procedure (proc &rest args)
  "Transform PROC in string for a scheme procedure using ARGS."
  (cl-case proc
    ((eval compile)
     (if (listp (cadr args))
         (format "(%s '%s '%s)" geiser-chez--ge (car args) (cadr args))
       (format "(%s '%s '%s)" geiser-chez--ev (car args) (cadr args))))
    ((load-file compile-file)
     (let ((lib (geiser-chez--current-library)))
       (format "(%s %s '%s)" geiser-chez--load (car args) (or lib "#f"))))
    (t (list (format "geiser:%s" proc) (mapconcat 'identity args " ")))))

(defun geiser-chez--current-library ()
  "Find current library."
  (save-excursion
    (geiser-syntax--pop-to-top)
    (when (looking-at "(library[ \n]+\\(([^)]+)\\)")
      (geiser-chez--get-module (match-string 1)))))

(defun geiser-chez--get-module (&optional module)
  "Find current module (libraries for Chez), or normalize MODULE."
  (cond ((null module) (or (geiser-chez--current-library) :f))
        ((listp module) module)
        ((and (stringp module)
              (ignore-errors (car (geiser-syntax--read-from-string module)))))
        (t :f)))

(defun geiser-chez--symbol-begin (module)
  "Return beginning of current symbol while in MODULE."
  (if module
      (max (save-excursion (beginning-of-line) (point))
           (save-excursion (skip-syntax-backward "^(>") (1- (point))))
    (save-excursion (skip-syntax-backward "^'-()>") (point))))

(defun geiser-chez--import-command (module)
  "Return string representing a sexp importing MODULE."
  (format "(import %s)" module))

(defun geiser-chez--exit-command ()
  "Return string representing a REPL exit sexp."
  "(exit 0)")


;;; Error display and debugger

(defun geiser-chez--enter-debugger ()
  "Tell Geiser to interact with the debugger."
  (when geiser-chez-debug-on-exception
    (geiser-repl-switch  nil 'chez)
    (compilation-forget-errors)
    (geiser-repl--send "(debug)")
    t))

(defun geiser-chez--display-error (_module key msg)
  "Display an error found during evaluation with the given KEY and message MSG."
  (when (and msg (listp msg))
    (save-excursion
      (insert (car msg))
      (insert "\n")
      (dolist (loc (reverse (cdr msg)))
        (let ((file (cdr (assoc "file" loc)))
              (line (or (cdr (assoc "line" loc)) ""))
              (col (or (cdr (assoc "column" loc)) (cdr (assoc "char" loc))))
              (name (cdr (assoc "name" loc))))
          (unless (string-prefix-p geiser-chez-scheme-dir file)
            (insert "\n" file (format ":%s:" line))
            (when col (insert (format "%s:" col)))
            (when name (insert (format " (%s)" name)))))))
    (geiser-edit--buttonize-files)
    t))

;;; Keywords and syntax

(defconst geiser-chez--builtin-keywords
  '("call-with-input-file"
    "call-with-output-file"
    "define-ftype"
    "define-structure"
    "exclusive-cond"
    "extend-syntax"
    "fluid-let"
    "fluid-let-syntax"
    "meta"
    "meta-cond"
    "module"
    "rec"
    "record-case"
    "trace-case-lambda"
    "trace-define"
    "trace-define-syntax"
    "trace-do"
    "trace-lambda"
    "trace-let"
    "with"
    "with-implicit"
    "with-input-from-file"
    "with-input-from-string"
    "with-interrupts-disabled"
    "with-mutex"
    "with-output-to-file"
    "with-output-to-string"))

(defun geiser-chez--keywords ()
  "Return list of Chez-specific keywords."
  (append
   (geiser-syntax--simple-keywords geiser-chez-extra-keywords)
   (geiser-syntax--simple-keywords geiser-chez--builtin-keywords)))

(geiser-syntax--scheme-indent
 (call-with-input-file 1)
 (call-with-output-file 1)
 (define-ftype 1)
 (struct 0)
 (union 0)
 (bits 0)
 (define-structure 1)
 (exclusive-cond 0)
 (extend-syntax 1)
 (fluid-let 1)
 (fluid-let-syntax 1)
 (meta 0)
 (meta-cond 0)
 (module 1)
 (rec 1)
 (record-case 1)
 (trace-case-lambda 1)
 (trace-define 1)
 (trace-define-syntax 1)
 (trace-do 2)
 (trace-lambda 2)
 (trace-let 2)
 (with 1)
 (with-implicit 1)
 (with-input-from-file 1)
 (with-input-from-string 1)
 (with-interrupts-disabled 0)
 (with-mutex 1)
 (with-output-to-file 1)
 (with-output-to-string 0))

;;; Documentation display
(defun geiser-chez--insert-button (url label)
  (insert-text-button label
                      'button-data url
                      'action geiser-chez-browse-function))

(defun geiser-chez--display-docstring (res)
  (when-let ((labels (cdr (assoc "labels" res))))
    (insert (format "%s\n" (or (cdr (assoc "docstring" res)) "")))
    (let* ((csug (cdr (assoc 'csug labels)))
           (csug-url (and (stringp csug) (concat geiser-chez-csug-url csug)))
           (tspl (cdr (assoc 'tspl labels)))
           (tspl-url (and (stringp tspl) (concat geiser-chez-tspl-url tspl))))
      (when csug-url
        (insert "\n")
        (geiser-chez--insert-button csug-url "· Chez Manual Entry"))
      (when tspl-url
        (insert "\n")
        (geiser-chez--insert-button tspl-url "· TSPL Entry")))
    t))

;;; Implementation definition:

(define-geiser-implementation chez
  (binary geiser-chez--binary)
  (arglist geiser-chez--parameters)
  (version-command geiser-chez--version)
  (minimum-version geiser-chez-minimum-version)
  (repl-startup geiser-chez--startup)
  (prompt-regexp geiser-chez--prompt-regexp)
  (debugger-prompt-regexp geiser-chez--debugger-prompt-regexp)
  (enter-debugger geiser-chez--enter-debugger)
  (marshall-procedure geiser-chez--geiser-procedure)
  (find-module geiser-chez--get-module)
  ;; (enter-command geiser-chez--enter-command)
  (exit-command geiser-chez--exit-command)
  (import-command geiser-chez--import-command)
  (find-symbol-begin geiser-chez--symbol-begin)
  (display-error geiser-chez--display-error)
  (display-docstring geiser-chez--display-docstring)
  ;; (external-help geiser-chez--manual-look-up)
  (keywords geiser-chez--keywords)
  (nested-definitions t)
  (case-sensitive nil))

(geiser-implementation-extension 'chez "ss")

;;;###autoload
(geiser-implementation-extension 'chez "def")

;;;###autoload
(geiser-activate-implementation 'chez)

;;;###autoload
(autoload 'run-chez "geiser-chez" "Start a Geiser Chez REPL." t)

;;;###autoload
(autoload 'switch-to-chez "geiser-chez"
  "Start a Geiser Chez REPL, or switch to a running one." t)

;;; -
(provide 'geiser-chez)

;;; geiser-chez.el ends here
