;;; helm-cider.el --- Helm interface to CIDER        -*- lexical-binding: t; -*-

;; Copyright (C) 2016-2022 Tianxiang Xiong

;; Author: Tianxiang Xiong <tianxiang.xiong@gmail.com>

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Common utility functions that don't belong anywhere else.

;;; Code:

(require 'cider)
(require 'cl-lib)
(require 'subr-x)


;;;; Utilities

(defun helm-cider--regexp-symbol (string)
  "Create a regexp that matches STRING as a symbol.

If STRING starts with a character that `helm-major-mode' does not
consider to be in the word or symbol syntax class, do not include
a symbol-start \(\\_<\); otherwise, the regexp wouldn't
match. Same for symbol-end."
  (if (string-empty-p string)
      ""
    (let* ((fchar (aref string 0))
           (lchar (aref string (1- (length string))))
           (symbol-start (with-syntax-table helm-major-mode-syntax-table
                           (if (or (= ?w (char-syntax fchar))
                                   (= ?_ (char-syntax fchar)))
                               "\\_<"
                             "")))
           (symbol-end (with-syntax-table helm-major-mode-syntax-table
                         (if (or (= ?w (char-syntax lchar))
                                 (= ?_ (char-syntax lchar)))
                             "\\_>"
                           ""))))
      (concat symbol-start (regexp-quote string) symbol-end))))

(defun helm-cider--source-by-name (name &optional sources)
  "Get a Helm source in SOURCES by NAME.

Default value of SOURCES is `helm-sources'."
  (car (cl-member-if (lambda (source)
                       (string= name (assoc-default 'name source)))
                     (or sources helm-sources))))

(defun helm-cider--symbol-name (qualified-name)
  "Get the name portion of the fully qualified symbol name
QUALIFIED-NAME (e.g. \"reduce\" for \"clojure.core/reduce\").

Defaults to QUALIFIED-NAME if name is NOT qualified (as is the
case for special forms)."
  (if (string-match-p "/" qualified-name)
      (cadr (split-string qualified-name "/"))
    qualified-name))

(defun helm-cider--symbol-ns (qualified-name)
  "Get the namespace portion of the fully qualified symbol name
QUALIFIED-NAME (e.g. \"clojure.core\" for
\"clojure.core/reduce\").

Defaults to the `clojure.core' ns if name is NOT qualified (as is
the case for special forms)."
  (if (string-match-p "/" qualified-name)
      (car (split-string qualified-name "/"))
    "clojure.core"))

(defun helm-cider--find-ns (ns)
  (cider-find-ns nil ns))

(defun helm-cider--find-var (var)
  (cider-find-var nil var))

(defun helm-cider--symbol-face (type)
  "Face for symbol of TYPE.

TYPE values include \"function\", \"macro\", etc."
  (pcase type
    ("function" 'font-lock-function-name-face)
    ("macro" 'font-lock-keyword-face)
    ("special-form" 'font-lock-keyword-face)
    ("variable" 'font-lock-variable-name-face)))

(defun helm-cider--doc-lookup-persistent-action (candidate)
  "Persistent action calling `cider-doc-lookup' on CANDIDATE."
  (cider-ensure-connected)
  (cider-ensure-op-supported "info")
  (if (and (helm-attr 'doc-lookup-p)
           (string= candidate (helm-attr 'current-candidate)))
      (progn
        (kill-buffer cider-doc-buffer)
        (helm-attrset 'doc-lookup-p nil))
    (cider-doc-lookup candidate)
    (helm-attrset 'doc-lookup-p t))
  (helm-attrset 'current-candidate candidate))

(defmacro wrap-helm-cider-action (f &optional ops)
  "Wrap Helm CIDER actions.

- Ensure that CIDER is connected
- Ensure ops are supported"
  `(lambda (&rest args)
     (cider-ensure-connected)
     ,@(mapcar (lambda (op) `(cider-ensure-op-supported ,op)) ops)
     (apply #',f args)))

(defvar helm-cider--doc-actions
  (helm-make-actions
   "CiderDoc" (wrap-helm-cider-action cider-doc-lookup)
   "Find definition" (wrap-helm-cider-action helm-cider--find-var)
   "Find on Grimoire" (wrap-helm-cider-action cider-grimoire-lookup))
  "Actions for looking up symbol's documentation.")


(provide 'helm-cider-util)

;;; helm-cider-util.el ends here
