;;; ob-ess-julia.el --- Org babel support for Julia language -*- lexical-binding: t; -*-

;; Copyright (C) 2020
;; SPDX-License-Identifier: CECILL-2.1
;; Credits:
;; - Primarily based on / forked from G. J. Kerns' ob-julia.
;;   See the original version at https://github.com/gjkerns/ob-julia
;; - Also based on ob-R.el by Eric Schulte and Dan Davison,
;;   for consistency with other ob-* backends.

;; Author: Frédéric Santos
;; Version: 1.0.3
;; Keywords: languages
;; URL: https://github.com/frederic-santos/ob-ess-julia
;; Package-Requires: ((ess "20201004.1522") (julia-mode "0.4"))

;; This file is *not* part of GNU Emacs.

;;; Commentary:
;; This package provides an elementary support for Julia language
;; in Org mode.

;;; Code:

;; Required packages:
(require 'cl-lib)
(require 'ess)
(require 'ess-julia)
(require 'ob)

;; External functions from ESS:
(declare-function inferior-ess-send-input "ext:ess-inf" ())
(declare-function ess-make-buffer-current "ext:ess-inf" ())
(declare-function ess-eval-buffer "ext:ess-inf" (vis))
(declare-function ess-wait-for-process "ext:ess-inf"
		  (&optional proc sec-prompt wait force-redisplay))

;; Other external functions:
(declare-function orgtbl-to-csv "org-table" (table params))
(declare-function s-matches? "s" (regexp s &optional start))

;; For external eval, we do not rely on ESS:
(defcustom org-babel-ess-julia-external-command "julia"
  "Name of command to use for executing Julia code."
  :group 'org-babel
  :package-version '(ob-ess-julia . "1.0.0")
  :version "27.1"
  :type 'string)

;; For session eval, Julia will be called as an ESS process:
(declare-function run-ess-julia "ext:ess-julia" (&optional start-args))
(declare-function julia "ext:ess-julia" (&optional start-args))

(defun ob-ess-julia--run-julia-and-select-buffer (&optional start-args)
  "Run Julia with ESS and make sure that its inferior buffer will be active.
START-ARGS is passed to `run-ess-julia'."
  (interactive "P")
  (set-buffer (run-ess-julia start-args)))

;; End of eval markers for org babel:
(defconst org-babel-ess-julia-eoe-indicator "\"org_babel_ess_julia_eoe\""
  "See help of `org-babel-comint-with-output'.")
(defconst org-babel-ess-julia-eoe-output "org_babel_ess_julia_eoe"
  "See help of `org-babel-comint-with-output'.")

;; ob-ess-julia needs Julia to load a startup script:
(defvar ob-ess-julia-startup
  (concat (file-name-directory (or load-file-name
                                   (buffer-file-name)))
          "ob-ess-julia-startup.jl")
  "File path for startup Julia script.")

;; Retrieve this variable defined by ESS:
(defvar inferior-julia-args)

;; Defaults for Julia session and headers:
(defvar org-babel-default-header-args:ess-julia '())
(defvar org-babel-ess-julia-default-session "*ess-julia*"
  "Default name given to a fresh new Julia session.")

(defconst org-babel-header-args:ess-julia
  '((width   . :any)
    (height  . :any)
    (dir     . :any)
    (results . ((file list scalar table vector verbatim)
		(raw html latex)
		(replace append none prepend silent)
		(output graphics value))))
  "Julia-specific header arguments.")

;; Set default extension to tangle Julia code:
(add-to-list 'org-babel-tangle-lang-exts '("ess-julia" . "jl"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Handling Julia sessions ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun org-babel-ess-julia-initiate-session (session params)
  "Create a Julia process if there is no active SESSION yet.
SESSION is a string; check whether the associated buffer is a comint buffer.
If SESSION is `none', do nothing.
PARAMS are user-specified src block parameters."
  (unless (equal session "none")
    (let* ((session (or session          ; if user-specified
                        org-babel-ess-julia-default-session))
           (dir (cdr (assoc :dir params)))
	   (ess-ask-for-ess-directory
	    (and (and (boundp 'ess-ask-for-ess-directory)
                      ess-ask-for-ess-directory)
		 (not dir)))
           (path-to-load-file (format "--load=%s" ob-ess-julia-startup))
           (inferior-julia-args
            (concat inferior-julia-args path-to-load-file)))
      (if (org-babel-comint-buffer-livep session)
	  session                       ; session already exists
	(save-window-excursion
          (when (get-buffer session)
	    ;; Session buffer exists, but with dead process
	    (set-buffer session))
	  (ob-ess-julia--run-julia-and-select-buffer) ; new Julia comint buffer
          (when dir
            (ess-eval-linewise (format "cd(\"%s\")" dir)))
	  (rename-buffer
	   (if (bufferp session)
	       (buffer-name session)
	     (if (stringp session)
		 session
	       (buffer-name))))
	  (current-buffer))))))

;; Retrieve ESS process info:
(defun org-babel-ess-julia-associate-session (session)
  "Associate Julia code buffer with an ESS[Julia] session.
See function `org-src-associate-babel-session'.
Make SESSION be the inferior ESS process associated with the
current code buffer."
  (setq ess-local-process-name
	(process-name (get-buffer-process session)))
  (ess-make-buffer-current))

(defvar ess-current-process-name)       ; dynamically scoped
(defvar ess-local-process-name)         ; dynamically scoped
(defvar ess-ask-for-ess-directory)      ; dynamically scoped
(defvar ess-eval-visibly-p)

;; Session helpers:
(defun org-babel-prep-session:ess-julia (session params)
  "Prepare SESSION according to the header arguments specified in PARAMS."
  (let* ((session (org-babel-ess-julia-initiate-session session params))
	 (var-lines (org-babel-variable-assignments:ess-julia params)))
    (org-babel-comint-in-buffer
        session                     ; name of buffer for Julia session
      (mapc (lambda (var)
              (end-of-line 1) (insert var) (comint-send-input nil t)
              (org-babel-comint-wait-for-output session))
            var-lines))
    session))

(defun org-babel-variable-assignments:ess-julia (params)
  "Parse block PARAMS to return a list of Julia statements assigning the variables in `:var'."
  (let ((vars (org-babel--get-vars params)))
    ;; Create Julia statements to assign each variable specified with `:var':
    (mapcar
     (lambda (pair)
       (org-babel-ess-julia-assign-elisp
	(car pair) (cdr pair)
	(equal "yes" (cdr (assoc :colnames params)))
	(equal "yes" (cdr (assoc :rownames params)))))
     (mapcar
      (lambda (i)
	(cons (car (nth i vars))
	      (org-babel-reassemble-table
	       (cdr (nth i vars))
	       (cdr (nth i (cdr (assoc :colname-names params))))
	       (cdr (nth i (cdr (assoc :rowname-names params)))))))
      (number-sequence 0 (1- (length vars)))))))

(defun org-babel-edit-prep:ess-julia (info)
  "Function to edit Julia code in OrgSrc mode.
I.e., for use with, and is called by, `org-edit-src-code'.
INFO is a list as returned by `org-babel-get-src-block-info'."
  (let ((session (cdr (assq :session (nth 2 info)))))
    (when (and session
	       (string-prefix-p "*" session)
	       (string-suffix-p "*" session))
      (org-babel-ess-julia-initiate-session session nil))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Executing Julia source blocks ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun org-babel-ess-julia-evaluate
  (session body result-type result-params column-names-p row-names-p)
  "Evaluate Julia code in BODY.
This can be done either within an existing SESSION, or with an external process.
This function only makes the convenient redirection towards the targeted
helper function, depending on this parameter."
  (if session
      (org-babel-ess-julia-evaluate-session
       session body result-type result-params column-names-p row-names-p)
    (org-babel-ess-julia-evaluate-external-process
     body result-type result-params column-names-p row-names-p)))

(defun org-babel-expand-body:ess-julia (body params &optional graphics-file)
  "Expand BODY according to PARAMS, return the expanded body.
I.e., add :prologue and :epilogue to BODY if required, as well as new Julia
variables declared from :var.  The 'expanded body' is actually the union set
of BODY and of all those instructions.
GRAPHICS-FILE is a boolean."
  (let ((width (or (cdr (assq :width params))
                   600))
        (height (or (cdr (assq :height params))
                    400)))
    (mapconcat #'identity
	       (append
	        (when (cdr (assq :prologue params))
		  (list (cdr (assq :prologue params))))
	        (org-babel-variable-assignments:ess-julia params)
	        (list body)
                (when graphics-file
                  (list (format "plot!(size = (%s, %s))" width height)
                        (format "savefig(\"%s\")" graphics-file)))
	        (when (cdr (assq :epilogue params))
		  (list (cdr (assq :epilogue params)))))
	       "\n")))

(defconst org-babel-ess-julia-write-object-command
  "ob_ess_julia_write(%s, \"%s\", %s);"
  "A Julia function to evaluate code blocks and write the result to a file.
Has three %s escapes to be filled in:
1. The code to be run (must be an expression, not a statement)
2. The name of the file to write to
3. Column names, \"true\" or\"false\" (used for DataFrames only)")

(defun org-babel-ess-julia-evaluate-external-process
    (body result-type result-params column-names-p row-names-p)
  "Evaluate BODY in an external Julia process.
If RESULT-TYPE equals `output' then return standard output as a
string.  If RESULT-TYPE equals `value' then return the value of the
last statement in BODY, as elisp.
RESULT-PARAMS is an alist of user-specified parameters.
COLUMN-NAMES-P and ROW-NAMES-P are either \"true\" of \"false\"."
  (if (equal result-type 'output)
      (org-babel-eval org-babel-ess-julia-external-command body)
    ;; else: result-type != "output"
    (when (equal result-type 'value)
      (let ((tmp-file (org-babel-temp-file "ess-julia-")))
        (org-babel-eval
         (concat org-babel-ess-julia-external-command
                 " "
                 (format "--load=%s" ob-ess-julia-startup))
         (format org-babel-ess-julia-write-object-command
                 (format "begin\n%s\nend" body)
                 (org-babel-process-file-name tmp-file 'noquote)
                 column-names-p))
        (org-babel-ess-julia-process-value-result
	 (org-babel-result-cond result-params
	   (with-temp-buffer
	     (insert-file-contents tmp-file)
	     (buffer-string))
	   (org-babel-import-elisp-from-file tmp-file "\t"))
	 column-names-p)))))

(defun org-babel-ess-julia-evaluate-session
    (session body result-type result-params column-names-p row-names-p)
  "Evaluate BODY in a given Julia SESSION.
If RESULT-TYPE equals `output' then return standard output as a
string.  If RESULT-TYPE equals `value' then return the value of the
last statement in BODY, as elisp."
  (cl-case result-type
    (value
     (let ((tmp-file (org-babel-temp-file "ess-julia-"))
           (tmp-file2 (org-babel-temp-file "ess-julia-")))
       (org-babel-comint-eval-invisibly-and-wait-for-file
	session tmp-file2
        (org-babel-chomp
         (format "@pipe begin\n%s\nend |> ob_ess_julia_write(_, \"%s\", %s)\nwritedlm(\"%s\", [1 2 3 4])"
                 body
                 (org-babel-process-file-name tmp-file 'noquote)
                 column-names-p
                 (org-babel-process-file-name tmp-file2 'noquote))))
       (org-babel-ess-julia-process-value-result
	(org-babel-result-cond result-params
	  (with-temp-buffer
	    (insert-file-contents tmp-file)
	    (org-babel-chomp (buffer-string) "\n"))
	  (org-babel-import-elisp-from-file tmp-file "\t"))
	column-names-p)))
    (output
     (let ((tmp-file (org-babel-temp-file "ess-julia-"))
           (tmp-file2 (org-babel-temp-file "ess-julia-")))
       (org-babel-comint-eval-invisibly-and-wait-for-file
        session tmp-file2
        (org-babel-chomp
         (format "startREPLcopy(\"%s\")\n%s\nendREPLcopy()\nwritedlm(\"%s\", [1 2 3 4])"
                 (org-babel-process-file-name tmp-file 'noquote)
                 body
                 (org-babel-process-file-name tmp-file2 'noquote))))
       (with-current-buffer session
      	 (comint-add-to-input-history body))
       (org-babel-result-cond result-params
         (with-temp-buffer
           (insert-file-contents tmp-file)
           (buffer-string)))))))

(defun org-babel-execute:ess-julia (body params)
  "Execute a block of Julia code.
The BODY is first refactored with `org-babel-expand-body:ess-julia',
according to user-specified PARAMS.
This function is called by `org-babel-execute-src-block'."
  (let* ((session-name (cdr (assq :session params)))
         (session (org-babel-ess-julia-initiate-session session-name params))
         (graphics-file (org-babel-ess-julia-graphical-output-file params))
         (column-names-p (unless graphics-file (cdr (assq :colnames params))))
	 (row-names-p (unless graphics-file (cdr (assq :rownames params))))
         (expanded-body (org-babel-expand-body:ess-julia body params graphics-file))
         (result-params (cdr (assq :result-params params)))
	 (result-type (cdr (assq :result-type params)))
         (result (org-babel-ess-julia-evaluate
                  session expanded-body result-type result-params
                  (if column-names-p "true" "false")
                  ;; TODO: handle correctly the following last args for rownames
                  nil)))
    ;; Return "textual" results, unless they have been written
    ;; in a graphical output file:
    (unless graphics-file
      result)))

;;;;;;;;;;;;;;;;;;;;;
;; Various helpers ;;
;;;;;;;;;;;;;;;;;;;;;

;; Dirty helpers for what seems to be a bug with iESS[Julia] buffers.
;; See https://github.com/emacs-ess/ESS/issues/1053

(defun ob-ess-julia--split-into-julia-commands (body eoe-indicator)
  "Split BODY into a list of valid Julia commands.
Complete commands are elements of the list; incomplete commands (i.e., commands
that are written on several lines) are `concat'enated, and then passed as one
single element of the list.
Adds string EOE-INDICATOR at the end of all instructions.
This workaround avoids what seems to be a bug with iESS[julia] buffers."
  (let* ((lines (split-string body
                              "\n" t))
         (cleaned-lines (mapcar #'org-babel-chomp lines))
         (last-end-char nil)
         (commands nil))
    (while cleaned-lines
      (if (or (not last-end-char)
              ;; matches an incomplete Julia command:
              (not (s-matches? "[(;,]" last-end-char)))
          (progn
            (setq last-end-char (substring (car cleaned-lines) -1))
            (setq commands (cons (pop cleaned-lines) commands)))
        (setq last-end-char (substring (car cleaned-lines) -1))
        (setcar commands (concat (car commands)
                                 " "
                                 (pop cleaned-lines)))))
    (reverse (cons eoe-indicator commands))))

(defun ob-ess-julia--execute-line-by-line (body eoe-indicator)
  "Execute cleaned BODY into a Julia session.
I.e., clean all Julia instructions, and send them one by one into the
active iESS[julia] process.
Instructions will end by string EOE-INDICATOR on Julia buffer."
  (let ((lines (ob-ess-julia--split-into-julia-commands body eoe-indicator))
        (jul-proc (get-process (process-name (get-buffer-process (current-buffer))))))
    (mapc
     (lambda (line)
       (insert line)
       (inferior-ess-send-input)
       (ess-wait-for-process jul-proc nil 0.2)
       (goto-char (point-max)))
     lines)))

(defun org-babel-ess-julia-process-value-result (result column-names-p)
  "Julia-specific processing for `:results value' output type.
RESULT should have been computed upstream (and is typiclly retrieved
from a temp file).
Insert hline if column names in output have been requested
with COLUMN-NAMES-P.  Otherwise RESULT is unchanged."
  (if (equal column-names-p "true")
      (cons (car result) (cons 'hline (cdr result)))
    result))

(defun org-babel-ess-julia-graphical-output-file (params)
  "Return the name of the file to which Julia should write graphical output.
This name is extracted from user-specified PARAMS of a code block."
  (and (member "graphics" (cdr (assq :result-params params)))
       (org-babel-graphical-output-file params)))

(defun org-babel-load-session:ess-julia (session body params)
  "Load BODY into a given Julia SESSION."
  (save-window-excursion
    (let ((buffer (org-babel-prep-session:ess-julia session params)))
      (with-current-buffer buffer
        (goto-char (process-mark (get-buffer-process (current-buffer))))
        (insert (org-babel-chomp body)))
      buffer)))

(defun org-babel-ess-julia-quote-csv-field (s)
  "Quote field S, if S is a string."
  (if (stringp s)
      (concat "\""
              (mapconcat #'identity
                         (split-string s "\"")
                         "\"\"")
              "\"")
    (format "%S" s)))

(defun org-babel-ess-julia-assign-elisp (name value colnames-p rownames-p)
  "Construct Julia code assigning the elisp VALUE to a Julia variable named NAME."
  (if (listp value)
      (let ((transition-file (org-babel-temp-file "julia-import-")))
        ;; ensure VALUE has an orgtbl structure (depth of at least 2):
        (unless (listp (car value)) (setq value (list value)))
        (with-temp-file transition-file
          (insert
	   (orgtbl-to-csv value '(:fmt org-babel-ess-julia-quote-csv-field))
	   "\n"))
	(let ((file (org-babel-process-file-name transition-file 'noquote))
	      (header (if (or (eq (nth 1 value) 'hline)
                              (equal colnames-p "true"))
			  "1"
                        "false")))
	  (format "%s = CSV.read(\"%s\", DataFrame, header=%s, delim=\",\");"
                  name file header)))
    ;; else, value is not a list: just produce something like "name = value":
    (format "%s = %s;" name (org-babel-ess-julia-quote-csv-field value))))

(provide 'ob-ess-julia)
;;; ob-ess-julia.el ends here
