;;; wiz-key.el --- Macros to simplify personal key bindings -*- lexical-binding: t; -*-

;; Copyright (C) 2024  USAMI Kenta

;; Author: USAMI Kenta <tadsan@zonu.me>
;; Created: 01 Jan 2024
;; Keywords: convenience, lisp
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

;; Shorthand macro for key bindings for init.el.

;;; Code:
(eval-when-compile
  (require 'cl-lib))

(cl-defmacro wiz-keys (keys-alist &key map)
  "Bind multiple KEYS-ALIST with MAP at once."
  (let ((keymap (or map 'global-map)))
    `(prog1 (quote (,keys-alist :map ,keymap))
       ,@(mapcar (lambda (pair)
                   (cl-destructuring-bind (key . def) pair
                     `(define-key ,keymap
                                  ,(if (stringp key) (kbd key) key)
                                  ,(if (and (listp def))
                                       def
                                     (list 'quote def)))))
                 keys-alist))))

(provide 'wiz-key)
;;; wiz-key.el ends here
