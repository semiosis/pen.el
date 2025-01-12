;;; ebdb-org.el --- Org mode integration for EBDB    -*- lexical-binding: t; -*-

;; Copyright (C) 2016-2023  Free Software Foundation, Inc.

;; Author: Eric Abrahamsen <eric@ericabrahamsen.net>
;; Keywords:

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

;; Org mode integration for EBDB.  At present this just defines a link
;; type; at some point we'll reproduce the Agenda anniversary
;; mechanisms from org-bbdb.el.

;; EBDB links can come in several varieties.  A plain string is
;; matched against record names in the database.  Otherwise, the
;; string can be prefixed with a field type, to search only on those
;; field values.  The prefix is separated with a forward slash.
;; Examples:

;; 1. "ebdb:uuid/af1373d6-4ba1-46a7-aa4b-845db01bc2ab" (link to unique
;; record)

;; 2. "ebdb:mail/google.com" (all records with google.com email
;; addresses).  These field name "shorthands" include "uuid", "mail",
;; "phone", "address", "notes", and "tags" (this last for the
;; `ebdb-org-field-tags' class defined in this file).

;; 3. "ebdb:ebdb-field-foobar/baz" (search on a particular field
;; class)

;; Valid prefixes include all the values accepted by
;; `ebdb-record-field', as well as the names of field classes.

;; When calling `org-store-link' on a contact, a "ebdb:uuid/" style
;; link is created by default.

;; This file also defines a "tags" field class, for tagging EBDB
;; contacts with Org tags.

;;; Code:

(require 'ebdb-com)
(require 'ebdb-format)
(require 'org)
(require 'org-agenda)

(defgroup ebdb-org nil
  "Custom group for EBDB Org options."
  :group 'ebdb)

(if (fboundp 'org-link-set-parameters)
    (org-link-set-parameters "ebdb"
			     :follow 'ebdb-org-open
			     :complete (lambda ()
					 (format
					  "ebdb:uuid/%s"
					  (ebdb-record-uuid (ebdb-prompt-for-record (ebdb-records)))))
			     :store 'ebdb-org-store-link
			     :export 'ebdb-org-export)
  (with-no-warnings ;; I know it's obsolete.
    (org-add-link-type "ebdb" #'ebdb-org-open #'ebdb-org-export)
    (add-hook 'org-store-link-functions #'ebdb-org-store-link)))

;; TODO: Put a custom keymap on the links (or else expand
;; `ebdb-org-open') so that users can choose what to do with the
;; linked record: display, email, etc.

(defun ebdb-org-store-link ()
  "Store a link to an EBDB contact."
  (when (eq major-mode 'ebdb-mode)
    (let* ((rec (ebdb-current-record))
	   (uuid (ebdb-record-uuid rec))
	   (name (ebdb-record-name-string rec))
	   (link (format "ebdb:uuid/%s" uuid)))
      (with-no-warnings
	(funcall (if (fboundp 'org-link-store-props)
		     #'org-link-store-props
		   #'org-store-link-props)
		 :type "ebdb" :name name
		 :link link :description name))
      link)))

(defun ebdb-org-open (link)
  "Follow a EBDB link."
  (let ((records (ebdb-org-retrieve link)))
    (if records
	(ebdb-display-records records nil nil nil (ebdb-popup-window))
      (message "No records found"))))

(defun ebdb-org-retrieve (link)
  (pcase (split-string link "/" t)
    (`("uuid" ,key) (list (ebdb-gethash key 'uuid)))
    (`(,key) (ebdb-search (ebdb-records) `((ebdb-field-name ,key))))
    (`("mail" ,key) (ebdb-search (ebdb-records) `((ebdb-field-mail ,key))))
    (`("phone" ,key) (ebdb-search (ebdb-records) `((ebdb-field-phone ,key))))
    (`("address" ,key) (ebdb-search (ebdb-records) `((ebdb-field-address ,key))))
    (`("notes" ,key) (ebdb-search (ebdb-records) `((ebdb-field-notes ,key))))
    (`("tags" ,key) (ebdb-search (ebdb-records) `((ebdb-field-tags ,key))))
    (`(,(and field
	     (let field-sym (intern-soft field))
	     (and field-sym
		  (guard (child-of-class-p field-sym 'ebdb-field))))
       ,key)
     (ebdb-search (ebdb-records) `((,field-sym ,key))))
    (`(,other _) (error "Unknown field search prefix: %s" other))))

(defun ebdb-org-export (path desc format)
  "Create the export version of a EBDB link specified by PATH or DESC.
If exporting to either HTML or LaTeX FORMAT the link will be
italicized, in all other cases it is left unchanged."
  (when (string= desc (format "ebdb:%s" path))
    (setq desc path))
  (cond
   ((eq format 'html) (format "<i>%s</i>" desc))
   ((eq format 'latex) (format "\\textit{%s}" desc))
   ((eq format 'odt)
    (format "<text:span text:style-name=\"Emphasis\">%s</text:span>" desc))
   (t desc)))

;; It was a mistake to make this a separate field class -- this
;; library should have just provided a new `ebdb-read' method for the
;; underlying `ebdb-field-tags' class.  I'm overriding `make-instance'
;; to redirect to `ebdb-field-tags', and will leave this override in
;; place for a year or so, then remove this class altogether some time
;; around Feb 2021.
;;;###autoload
(defclass ebdb-org-field-tags (ebdb-field-tags)
  nil
  :human-readable "org tags")

(cl-defmethod make-instance :around ((_cls (subclass ebdb-org-field-tags))
				     &rest slots)
  "Return an instance of `ebdb-field-tags' instead."
  (apply #'cl-call-next-method 'ebdb-field-tags slots))

(cl-defmethod ebdb-read ((field (subclass ebdb-field-tags)) &optional slots obj)
  (let* ((crm-separator (cadr (assq 'ebdb-field-tags ebdb-separator-alist)))
	 (val (completing-read-multiple
	       (format "Tags (separate with \"%s\"): " crm-separator)
	       (org--tag-add-to-alist
		(org--tag-add-to-alist
		 (org--tag-add-to-alist
		  (org-global-tags-completion-table)
		  org-tag-alist)
		 org-tag-persistent-alist)
		ebdb-tags)
	       nil nil
	       (when obj (ebdb-string obj)) 'org-tags-history)))
    (cl-call-next-method field (plist-put slots :tags val))))

;;;###autoload
(defun ebdb-org-agenda-popup (&optional inter)
  "Pop up an *EBDB* buffer from an Org Agenda tags search.
Uses the tags searched for in the Agenda buffer to do an
equivalent tags search of EBDB records.

To do this automatically for every search, add this function to
`org-agenda-mode-hook'."
  (interactive "p")
  (if (null (and (derived-mode-p 'org-agenda-mode)
		 (eql org-agenda-type 'tags)))
      (when inter
	(message "Not in an Org Agenda tags search buffer"))
    (let* ((func (cdr (org-make-tags-matcher org-agenda-query-string)))
	   (records (ebdb-search (ebdb-records)
				 `((ebdb-field-tags ,func)))))
      (ebdb-display-records records nil nil nil (ebdb-popup-window)))))

(cl-defmethod ebdb-make-buffer-name (&context (major-mode org-mode))
  "Use a separate EBDB buffer for Org-related contacts."
  (format "*%s-Org*" ebdb-buffer-name))

;;; Formatters

(defclass ebdb-org-formatter (ebdb-formatter)
  ((post-format-function :initform #'org-mode))
  :abstract t
  :documentation "Formatter responsible for Org-specific field
  formatting.")

(cl-defmethod ebdb-fmt-field ((_fmt ebdb-org-formatter)
			      (_field ebdb-field-mail)
			      _style
			      (_rec ebdb-record))
  (concat "mailto:" (cl-call-next-method)))

(defun ebdb-org-table-post-format ()
  "Align the formatted Org table."
  (org-mode)
  (goto-char (point-min))
  (forward-char)
  (org-table-align))

(defclass ebdb-org-formatter-tabular (ebdb-formatter-tabular
				      ebdb-org-formatter)
  ((record-separator :initform "\n")
   (field-separator :initform " | ")
   (post-format-function :initform #'ebdb-org-table-post-format)))

(cl-defmethod ebdb-fmt-header :around ((_fmt ebdb-org-formatter-tabular)
				       _records)
  (concat "| "
	  (cl-call-next-method)
	  " |\n"
	  "|---|\n"))

(cl-defmethod ebdb-fmt-compose-fields :around ((_fmt ebdb-org-formatter-tabular)
					       (_rec ebdb-record)
					       &optional _field-list _depth)
  (concat "| "
	  (cl-call-next-method)
	  " |"))

(defcustom ebdb-org-default-tabular-formatter
  (make-instance 'ebdb-org-formatter-tabular
		 :label "org table"
		 :fields '(mail-primary))
  "Default Org table formatter."
  :type 'ebdb-formatter-tabular)

(provide 'ebdb-org)
;;; ebdb-org.el ends here
