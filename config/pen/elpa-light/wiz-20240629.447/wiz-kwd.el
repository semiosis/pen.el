;;; wiz-kwd.el --- wiz keyword impletations          -*- lexical-binding: t; -*-

;; Copyright (C) 2024  USAMI Kenta

;; Author: USAMI Kenta <tadsan@zonu.me>
;; Created: 06 Jan 2024
;; Keywords: lisp
;; Homepage: https://github.com/zonuexe/emacs-wiz
;; License: GPL-3.0-or-later

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; wiz keyword impletations.

;;; Code:
(require 'pcase)
(require 'wiz-pkgs)
(eval-when-compile
  (defvar wiz--disabled)
  (defvar wiz--feature-name)
  (defvar wiz--hook-names))

;; Utilities
(defun wiz-kwd--parse-form (keyword form)
  "Return expressions from FORM in KEYWORD."
  (if (not (eq (caar form) 'lambda))
      form
    (cond
     ((not (eq 1 (length form))) (error "(%S form): Accept only one argument %S" keyword form))
     ((pcase-let ((`(lambda . (() . ,body)) (car form))) body))
     ((error "(%S form): %S i unexpected form" keyword form)))))

;; Keywords
(defun wiz-kwd-package-assert-before (expr)
  "Assert EXPR for wiz :package keyword."
  (unless (or (stringp expr) (symbolp expr) (eq expr t) (listp expr))
    (error "(:package form): `form' is invalid")))

(defun wiz-kwd-package-transform (expr)
  "Transform EXPR for wiz :package keyword."
  (macroexp-unprogn
   (pcase expr
     (`(,type . (,package . ,rest)) (wiz-pkgs type package rest))
     ((pred stringp) (wiz-pkgs wiz-pkgs-default-type expr))
     (_ (if (not (eq expr t))
            (error "Unexpected form: %S" expr)
          (wiz-pkgs wiz-pkgs-default-type wiz--feature-name)
          (unless (require wiz--feature-name nil t)
            (user-error "Wiz: feature `%s' is not a available feature name" wiz--feature-name)))))))

(defun wiz-kwd-load-if-exists-transform (expr)
  "Transform EXPR for wiz :load-if-exists keyword."
  (let* ((file (eval expr))
         (sexp `(when (file-exists-p ,file) (load ,file))))
    (prog1 (list sexp)
      (when (eval sexp)
        (unless (require wiz--feature-name nil t)
          (user-error "Wiz: feature %s is not a available feature name" wiz--feature-name))))))

(defun wiz-kwd-load-transform (expr)
  "Transform EXPR for wiz :load keyword."
  (let ((sexp `(load ,(eval expr))))
    (prog1 (list sexp)
      (when (eval sexp)
        (unless (require wiz--feature-name nil t)
          (user-error "Wiz: feature %s is not a available feature name" wiz--feature-name))))))

(defun wiz-kwd-load-assert-after (exprs)
  "Assert EXPRS postcondition for wiz :load keyword."
  (unless (stringp (nth 1 (car exprs)))
    (error "(:load file): `file' must be evalute as string %S" (car exprs))))

(defun wiz-kwd-config-transform (form)
  "Transform FORM for wiz :config keyword."
  (list
   (cons 'with-eval-after-load
         (cons (list 'quote wiz--feature-name)
               (wiz-kwd--parse-form :config form)))))

(defun wiz-kwd-hook-names-assert-before (names)
  "Assert NAMES precondition for wiz :hook-names keyword."
  (unless (and (listp names) (cl-every #'symbolp names))
    (error "(:hook-names %S): `names' must be list of symbols" names))
  (unless (cl-every #'boundp names)
    (error "(:hook-names %S): `names' must be existing hook name" names)))

(defun wiz-kwd-hook-names-transform (names)
  "Transform NAMES for wiz :hook-names keyword."
  (prog1 nil
    (setq wiz--hook-names names)))

(defun wiz-kwd-setup-hook-transform (expr)
  "Transform EXPR form wiz :setup-hook keyword."
  (let ((setup-hook-name (nth 1 expr))
        (target-hook-names
         (or wiz--hook-names
             (let ((name (symbol-name wiz--feature-name)))
               (list (intern (format "%s-hook"
                                     (if (string-match-p "-mode" name)
                                         name
                                       (concat name "-mode")))))))))
    `(,@(mapcar (lambda (target-hook-name)
                  `(add-hook ,(list 'quote target-hook-name)
                             ,(list 'function setup-hook-name)))
                target-hook-names)
      ,expr)))

(defun wiz-kwd-init-transform (form)
  "Transform FORM for wiz :init keyword."
  (list
   (cons 'prog1 (cons nil (wiz-kwd--parse-form :init form)))))

(provide 'wiz-kwd)
;;; wiz-kwd.el ends here
