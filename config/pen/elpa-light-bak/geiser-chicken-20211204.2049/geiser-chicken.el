;;; geiser-chicken.el --- Chicken's implementation of the geiser protocols  -*- lexical-binding: t; -*-

;; Copyright (C) 2014, 2015, 2019, 2020, 2021 Daniel Leslie

;; Based on geiser-guile.el by Jose Antonio Ortega Ruiz

;; Author: Daniel Leslie
;; Maintainer: Daniel Leslie
;; Keywords: languages, chicken, scheme, geiser
;; Homepage: https://gitlab.com/emacs-geiser/chicken
;; Package-Requires: ((emacs "24.4") (geiser "0.19"))
;; SPDX-License-Identifier: BSD-3-Clause
;; Version: 0.17

;; This file is NOT part of GNU Emacs.

;;; Commentary:

;;  This package extends the `geiser' core package to support
;;  Chicken.


;;; Code:

(require 'geiser-impl)
(require 'geiser-connection)
(require 'geiser-syntax)
(require 'geiser-custom)
(require 'geiser-base)
(require 'geiser-eval)
(require 'geiser-edit)
(require 'geiser-log)
(require 'geiser)

(require 'compile)
(require 'info-look)

(eval-when-compile (require 'cl-lib))

(defconst geiser-chicken-builtin-keywords
  '("assume"
    "compiler-typecase"
    "cond-expand"
    "condition-case"
    "declare"
    "define-constant"
    "define-inline"
    "define-interface"
    "define-record"
    "define-specialization"
    "define-type"
    "dotimes"
    "ecase"
    "fluid-let"
    "foreign-lambda"
    "foreign-lambda*"
    "foreign-primitive"
    "foreign-safe-lambda"
    "foreign-safe-lambda*"
    "functor"
    "handle-exceptions"
    "let-location"
    "let-optionals"
    "let-optionals*"
    "letrec-values"
    "module"
    "regex-case"
    "select"
    "use"
    "with-input-from-pipe"))


;;; Customization:

(defgroup geiser-chicken nil
  "Customization for Geiser's Chicken flavour."
  :group 'geiser)

(geiser-custom--defcustom geiser-chicken-binary
  (cond ((eq system-type 'windows-nt) '("csi.exe" "-:c"))
        ((eq system-type 'darwin) "csi")
        (t "csi"))
  "Name to use to call the Chicken executable when starting a REPL."
  :type '(choice string (repeat string))
  :group 'geiser-chicken)

(geiser-custom--defcustom geiser-chicken-load-path nil
  "A list of paths to be added to Chicken's load path when it's started."
  :type '(repeat file)
  :group 'geiser-chicken)

(geiser-custom--defcustom geiser-chicken-init-file "~/.chicken-geiser"
  "Initialization file with user code for the Chicken REPL.
If all you want is to load ~/.csirc, set
`geiser-chicken-load-init-file-p' instead."
  :type 'string
  :group 'geiser-chicken)

