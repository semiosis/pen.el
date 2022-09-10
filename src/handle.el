;;; handle.el --- A handle for major-mode generic functions. -*- lexical-binding: t; -*-

;; Copyright (C) 2019 Uros Perisic

;; Author: Uros Perisic
;; URL: https://gitlab.com/jjzmajic/handle
;;
;; Version: 0.1
;; Keywords: convenience
;; Package-Requires: ((emacs "25.1") (parent-mode "2.3"))

;; This program is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see
;; <https://www.gnu.org/licenses/>.

;; This file is not part of Emacs.

;;; Commentary:
;; A handle for major-mode generic functions.

;; `handle' provides generic functions that specialize on major modes
;; and intended purpose instead of arguments.  Similar functionality is
;; needed across programming languages such as:

;; - evaluating expressions
;; - starting repls
;; - finding documentation
;; - going to definition
;; - formatting code
;; - compiling code
;; - listing errors

;; But this functionality is performed by different callables across
;; major modes and often by multiple callables in the same
;; one.  `handle' groups them together so that they can be bound to a
;; single global `kbd', selected based on major mode, and run in
;; sequence until one succeeds.

;;; Code:
(require 'parent-mode)

(defgroup handle nil
  "A `handle' for major-mode generic functions."
  :link '(url-link :tag "gitlab"
          "https://gitlab.com/jjzmajic/handle")
  :prefix "handle-"
  :group 'tools)

(defcustom handle-keywords
  '(:evaluators :repls :docs :gotos
    :formatters :compilers :errors)
  "Package author's preffered `handle' keywords.
Users are strongly encouraged to override this vairable to suit
their needs, and to do so before the package is loaded."
  :type '(repeat symbol)
  :group 'handle)

(add-to-list 'handle-keywords :navtree)
(add-to-list 'handle-keywords :playground)
(add-to-list 'handle-keywords :godef)
(add-to-list 'handle-keywords :refactor)
(add-to-list 'handle-keywords :rename-symbol)
(add-to-list 'handle-keywords :complete)
(add-to-list 'handle-keywords :debug)
(add-to-list 'handle-keywords :path)
(add-to-list 'handle-keywords :run)
(add-to-list 'handle-keywords :compile)
(add-to-list 'handle-keywords :rc)
(add-to-list 'handle-keywords :jumpto)

;; Thing at point (builtin keyword)
;; (add-to-list 'handle-keywords :docs)
;; Not at point - manual entry of symbol with fuzzy finder
(add-to-list 'handle-keywords :docfun)        
;; Not at point - manual entry of symbol
(add-to-list 'handle-keywords :docsearch)

;; Project syms
(add-to-list 'handle-keywords :fz-sym)

(add-to-list 'handle-keywords :testall)
(add-to-list 'handle-keywords :navleft)
(add-to-list 'handle-keywords :navright)
(add-to-list 'handle-keywords :navup)
(add-to-list 'handle-keywords :navdown)
(add-to-list 'handle-keywords :callees)
(add-to-list 'handle-keywords :callers)
(add-to-list 'handle-keywords :showuml)
(add-to-list 'handle-keywords :nextdef)
(add-to-list 'handle-keywords :prevdef)
(add-to-list 'handle-keywords :nexterr)
(add-to-list 'handle-keywords :preverr)
(add-to-list 'handle-keywords :assignments)
(add-to-list 'handle-keywords :references)
(add-to-list 'handle-keywords :global-references)
(add-to-list 'handle-keywords :implementaions)
;; This may use GPT-2 at some stage
(add-to-list 'handle-keywords :spellcorrect)

(add-to-list 'handle-keywords :projectfile)
;; toggle between test case
(add-to-list 'handle-keywords :toggle-test)


(defcustom handle-nice-functions nil
  "List of commands that return t on success like good citizens.
If t, treat all commands passed to `handle' this way.  If nil,
treat none of them this way.  If a list, only treat listed
functions this way.  If a list starting with `not' treat all
commands except those listed this way."
  :group 'handle
  :type '(choice
          (const :tag "none" nil)
          (const :tag "all" t)
          (set :menu-tag "command specific" :tag "commands"
               :value (not)
               (const :tag "except" not)
               (repeat :inline t (symbol :tag "command")))))

(defvar handle--alist nil
  "`handle' dispatch alist.
Associates major modes with handlers.")

(defun handle--nice-function-p (function)
  "Check if FUNCTION returns t on success.
Consult `handle-nice-functions'."
  (and (pcase handle-nice-functions
         ('t t)
         (`(not . ,functions) (not (memq function functions)))
         (functions (memq function functions)))))

(defun handle--enlist (exp)
  "Return EXP wrapped in a list, or as-is if already a list."
  (declare (pure t) (side-effect-free t))
  (if (listp exp) exp (list exp)))

(defun handle--keyword-name (keyword)
  "Get KEYWORD name as a string."
  (substring (symbol-name keyword) 1))

(defalias 'handle
  (lambda (modes &rest args)
    (let ((modes (handle--enlist modes))
          (args (cl-loop
                 for arg in args collect
                 (if (keywordp arg) arg
                   (handle--enlist arg)))))
      (dolist (mode modes)
        (push `(,mode . ,args)
              handle--alist))))
  (format
   "Define handles for MODES through plist ARGS.
You can use any keyword from `handle-keywords', as long as you
define them before the package is loaded.

\(fn MODES &key %s)"
   (upcase (mapconcat #'handle--keyword-name handle-keywords " "))))

(defun handle--command-execute (commands arg)
  "Run COMMANDS with `command-execute'.
Try next command on `error', passing ARG as `prefix-arg'."
  (when commands
    (let ((first (car commands))
          (rest (cdr commands)))
      (condition-case nil
          (cond
           ((let ((prefix-arg arg))
              ;; (message "`handle' running `%s'." first)
              (command-execute first 'record)) t)
           ((not (handle--nice-function-p first)) t)
           (t (progn
                ;; (message "`handle' ran `%s' unsuccessfully." first)
                (handle--command-execute rest arg))))
        (error ;; (message "`handle' failed to run `%s'." first)
               (format "`handle' failed to run `%s'." first)
               (handle--command-execute rest arg))))))

(defun handle--get (mode keyword)
  "Return handlers for KEYWORD in MODE."
  (plist-get (alist-get mode handle--alist) keyword))

(defun handle--mode-execute (modes keyword keyword-name arg)
  "Handle KEYWORD for MODES, passing prefix ARG."
  (let ((first (car modes))
        (rest (cdr modes)))
    (when modes
      ;; (message "`handle' handling `%s' %s." first keyword-name)
      (unless (handle--command-execute (handle--get first keyword) arg)
        ;; (message "`handle' couldn't handle `%s' %s." first keyword-name)
        (handle--mode-execute rest keyword keyword-name arg)))))

(dolist (keyword handle-keywords)
  (let ((keyword-name (handle--keyword-name keyword)))
    (defalias (intern (format "handle-%s" keyword-name))
      (lambda (arg)
        (interactive "P")
        (handle--mode-execute
         (reverse (parent-mode-list major-mode))
         keyword keyword-name arg))
      (format "`handle' %s." keyword-name))))

(provide 'handle)
;;; handle.el ends here
