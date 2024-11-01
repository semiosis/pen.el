;;; ob-clojurescript.el --- org-babel functions for ClojureScript evaluation -*- lexical-binding: t; -*-

;; Author: Larry Staton Jr.
;; Maintainer: Larry Staton Jr.
;; Created: 10 March 2018
;; Keywords: literate programming, reproducible research
;; Package-Version: 20180406.1828
;; Package-Commit: 17ee1558aa94c7b0246fd03f684884122806cfe7
;; Homepage: https://gitlab.com/statonjr/ob-clojurescript
;; Package-Requires: ((emacs "24.4") (org "9.0"))

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Org-babel support for evaluating ClojureScript code.

;; Requirements:

;; - [[https://github.com/anmonteiro/lumo][lumo]]
;; - clojurescript-mode

;;; License:

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.
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

;;; Code:
(require 'ob)

(defvar org-babel-tangle-lang-exts)
(add-to-list 'org-babel-tangle-lang-exts '("clojurescript" . "cljs"))

(defvar org-babel-clojurescript-command (executable-find "lumo")
  "The command to use to compile and run your ClojureScript code.")

(defvar org-babel-default-header-args:clojurescript '())
(defvar org-babel-header-args:clojurescript '((package . :any)))

(defun ob-clojurescript-escape-quotes (str-val)
  "Escape quotes for STR-VAL so that Lumo can understand."
  (replace-regexp-in-string "\"" "\\\"" str-val 'FIXEDCASE 'LITERAL))

(defun org-babel-expand-body:clojurescript (body params)
  "Expand BODY according to PARAMS, return the expanded body."
  (let* ((vars (org-babel--get-vars params))
         (result-params (cdr (assq :result-params params)))
         (print-level nil) (print-length nil)
         (body (ob-clojurescript-escape-quotes
                (org-trim
                 (if (null vars)
                     (org-trim body)
                   (concat "(let ["
                           (mapconcat
                            (lambda (var)
                              (format "%S (quote %S)" (car var) (cdr var)))
                            vars "\n      ")
                           "]\n" body ")"))))))
    (if (or (member "code" result-params)
            (member "pp" result-params))
        (format "(print (do %s))" body)
      body)))

(defun org-babel-execute:clojurescript (body params)
  "Execute a block of ClojureScript code in BODY with Babel using PARAMS."
  (let ((expanded (org-babel-expand-body:clojurescript body params))
        result)
    (setq result
          (org-babel-trim
           (shell-command-to-string
            (concat org-babel-clojurescript-command " -e \"" expanded "\""))))
    (org-babel-result-cond (cdr (assoc :result-params params))
      result
      (condition-case nil (org-babel-script-escape result)
        (error result)))))

(provide 'ob-clojurescript)

;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; ob-clojurescript.el ends here
