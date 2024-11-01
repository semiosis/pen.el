;;; geiser-chibi.el --- Chibi Scheme's implementation of the geiser protocols  -*- lexical-binding: t; -*-

;; Author: Peter <craven@gmx.net>
;; Maintainer: Jose A Ortega Ruiz <jao@gnu.org>
;; Keywords: languages, chibi, scheme, geiser
;; Homepage: https://gitlab.com/emacs-geiser/chibi
;; Package-Requires: ((emacs "24.4") (geiser "0.18"))
;; SPDX-License-Identifier: BSD-3-Clause
;; Version: 0.17

;;; Commentary:

;; This package provides support for Chibi in geiser.


;;; Code:

(require 'geiser-connection)
(require 'geiser-syntax)
(require 'geiser-impl)
(require 'geiser-custom)
(require 'geiser-base)
(require 'geiser-eval)
(require 'geiser-edit)
(require 'geiser-log)
(require 'geiser)

(require 'compile)
(require 'info-look)

(eval-when-compile (require 'cl-lib))


;;; Customization:

(defgroup geiser-chibi nil
  "Customization for Geiser's Chibi Scheme flavour."
  :group 'geiser)

(geiser-custom--defcustom geiser-chibi-binary
    "chibi-scheme"
  "Name to use to call the Chibi Scheme executable when starting a REPL."
  :type '(choice string (repeat string))
  :group 'geiser-chibi)

(geiser-custom--defcustom geiser-chibi-extra-command-line-parameters
    '("-R" "-m" "chibi ast")
  "Additional parameters to supply to the Chibi binary."
  :type '(repeat string)
  :group 'geiser-chibi)



;;; REPL support:

(defun geiser-chibi--binary ()
  "Return path to Chibi scheme executable."
  (if (listp geiser-chibi-binary)
      (car geiser-chibi-binary)
    geiser-chibi-binary))

(defvar geiser-chibi-scheme-dir
  (expand-file-name "src" (file-name-directory load-file-name))
  "Directory where the Chibi scheme geiser modules are installed.")

(defun geiser-chibi--parameters ()
  "Return a list with all parameters needed to start Chibi Scheme.
This function uses `geiser-chibi-init-file' if it exists."
  `(,@geiser-chibi-extra-command-line-parameters
    "-I" ,(expand-file-name "geiser/" geiser-chibi-scheme-dir)
    "-m" "geiser"
    ,@(and (listp geiser-chibi-binary) (cdr geiser-chibi-binary))))

(defconst geiser-chibi--prompt-regexp "> ")


;;; Evaluation support:

(defun geiser-chibi--geiser-procedure (proc &rest args)
  "Transform PROC in string for a scheme procedure using ARGS."
  (cl-case proc
    ((eval compile)
     (let ((form (mapconcat 'identity (cdr args) " "))
           (module (cond ((string-equal "'()" (car args))
                          "'()")
                         ((and (car args))
                          (concat "'" (car args)))
                         (t
                          "#f"))))
       (format "(geiser:eval %s '%s)" module form)))
    ((load-file compile-file)
     (format "(geiser:load-file %s)" (car args)))
    ((no-values)
     "(geiser:no-values)")
    (t
     (let ((form (mapconcat 'identity args " ")))
       (format "(geiser:%s %s)" proc form)))))

(defun geiser-chibi--get-module (&optional module)
  "Find current buffer's module, using MODULE as a hint."
  (cond ((null module)  :f)
        ((listp module) module)
        ((stringp module)
         (condition-case nil
             (car (geiser-syntax--read-from-string module))
           (error :f)))
        (t :f)))

(defun geiser-chibi--symbol-begin (module)
  "Return beginning of current symbol while in MODULE."
  (if module
      (max (save-excursion (beginning-of-line) (point))
           (save-excursion (skip-syntax-backward "^(>") (1- (point))))
    (save-excursion (skip-syntax-backward "^'-()>") (point))))

(defun geiser-chibi--import-command (module)
  "Return string representing an sexp importing MODULE."
  (format "(import %s)" module))

(defun geiser-chibi--exit-command ()
  "Return string representing a REPL exit sexp."
  "(exit 0)")

;; 

;; ;;; REPL startup

(defconst geiser-chibi-minimum-version "0.7.3")

(defun geiser-chibi--version (binary)
  "Use BINARY to find Chez scheme version."
  (cadr (split-string
         (car (process-lines binary "-V"))
         " ")))

(defun geiser-chibi--startup (_remote)
  "Startup function."
  (let ((geiser-log-verbose-p t))
    (compilation-setup t)))

;;; Implementation definition:

(define-geiser-implementation chibi
  (binary geiser-chibi--binary)
  (arglist geiser-chibi--parameters)
  (version-command geiser-chibi--version)
  (minimum-version geiser-chibi-minimum-version)
  (repl-startup geiser-chibi--startup)
  (prompt-regexp geiser-chibi--prompt-regexp)
  (debugger-prompt-regexp nil) ;; geiser-chibi--debugger-prompt-regexp
  ;; (enter-debugger geiser-chibi--enter-debugger)
  (marshall-procedure geiser-chibi--geiser-procedure)
  (find-module geiser-chibi--get-module)
  ;; (enter-command geiser-chibi--enter-command)
  (exit-command geiser-chibi--exit-command)
  (import-command geiser-chibi--import-command)
  (find-symbol-begin geiser-chibi--symbol-begin)
  ;; (display-error geiser-chibi--display-error)
  ;; (external-help geiser-chibi--manual-look-up)
  ;; (check-buffer geiser-chibi--guess)
  ;; (keywords geiser-chibi--keywords)
  ;; (case-sensitive geiser-chibi-case-sensitive-p)
  )

;;;###autoload
(geiser-implementation-extension 'chibi "sld")

;;;###autoload
(geiser-activate-implementation 'chibi)

;;;###autoload
(autoload 'run-chibi "geiser-chibi" "Start a Geiser Chibi Scheme REPL." t)

;;;###autoload
(autoload 'switch-to-chibi "geiser-chibi"
  "Start a Geiser Chibi Scheme REPL, or switch to a running one." t)


(provide 'geiser-chibi)
;;; geiser-chibi.el ends here
