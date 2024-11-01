;;; ob-elm.el --- Org-babel functions for elm evaluation -*- lexical-binding: t; -*-

;; Copyright (C) 2019 Bonface M. K.

;; Author: Bonface M. K.
;; Keywords: languages, tools
;; Package-Version: 20200528.1857
;; Package-Commit: d3a9fbc2f56416894c9aed65ea9a20cc1d98f15d
;; Homepage: https://www.bonfacemunyoki.com
;; Version: 0.01
;; Package-Requires: ((emacs  "26.1") (org "9.3"))

;;; License:

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

;; Org-Babel support for evaluating Elm code

;;; System Requirements:

;; All you need is Elm >= 0.19 installed on your system

;;; Code:
(require 'ob)
(require 'org)
(require 'org-macs)
(require 'comint)

(declare-function elm-mode "ext:elm-mode" ())
(declare-function run-elm-interactive "ext:elm-mode" (&optional arg))

(defvar org-babel-default-header-args:elm
  '((:padlines . "no")))

(defvar org-babel-tangle-lang-exts)
(add-to-list 'org-babel-tangle-lang-exts '("elm" . "elm"))

(defvar org-babel-elm-eoe "\"org-babel-elm-eoe\"")

(defvar elm-prompt-regexp)

(defun org-babel-execute:elm (body params)
  "Execute a block of Elm code.
BODY is the elm block to execute.
PARAMS are the args passed to the src block header"
  (let* ((session (cdr (assq :session params)))
         (result-type (cdr (assq :result-type params)))
         (full-body (org-babel-expand-body:generic
		     body params
		     (org-babel-variable-assignments:elm params)))
         (session (org-babel-elm-initiate-session session params))
	 (comint-preoutput-filter-functions
	  (cons 'ansi-color-filter-apply comint-preoutput-filter-functions))
         (raw (org-babel-comint-with-output
		  (session org-babel-elm-eoe t full-body)
                (insert (org-trim full-body))
                (comint-send-input nil t)
                (insert org-babel-elm-eoe)
                (comint-send-input nil t)))
         (results (mapcar #'org-strip-quotes
			  (cdr (member (concat org-babel-elm-eoe " : String")
                                       (reverse (mapcar #'org-trim raw)))))))
    (let ((result (car results)))
      (org-babel-result-cond (cdr (assq :result-params params))
	result (org-babel-script-escape result)))

    (org-babel-reassemble-table
     (let ((result
            (pcase result-type
              (`output (mapconcat #'identity (reverse (cdr results)) "\n"))
              (`value (car results)))))
       (org-babel-result-cond (cdr (assq :result-params params))
	 result (org-babel-script-escape result)))
     (org-babel-pick-name (cdr (assq :colname-names params))
			  (cdr (assq :colname-names params)))
     (org-babel-pick-name (cdr (assq :rowname-names params))
			  (cdr (assq :rowname-names params))))))


(defun org-babel-variable-assignments:elm (params)
  "Return list of Elm statements assigning the block's PARAMS(variables)."
  (mapcar (lambda (pair)
	    (format "let %s = %s"
		    (car pair)
		    (org-babel-elm-var-to-elm (cdr pair))))
	  (org-babel--get-vars params)))

(defun org-babel-elm-initiate-session (&optional _session _params)
  "Initiate an Elm session.
If there is not a current inferior-process-buffer in SESSION
then create one.  Return the initialized session."
  (or (get-buffer "*elm*")
      (save-window-excursion (run-elm-interactive) (sleep-for 0.25) (current-buffer))))

(defun org-babel-load-session:elm (session body params)
  "Load BODY into SESSION."
  (save-window-excursion
    (let* ((buffer (org-babel-prep-session:elm session params))
           (load-file (concat (org-babel-temp-file "elm-load-") ".elm")))
      (with-temp-buffer
        (insert body)
        (write-file load-file)
        (elm-mode))
      buffer)))

(defun org-babel-prep-session:elm (session params)
  "Prepare SESSION according to the header arguments in PARAMS."
  (save-window-excursion
    (let ((buffer (org-babel-elm-initiate-session session)))
      (org-babel-comint-in-buffer buffer
      	(mapc (lambda (line)
		(insert line)
		(comint-send-input nil t))
	      (org-babel-variable-assignments:elm params)))
      (current-buffer))))

(defun org-babel-elm-var-to-elm (var)
  "Convert an elisp value VAR into an elm variable."
  (if (listp var)
      (concat "[" (mapconcat #'org-babel-elm-var-to-elm var ", ") "]")
    (format "%S" var)))

(defvar org-export-copy-to-kill-ring)

(declare-function org-export-to-file "ox"
		  (backend file
			   &optional async subtreep visible-only body-only
			   ext-plist post-process))

(provide 'ob-elm)

;;; ob-elm.el ends here
