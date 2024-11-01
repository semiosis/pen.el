;;; company-erlang.el --- company backend based on ivy-erlang-complete -*- lexical-binding: t -*-
;;
;; Filename: company-erlang.el
;; Description: Context sensitive erlang completion package with company as
;; frontend.
;; Author: Sergey Kostyaev <feo.me@ya.ru>
;; Version: 1.0.0
;; Package-Version: 20170123.538
;; Package-Commit: bc0524a16f17b66c7397690e4ca0e004f09ea6c5
;; Package-Requires: ((emacs "24.4") (ivy-erlang-complete "0.1") (company "0.9.2"))
;; Keywords: tools
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;;; Commentary:
;; 
;; `company-erlang' is company backend for erlang based on ivy-erlang-complete.
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or (at
;; your option) any later version.
;; 
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;; 
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;;; Code:

(require 'company)
(require 'company-template)
(require 'ivy-erlang-complete)

;;;###autoload
(defun company-erlang (command &optional arg &rest ignored)
  "Company backend for erlang completions with company COMMAND and optional ARG as arguments another one will be IGNORED."
  (interactive (list 'interactive))
  (cl-case command
    (interactive (company-begin-backend 'company-erlang))
    (prefix (or (ivy-erlang-complete-thing-at-point) (company-erlang-record-at-point) 'stop))
    (candidates
     (cl-remove-if-not
                 (lambda (c) (string-prefix-p ivy-erlang-complete-predicate c))
                 (company-erlang--candidates arg)))
    (annotation (get-text-property 0 'meta arg))
    (duplicates t)
    (sorted t)
    (require-match 'never)
    (post-completion (company-template-c-like-templatify arg))))

;;;###autoload
(defun company-erlang-init ()
  "Init company erlang backend."
  (set (make-local-variable 'company-backends) '(company-erlang))
  (company-mode t))

(defun company-erlang-record-at-point ()
  "Return the erlang record at point, or nil if none is found."
  (interactive)
  (when (thing-at-point-looking-at
         (format "#\\(%s\\)\\([\.]%s\\)?" erlang-atom-regexp erlang-atom-regexp)
         500)
    (match-string-no-properties 0)))

(defun company-erlang--candidates (thing)
  "Completion candidates for THING."
  (cond
   ((and thing (string-match "#?\\([^\:]+\\)\:\\([^\:]*\\)" thing))
    (let ((erl-prefix (substring thing (match-beginning 1) (match-end 1))))
      (setq ivy-erlang-complete-candidates
            (if (ivy-erlang-complete--is-type-at-point)
                (company-erlang--transform-arity
                 (ivy-erlang-complete--exported-types erl-prefix))
              (company-erlang--transform-arity
               (ivy-erlang-complete--find-functions erl-prefix))))
      (setq ivy-erlang-complete-predicate
            (string-remove-prefix (concat erl-prefix ":") thing))))
   ((ivy-erlang-complete-export-at-point)
    (setq ivy-erlang-complete-predicate thing)
    (setq ivy-erlang-complete--local-functions nil)
    (setq ivy-erlang-complete-candidates
          (cl-remove-if
           (lambda (el)
             (member el (ivy-erlang-complete--get-export)))
           (ivy-erlang-complete--find-local-functions))))
   ((ivy-erlang-complete--is-guard-at-point)
    (setq ivy-erlang-complete-predicate thing)
    (setq ivy-erlang-complete-candidates
          (append (cl-mapcar (lambda (g) (format "%s(_)" g))
                             erlang-guards)
                  erlang-operators)))
   ((ivy-erlang-complete-record-at-point)
    (setq ivy-erlang-complete-candidates
          (append
           (company-erlang--get-record-fields
            (buffer-substring-no-properties
             (match-beginning 1) (match-end 1)))
           (ivy-erlang-complete--find-local-vars)
           (company-erlang--transform-arity
            (ivy-erlang-complete--find-local-functions))
           (ivy-erlang-complete--get-record-names)
           (ivy-erlang-complete--find-modules)
           ivy-erlang-complete-macros))
    (setq ivy-erlang-complete-predicate
          (let ((rec (ivy-erlang-complete-record-at-point)))
            (cond ((string-suffix-p "}" rec) thing)
                  ((string-suffix-p "." rec) "")
                  (t rec))))
    (if (string-suffix-p "." (ivy-erlang-complete-record-at-point))
        (setq ivy-erlang-complete-candidates
              (company-erlang--get-record-fields
               (match-string-no-properties 1)))))
   ((company-erlang-record-at-point)
    (match-string-no-properties 1)
    (setq ivy-erlang-complete-predicate
          (string-remove-prefix "." (match-string-no-properties 3)))
    (setq ivy-erlang-complete-candidates
          (company-erlang--get-record-fields
           (match-string-no-properties 1))))
   ((ivy-erlang-complete--is-type-at-point)
    (setq ivy-erlang-complete-predicate thing)
    (setq ivy-erlang-complete-candidates
          (append
           (cl-mapcar (lambda (s) (concat s "()")) erlang-predefined-types)
           (company-erlang--transform-arity
            (ivy-erlang-complete--get-defined-types))
           (ivy-erlang-complete--find-modules))))
   (t
    (setq ivy-erlang-complete-candidates
          (append
           (ivy-erlang-complete--find-local-vars)
           (company-erlang--transform-arity
            (ivy-erlang-complete--find-local-functions))
           (ivy-erlang-complete--get-record-names)
           (ivy-erlang-complete--find-modules)
           ivy-erlang-complete-macros))
    (setq ivy-erlang-complete-predicate thing)))
  (setq company-prefix ivy-erlang-complete-predicate)
  ivy-erlang-complete-candidates)

(defun company-erlang--transform-arity (functions)
  "Prepare FUNCTIONS to insert with company."
  (cl-remove-if
   #'string-empty-p
   (cl-mapcar
    (lambda (s) (if (and (stringp s) (string-match-p "/" s))
                    (let ((splitted (split-string s "/")))
                      (format "%s(%s)" (car splitted)
                              (string-join
                               (make-list
                                (string-to-number
                                 (cadr splitted)) "_") ", ")))
                  ""))
    functions)))

(defun company-erlang--get-record-fields (record)
  "Return list of RECORD fields."
  (if (not ivy-erlang-complete-records)
      (progn
        (ivy-erlang-complete-reparse)
        (message "Please wait for record parsing")
        nil)
    (cl-mapcar
     (lambda (s)
       (propertize
        (car s)
        'meta
        (if (cdr s)
            (let ((type
                   (concat " :: " (string-join (ivy-erlang-complete--flatten
                                                   (cdr s))  " | "))))
              type))))
     (gethash record ivy-erlang-complete-records))))

(provide 'company-erlang)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; company-erlang.el ends here
