;;; ebdb-html.el --- EBDB HTML integration        -*- lexical-binding: t; -*-

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

;; This file contains code for "doing HTML things" with EBDB records.
;; Right now that only means formatters for exporting EBDB records as
;; HTML.

;;; Code:

(require 'ebdb-format)

(defgroup ebdb-html nil
  "Customization options for EBDB with HTML."
  :group 'ebdb)

(defclass ebdb-html-formatter (ebdb-formatter)
  ((post-format-function :initform #'html-mode))
  :abstract t
  :documentation "Formatter responsible for HTML-specific field
  formatting.")

(defclass ebdb-html-formatter-html5 (ebdb-html-formatter
				     ebdb-formatter-freeform)
  ((header :initform '((ebdb-record-person ebdb-field-notes))))
  :documentation "HTML formatter for \"block-style\" HTML
  formatting.")

(cl-defmethod ebdb-fmt-record :around ((_fmt ebdb-html-formatter-html5)
				       (_rec ebdb-record))
  (concat
   "<article class=\"ebdb-record\">\n"
   (cl-call-next-method)
   "\n</article>\n"))

(cl-defmethod ebdb-fmt-record-header ((fmt ebdb-html-formatter-html5)
				      (rec ebdb-record)
				      header-fields)
  (concat
   "<header>\n"
   (format "<h1>%s</h1>\n" (ebdb-record-name-string rec))
   (mapconcat
    (pcase-lambda ((map style inst _class))
      (format "<p>%s</p>" (mapconcat (lambda (f) (ebdb-fmt-field fmt f style rec)) inst ", ")))
    header-fields
    "\n")
   "</header>\n"))

(cl-defmethod ebdb-fmt-compose-fields ((fmt ebdb-html-formatter-html5)
				       (rec ebdb-record)
				       &optional field-list _depth)
  "This particular implementation uses description lists (<dl>)."
  (when field-list
    (concat
     "<dl>\n"
     (mapconcat
      (pcase-lambda ((map style inst class))
	(concat
	 (format "<dt>%s</dt>" (ebdb-fmt-field-label
				fmt
				(if (= 1 (length inst))
				    (car inst)
				  class)
				style
				rec))
	 (mapconcat
	  (lambda (f)
	    (format "<dd>%s</dd>" (ebdb-fmt-field fmt f style rec)))
	  inst
	  "\n")))
      field-list "\n")
     "</dl>\n")))

(cl-defmethod ebdb-fmt-field ((_fmt ebdb-html-formatter)
			      (field ebdb-field-mail)
			      _style
			      (_rec ebdb-record))
  (with-slots (mail aka) field
    (format "<a href=\"mailto:%s\">%s</a>" mail (or aka mail))))

(defclass ebdb-html-formatter-tabular (ebdb-formatter-tabular
				       ebdb-html-formatter)
  ;; We put the <tr> elements in manually.
  ((record-separator :initform "")
   (field-separator :initform "</td><td>")))

(defcustom ebdb-html-default-formatter-tabular
  (make-instance 'ebdb-html-formatter-tabular
		 :label "html table"
		 :fields '(mail-primary))
  "The default HTML table formatter."
  :type 'ebdb-html-formatter-tabular)

(defcustom ebdb-html-default-formatter-html5
  (make-instance 'ebdb-html-formatter-html5
		 :label "html5 block"
		 :include '(mail-primary ebdb-field-phone ebdb-field-address ebdb-field-notes))
  "The default HTML5 block formatter."
  :type 'ebdb-html-formatter-html5)

(cl-defmethod ebdb-fmt-header ((fmt ebdb-html-formatter-tabular)
			       _records)
  (with-slots (fields) fmt
    (concat
     "<table>\n<tr><th>Name</th><th>"
     (mapconcat
      (lambda (f)
	(cond
	 ((stringp f) f)
	 ((or (class-p f)
	      (eieio-object-p f))
	  (ebdb-fmt-field-label fmt f 'normal))
	 ((symbolp f)
	  (symbol-name f))))
      fields
      "</th><th>")
     "</th></tr>\n")))

(cl-defmethod ebdb-fmt-footer ((_fmt ebdb-html-formatter-tabular)
			      _records)
  "\n</table>")

(cl-defmethod ebdb-fmt-record ((_fmt ebdb-html-formatter-tabular)
			       (_rec ebdb-record))
  "Wrap records in <tr> elements.
This is done in lieu of a `record-separator' slot, since it's
around each record, not between records."
  (concat "<tr>"
	  (cl-call-next-method)
	  "</tr>"))

(cl-defmethod ebdb-fmt-compose-fields :around ((_fmt ebdb-html-formatter-tabular)
					       (_rec ebdb-record)
					       &optional _field-list _depth)
  (concat "<td>"
	  (cl-call-next-method)
	  "</td>"))

(provide 'ebdb-html)
;;; ebdb-html.el ends here
