;;; ebdb-latex.el --- LaTex formatting routines for EBDB  -*- lexical-binding: t; -*-

;; Copyright (C) 2018-2023  Free Software Foundation, Inc.

;; Author: Eric Abrahamsen <eric@ericabrahamsen.net>
;; Maintainer: Eric Abrahamsen <eric@ericabrahamsen.net>

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

;; This file contains routines for formatting EBDB records as LaTeX.

;;; Code:

(require 'ebdb-format)

(defgroup ebdb-latex nil
  "Options for EBDB and LaTeX."
  :group 'ebdb)

(defclass ebdb-latex-formatter (ebdb-formatter)
  ((post-format-function :initform #'latex-mode))
  :abstract t
  :documentation "")

(cl-defmethod ebdb-fmt-field ((_fmt ebdb-latex-formatter)
			      (field ebdb-field-mail)
			      _style
			      (_rec ebdb-record))
  (with-slots (mail aka) field
    (format "\\href{mailto:%s}{%s}" mail (or aka mail))))

(defclass ebdb-latex-formatter-tabular (ebdb-latex-formatter
					ebdb-formatter-tabular)
  ((record-separator :initform " \\\\\n")
   (field-separator :initform " & ")
   (table-environment :initform "tabular")
   (table-spec
    :type (or string null)
    :initarg :table-spec
    :initform nil)))

(cl-defmethod ebdb-fmt-field ((_fmt ebdb-latex-formatter-tabular)
			      (_field ebdb-field)
			      _style
			      (_rec ebdb-record))
  "Escape column separators in field strings."
  (replace-regexp-in-string "\\([^\\]\\)&" "\\1\\\\&"
			    (cl-call-next-method)))

(cl-defmethod ebdb-fmt-header ((fmt ebdb-latex-formatter-tabular)
			       _recs)
  (with-slots (table-environment table-spec) fmt
    (concat (format "\\begin{%s}" table-environment)
	    (when table-spec
	      (format "%s" table-spec))
	    "\n")))

(cl-defmethod ebdb-fmt-footer ((fmt ebdb-latex-formatter-tabular)
			       _recs)
  (with-slots (table-environment) fmt
    (format "\\end{%s}" table-environment)))

(defcustom ebdb-latex-default-tabular-formatter
  (make-instance 'ebdb-latex-formatter-tabular
		 :label "latex table"
		 :fields '(mail-primary))
  "Default LaTeX tabular formatter."
  :type 'ebdb-formatter-tabular)

(provide 'ebdb-latex)
;;; ebdb-latex.el ends here
