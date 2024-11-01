;;; geiser-chez.el --- Chez Scheme's implementation of the geiser protocols  -*- lexical-binding: t; -*-

;; Author: Peter <craven@gmx.net>
;; Maintainer: Jose A Ortega Ruiz <jao@gnu.org>
;; Keywords: languages, chez, scheme, geiser
;; Homepage: https://gitlab.com/emacs-geiser/chez
;; Package-Requires: ((emacs "26.1") (geiser "0.19"))
;; SPDX-License-Identifier: BSD-3-Clause
;; Version: 0.17

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


;;; Customization:

(defgroup geiser-chez nil
  "Customization for Geiser's Chez Scheme flavour."
  :group 'geiser)

(geiser-custom--defcustom geiser-chez-binary
    "scheme"
  "Name to use to call the Chez Scheme executable when starting a REPL."
  :type '(choice string (repeat string))
  :group 'geiser-chez)

(geiser-custom--defcustom geiser-chez-init-file "~/.chez-geiser"
  "Initialization file with user code for the Chez REPL.

Do mind that this file is local to running process, so remote process will use
init file at this location in remote host."
  :type 'string
  :group 'geiser-chez)

(geiser-custom--defcustom geiser-chez-extra-command-line-parameters '()
  "Additional parameters to supply to the Chez binary."
  :type '(repeat string)
  :group 'geiser-chez)

(geiser-custom--defcustom geiser-chez-extra-keywords '()
  "Extra keywords highlighted in Chez Scheme buffers."
  :type '(repeat string)
  :group 'geiser-chez)

(geiser-custom--defcustom geiser-chez-debug-on-exception-p nil
  "Whether to automatically enter the debugger when catching an exception"
  :type 'boolean
  :group 'geiser-chez)


;;; REPL support:

(defun geiser-chez--binary ()
  "Return path to Chez scheme binary."
  (if (listp geiser-chez-binary)
      (car geiser-chez-binary)
    geiser-chez-binary))

(defvar geiser-chez-scheme-dir
  (expand-file-name "src" (file-name-directory load-file-name))
  "Directory where the Chez scheme geiser modules are installed.")

(defun geiser-chez--parameters ()
  "Return a list with all parameters needed to start Chez Scheme.
This function uses `geiser-chez-init-file' if it exists."
  (append
   (when-let ((init-file (and (stringp geiser-chez-init-file)
                              (expand-file-name geiser-chez-init-file))))
     (if (file-exists-p
          (concat
           (file-remote-p default-directory)
           init-file))
         (list init-file)
       (geiser-log--warn
        "File %s does not exist, so it's not added to CLI args"
        init-file)))
   (let* ((local-geiser-module-file
           (expand-file-name "geiser/geiser.ss" geiser-chez-scheme-dir))
          (geiser-module-file
           (if (file-remote-p default-directory)
               ;; copy the content to remote file
               (let* ((temporary-file-directory (temporary-file-directory))
                      (temp-dir
                       (make-temp-file "geiser" t))
                      (remote-geiser-module-file
                       (concat
                        (file-name-as-directory
                         temp-dir)
                        "geiser.ss")))
                 ;; write to file
                 (with-temp-buffer
                   (insert-file-contents local-geiser-module-file)
                   (write-file remote-geiser-module-file))
                 (file-local-name
                  remote-geiser-module-file))
             ;; else, process and file are local
             local-geiser-module-file)))
     (list geiser-module-file))
   geiser-chez-extra-command-line-parameters))

(defconst geiser-chez--prompt-regexp "> ")

(defconst geiser-chez--debugger-prompt-regexp "debug> $\\|break> $\\|.+: $")


;;; Evaluation support:

(defun geiser-chez--geiser-procedure (proc &rest args)
  "Transform PROC in string for a scheme procedure using ARGS."
  (cl-case proc
    ((eval compile)
     (let ((form (mapconcat 'identity (cdr args) " "))
           (module (cond ((string-equal "'()" (car args)) "'()")
                         ((car args) (concat "'" (car args)))
                         (t "#f"))))
       (format "(geiser:eval %s '%s)" module form)))
    ((load-file compile-file)
     (format "(geiser:load-file %s)" (car args)))
    ((no-values)
     "(geiser:no-values)")
    (t
     (let ((form (mapconcat 'identity args " ")))
       (format "(geiser:%s %s)" proc form)))))

(defun geiser-chez--get-module (&optional module)
  "Find current module, or normalize MODULE."
  (cond ((null module)
         :f)
        ((listp module) module)
        ((stringp module)
         (condition-case nil
             (car (geiser-syntax--read-from-string module))
           (error :f)))
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

;; 
;; ;;; REPL startup

(defconst geiser-chez-minimum-version "9.4")

(defun geiser-chez--version (binary)
  "Use BINARY to find Chez scheme version."
  (car (process-lines binary "--version")))

(defun geiser-chez--startup (_remote)
  "Startup function."
  (let ((geiser-log-verbose-p t))
    (compilation-setup t)
    (geiser-eval--send/wait
     "(begin (import (geiser)) (write `((result ) (output . \"\"))) (newline))")))


;;; Error display:

(defun geiser-chez--enter-debugger ()
  "Tell Geiser to interact with the debugger."
  (when geiser-chez-debug-on-exception-p
    (let ((bt-cmd "\n(debug)\n")
          (repl-buffer (geiser-repl--repl/impl 'chez)))
      (compilation-forget-errors)
      (goto-char (point-max))
      (geiser-repl--prepare-send)
      (comint-send-string repl-buffer bt-cmd)
      (ignore-errors (next-error)))
    t))

(defun geiser-chez--display-error (_module key msg)
  "Display an error found during evaluation with the given KEY and message MSG."
  (when (stringp msg)
    (save-excursion (insert msg))
    (geiser-edit--buttonize-files))
  (and (not key)
       (not (zerop (length msg)))
       msg))


;;; Keywords and syntax:

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
  ;; (external-help geiser-chez--manual-look-up)
  ;; (check-buffer geiser-chez--guess)
  (keywords geiser-chez--keywords)
  ;; (case-sensitive geiser-chez-case-sensitive-p)
  )

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


(provide 'geiser-chez)
;;; geiser-chez.el ends here
