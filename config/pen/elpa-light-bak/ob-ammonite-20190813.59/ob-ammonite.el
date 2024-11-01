;;; ob-ammonite.el --- org-babel for scala evaluation in Ammonite.

;; Author: zwild <judezhao@outlook.com>
;; Created: 2018-12-26T22:56:51+08:00
;; URL: https://github.com/zwild/ob-ammonite
;; Package-Version: 20190813.59
;; Package-Commit: 39937dff395e70aff76a4224fa49cf2ec6c57cca
;; Package-Requires: ((s "1.12.0") (ammonite-term-repl "0.1") (xterm-color "1.7"))
;; Version: 0.2
;; Keywords: tools, ammnite, org-mode, scala, org-babel

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
;; org-babel for scala evaluation in `ammonite-term-repl'.

;;; Code:
(require 'ob)
(require 'ob-comint)
(require 'ammonite-term-repl)
(require 's)
(require 'xterm-color)

(add-to-list 'org-babel-tangle-lang-exts '("amm" . "scala"))
(add-to-list 'org-src-lang-modes '("amm" . scala))

(defcustom ob-ammonite-prompt-str "@"
  "Regex for ammonite prompt."
  :type 'string
  :group 'org-babel)

(defvar ob-ammonite-debug-p nil
  "The variable to control the debug message.")

(defvar ob-ammonite-eval-result ""
  "The result of the evaluation.")

(defvar ob-ammonite-eval-needle ";;;;;;;;;"
  "The mark to tell whether the evaluation is done.")

(defun ob-ammonite-expand-body (body)
  "Expand the BODY to evaluate."
  (format "{\n %s\n%s }" body ob-ammonite-eval-needle))

(defun ob-ammonite--trim-result (str)
  "Trim the result string.
Argument STR the result evaluated."
  (s-trim
   (s-chop-suffix
    ob-ammonite-prompt-str
    (s-chop-prefix
     "}"
     (s-trim
      (s-join "" (cdr (s-split ob-ammonite-eval-needle str))))))))

(defun org-babel-execute:amm (body params)
  "Execute the scala code in BODY using PARAMS in org-babel.
This function is called by `org-babel-execute-src-block'
Argument BODY the body to evaluate.
Argument PARAMS the header arguments."
  (unless (comint-check-proc ammonite-term-repl-buffer-name)
    (ignore-errors
      (kill-buffer ammonite-term-repl-buffer-name))
    (save-window-excursion
      (ammonite-term-repl)))

  (setq ob-ammonite-eval-result "")

  (set-process-filter
   (get-buffer-process ammonite-term-repl-buffer-name)
   (lambda (process str)
     (term-emulate-terminal process str)
     (let ((str (s-replace "" "" (substring-no-properties (xterm-color-filter str)))))
       (when ob-ammonite-debug-p (print str))
       (setq ob-ammonite-eval-result (concat ob-ammonite-eval-result str)))))

  (let ((full-body (ob-ammonite-expand-body body)))
    (comint-send-string ammonite-term-repl-buffer-name full-body)
    (comint-send-string ammonite-term-repl-buffer-name "\n"))

  (while (not (s-ends-with? ob-ammonite-prompt-str (s-trim-right ob-ammonite-eval-result)))
    (sit-for 0.5))
  (sit-for 0.2)

  (when ob-ammonite-debug-p (print (concat "#### " ob-ammonite-eval-result)))
  (ob-ammonite--trim-result ob-ammonite-eval-result))

(provide 'ob-ammonite)

;;; ob-ammonite.el ends here
