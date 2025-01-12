;;; comint-intercept.el --- Intercept input in comint-mode -*- lexical-binding: t -*-

;; Copyright (C) 2017 "Huang, Ying" <huang.ying.caritas@gmail.com>

;; Author: "Huang, Ying" <huang.ying.caritas@gmail.com>
;; Maintainer: "Huang, Ying" <huang.ying.caritas@gmail.com>
;; URL: https://github.com/hying-caritas/comint-intercept
;; Package-Version: 20241021.629
;; Package-Revision: 99b17be632ff
;; Package-Type: simple
;; Keywords: processes, terminals
;; Package-Requires: ((emacs "24.3") (vterm "20240102.1640"))

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; Intercept the input in comint-mode.  This can be used to run eshell
;; command, or run some command in a terminal buffer from the command
;; line in shell buffer.  That is, this is to combine the best part of
;; shell, eshell and term mode.  For example, you can run eshell
;; `grep' in the shell buffer, or when you run `top' in the shell
;; buffer, a terminal buffer is poped to run it.  SSH is supported to
;; run command remotely.

;;; Code:

(require 'cl-lib)
(require 'comint)
(require 'eshell)
(require 'term)
(require 'vterm)
(require 'tramp)

(defvar-local comint-intercept--origin-sender nil)
(defvar-local comint-intercept--last-prompt nil)

(defgroup comint-intercept nil
  "Intercept input in comint mode buffer"
  :group 'tools
  :link '(url-link :tag "Github" "https://github.com/hying-caritas/comint-intercept"))

(defcustom comint-intercept-eshell-prefix "e"
  "Prefix to run the remaining of the line as an eshell command."
  :group 'comint-intercept
  :type 'string)

(defcustom comint-intercept-eshell-commands
  '("find-file" "find-file-other-window" "view-file" "view-file-other-window"
    "dired" "dired-other-window" "find-dired"
    "man" "info" "apropos-command"
    "diff" "grep" "compile" "magit" "proced")
  "Command to be run as the eshell command."
  :group 'comint-intercept
  :type '(repeat string))

(defcustom comint-intercept-term-prefix "t"
  "Prefix to run the remaining of the line in a terminal buffer."
  :group 'comint-intercept
  :type '(repeat string))

(defcustom comint-intercept-vterm-prefix "v"
  "Prefix to run the remaining of the line in a vterm buffer."
  :group 'comint-intercept
  :type '(repeat string))

(defcustom comint-intercept-term-commands
  '("top" "less")
  "Command to be run in a terminal buffer."
  :group 'comint-intercept
  :type '(repeat string))

(defcustom comint-intercept-pattern-actions nil
  "Alist maps input pattern (regexp) to action to take (function).

The input string will be fed to the action function."
  :group 'comint-intercept
  :type '(alist :key-type (string :tag "Pattern")
		:value-type (function :tag "Action")))

(defcustom comint-intercept-term-runner "bash -c"
  "Command line to run the line in the terminal buffer."
  :group 'comint-intercept
  :type 'string)

(defcustom comint-intercept-prompt-regexp "[#>$] $"
  "The regular expression that the prompt string should match to intercept."
  :group 'comint-intercept
  :type 'string)

(cl-defun comint-intercept--save-last-prompt (_str)
  (setf comint-intercept--last-prompt comint-last-prompt))

(cl-defun comint-intercept--check-prompt ()
  (and comint-intercept--last-prompt
       (string-match-p comint-intercept-prompt-regexp
		       (buffer-substring-no-properties
			(car comint-intercept--last-prompt)
			(cdr comint-intercept--last-prompt)))))

(cl-defun comint-intercept--commands-pattern (commands)
  (concat "^" (regexp-opt commands) "\\(?:;\\|[[:space:]]\\|$\\)"))

(cl-defun comint-intercept--prefix-pattern (prefix)
  (concat "^" (regexp-quote prefix) "[[:space:]]"))

(cl-defmacro comint-intercept--memorizeq1 (func base-func)
  (let ((param (cl-gensym))
	(saved-param (cl-gensym))
	(saved-result (cl-gensym)))
    `(let ((,saved-param nil)
	   (,saved-result nil))
       (cl-defun ,func (,param)
	 (when (not (eq ,saved-param ,param))
	   (setf ,saved-result (,base-func ,param)
		 ,saved-param ,param))
	 ,saved-result))))

(comint-intercept--memorizeq1 comint-intercept--eshell-commands-pattern
			      comint-intercept--commands-pattern)

(comint-intercept--memorizeq1 comint-intercept--term-commands-pattern
			      comint-intercept--commands-pattern)

(comint-intercept--memorizeq1 comint-intercept--eshell-prefix-pattern
			      comint-intercept--prefix-pattern)

(comint-intercept--memorizeq1 comint-intercept--term-prefix-pattern
			      comint-intercept--prefix-pattern)

(comint-intercept--memorizeq1 comint-intercept--vterm-prefix-pattern
			      comint-intercept--prefix-pattern)

(cl-defun comint-intercept-term-command (cmdline)
  "Run `cmdline' in a new created terminal buffer"
  (let* ((qcmdline (shell-quote-argument cmdline))
	 (full-cmdline
	  (if (file-remote-p default-directory)
	      (with-parsed-tramp-file-name default-directory tgt
		(format "ssh -t %s %s %s%s"
			(if tgt-user
			    (format "%s@%s" tgt-user tgt-host)
			  tgt-host)
			comint-intercept-term-runner
			;; Double quote because this
			;; will be interpreted twice
			(shell-quote-argument
			 (shell-quote-argument
			  (format "cd %s;" tgt-localname)))
			(shell-quote-argument qcmdline)))
	    (format "%s %s" comint-intercept-term-runner
		    qcmdline))))
    (ansi-term "/bin/sh" (car (split-string cmdline)))
    (term-send-raw-string (format "exec %s\n" full-cmdline))))

(cl-defun comint-intercept-vterm-command (cmdline)
  "Run `cmdline' in a new created vterm buffer"
  (let* ((qcmdline (shell-quote-argument cmdline))
	 (full-cmdline
	  (if (file-remote-p default-directory)
	      (with-parsed-tramp-file-name default-directory tgt
		(format "ssh -t %s %s %s%s"
			(if tgt-user
			    (format "%s@%s" tgt-user tgt-host)
			  tgt-host)
			comint-intercept-term-runner
			;; Double quote because this
			;; will be interpreted twice
			(shell-quote-argument
			 (shell-quote-argument
			  (format "cd %s;" tgt-localname)))
			(shell-quote-argument qcmdline)))
	    (format "%s %s" comint-intercept-term-runner
		    qcmdline))))
    (vterm (car (split-string cmdline)))
    (vterm-send-string (format "exec %s\n" full-cmdline))))

(cl-defun comint-intercept--send-input (proc str)
  (let ((not-origin
	 (and (comint-intercept--check-prompt)
	      (save-excursion
		(cond
		 ((string-match
		   (comint-intercept--eshell-prefix-pattern
		    comint-intercept-eshell-prefix)
		   str)
		  (eshell-command
		   (substring str (1+ (length comint-intercept-eshell-prefix))))
		  t)
		 ((string-match
		   (comint-intercept--eshell-commands-pattern
		    comint-intercept-eshell-commands)
		   str)
		  (eshell-command str)
		  t)
		 ((string-match
		   (comint-intercept--term-prefix-pattern
		    comint-intercept-term-prefix)
		   str)
		  (comint-intercept-term-command
		   (substring str (1+ (length comint-intercept-term-prefix))))
		  t)
		 ((string-match
		   (comint-intercept--term-commands-pattern
		    comint-intercept-term-commands)
		   str)
		  (comint-intercept-term-command str)
		  t)
		 ((string-match
		   (comint-intercept--vterm-prefix-pattern
		    comint-intercept-vterm-prefix)
		   str)
		  (comint-intercept-vterm-command
		   (substring str (1+ (length comint-intercept-term-prefix))))
		  t)

		 ((cl-loop
		   for (pat . action) in comint-intercept-pattern-actions
		   when (string-match pat str)
		   do (progn
			(funcall action str)))))))))
    (funcall comint-intercept--origin-sender proc
	     (if not-origin "" str))))

(cl-defun comint-intercept--enable (enable)
  (interactive)
  (cond
   ((and enable (not comint-intercept--origin-sender))
    (setf comint-intercept--origin-sender comint-input-sender
	  comint-input-sender #'comint-intercept--send-input)
    (add-hook 'comint-input-filter-functions
	      'comint-intercept--save-last-prompt nil t))
   ((and (not enable) comint-intercept--origin-sender)
    (setf comint-input-sender comint-intercept--origin-sender
	  comint-intercept--origin-sender nil)
    (remove-hook 'comint-input-filter-functions
		 'comint-intercept--save-last-prompt t))))

;;;###autoload
(define-minor-mode comint-intercept-mode
  "Intercept comint input and send it to other buffers or run some functions."
  :lighter " CI"
  :group comint-intercept
  (comint-intercept--enable comint-intercept-mode))

(provide 'comint-intercept)

;;; comint-intercept.el ends here
