;;; choice-program.el --- Parameter based program  -*- lexical-binding: t; -*-

;; Copyright (C) 2015 - 2023 Paul Landes

;; Version: 0.14
;; Author: Paul Landes
;; Maintainer: Paul Landes
;; Keywords: execution processes unix lisp
;; URL: https://github.com/plandes/choice-program
;; Package-Requires: ((emacs "26") (dash "2.17.0"))

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; Run a program in an async buffer with a particular choice, which is
;; prompted by the user.

;;; Code:

(require 'dash)
(require 'eieio)
(require 'eieio-base)
(require 'choice-program-complete)

(defvar choice-program-exec-debug-p nil
  "*If non-nil, output debuging to buffer *Option Prog Debug*.")

(defvar choice-program-instance-syms nil
  "A list of choice-program instance variables.")

(defgroup choice-program nil
  "Parameter choice driven program execution."
  :group 'choice-program
  :prefix "choice-program-")

(defclass choice-program (eieio-named)
  ((program :initarg :program
	    :type string
	    :documentation "The conduit program to run.")
   (interpreter :initarg :interpreter
		:type (or null string)
		:documentation "The interpreter (i.e. /bin/sh) or nil.")
   (selection-args :initarg :selection-args
		   :type list
		   :documentation "List of arguments used to get the options.")
   (choice-prompt :initarg :choice-prompt
		  :initform "Choice"
		  :type string
		  :documentation "Name of the parameter choice list \
\(i.e. Mmenomic) when used for prompting.  This should always be capitalized.")
   (choice-switch-name :initarg :choice-switch-name
		       :initform "-o"
		       :type string
		       :documentation "Name of the parameter switch \
\(i.e. -m).")
   (dryrun-switch-name :initarg :dryrun-switch-name
		       :initform "-d"
		       :type string
		       :documentation "Name of the switch given to the \
program execute a dry run (defaults to -n).")
   (verbose-switch-form :initarg :verbose-switch-form
			:initform nil
			:type (or null string)
			:documentation "Switch and/or parameter given to the \
program to produce verbose output.")
   (buffer-name :initarg :buffer-name
		:initform nil
		:type (or symbol string)
		:documentation "The name of the buffer to generate when \
executing the synchronized command.")
   (documentation :initarg :documentation
		  :initform ""
		  :type string
		  :documentation "Documentation about this choice program.
This is used for things like what is used for the generated function
documentation.")
   (prompt-history :initarg :prompt-history
		   :protection :private
		   :initform (gensym "choice-program-prompt-history")
		   :type symbol
		   :documentation "History variable used for user prompts.")
   (display-buffer :initarg :display-buffer
		   :initform t
		   :type boolean
		   :documentation "\
Whether or not to display the buffer on execution."))
  :documentation "Represents a single `actionable' program instance.")

(cl-defmethod initialize-instance ((this choice-program) &optional slots)
  "Initialize instance THIS with arguments SLOTS."
  (setq slots (plist-put slots :buffer-name
			 (or (plist-get slots :buffer-name)
			     (format "*%s Output*"
				     (capitalize (slot-value this 'program)))))
	slots (plist-put slots :object-name
			 (or (plist-get slots :object-name)
			     (plist-get slots :program))))
  (cl-call-next-method this slots))

(cl-defmethod choice-program-name ((this choice-program))
  "Return the name of THIS choice program launcher."
  (slot-value this 'object-name))

(cl-defmethod choice-program-debug ((_ choice-program) object)
  "Add a debugging message with debug parameter OBJECT."
  (with-current-buffer
      (get-buffer-create "*Option Prog Debug*")
    (goto-char (point-max))
    (insert (format (if (stringp object) "%s" "%S") object))
    (newline)))

(cl-defmethod eieio-object-value-string ((this choice-program) val)
  "Return a string representation of VAL overriden for THIS.
This is used for prettyprinting by `eieio-object-name-string'."
  (cond ((stringp val) val)
	((consp val) (->> (mapconcat #'(lambda (val)
					 (eieio-object-value-string this val))
				     val " ")
			  (format "(%s)")))
	(t (prin1-to-string val))))

(cl-defmethod eieio-object-value-slots ((_ choice-program))
  "Return a list of slot names used in `eieio-object-name-string'."
  '(selection-args buffer-name))

(cl-defmethod eieio-object-name-string ((this choice-program))
  "Return a string as a representation of the in memory instance of THIS."
  (->> (mapconcat #'(lambda (slot)
		      (let ((val (slot-value this slot)))
			(eieio-object-value-string this val)))
		  (eieio-object-value-slots this)
		  " ")
       (concat (cl-call-next-method this) " ")))

(cl-defmethod choice-program-exec-prog ((this choice-program) args
					&optional no-trim-p)
  "Execute the program defined in THIS with ARGS and return the output.
NO-TRIM-P, if non-nil, don't remove the terminating from the program's output."
  (with-output-to-string
    (with-current-buffer
	standard-output
      (let* ((exec-name (slot-value this 'program))
	     (prg (or (executable-find exec-name)
		      (error "No such executable found: %s" exec-name)))
	     (inter (and (slot-value this 'interpreter)
			 (executable-find (slot-value this 'interpreter)))))
	(when inter
	  (setq args (append (list prg) args))
	  (setq prg inter))
	(if choice-program-exec-debug-p
	    (choice-program-debug this (format "execution: %s %s"
					       (slot-value this 'program)
					       (mapconcat 'identity args " "))))
	(apply 'call-process prg nil t nil args)
	(if choice-program-exec-debug-p
	    (choice-program-debug this
				  (format "execution output: <%s>" (buffer-string))))
	(when (not no-trim-p)
	  (goto-char (point-max))
	  (if (and (not (bobp)) (looking-at "^$"))
	      (delete-char -1)))))))

(cl-defmethod choice-program-selections ((this choice-program))
  "Return a list of possibilities for mnemonics for this program.
THIS is the instance"
  (let ((output (choice-program-exec-prog this (slot-value this 'selection-args))))
    (split-string output "\n")))

(cl-defmethod choice-program-read-option ((this choice-program)
					  &optional default history)
  "Read one of the possible options from the list generated by the program.
THIS is the instance.
DEFAULT is used as the default input for the user input.
HISTORY is the history variable used for the user input."
  (let* ((prompt-history (or history (slot-value this 'prompt-history)))
	 (default (or default (and (boundp prompt-history)
				   (car (symbol-value prompt-history))))))
    (choice-program-complete (slot-value this 'choice-prompt)
			     (choice-program-selections this)
			     t t	    ; return-as-string require-match
			     nil	    ; initial
			     prompt-history ; history
			     default
			     nil	; allow-empty-p
			     nil	; no-initial
			     t)))       ; add-prompt-default

(cl-defmethod choice-program-command ((this choice-program)
				      choice &optional dryrun-p)
  "Create the command used to execute the command.
THIS is the instance.
CHOICE is the mnemonic choice, usually called the `action'.
DRYRUN-P logs like its doing something, but doesn't."
  (let ((cmd-lst (remove nil
			 (list
			  (and (slot-value this 'interpreter)
			       (executable-find (slot-value this 'interpreter)))
			  (and (slot-value this 'program)
			       (executable-find (slot-value this 'program)))
			  (if dryrun-p (slot-value this 'dryrun-switch-name))
			  (slot-value this 'verbose-switch-form)
			  (slot-value this 'choice-switch-name)
			  choice))))
    (mapconcat #'identity cmd-lst " ")))

(cl-defmethod choice-program-exec ((this choice-program) choice
				   &optional dryrun-p)
  "Run the program with a particular choice, which is prompted by the user.
This should be called by an interactive function, or by the function created by
the `choice-program-create-exec-function' method.
THIS is the instance.
CHOICE is the choice to use for the execution.
DRYRUN-P logs like its doing something, but doesn't."
  (let ((cmd (choice-program-command this choice dryrun-p))
	buf)
    (cl-flet ((prog-exec
	       ()
	       (compilation-start cmd t #'(lambda (_)
					    (slot-value this 'buffer-name)))))
      (if (slot-value this 'display-buffer)
	  (setq buf (prog-exec))
	(save-window-excursion
	  (setq buf (prog-exec)))))
    (message "Started: %s" cmd)
    buf))

(cl-defmethod choice-program-exec-string ((this choice-program) choice)
  "Run the program with CHOICE and return the output as a string.
This is meant to be used programmatically.
THIS is the instance."
  (shell-command-to-string (choice-program-command this choice nil)))

(defun choice-program-instances ()
  "Return all `choice-program' instances."
  (mapcar #'symbol-value
	  choice-program-instance-syms))

(defun choice-program-create-exec-function (instance-var)
  "Create functions for a `choice-program' instance.
INSTANCE-VAR is an instance of the `choice-program' eieio class.
NAME overrides the `:program' slot if given."
  (let* ((this (symbol-value instance-var))
	 (name (intern (choice-program-name this)))
	 (option-doc (format "\
CHOICE is given to the `%s' program with the `%s' option.
DRYRUN-P, if non-`nil' doesn't execute the command, but instead shows what it
would do if it were to be run.  This adds the `%s' option to the command line."
			     name
			     (slot-value this 'choice-switch-name)
			     (slot-value this 'dryrun-switch-name))))
    (let ((def
	   `(defun ,name (choice dryrun-p)
	      ,(if (slot-value this 'documentation)
		   (concat (slot-value this 'documentation) "\n\n" option-doc))
	      (interactive (list (choice-program-read-option ,instance-var)
				 current-prefix-arg))
	      (choice-program-exec ,instance-var choice dryrun-p))))
      (eval def))
    (add-to-list 'choice-program-instance-syms instance-var)))

(provide 'choice-program)

;;; choice-program.el ends here
