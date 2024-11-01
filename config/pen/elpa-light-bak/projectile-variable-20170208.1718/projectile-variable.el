;;; projectile-variable.el --- Store project local variables. -*- lexical-binding: t -*-

;; Copyright (C) 2016 USAMI Kenta

;; Author: USAMI Kenta <tadsan@zonu.me>
;; Created: 11 Sep 2016
;; Version: 0.0.2
;; Package-Version: 20170208.1718
;; Package-Commit: 8d348ac70bdd6dc320c13a12941b32b38140e264
;; Keywords: project, convenience
;; Homepage: https://github.com/zonuexe/projectile-variable
;; Package-Requires: ((emacs "24") (cl-lib "0.5"))

;; This file is NOT part of GNU Emacs.

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

;; Store project local variables (property) using Projectile and Symbol Plists.
;; The name of this package has projectile- in the prefix, but it can now be executed without depending on it.

;;
;; - https://github.com/bbatsov/projectile
;; - https://www.gnu.org/software/emacs/manual/html_node/elisp/Symbol-Plists.html

;; (projectile-variable-put 'foo-value 2) ;; Store property
;; (projectile-variable-get 'foo-value)   ;;=> 2
;;
;; (projectile-variable-plist)        ;; Return all project local property list
;; (projectile-variable-plist "foo-") ;; Return project local property list filterd by prefix "foo-"
;; (projectile-variable-alist)        ;; Return all project local properties as association list (alist)
;; (projectile-variable-alist "foo-") ;; Return project local properties alist filterd by prefix "foo-"

;;; Code:
(require 'cl-lib)
(require 'projectile nil t)

(defconst projectile-variable--prefix "projectile-variable--")

(defgroup projectile-variable nil
  "Store project local variables."
  :group 'lisp
  :prefix "projectile-variable-")

(defcustom projectile-variable-default-project-root-function #'projectile-project-root
  "Default function to retrieve root directory."
  :type 'function)

(defvar projectile-variable-project-root-function nil)

(defun projectile-variable--get-root ()
  "Return path to root directory the project."
  (if projectile-variable-project-root-function
      (funcall projectile-variable-project-root-function)
    (if (fboundp projectile-variable-default-project-root-function)
        (funcall projectile-variable-default-project-root-function)
      (error "Function `%s' is not exists" projectile-variable-default-project-root-function))))

(defun projectile-variable--make-symbol ()
  "Make symbol for save project local variable."
  (intern (concat projectile-variable--prefix (projectile-variable--get-root))))

(defun projectile-variable-plist (&optional prefix)
  "Return project local property list.  Fiter properties by prefix if PREFIX is not nil."
  (let ((plist (symbol-plist (projectile-variable--make-symbol)))
        filtered-plist)
    (if (null prefix)
        plist
      (cl-loop for (prop value) on plist by 'cddr
               if (string-prefix-p prefix (symbol-name prop))
               do (setq filtered-plist (plist-put filtered-plist prop value)))
      filtered-plist)))

(defun projectile-variable-alist (&optional prefix)
  "Return project local property list as alist.  Fiter properties by prefix if PREFIX is not nil."
  (let ((plist (symbol-plist (projectile-variable--make-symbol))))
    (cl-loop for (prop value) on plist by 'cddr
             if (or (null prefix) (string-prefix-p prefix (symbol-name prop)))
             collect (cons prop value))))

(defun projectile-variable-put (propname value)
  "Store the project local PROPNAME property with value VALUE."
  (put (projectile-variable--make-symbol) propname value))

(defun projectile-variable-get (propname)
  "Return the value of the project local PROPNAME property."
  (get (projectile-variable--make-symbol) propname))

(provide 'projectile-variable)
;;; projectile-variable.el ends here
