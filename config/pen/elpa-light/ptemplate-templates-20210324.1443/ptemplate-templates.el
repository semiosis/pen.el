;;; ptemplate-templates.el --- Official templates -*- lexical-binding: t -*-

;; Copyright (C) 2020  Nikita Bloshchanevich

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

;; Author: Nikita Bloshchanevich <nikblos@outlook.com>
;; URL: https://github.com/nbfalcon/ptemplate-templates
;; Package-Requires: ((emacs "25.1") (ptemplate "2.0.0"))
;; Version: 0.1.1

;;; Commentary:

;; This package provides the official collection of `ptemplate' templates and a
;; convenient loader plugin for them. The templates here can be enabled by
;; simply turning on `ptemplate-templates-mode'. If the templates are no longer
;; wanted, `ptemplate-templates-mode' can also be turned off like any other
;; minor-mode.
;;
;; The following configuration snippet will correctly configure
;; `ptemplate-templates:'
;; (eval-after-load 'ptemplate '(ptemplate-templates-mode 1))
;;
;; Currently, only a few project templates are provided; other templates are
;; coming soon. New ones can be requested by opening an issue on github.

;;; Code:

(require 'cl-lib)                       ; `cl-delete', `cl-loop'

(defconst ptemplate-templates--rsc-dir
  (file-name-directory
   (cond (load-in-progress load-file-name)
         ((and (boundp 'byte-compile-current-file) byte-compile-current-file))
         (t (buffer-file-name))))
  "Absolute path to `ptemplate-templates'.")

(defun ptemplate-templates--rsc (path)
  "Expand PATH relative to `ptemplate-templates--rsc-dir'.
The result is an absolute path to the resource"
  (expand-file-name (concat (file-name-as-directory "rsc") path)
                    ptemplate-templates--rsc-dir))

(defun ptemplate-templates--remove-from-list
    (list-var element &optional compare-fn)
  "The inverse of `add-to-list'.
Remove all occurrences of ELEMENT in LIST-VAR. COMPARE-FN is used
to test for equality between elements.

Unless otherwise stated, the behaviour of this function is
identical to that of `add-to-list'."
  (set list-var (cl-delete element (symbol-value list-var) :test compare-fn)))

(defconst ptemplate-templates-templates
  '((ptemplate-project-template-dirs "project-templates"))
  "Alist (VAR . RSC-DIR...) listing this package's templates.
VAR is a template directory list variable, like
`ptemplate-project-template-dirs', while RSC-DIR... is a list of
\"rsc/\" relative paths to template directories.

These templates are registered and unregistered in
`ptemplate-templates-mode'.")

;;;###autoload
(define-minor-mode ptemplate-templates-mode
  "If on, the templates in this repository will be enabled.
Toggles whether the templates in this repository should be made
available to `ptemplate-new-project' and
`ptemplate-expand-template'."
  :global t
  :group 'ptemplate-templates
  :init-value nil
  :lighter nil
  (defvar ptemplate-project-template-dirs)
  (cond
   (ptemplate-templates-mode
    (require 'ptemplate)
    (cl-loop for (var . rsc-dirs) in ptemplate-templates-templates do
             (mapc (apply-partially #'add-to-list var)
                   (mapcar #'ptemplate-templates--rsc rsc-dirs))))
   (t
    (cl-loop for (var . rsc-dirs) in ptemplate-templates-templates do
             (mapc (apply-partially
                    #'ptemplate-templates--remove-from-list var)
                   (mapcar #'ptemplate-templates--rsc rsc-dirs))))))

;;; customization

(defcustom ptemplate-templates-repository-url-format
  (format "https://github.com/%s/%%s" (user-real-login-name))
  "A `format' string for github repositories.
This string will be `format'ted with one argument, the name of a
project, which should yield a browser-visitable URL pointing to
the (possibly future) project's repository.

The Emacs-plugin template uses this to derive the URL: attribute,
for example.

Given that the default is probably wrong, this should be
customized."
  :type 'string
  :group 'ptemplate-templates)

;;; template utilities

(defun ptemplate-templates--project-name ()
  "Return the name of the project being generated.
Useful in project templates."
  (defvar ptemplate-target-directory)
  (file-name-nondirectory (directory-file-name ptemplate-target-directory)))

(provide 'ptemplate-templates)
;;; ptemplate-templates.el ends here
