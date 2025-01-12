;;; el-secretario-function.el --- Source for just calling one function -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2021 Leo
;;
;; Author: Leo <https://github.com/Zetagon>
;; Maintainer: Leo <github@relevant-information.com>
;; Created: June 18, 2021
;; Modified: June 18, 2021
;; Version: 0.0.1
;; Keywords: convenience
;; Homepage: https://github.com/zetagon/el-secretario
;;
;; This file is not part of GNU Emacs.
;;
;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file LICENSE.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.
;;
;;; Commentary:
;;
;; Source for just calling one function
;;
;;; Code:
(require 'el-secretario)

;;;###autoload
(defclass el-secretario-function-source (el-secretario-source)
  ((func :initarg :func)))
(cl-defmethod el-secretario-source-activate ((obj el-secretario-function-source) &optional _backwards)
  "See `el-secretario-source.el'.
OBJ."
  (funcall (oref obj func)))

(cl-defmethod el-secretario-source-next-item ((obj el-secretario-function-source))
  "See `el-secretario-source.el'.
OBJ."
  (with-slots (current-item items-left items-done) obj
    (el-secretario--next-source)))

(cl-defmethod el-secretario-source-previous-item ((obj el-secretario-function-source))
  "See `el-secretario-source.el'.
OBJ."
  (with-slots (current-item items-left items-done) obj
    (el-secretario--previous-source)))

(provide 'el-secretario-function)
;;; el-secretario-function.el ends here