(geiser-custom--defcustom geiser-chicken-load-init-file-p nil
  "Whether to load ~/.chicken when starting Chicken.
Note that, due to peculiarities in the way Chicken loads its init
file, using `geiser-chicken-init-file' is not equivalent to setting
this variable to t."
  :type 'boolean
  :group 'geiser-chicken)

(geiser-custom--defcustom geiser-chicken-extra-keywords nil
  "Extra keywords highlighted in Chicken scheme buffers."
  :type '(repeat string)
  :group 'geiser-chicken)

(geiser-custom--defcustom geiser-chicken-case-sensitive-p t
  "Non-nil means keyword highlighting is case-sensitive."
  :type 'boolean
  :group 'geiser-chicken)

(geiser-custom--defcustom geiser-chicken-match-limit 20
  "The limit on the number of matching symbols that Chicken will provide to Geiser."
  :type 'integer
  :group 'geiser-chicken)


;;; REPL support:

(defvar geiser-chicken-scheme-dir
  (expand-file-name "src" (file-name-directory load-file-name))
  "Directory where the Chicken scheme geiser modules are installed.")

(defun geiser-chicken--binary ()
  "Return path to chicken executable."
  (if (listp geiser-chicken-binary)
      (car geiser-chicken-binary)
    geiser-chicken-binary))

(defun geiser-chicken--parameters ()
  "Return a list with all parameters needed to start Chicken.
This function uses `geiser-chicken-init-file' if it exists."
  (let ((init-file (and (stringp geiser-chicken-init-file)
                        (expand-file-name geiser-chicken-init-file)))
        (n-flags (and (not geiser-chicken-load-init-file-p) '("-n"))))
    `(,@(and (listp geiser-chicken-binary) (cdr geiser-chicken-binary))
      ,@n-flags "-include-path" ,geiser-chicken-scheme-dir
      ,@(apply 'append (mapcar (lambda (p) (list "-include-path" p))
                               geiser-chicken-load-path))
      ,@(and init-file (file-readable-p init-file) (list init-file)))))

(defconst geiser-chicken--prompt-regexp "#[^;]*;[^:0-9]*:?[0-9]+> ")


;;; Evaluation support:

(defun geiser-chicken--geiser-procedure (proc &rest args)
  "Transform PROC in string for a scheme procedure using ARGS."
  (cl-case proc
    ((eval compile)
     (let ((form (mapconcat 'identity (cdr args) " "))
           (module (if (car args) (concat "'" (car args)) "#f")))
       (format "(geiser#geiser-eval %s '%s)" module form)))
    ((load-file compile-file)
     (format "(geiser#geiser-load-file %s)" (car args)))
    ((no-values)
     "(geiser#geiser-no-values)")
    (t
     (let ((form (mapconcat 'identity args " ")))
       (format "(geiser#geiser-%s %s)" proc form)))))

(defconst geiser-chicken--module-re
  "( *module +\\(([^)]+)\\|[^ ]+\\)")

(defconst geiser-chicken--define-library-re
  "( *define-library +\\(([^)]+)\\)")

(defun geiser-chicken--get-module (&optional module)
  "Find current buffer's module using MODULE as a hint."
  (cond ((null module)
         (save-excursion
           (geiser-syntax--pop-to-top)
           (if (or (re-search-backward geiser-chicken--module-re nil t)
                   (re-search-backward geiser-chicken--define-library-re nil t)
                   (re-search-forward geiser-chicken--module-re nil t)
                   (re-search-forward geiser-chicken--define-library-re nil t))
               (geiser-chicken--get-module (match-string-no-properties 1))
             :f)))
        ((listp module) module)
        ((stringp module)
         (condition-case nil
             (car (geiser-syntax--read-from-string module))
           (error :f)))
        (t :f)))

(defun geiser-chicken--module-cmd (module fmt &optional def)
  "Use FMT to format a change to MODULE, with default DEF."
  (when module
    (let* ((module (geiser-chicken--get-module module))
           (module (cond ((or (null module) (eq module :f)) def)
                         (t (format "%s" module)))))
      (and module (format fmt module)))))

(defun geiser-chicken--import-command (module)
  "Format a sexp to use MODULE."
  (geiser-chicken--module-cmd module "(use %s)"))

(defun geiser-chicken--enter-command (module)
  "Format a REPL command to enter MODULE."
  (geiser-chicken--module-cmd module ",m %s" module))

(defun geiser-chicken--exit-command ()
  "Format a REPL command to quit."
  ",q")

(defun geiser-chicken--symbol-begin (module)
  "Find beginning of symbol, in the context of MODULE."
  (if module
      (max (save-excursion (beginning-of-line) (point))
           (save-excursion (skip-syntax-backward "^(>") (1- (point))))
    (save-excursion (skip-syntax-backward "^'-()>") (point))))


;;; Error display

(defun geiser-chicken--display-error (_module key msg)
  "Display an error with key KEY and message MSG."
  (newline)
  (when (stringp msg)
    (save-excursion (insert msg))
    (geiser-edit--buttonize-files))
  (and (not key) msg (not (zerop (length msg)))))


;;; Trying to ascertain whether a buffer is Chicken Scheme:

(defconst geiser-chicken--guess-re
  (regexp-opt '("csi" "chicken" "csc")))

(defun geiser-chicken--guess ()
  "Try to detect whether we're in a Chicken scheme buffer."
  (save-excursion
    (goto-char (point-min))
    (re-search-forward geiser-chicken--guess-re nil t)))

(defun geiser-chicken--external-help (id _module)
  "Load chicken doc for ID into a buffer."
  (let* ((version (geiser-chicken--version (geiser-chicken--binary)))
	 (major-version (car (split-string version "\\\."))))
    (browse-url (format "http://api.call-cc.org/%s/cdoc?q=%s&query-name=Look+up"
                        major-version id))))


;;; Keywords and syntax

(defun geiser-chicken--keywords ()
  "Return Chicken-specific scheme keywords."
  (append
   (geiser-syntax--simple-keywords geiser-chicken-extra-keywords)
   (geiser-syntax--simple-keywords geiser-chicken-builtin-keywords)))

(geiser-syntax--scheme-indent
 (assume 1)
 (compiler-typecase 1)
 (cond-expand 0)
 (condition-case 1)
 (cut 1)
 (cute 1)
 (declare 0)
 (dotimes 1)
 (ecase 1)
 (fluid-let 1)
 (foreign-lambda 2)
 (foreign-lambda* 2)
 (foreign-primitive 2)
 (foreign-safe-lambda 2)
 (foreign-safe-lambda* 2)
 (functor 3)
 (handle-exceptions 2)
 (import 0)
 (let-location 1)
 (let-optionals 2)
 (let-optionals* 2)
 (letrec-values 1)
 (module 2)
 (regex-case 1)
 (select 1)
 (set! 1)
 (use 0)
 (with-input-from-pipe 1)
 (with-output-to-pipe 1))


;;; REPL startup

(defconst geiser-chicken-minimum-version "4.8.0.0")

(defun geiser-chicken--version (binary)
  "Find Chicken's version using  BINARY."
  (cl-destructuring-bind (program . args)
      (append (if (listp binary) binary (list binary))
              '("-e" "(display \
                     (or (handle-exceptions exn \
                           #f \
                           (eval `(begin (import chicken.platform) \
                                         (chicken-version)))) \
                         (chicken-version)))"))
    (with-temp-buffer
      (apply #'call-process program nil '(t t) t args)
      (buffer-string))))

