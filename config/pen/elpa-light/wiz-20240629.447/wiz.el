;;; wiz.el --- Macros to simplify startup initialization  -*- lexical-binding: t; -*-

;; Copyright (C) 2024  USAMI Kenta

;; Author: USAMI Kenta <tadsan@zonu.me>
;; Created: 01 Dec 2023
;; Package-Version: 20240629.447
;; Package-Revision: 4f48029d39b8
;; Keywords: convenience, lisp
;; Homepage: https://github.com/zonuexe/emacs-wiz
;; Package-Requires: ((emacs "29.1") (exec-path-from-shell "2.1"))
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

;; Shorthand macro for feature configuration for init.el.

;;; Code:
(eval-when-compile
  (require 'pcase)
  (require 'macroexp)
  (require 'cl-lib))
(require 'wiz-kwd)
(require 'wiz-pkgs)
(require 'wiz-shortdoc)

(defvar wiz--disabled)
(defvar wiz--feature-name)
(defvar wiz--hook-names)

(defgroup wiz nil
  "Macros to simplify startup initialization."
  :group 'convenience)

(defvar wiz-keywords
  `((:package
     :assert-before wiz-kwd-package-assert-before
     :transform wiz-kwd-package-transform)
    (:load-if-exists
     :transform wiz-kwd-load-if-exists-transform)
    (:load
     :transform wiz-kwd-load-transform
     :assert-after wiz-kwd-load-assert-after)
    (:config
     :accept-multiple t
     :transform wiz-kwd-config-transform)
    (:hook-names
     :assert-before wiz-kwd-hook-names-assert-before
     :transform wiz-kwd-hook-names-transform)
    (:setup-hook
     :transform wiz-kwd-setup-hook-transform)
    (:init
     :accept-multiple t
     :transform wiz-kwd-init-transform)))

(defun wiz--assert-feature-spec (feature-name alist)
  "Assert wiz FEATURE-NAME feature spec ALIST."
  (cl-check-type feature-name symbol)
  (cl-loop for (key . _value) in alist
           for spec = (cdr-safe (assq key wiz-keywords))
           unless spec
           do (error "`%s' is unexpected keyword for wiz" key)))

(defun wiz--feature-process-1 (feature-name alist keyword spec)
  "Process wiz FEATURE-NAME feature SPEC for ALIST of KEYWORD."
  (cl-check-type feature-name symbol)
  (when-let (value (cdr-safe (assq keyword alist)))
    (let ((assert-before (or (plist-get spec :assert-before) #'always))
          (transform (plist-get spec :transform))
          (assert-after (or (plist-get spec :assert-after) #'always))
          transformed)
      (unless (plist-get spec :accept-multiple)
        (if (eq 1 (length value))
            (cl-callf car value)
          (error "%s expected only one argument %S" keyword value)))
      (funcall assert-before value)
      (setq transformed (funcall transform value))
      (funcall assert-after transformed)
      transformed)))

(defun wiz--feature-process (feature-name alist)
  "Process wiz FEATURE-NAME spec by ALIST."
  (let ((wiz--feature-name feature-name)
        wiz--disabled
        wiz--hook-names)
    (cl-loop for (keyword . spec) in wiz-keywords
             for transformed = (unless wiz--disabled
                                 (wiz--feature-process-1 feature-name alist keyword spec))
             if transformed
             append transformed)))

(defun wiz--form-to-alist (keywords form)
  "Convert plist-like FORM to alist by KEYWORDS."
  (let ((keyword (car form))
        (alist (mapcar (lambda (kwd) (list kwd)) keywords)))
    (unless (keywordp keyword)
      (error "First clause of wiz form must be :keyword in %S" keywords))
    (dolist (element form)
      (if (memq element keywords)
          (setq keyword element)
        (push element (alist-get keyword alist))))
    (mapcar (lambda (elt) (cons (car elt) (nreverse (cdr elt)))) alist)))

(defmacro wiz (feature-name &rest form)
  "Wiz for activate FEATURE-NAME with FORM."
  (declare (indent defun))
  (let* ((alist (if (null form) nil (wiz--form-to-alist (mapcar #'car wiz-keywords) form)))
         (delay-require (cl-union '(:load :load-if-exists :package) (mapcar #'car alist))))
    (wiz--assert-feature-spec feature-name alist)
    (unless (or delay-require (require feature-name nil t))
      (user-error "Wiz: feature `%s' is not a available feature name" feature-name))
    (cons 'prog1 (cons (list 'quote feature-name) (wiz--feature-process feature-name alist)))))

(defmacro wiz-map (list function)
  "Apply FUNCTION to each element of LIST.
This macro helps with expression expansion at compile time."
  (declare (debug (form body)) (indent 1))
  (let ((sequence (eval list)))
    `(prog1 (quote ,sequence)
       ,@(mapcar function sequence))))

(defmacro wiz-pkg (&rest form)
  "Install package FORM."
  (pcase form
    (`(,type . (,package . ,rest)) (wiz-pkgs type package rest))
    (`(,package) (wiz-pkgs wiz-pkgs-default-type package))
    (_ (error "Unexpected form: %S" form))))

(provide 'wiz)
;;; wiz.el ends here
