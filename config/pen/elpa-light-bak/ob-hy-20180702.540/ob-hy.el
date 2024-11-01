;;; ob-hy.el --- org-babel functions for Hy-lang evaluation

;; Copyright (C) 2017 Brantou

;; Author: Brantou <brantou89@gmail.com>
;; URL: https://github.com/brantou/ob-hy
;; Keywords: hy, literate programming, reproducible research
;; Homepage: http://orgmode.org
;; Version:  1.0.1
;; Package-Requires: ((emacs "24.4"))

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

;; This file is not part of GNU Emacs.

;;; Commentary:
;;
;; Org-Babel support for evaluating hy-lang code.
;;
;; It was created based on the usage of ob-template.
;;

;;; Requirements:
;;
;; - hy :: https://hy-lang.org/
;;
;; - hy-mode :: Can be installed through from ELPA, or from
;;   https://raw.githubusercontent.com/hylang/hy-mode/master/hy-mode.el
;;

;;; TODO
;;
;; - Provide better error feedback.
;;

;;; Code:
(require 'ob)
(require 'ob-eval)
(require 'ob-tangle)

(defvar org-babel-tangle-lang-exts)
(add-to-list 'org-babel-tangle-lang-exts '("hy" . "hy"))

(defvar org-babel-default-header-args:hy '()
  "Default header arguments for hy code blocks.")

(defcustom org-babel-hy-command "hy"
  "Name of command used to evaluate hy blocks."
  :group 'org-babel
  :version "24.4"
  :package-version '(Org . "8.0")
  :type 'string)

(defcustom org-babel-hy-nil-to 'hline
  "Replace nil in hy tables with this before returning."
  :group 'org-babel
  :version "24.4"
  :package-version '(Org . "8.0")
  :type 'symbol)

(defvar org-babel-hy-eoe-indicator ":org_babel_hy_eoe"
  "A string to indicate that evaluation has completed.")

(defconst org-babel-hy-wrapper-method
  "
(defn main []
  %s)

(with [f (open \"%s\" \"w\")] (.write f (str (main))))")

(defconst org-babel-hy-pp-wrapper-method
  "
(import pprint)
(defn main []
  %s)

(with [f (open \"%s\" \"w\")] (.write f (.pformat pprint (main))))")

(defun org-babel-expand-body:hy (body params)
  "Expand BODY according to PARAMS, return the expanded body."
  (let* ((vars (org-babel-hy-get-vars params))
         (body (if (null vars) (org-trim body)
                 (concat
                  (mapconcat
                   (lambda (var)
                     (format "(setv %S (quote %S))" (car var) (cdr var)))
                   vars "\n")
                  "\n" body))))
    body))

(defun org-babel-execute:hy (body params)
  "Execute a block of Hy code with org-babel.
 This function is called by `org-babel-execute-src-block'"
  (message "executing Hy source code block")
  (let* ((org-babel-hy-command
          (or (cdr (assq :hy params))
              org-babel-hy-command))
         (session (org-babel-hy-initiate-session
                   (cdr (assq :session params))))
         (result-params (cdr (assq :result-params params)))
         (result-type (cdr (assq :result-type params)))
         (full-body (org-babel-expand-body:hy body params))
         (result (org-babel-hy-evaluate
                  session full-body result-type result-params)))
    (org-babel-reassemble-table
     result
     (org-babel-pick-name (cdr (assq :colname-names params))
                          (cdr (assq :colnames params)))
     (org-babel-pick-name (cdr (assq :rowname-names params))
                          (cdr (assq :rownames params))))))

(defun org-babel-hy-evaluate
    (session body &optional result-type result-params)
  "Evaluate BODY as Hy code."
  (if session
      (org-babel-hy-evaluate-session
       session body result-type result-params)
    (org-babel-hy-evaluate-external-process
     body result-type result-params)))

(defun org-babel-hy-evaluate-external-process
    (body &optional result-type result-params)
  "Evaluate BODY in external hy process.
If RESULT-TYPE equals `output' then return standard output as a
string.  If RESULT-TYPE equals `value' then return the value of the
last statement in BODY, as elisp."
  (let ((result
         (pcase result-type
           (`output (org-babel-eval
                     (format "%s -c '%s'" org-babel-hy-command body) ""))
           (`value (let ((tmp-file (org-babel-temp-file "hy-")))
                     (org-babel-eval
                      (format
                       "%s -c '%s'"
                       org-babel-hy-command
                       (format
                        (if (member "pp" result-params)
                            org-babel-hy-pp-wrapper-method
                          org-babel-hy-wrapper-method)
                        body
                        (org-babel-process-file-name tmp-file 'noquote))) "")
                     (org-babel-eval-read-file tmp-file))))))
    (org-babel-result-cond result-params
      result
      (org-babel-hy-table-or-string result))))

(defun org-babel-hy-evaluate-session
    (session body &optional result-type result-params)
  "Pass BODY to the Hy process in SESSION.
If RESULT-TYPE equals `output' then return standard output as a
string.  If RESULT-TYPE equals `value' then return the value of the
last statement in BODY, as elisp."
  (let* ((send-wait (lambda () (comint-send-input nil t)))
         (dump-last-value
          (lambda
            (tmp-file pp)
            (mapc
             (lambda
               (statement)
               (insert (org-babel-chomp statement)) (funcall send-wait))
             (if pp
                 (list
                  "(import pprint)"
                  (format "(with [f (open \"%s\" \"w\")] (.write f (.pformat pprint _)))"
                          (org-babel-process-file-name tmp-file 'noquote)))
               (list (format "(with [f (open \"%s\" \"w\")] (.write f (str _)))"
                             (org-babel-process-file-name tmp-file 'noquote)))))))
         (input-body (lambda (body)
                       (mapc
                        (lambda (line)
                          (insert (org-babel-chomp line)) (funcall send-wait))
                        (list body))))
         (results
          (pcase result-type
            (`output
             (replace-regexp-in-string "=> " ""
              (mapconcat
              #'org-trim
              (butlast
               (org-babel-comint-with-output
                   (session org-babel-hy-eoe-indicator t body)
                 (funcall input-body body)
                 (insert (format "(import builtins)\n(builtins.print \"%s\")"
                                       org-babel-hy-eoe-indicator))
                 (funcall send-wait))
               2) "\n")))
            (`value
             (let ((tmp-file (org-babel-temp-file "hy-")))
               (org-babel-comint-with-output
                   (session org-babel-hy-eoe-indicator t body)
                 (let ((comint-process-echoes nil))
                   (funcall send-wait)
                   (funcall input-body body)
                   (funcall dump-last-value tmp-file
                            (member "pp" result-params))
                   (insert (format "(import builtins)\n(builtins.print \"%s\")"
                                   org-babel-hy-eoe-indicator))
                   (funcall send-wait) (funcall send-wait)))
               (org-babel-eval-read-file tmp-file))))))
    (unless (string= (substring org-babel-hy-eoe-indicator 1 -1) results)
      (org-babel-result-cond result-params
        (org-trim results)
        (org-babel-hy-table-or-string (org-trim results))))))

(defun org-babel-prep-session:hy (session params)
  "Prepare SESSION according to the header arguments in PARAMS.
VARS contains resolved variable references"
  (let* ((session (org-babel-hy-initiate-session session))
         (var-lines
          (org-babel-variable-assignments:hy params)))
    (org-babel-comint-in-buffer session
      (mapc (lambda (var)
              (end-of-line 1) (insert var) (comint-send-input)
              (org-babel-comint-wait-for-output session)) var-lines))
    session))

(defun org-babel-load-session:hy (session body params)
  "Load BODY into SESSION."
  (save-window-excursion
    (let ((buffer (org-babel-prep-session:hy session params)))
      (with-current-buffer buffer
        (goto-char (process-mark (get-buffer-process (current-buffer))))
        (insert (org-babel-chomp body)))
      buffer)))

;; helper functions

(defun org-babel-hy-get-vars (params)
  "org-babel-get-header was removed in org version 8.3.3"
  (if (fboundp 'org-babel-get-header)
      (mapcar #'cdr (org-babel-get-header params :var))
    (org-babel--get-vars params)))

(defun org-babel-variable-assignments:hy (params)
  "Return list of hy statements assigning the block's variables."
  (mapcar
   (lambda (pair)
     (format "%s=%s"
             (car pair)
             (org-babel-hy-var-to-hy (cdr pair))))
   (org-babel-hy-get-vars params)))

(defun org-babel-hy-var-to-hy (var)
  "Convert VAR into a hy variable.
Convert an elisp value into a string of hy source code
specifying a variable of the same value."
  (if (listp var)
      (concat "[" (mapconcat #'org-babel-hy-var-to-hy var ", ") "]")
    (if (eq var 'hline)
        org-babel-hy-hline-to
      (format "%S" var))))

(defun org-babel-hy-table-or-string (results)
  "Convert RESULTS into an appropriate elisp value.
If RESULTS look like a table, then convert them into an
Emacs-lisp table, otherwise return the results as a string."
  (let ((res (org-babel-script-escape results)))
    (if (listp res)
        (mapcar (lambda (el) (if (not el)
                                 org-babel-hy-nil-to el))
                res)
      res)))

(defun org-babel-hy-read (results)
  "Convert RESULTS into an appropriate elisp value.
If RESULTS look like a table, then convert them into an
Emacs-lisp table, otherwise return the results as a string."
  (org-babel-read
   (if (and (stringp results)
            (string-prefix-p "[" results)
            (string-suffix-p "]" results))
       (org-babel-read
        (concat "'"
                (replace-regexp-in-string
                 "\\[" "(" (replace-regexp-in-string
                            "\\]" ")" (replace-regexp-in-string
                                       ",[[:space:]]" " "
                                       (replace-regexp-in-string
                                        "'" "\"" results))))))
     results)))

;; session helper functions

(defvar org-babel-hy-buffers '((:default . "*Hy*")))

(defun org-babel-hy-session-buffer (session)
  "Return the buffer associated with SESSION."
  (cdr (assoc session org-babel-hy-buffers)))

(defun org-babel-hy-with-earmuffs (session)
  (let ((name (if (stringp session) session (format "%s" session))))
    (if (and (string= "*" (substring name 0 1))
             (string= "*" (substring name (- (length name) 1))))
        name
      (format "*%s*" name))))

(defun org-babel-hy-without-earmuffs (session)
  (let ((name (if (stringp session) session (format "%s" session))))
    (if (and (string= "*" (substring name 0 1))
             (string= "*" (substring name (- (length name) 1))))
        (substring name 1 (- (length name) 1))
      name)))

(defvar hy-default-interpreter)
(defvar hy-which-bufname)
(defvar hy-shell-buffer-name)
(defun org-babel-hy-initiate-session-by-key (&optional session)
  "Initiate a hy session.
If there is not a current inferior-process-buffer in SESSION
then create.  Return the initialized session."
  (if (and (featurep 'hy-mode) (fboundp 'run-python))
      (require 'hy-mode)
    (error "No function available for running an inferior Hy"))
  (save-window-excursion
    (let* ((session (if session (intern session) :default))
           (hy-buffer (org-babel-hy-session-buffer session))
           (cmd org-babel-hy-command))
      (unless hy-buffer
        (setq hy-buffer (org-babel-hy-with-earmuffs session)))
      (let ((hy-shell-buffer-name
             (org-babel-hy-without-earmuffs hy-buffer)))
        (run-hy cmd))
      (setq org-babel-hy-buffers
            (cons (cons session hy-buffer)
                  (assq-delete-all session org-babel-hy-buffers)))
      session)))

(defun org-babel-hy-initiate-session (&optional session _params)
  "Create a session named SESSION according to PARAMS."
  (unless (string= session "none")
    (org-babel-hy-session-buffer
     (org-babel-hy-initiate-session-by-key session))))

(provide 'ob-hy)
;;; ob-hy.el ends here