(defun connect-to-chicken ()
  "Start a Chicken REPL connected to a remote process."
  (interactive)
  (geiser-connect 'chicken))

(defun geiser-chicken4--compile-or-load (force-load)
  "Compile or load Geiser support code in Chiken4, forcibly if FORCE-LOAD is t."
  (let ((target
         (expand-file-name "geiser/chicken4.so" geiser-chicken-scheme-dir))
        (source
         (expand-file-name "geiser/chicken4.scm" geiser-chicken-scheme-dir))
        (force-load (or force-load (eq system-type 'windows-nt)))
        (suppression-prefix
         "(define geiser-stdout (current-output-port))(current-output-port (make-output-port (lambda a #f) (lambda a #f)))")
        (suppression-postfix
         "(current-output-port geiser-stdout)"))
    (let ((load-sequence
           (cond
            (force-load
             (format "(load \"%s\")\n(import geiser)\n" source))
            ((file-exists-p target)
             (format "%s(load \"%s\")(import geiser)%s\n"
                     suppression-prefix target suppression-postfix))
            (t
             (format "%s(use utils)(compile-file \"%s\" options: '(\"-O3\" \"-s\") output-file: \"%s\" load: #t)(import geiser)%s\n"
                     suppression-prefix source target suppression-postfix)))))
      (geiser-eval--send/wait load-sequence))))

(defun geiser-chicken5-load ()
  "Load Geiser support code in Chicken 5."
  (let ((source (expand-file-name "geiser/chicken5.scm"
                                  geiser-chicken-scheme-dir)))
    (geiser-eval--send/wait
     (format
      "(display '((result . t) (output . f))) (load \"%s\")"
      source))))

(defun geiser-chicken--startup (_remote)
  "Startup function."
  (compilation-setup t)
  (cond
   ((version< (geiser-chicken--version geiser-chicken-binary) "5.0.0")
    (geiser-chicken4--compile-or-load t))
   (t (geiser-chicken5-load))))


;;; Implementation definition:

(define-geiser-implementation chicken
  (unsupported-procedures '(callers callees generic-methods))
  (binary geiser-chicken--binary)
  (arglist geiser-chicken--parameters)
  (version-command geiser-chicken--version)
  (minimum-version geiser-chicken-minimum-version)
  (repl-startup geiser-chicken--startup)
  (prompt-regexp geiser-chicken--prompt-regexp)
  (debugger-prompt-regexp nil)
  (enter-debugger nil)
  (marshall-procedure geiser-chicken--geiser-procedure)
  (find-module geiser-chicken--get-module)
  (enter-command geiser-chicken--enter-command)
  (exit-command geiser-chicken--exit-command)
  (import-command geiser-chicken--import-command)
  (find-symbol-begin geiser-chicken--symbol-begin)
  (display-error geiser-chicken--display-error)
  (external-help geiser-chicken--external-help)
  (check-buffer geiser-chicken--guess)
  (keywords geiser-chicken--keywords)
  (case-sensitive geiser-chicken-case-sensitive-p))

;;;###autoload
(geiser-activate-implementation 'chicken)

;;;###autoload
(geiser-implementation-extension 'chicken "release-info")
;;;###autoload
(geiser-implementation-extension 'chicken "meta")
;;;###autoload
(geiser-implementation-extension 'chicken "setup")

;;;###autoload
(autoload 'run-chicken "geiser-chicken" "Start a Geiser Chicken REPL." t)

;;;###autoload
(autoload 'switch-to-chicken "geiser-chicken"
  "Start a Geiser Chicken REPL, or switch to a running one." t)

;;;###autoload
(autoload 'connect-to-chicken "geiser-chicken"
  "Connect to a remote Geiser Chicken REPL." t)

(provide 'geiser-chicken)
;;; geiser-chicken.el ends here
