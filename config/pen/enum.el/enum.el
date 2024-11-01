;;; enum.el --- Enums in Emacs Lisp -*- lexical-binding: t -*-

;; Author: Edward Minnix <egregius313@gmail.com>
;; URL: https://gitlab.com/emacsos/enum.el
;; Keywords: convenience
;; Version: 0.0.1
;; Package-Requires: ((emacs "24.5"))

;; This file is NOT part of GNU Emacs.

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

;; # Emacs Lisp basic implementation of enums using alists.

;;; Code:

(eval-when-compile
  (require 'cl-lib))


(defun enum-get (enum name)
  "Get the value in ENUM corresponding to NAME."
  (alist-get name enum))



(defun enum-find-name (enum value)
  "Get the name in the ENUM corresponding to VALUE."
  (cl-loop for (name . val) in enum
		   when (eq val value)
		   return name))


(defun enum-find-all-names (enum value)
  "Get all properties of the value which match according to XOR."
  (if (zerop value)
	  (enum-find-value enum 0)
	(cl-loop for (name . val) in enum
			 when (eq val (logand val value))
			 collect name)))


(defun enum-reduce (enum names)
  "Reduce a list of names into a single integral value."
  (cl-loop with value = 0
		   for name in names
		   for val = (enum-get enum name)
		   when val do (setq value (logior value val))
		   finally return value))


(defmacro defenum (enum-name values &optional doc)
  (let* ((name-length (cl-loop for (name val doc) in values
							   maximize (length (symbol-name name))))
		 (fmt (format "%%-%ds %%s\n" name-length))
		 (name-val-pairs (cl-loop for (name val doc) in values
								  collect `(,name . ,val))))
	`(defconst ,enum-name
	   ',name-val-pairs
	   ,(concat (or (and doc (concat doc "\n")) "")
				(apply #'concat (cl-loop for (name val doc) in values
									   collect (format fmt name doc)))))))


(provide 'enum)
