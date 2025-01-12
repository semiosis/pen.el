;;; choice-program-complete.el --- Utility functions for user input selection  -*- lexical-binding: t; -*-

;; Copyright (C) 2015 - 2020 Paul Landes

;; Author: Paul Landes
;; Maintainer: Paul Landes
;; Keywords: internal convenience
;; URL: https://github.com/plandes/choice-program
;; Package-Version: 0
;; Package-Requires: ((emacs "26"))

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

;;; This library has utility functions to help with user input selection.

;;; Code:

(require 'cl-lib)

;;;###autoload
(defun choice-program-complete-default-prompt (prompt &optional
						      default history)
  "Format a prompt with optional default formatting.
PROMPT is the text used in the header minibuffer.
DEFAULT is the default input if given.
HISTORY is a quoted variable that has the history for this prompt history."
  (let ((def (or default (car history))))
    (format "%s%s"
	    prompt (if def (format " (default %s): " def) ": "))))

;;;###autoload
(defun choice-program-complete (prompt choices &optional return-as-string
				       require-match initial-contents
				       history default allow-empty-p
				       no-initial-contents-on-singleton-p
				       add-prompt-default-p)
  "Read from the user a choice.

See `completing-read'.

PROMPT is a string to prompt with; normally it ends in a colon and a space.

CHOICES the list of things to auto-complete and allow the user to choose
  from.  Each element is analyzed independently If each element is not a
  string, it is written with `prin1-to-string'.

RETURN-AS-STRING is non-nil, return the symbol as a string
  (i.e. `symbol-name).

If REQUIRE-MATCH is non-nil, the user is not allowed to exit unless
  the input is (or completes to) an element of TABLE or is null.
  If it is also not t, Return does not exit if it does non-null completion.

If INITIAL-CONTENTS is non-nil, insert it in the minibuffer initially.
  If it is (STRING . POSITION), the initial input
  is STRING, but point is placed POSITION characters into the string.

HISTORY, if non-nil, specifies a history list
  and optionally the initial position in the list.
  It can be a symbol, which is the history list variable to use,
  or it can be a cons cell (HISTVAR . HISTPOS).
  In that case, HISTVAR is the history list variable to use,
  and HISTPOS is the initial position (the position in the list
  which INITIAL-CONTENTS corresponds to).
  If HISTORY is t, no history will be recorded.
  Positions are counted starting from 1 at the beginning of the list.

DEFAULT, if non-nil, will be returned when the user enters an empty
  string.

ALLOW-EMPTY-P, if non-nil, allow no data (empty string) to be returned.  In
  this case, nil is returned, otherwise, an error is raised.

NO-INITIAL-CONTENTS-ON-SINGLETON-P, if non-nil, don't populate with initialial
  contents when there is only one choice to pick from.

ADD-PROMPT-DEFAULT-P, if non-nil, munge the prompt using the default notation
  \(ie `<Prompt> (default CHOICE)')."
  (let* ((choice-alist-p (listp (car choices)))
	 (choice-options (if choice-alist-p (mapcar #'car choices) choices))
	 (sym-list (mapcar #'(lambda (arg)
			       (cl-typecase arg
				 (string arg)
				 (t (prin1-to-string arg))))
			   choice-options))
	 (initial (if initial-contents
		      (if (symbolp initial-contents)
			  (symbol-name initial-contents)
			initial-contents)))
	 (def (if default
		  (cl-typecase default
		    (nil nil)
		    (symbol default (symbol-name default))
		    (string default))))
	 res-str)
    (when (not no-initial-contents-on-singleton-p)
      (if (and (null initial) (= 1 (length sym-list)))
	  (setq initial (car sym-list)))
      (if (and (null initial)
	       ;; cases where a default is given and the user can't then just
	       ;; press return; instead, the user has to clear the minibuffer
	       ;; contents first
	       (null def))
	  (setq initial "")))
    (if add-prompt-default-p
	(setq prompt (choice-program-complete-default-prompt prompt def)))
    (cl-block wh
      (while t
	(setq res-str (completing-read prompt sym-list nil
				       require-match initial
				       history def))
	(if (or allow-empty-p (> (length res-str) 0))
	    (cl-return-from wh)
	  (ding)
	  (message (substitute-command-keys
		    "Input required or type `\\[keyboard-quit]' to quit"))
	  (sit-for 5))))
    (when (> (length res-str) 0)
      (if choice-alist-p
	  (let ((choices (if (symbolp (caar choices))
			     (mapcar #'(lambda (arg)
					 (cons (symbol-name (car arg))
					       (cdr arg)))
				     choices)
			   choices)))
	    (setq res-str (cdr (assoc res-str choices))))
	(setq res-str
	      (if return-as-string
		  res-str
		(intern res-str)))))
    res-str))

(provide 'choice-program-complete)

;;; choice-program-complete.el ends here
