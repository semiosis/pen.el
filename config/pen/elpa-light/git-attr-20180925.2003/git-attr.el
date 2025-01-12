;;; git-attr.el --- Git attributes of buffer file  -*- lexical-binding: t; -*-

;; Copyright (C) 2018  Arne Jørgensen
;; URL: https://github.com/arnested/emacs-git-attr
;; Version: 0.0.3
;; Package-Requires: ((emacs "24.3"))

;; Author: Arne Jørgensen <arne@arnested.dk>
;; Keywords: vc

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

;; This tool will let you use git attributes
;; (https://git-scm.com/docs/gitattributes) in Emacs buffers.

;; In example the following will get the value of a `foo' git
;; attribute for the file associated with the current buffer:

;;   (git-attr-get "foo")

;; The `git-attr-get' function will return

;;   * t for git attributes with the value `set'
;;   * nil for git attributes with the value `unset'
;;   * 'undecided for git attributes that are `unspecified'
;;   * and the value if the git attribute is set to a value

;;; Code:

(defvar-local git-attr 'undecided "Git attributes for current buffer.")

(defun git-attr-check ()
  "Get git attributes for current buffer file."
  (let ((file buffer-file-name)
        (git (executable-find "git")))
    (when (and file
               git
               (file-exists-p file))
      (let ((attr-list (split-string (with-output-to-string
                                       (with-current-buffer standard-output
                                         (call-process git nil (list t nil) nil "check-attr" "-z" "-a" file)
                                         )
                                       ) "\000" t))
            result)
        (while attr-list
          (push `(,(car (cdr attr-list)) . ,(car (cdr (cdr attr-list)))) result)
          (setq attr-list (cdr (cdr (cdr attr-list)))))
        result))))

;;;###autoload
(defun git-attr ()
  "Get git attributes for current buffer file and set in buffer local variable `git-attr'."
  (interactive)
  (if (eq git-attr 'undecided)
      (setq git-attr (git-attr-check))
    git-attr))

(defun git-attr-raw (attr)
  "Get the raw git attribute named ATTR for the file in current buffer.

This is the raw value as returned from `git check-attr -a' (if specified).

You probably want to use `git-attr-get' instead."
  (cdr (assoc attr (git-attr))))

;;;###autoload
(defun git-attr-get (attr)
  "Get the git attribute named ATTR for the file in current buffer.

 * t for git attributes with the value `set'
 * nil for git attributes with the value `unset'
 * 'undecided for git attributes that are `unspecified'
 * and the value if the git attribute is set to a value"
  (let ((value (git-attr-raw attr)))
    (cond ((string= value "set") t)
          ((string= value "unset") nil)
          ((eq nil value) 'undecided)
          (t value))))

(provide 'git-attr)
;;; git-attr.el ends here
