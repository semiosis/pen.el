;;; ebdb-vm.el --- EBDB interface to VM              -*- lexical-binding: t; -*-

;; Copyright (C) 2016-2023  Free Software Foundation, Inc.

;; Author: Eric Abrahamsen <eric@ericabrahamsen.net>

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

;; EBDB's interface to VM.

;;; Code:

(require 'ebdb-mua)

(declare-function vm-check-for-killed-summary "ext:vm-misc")
(declare-function vm-error-if-folder-empty "ext:vm-misc")
(declare-function vm-get-header-contents "ext:vm-summary")
(declare-function vm-su-to-names "ext:vm-summary")
(declare-function vm-su-from "ext:vm-summary")
(declare-function vm-su-to "ext:vm-summary")
(declare-function vm-su-full-name "ext:vm-summary")
(declare-function vm-su-interesting-full-name "ext:vm-summary")
(declare-function vm-decode-mime-encoded-words-in-string "ext:vm-mime")
(declare-function vm-follow-summary-cursor "ext:vm-motion")
(declare-function vm-add-message-labels "ext:vm-undo")

(defvar vm-summary-function-B)
(defvar vm-summary-uninteresting-senders)
(defvar vm-summary-uninteresting-senders-arrow)
(defvar vm-message-pointer)
(defvar vm-auto-folder-alist)
(defvar vm-virtual-folder-alist)
(defvar vm-folder-directory)
(defvar vm-primary-inbox)
(defvar vm-mode-map)

(defgroup ebdb-mua-vm nil
  "VM-specific EBDB customizations"
  :group 'ebdb-mua)
(put 'ebdb-mua-vm 'custom-loads '(ebdb-vm))

(defcustom ebdb-vm-auto-update-p ebdb-mua-reader-update-p
  "VM-specific value of `ebdb-mua-auto-update-p'."
  :type '(choice (const :tag "do nothing" nil)
                 (const :tag "search for existing records" existing)
                 (const :tag "update existing records" update)
                 (const :tag "query for update or record creation" query)
                 (const :tag "update or create automatically" create)
                 (function :tag "User-defined function")))

(defun ebdb/vm-header (header)
  (save-current-buffer
    (with-no-warnings
      ;; This is a defsubst, and will cause compiler warnings if the
      ;; user doesn't actually have vm installed.
     (vm-select-folder-buffer))
    (vm-check-for-killed-summary)
    (vm-error-if-folder-empty)
    (let ((enable-local-variables t))
      (vm-get-header-contents (car vm-message-pointer)
			      (concat header ":")))))


;; By Alastair Burt <burt@dfki.uni-kl.de>
;; vm 5.40 and newer support a new summary format, %U<letter>, to call
;; a user-provided function.  Use "%-17.17UB" instead of "%-17.17F" to
;; have your VM summary buffers display EBDB's idea of the sender's full
;; name instead of the name (or lack thereof) in the message itself.

;; RW: this is a VM-specific version of `ebdb-mua-summary-unify'
;; which respects `vm-summary-uninteresting-senders'.

(defun vm-summary-function-B (m)
  "For VM message M return the EBDB name of the sender.
Respect `vm-summary-uninteresting-senders'."
  (if vm-summary-uninteresting-senders
        (if (let ((case-fold-search t))
              (string-match vm-summary-uninteresting-senders (vm-su-from m)))
            (concat vm-summary-uninteresting-senders-arrow
                    (or (ebdb/vm-alternate-full-name (vm-su-to m))
                        (vm-decode-mime-encoded-words-in-string
                         (vm-su-to-names m))))
          (or (ebdb/vm-alternate-full-name (vm-su-from m))
              (vm-su-full-name m)))
    (or (ebdb/vm-alternate-full-name (vm-su-from m))
        (vm-decode-mime-encoded-words-in-string (vm-su-full-name m)))))

(defun ebdb/vm-alternate-full-name (address)
  (if address
      (let* ((data (ebdb-extract-address-components address))
             (record (car (ebdb-message-search (car data) (cadr data)))))
        (if record
            (or (slot-value (ebdb-record-one-mail record) 'aka)
                (ebdb-record-name-string record))))))



(defcustom ebdb-vm-window-size ebdb-default-window-size
  "Size of the EBDB buffer when popping up in VM.
Size should be specified as a float between 0 and 1.  Defaults to
the value of `ebdb-default-window-size'."
  :type 'float)

;;;###autoload
(defcustom ebdb/vm-auto-folder-headers '("From:" "To:" "CC:")
  "The headers used by `ebdb/vm-auto-folder'.
The order in this list is the order how matching will be performed."
  :type '(repeat (string :tag "header name")))

;;;###autoload
(defcustom ebdb/vm-auto-folder-field "vm-folder"
  "The xfield which `ebdb/vm-auto-folder' searches for."
  :type 'symbol)

;;;###autoload
(defcustom ebdb/vm-virtual-folder-field "vm-virtual"
  "The xfield which `ebdb/vm-virtual-folder' searches for."
  :type 'symbol)

;;;###autoload
(defcustom ebdb/vm-virtual-real-folders nil
  "Real folders used for defining virtual folders.
If nil use `vm-primary-inbox'."
  :type '(choice (const :tag "Use vm-primary-inbox" nil)
                 (repeat (string :tag "Real folder"))))

;;;###autoload
(defun ebdb/vm-auto-folder ()
  "Add entries to `vm-auto-folder-alist' for the records in EBDB.
For each record that has a `vm-folder' field, add an element
\(MAIL-REGEXP . FOLDER-NAME) to `vm-auto-folder-alist'.
The element gets added to the sublists of `vm-auto-folder-alist'
specified in `ebdb/vm-auto-folder-headers'.
MAIL-REGEXP matches the mail addresses of the EBDB record.
The value of the `vm-folder' field becomes FOLDER-NAME.
The `vm-folder' field is defined via `ebdb/vm-auto-folder-field'.

Add this function to `ebdb-before-save-hook' and your .vm."
  (interactive)
  (let ((records       ; Collect EBDB records with a vm-folder field.
         (delq nil
               (mapcar (lambda (r)
                         (if (ebdb-record-field r ebdb/vm-auto-folder-field)
                             r))
                       (ebdb-records))))
        folder-list folder-name mail-regexp)
    ;; Add (MAIL-REGEXP . FOLDER-NAME) pair to this sublist of `vm-auto-folder-alist'
    (dolist (header ebdb/vm-auto-folder-headers)
      ;; create the folder-list in `vm-auto-folder-alist' if it does not exist
      (unless (setq folder-list (assoc header vm-auto-folder-alist))
        (push (list header) vm-auto-folder-alist)
        (setq folder-list (assoc header vm-auto-folder-alist)))
      (dolist (record records)
        ;; Ignore everything past a comma
        (setq folder-name (car (ebdb-record-field
                                record ebdb/vm-auto-folder-field))
              ;; quote all the mail addresses for the record and join them
              mail-regexp (regexp-opt (ebdb-record-mail record)))
        ;; In general, the values of fields are strings (required for editing).
        ;; If we could set the value of `ebdb/vm-auto-folder-field' to a symbol,
        ;; it could be a function that is called with arg record to calculate
        ;; the value of folder-name.
        ;; (if (functionp folder-name)
        ;;     (setq folder-name (funcall folder-name record)))
        (unless (or (string= "" mail-regexp)
                    (assoc mail-regexp folder-list))
          ;; Convert relative into absolute file names using
          ;; `vm-folder-directory'.
          (unless (file-name-absolute-p folder-name)
            (setq folder-name (abbreviate-file-name
                               (expand-file-name folder-name
                                                 vm-folder-directory))))
          ;; nconc modifies the list in place
          (nconc folder-list (list (cons mail-regexp folder-name))))))))

;;;###autoload
(defun ebdb/vm-virtual-folder ()
  "Create `vm-virtual-folder-alist' according to the records in EBDB.
For each record that has a `vm-virtual' field, add or modify the
corresponding VIRTUAL-FOLDER-NAME element of `vm-virtual-folder-alist'.

  (VIRTUAL-FOLDER-NAME ((FOLDER-NAME ...)
                        (author-or-recipient MAIL-REGEXP)))

VIRTUAL-FOLDER-NAME is the first element of the `vm-virtual' field.
FOLDER-NAME ... are either the remaining elements of the `vm-virtual' field,
or `ebdb/vm-virtual-real-folders' or `vm-primary-inbox'.
MAIL-REGEXP matches the mail addresses of the EBDB record.
The `vm-virtual' field is defined via `ebdb/vm-virtual-folder-field'.

Add this function to `ebdb-before-save-hook' and your .vm."
  (interactive)
  (let (real-folders mail-regexp folder val tmp)
    (dolist (record (ebdb-records))
      (when (setq val (ebdb-record-field
                       record ebdb/vm-virtual-folder-field))
        (setq mail-regexp (regexp-opt (ebdb-record-mail record)))
        (unless (string= "" mail-regexp)
          (setq folder (car val)
                real-folders (mapcar
                              (lambda (f)
                                (if (file-name-absolute-p f) f
                                  (abbreviate-file-name
                                   (expand-file-name f vm-folder-directory))))
                              (or (cdr val) ebdb/vm-virtual-real-folders
                                  (list vm-primary-inbox)))
                ;; Either extend the definition of an already defined
                ;; virtual folder or define a new virtual folder
                tmp (or (assoc folder vm-virtual-folder-alist)
                        (car (push (list folder) vm-virtual-folder-alist)))
                tmp (or (assoc real-folders (cdr tmp))
                        (car (setcdr tmp (cons (list real-folders)
                                               (cdr tmp)))))
                tmp (or (assoc 'author-or-recipient (cdr tmp))
                        (car (setcdr tmp (cons (list 'author-or-recipient)
                                               (cdr tmp))))))
          (cond ((not (cdr tmp))
                 (setcdr tmp (list mail-regexp)))
                ((not (string-match (regexp-quote mail-regexp)
                                    (cadr tmp)))
                 (setcdr tmp (list (concat (cadr tmp) "\\|" mail-regexp))))))))))


;; RW: Adding custom labels to VM messages allows one to create,
;; for example, virtual folders.  The following code creates
;; the required labels in a rather simplistic way, checking merely
;; whether the sender's EBDB record uses a certain mail alias.
;; (Note that `ebdb/vm-virtual-folder' can achieve the same goal,
;; yet this requires a second field that must be kept up-to-date, too.)
;; To make auto labels yet more useful, the code could allow more
;; sophisticated schemes, too.  Are there real-world applications
;; for this?

;;; Howard Melman, contributed Jun 16 2000
(defcustom ebdb/vm-auto-add-label-list nil
  "List used by `ebdb/vm-auto-add-label' to automatically label VM messages.
Its elements may be strings used both as the field value to check for
and as the label to apply to the message.
If an element is a cons pair (VALUE . LABEL), VALUE is the field value
to search for and LABEL is the label to apply."
  :type '(repeat string))

(defcustom ebdb/vm-auto-add-label-field 'ebdb-mail-alias-field
  "Fields used by `ebdb/vm-auto-add-label' to automatically label messages.
This is either a single EBDB field or a list of fields that
`ebdb/vm-auto-add-label' uses to check for labels to apply to a message.
Defaults to `ebdb-mail-alias-field' which defaults to `mail-alias'."
  :type '(choice symbol (repeat symbol)))

(defun ebdb/vm-auto-add-label (record)
  "Automatically add labels to VM messages.
Add this to `ebdb-notice-record-hook' to check the messages noticed by EBDB.
If the value of `ebdb/vm-auto-add-label-field' in the sender's EBDB record
matches a value in `ebdb/vm-auto-add-label-list' then a VM label will be added
to the message.  Such VM labels can be used, e.g., to mark messages via
`vm-mark-matching-messages' or to define virtual folders via
`vm-create-virtual-folder'

Typically `ebdb/vm-auto-add-label-field' and `ebdb/vm-auto-add-label-list'
refer to mail aliases FOO used with multiple records.  This adds a label FOO
to all incoming messages matching FOO.  Then VM can create a virtual folder
for these messages.  The concept of combining multiple recipients of an
outgoing message in one mail alias thus gets extended to incoming messages
from different senders."
  ;; This could go into `vm-arrived-message-hook' to check messages only once.
  (if (eq major-mode 'vm-mode)
      (let* ((xvalues
              ;; Inspect the relevant fields of RECORD
              (append
               (mapcar (lambda (field)
                         (ebdb-record-field record field))
                       (cond ((listp ebdb/vm-auto-add-label-field)
                              ebdb/vm-auto-add-label-field)
                             ((stringp ebdb/vm-auto-add-label-field)
                              (list ebdb/vm-auto-add-label-field))
                             (t (error "Bad value for ebdb/vm-auto-add-label-field"))))))
             ;; Collect the relevant labels from `ebdb/vm-auto-add-label-list'
             (labels
              (delq nil
                    (mapcar (lambda (l)
                              (cond ((stringp l)
                                     (if (member l xvalues)
                                         l))
                                    ((and (consp l)
                                          (stringp (car l))
                                          (stringp (cdr l)))
                                     (if (member (car l) xvalues)
                                         (cdr l)))
                                    (t
                                     (error "Malformed ebdb/vm-auto-add-label-list"))))
                            ebdb/vm-auto-add-label-list))))
        (if labels
            (vm-add-message-labels
             (mapconcat #'identity labels " ") 1)))))



;;; If vm has set up its various modes using `define-derived-mode' we
;;; should be able to collapse all these various methods into one that
;;; checks `derived-mode-p'.  Check how to do that with &context.

(cl-defmethod ebdb-popup-window (&context (major-mode vm-mode))
  (let ((win [WHAT??]))
    (list win ebdb-vm-window-size)))

(cl-defmethod ebdb-make-buffer-name (&context (major-mode vm-mode))
  "Produce a EBDB buffer name associated with VM mode."
  (format "*%s-VM*" ebdb-buffer-name))

(cl-defmethod ebdb-make-buffer-name (&context (major-mode vm-presentation-mode))
  "Produce a EBDB buffer name associated with VM mode."
  (format "*%s-VM*" ebdb-buffer-name))

(cl-defmethod ebdb-make-buffer-name (&context (major-mode vm-summary-mode))
  "Produce a EBDB buffer name associated with VM mode."
  (format "*%s-VM*" ebdb-buffer-name))

(cl-defmethod ebdb-make-buffer-name (&context (major-mode vm-virtual-mode))
  "Produce a EBDB buffer name associated with VM mode."
  (format "*%s-VM*" ebdb-buffer-name))

(cl-defmethod ebdb-mua-message-header ((header string)
				   &context (major-mode vm-mode))
  (ebdb/vm-header header))

(cl-defmethod ebdb-mua-message-header ((header string)
				   &context (major-mode vm-virtual-mode))
  (ebdb/vm-header header))

(cl-defmethod ebdb-mua-message-header ((header string)
				   &context (major-mode vm-summary-mode))
  (ebdb/vm-header header))

(cl-defmethod ebdb-mua-message-header ((header string)
				   &context (major-mode vm-presentation-mode))
  (ebdb/vm-header header))

(cl-defmethod ebdb-mua-prepare-article (&context (major-mode vm-mode))
  (vm-follow-summary-cursor))

(cl-defmethod ebdb-mua-prepare-article (&context (major-mode vm-virtual-mode))
  (vm-follow-summary-cursor))

(cl-defmethod ebdb-mua-prepare-article (&context (major-mode vm-summary-mode))
  (vm-follow-summary-cursor))

(cl-defmethod ebdb-mua-prepare-article (&context (major-mode vm-presentation-mode))
  (vm-follow-summary-cursor))

;;;###autoload
(defun ebdb-insinuate-vm ()
  "Hook EBDB into VM."
  (unless ebdb-db-list
    (ebdb-load))
  (define-key vm-mode-map ";" ebdb-mua-keymap)
  (define-key vm-mode-map "/" #'ebdb)
  ;; `mail-mode-map' is the parent of `vm-mail-mode-map'.
  ;; So the following is also done by `ebdb-insinuate-mail'.
  (if (and ebdb-complete-mail (boundp 'vm-mail-mode-map))
      (define-key vm-mail-mode-map "\M-\t" #'ebdb-complete-mail))

  ;; Set up user field for use in `vm-summary-format'
  ;; (1) Big solution: use whole name
  (if ebdb-mua-summary-unify-format-letter
      (fset (intern (concat "vm-summary-function-"
                            ebdb-mua-summary-unify-format-letter))
            (lambda (m) (ebdb-mua-summary-unify
                         ;; VM does not give us the original From header.
                         ;; So we have to work backwards.
                         (let ((name (vm-decode-mime-encoded-words-in-string
                                      (vm-su-interesting-full-name m)))
                               (mail (vm-su-from m)))
                           (if (string= name mail) mail
                             (format "\"%s\" <%s>" name mail)))))))

  ;; (2) Small solution: a mark for messages whos sender is in EBDB.
  (if ebdb-mua-summary-mark-format-letter
      (fset (intern (concat "vm-summary-function-"
                            ebdb-mua-summary-mark-format-letter))
            ;; VM does not give us the original From header.
            ;; So we assume that the mail address is sufficient to identify
            ;; the EBDB record of the sender.
            (lambda (m) (ebdb-mua-summary-mark (vm-su-from m))))))

;;;###autoload
(defun ebdb-vm-auto-update ()
  (ebdb-mua-auto-update ebdb-vm-auto-update-p))

(add-hook 'vm-mode-hook #'ebdb-insinuate-vm)

(add-hook 'vm-select-message-hook #'ebdb-vm-auto-update)

(provide 'ebdb-vm)
;;; ebdb-vm.el ends here
