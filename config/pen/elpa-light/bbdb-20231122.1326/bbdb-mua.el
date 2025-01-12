;;; bbdb-mua.el --- various MUA functionality for BBDB -*- lexical-binding: t -*-

;; Copyright (C) 2010-2023  Free Software Foundation, Inc.

;; This file is part of the Insidious Big Brother Database (aka BBDB),

;; BBDB is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; BBDB is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with BBDB.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; This file provides various additional functionality for BBDB
;; See the BBDB info manual for documentation.

;; This file lets you do stuff like
;;
;; o  automatically add some string to some field(s) based on the
;;    contents of header fields of the current message
;; o  only automatically create records when certain header fields
;;    are matched
;; o  do not automatically create records when certain header fields
;;    are matched
;;
;; Read the docstrings; read the texinfo file.

;;; Code:

(require 'bbdb)
(require 'bbdb-com)

(eval-and-compile
  (autoload 'gnus-fetch-original-field "gnus-utils")
  (autoload 'gnus-summary-select-article "gnus-sum")
  ;; `gnus-info-params' was a macro up to Emacs 26;
  ;; it was turned into a function starting with Emacs 27.
  ;; If BBDB was compiled with an old version of Emacs up to Emacs 26,
  ;; this will fail if the code is loaded into a newer version of Emacs.
  (autoload 'gnus-info-params "gnus"
    nil nil (string> "27" emacs-version))
  (autoload 'gnus-get-info "gnus" nil nil 'macro)
  (defvar gnus-article-buffer)
  (defvar gnus-newsgroup-name)

  (autoload 'bbdb/vm-header "bbdb-vm")
  (autoload 'vm-follow-summary-cursor "vm-motion")
  (autoload 'vm-select-folder-buffer "vm-macro")
  (autoload 'vm-check-for-killed-summary "vm-misc")
  (autoload 'vm-error-if-folder-empty "vm-misc")

  (autoload 'rmail-get-header "rmail")
  (defvar rmail-buffer)

  (autoload 'bbdb/mh-header "bbdb-mhe")
  (autoload 'mh-show "mh-show")
  (defvar mh-show-buffer)

  (autoload 'bbdb/wl-header "bbdb-wl")

  (autoload 'bbdb/notmuch-header "bbdb-notmuch")

  (autoload 'message-field-value "message")
  (autoload 'mail-decode-encoded-word-string "mail-parse"))

(defconst bbdb-mua-mode-alist
  '((vm vm-mode vm-virtual-mode vm-summary-mode vm-presentation-mode)
    (gnus gnus-summary-mode gnus-article-mode gnus-tree-mode)
    (rmail rmail-mode rmail-summary-mode)
    (mh mhe-mode mhe-summary-mode mh-folder-mode)
    (mu4e mu4e-view-mode)  ; Tackle `mu4e-headers-mode' later
    (notmuch notmuch-show-mode notmuch-tree-mode)
    (wl wl-summary-mode wl-draft-mode mime-view-mode)
    (message message-mode mu4e-compose-mode notmuch-message-mode)
    (mail mail-mode))
  "Alist of MUA modes supported by BBDB.
Each element is of the form (MUA MODE MODE ...), where MODEs are used by MUA.")

(defun bbdb-mua ()
  "For the current message return the MUA.
Return values include
  gnus      Newsreader Gnus
  rmail     Reading Mail in Emacs
  vm        Viewmail
  mh        Emacs interface to the MH mail system (aka MH-E)
  mu4e      Mu4e
  notmuch   Notmuch
  wl        Wanderlust
  message   Mail and News composition mode that goes with Gnus
  mail      Emacs Mail Mode."
  (let ((mm-alist bbdb-mua-mode-alist)
        elt mua)
    (while (setq elt (pop mm-alist))
      (if (memq major-mode (cdr elt))
          (setq mua (car elt)
                mm-alist nil)))
    (or mua (user-error "BBDB: MUA `%s' not supported" major-mode))))

;;;###autoload
(defun bbdb-message-header (header)
  "For the current message return the value of HEADER.
MIME encoded headers are decoded.  Return nil if HEADER does not exist."
  ;; RW: If HEADER was allowed to be a regexp and the content of multiple
  ;; matching headers was concatenated as in `message-field-value',
  ;; this would simplify the usage of `bbdb-accept-message-alist' and
  ;; `bbdb-ignore-message-alist'.
  ;; RW: If this function had a remember table, it could look up the value
  ;; of a header if we request the value of the same header multiple times.
  ;; (We would reset the remember table each time we move on to a new message.)
  (let* ((mua (bbdb-mua))
         (val (cond ((eq mua 'gnus)
                     ;; `gnus-fetch-field' can fetch only the content of
                     ;; `gnus-visible-headers', but it ignores
                     ;; `gnus-ignored-headers'.  `gnus-fetch-original-field'
                     ;; uses the uncensored set of headers in
                     ;; `gnus-original-article-buffer'.  The latter headers are
                     ;; encoded, so that decoding makes this slower, but BBDB
                     ;; does not get fooled by an apparent absence of some
                     ;; headers.  (See gmane.emacs.gnus.general #78741)
                     (or (gnus-fetch-original-field header)
                         ;; `gnus-fetch-original-field' returns nil in nndoc
                         ;; groups (digests) because `gnus-original-article-buffer'
                         ;; is empty for the nndoc summary buffer, but not for
                         ;; the parent summary buffer. (bug#54423)
                         (let ((parent-summary-buffer
                                (cadr (assq 'quit-config
                                            (gnus-info-params
                                             (gnus-get-info gnus-newsgroup-name))))))
                           (and parent-summary-buffer
                                (with-current-buffer parent-summary-buffer
                                  (gnus-fetch-original-field header))))))
                    ((eq mua 'vm) (bbdb/vm-header header))
                    ((eq mua 'rmail)
                     (with-current-buffer rmail-buffer
                       (rmail-get-header header)))
                    ((eq mua 'mh) (bbdb/mh-header header))
                    ((eq mua 'mu4e) (message-field-value header))
                    ((eq mua 'notmuch) (bbdb/notmuch-header header))
                    ((eq mua 'wl) (bbdb/wl-header header))
                    ((memq mua '(message mail)) (message-field-value header))
                    (t (error "BBDB/%s: header function undefined" mua)))))
    (if val (mail-decode-encoded-word-string val))))

(defsubst bbdb-message-header-re (header regexp)
  "Return non-nil if REGEXP matches value of HEADER."
  (let ((val (bbdb-message-header header))
        (case-fold-search t)) ; RW: Is this what we want?
    (and val (string-match regexp val))))

;;; Update database

;;;###autoload
(defun bbdb-accept-message (&optional invert)
  "For use with variable `bbdb-mua-auto-action' and friends.
Return the value of variable `bbdb-mua-action' for messages matching
`bbdb-accept-message-alist'.  If INVERT is non-nil, accept messages
not matching `bbdb-ignore-message-alist'."
  (let ((rest (if invert bbdb-ignore-message-alist
                bbdb-accept-message-alist))
        done elt)
    (if (eq rest t)
        (setq done t)
      (while (and (setq elt (pop rest)) (not done))
        (dolist (header (if (stringp (car elt)) (list (car elt)) (car elt)))
          (if (bbdb-message-header-re header (cdr elt))
              (setq done t)))))
    (if invert (setq done (not done)))
    (if done bbdb-mua-action)))

;;;###autoload
(defun bbdb-ignore-message (&optional invert)
  "For use with variable `bbdb-mua-auto-action' and friends.
Return the value of variable `bbdb-mua-action' for messages not matching
`bbdb-ignore-message-alist'.  If INVERT is non-nil, accept messages
matching `bbdb-accept-message-alist'."
  (bbdb-accept-message (not invert)))

;;;###autoload
(defun bbdb-select-message ()
  "For use with variable `bbdb-mua-auto-action' and friends.
Return the value of variable `bbdb-mua-action' for messages both matching
`bbdb-accept-message-alist' and not matching `bbdb-ignore-message-alist'."
  (and (bbdb-accept-message)
       (bbdb-ignore-message)))

(defun bbdb-get-address-components (&optional header-class ignore-address)
  "Extract mail addresses from a message.
Return list with elements (NAME EMAIL HEADER HEADER-CLASS MUA).
HEADER-CLASS is defined in `bbdb-message-headers'.  If HEADER-CLASS is nil,
use all classes in `bbdb-message-headers'.
If regexp IGNORE-ADDRESS matches NAME or EMAIL of an address, this address
is ignored. If IGNORE-ADDRESS is nil, use value of `bbdb-user-mail-address-re'."
  ;; We do not use `bbdb-message-all-addresses' here because only when we
  ;; have compared the addresses with the records in BBDB do we know which
  ;; address(es) are relevant for us.
  (let ((message-headers (if header-class
                             (list (assoc header-class bbdb-message-headers))
                           bbdb-message-headers))
        (mua (bbdb-mua))
        (ignore-address (or ignore-address bbdb-user-mail-address-re))
        address-list name mail mail-list content)
    (dolist (headers message-headers)
      (dolist (header (cdr headers))
        (when (setq content (bbdb-message-header header))
          ;; Always extract all addresses because we do not know yet which
          ;; address might match IGNORE-ADDRESS.
          (dolist (address (bbdb-extract-address-components content t))
            ;; We canonicalize name and mail as early as possible.
            (setq name (car address)
                  mail (cadr address))
            ;; ignore uninteresting addresses
            (unless (or (and (stringp ignore-address)
                             (or (and name (string-match ignore-address name))
                                 (and mail (string-match ignore-address mail))))
                        (and mail (member-ignore-case mail mail-list)))
              ;; Add each address only once. (Use MAIL-LIST for book keeping.)
              ;; Thus if we care about whether an address gets associated with
              ;; one or another header, the order of elements in
              ;; `bbdb-message-headers' is relevant.  The "most important"
              ;; headers should be first in `bbdb-message-headers'.
              (if mail (push mail mail-list))
              (push (list name mail header (car headers) mua) address-list))))))
    (or (nreverse address-list)
        (and header-class bbdb-message-try-all-headers
             ;; Try again the remaining header classes
             (let ((bbdb-message-headers
                    (remove (assoc header-class bbdb-message-headers)
                            bbdb-message-headers)))
               (bbdb-get-address-components nil ignore-address))))))

;;;###autoload
(defun bbdb-update-records (address-list &optional action sort)
  "Return the list of BBDB records matching ADDRESS-LIST.
ADDRESS-LIST is a list of mail addresses.  (It can be extracted from
a mail message using `bbdb-get-address-components'.)
ACTION may take the following values:
 search       Search for existing records matching ADDRESS.
 update       Search for existing records matching ADDRESS;
                update name and mail field if necessary.
 query        Search for existing records matching ADDRESS;
                query for creation of a new record if the record does not exist.
 create or t  Search for existing records matching ADDRESS;
                create a new record if it does not yet exist.
 nil          Do nothing.
 a function   This functions will be called with no arguments.
                It should return one of the above values.

If SORT is non-nil, sort records according to `bbdb-record-lessp'.
Otherwise, the records are ordered according to ADDRESS-LIST.

Usually this function is called by the wrapper `bbdb-mua-update-records'."
  ;; ACTION allows filtering of complete messages.
  ;; Filtering of individual addresses within an accepted message
  ;; is done by `bbdb-get-address-components' using `bbdb-user-mail-address-re'.
  ;; We resolve ACTION repeatedly.  This is needed, for example,
  ;; with the chain `bbdb-mua-auto-action' -> `bbdb-select-message'
  ;; -> `bbdb-mua-action'.
  (while (and (functionp action)
              ;; Bad! `search' is a function in `cl.el'.
              (not (eq action 'search)))
    (setq action (funcall action)))
  (cond ((eq t action)
         (setq action 'create))
        ((not (memq action '(search update query create nil)))
         (user-error "Illegal value of arg action: %s" action)))

  (let (records-alist records elt)
    ;; RECORDS-ALIST associates records with mail addresses.
    ;; Its elements are (RECORD (ADDRESS1 ADDRESS2 ...))
    ;; Each element ADDRESS is a list (NAME MAIL HEADER HEADER-CLASS MUA)
    ;; as returned by ‘bbdb-get-address-components’.  RECORD may be nil
    ;; when no existing record matches an address.  In such a case, there is
    ;; only one element ADDRESS that BBDB uses to create a new record.
    ;; We could add optional flags at the end of the elements of RECORDS-ALIST
    ;; (via `bbdb-record-address-alist-function') to control further processing.
    ;; Would that be useful?
    (dolist (address (nreverse address-list))
      (let* ((mail (nth 1 address)) ; possibly nil
             (name (unless (equal mail (car address))
                     (car address)))
             (records (bbdb-message-search name mail)))
        (if records
            (dolist (record records) ; order of RECORDS insignificant!
              ;; Accumulate list of addresses for each RECORD.
              (if (setq elt (assq record records-alist))
                  (setcar (cdr elt) (cons address (cadr elt)))
                (push (list record (list address)) records-alist)))
          ;; We do not yet have a record for the address.
          (when (or name mail) ; ignore empty addresses
            ;; If there is no NAME, try to use MAIL as NAME
            ;; (but only if we do not yet have a record for MAIL).
            (if (and mail bbdb-message-mail-as-name
                     (or (null name)
                         (string= "" name)))
                ;; Clean MAIL as if it was a NAME.
                (setcar address (funcall bbdb-message-clean-name-function mail)))
            (push (list nil (list address)) records-alist)))))

    (if bbdb-record-address-alist-function
        (setq records-alist (funcall bbdb-record-address-alist-function
                                     records-alist)))

    (while (setq elt (pop records-alist))
      (let* ((record (nth 0 elt))
             (address (nth 0 (nth 1 elt)))
             (mail (or (nth 0 address) (nth 1 address)))
             task)
        (when (and (not record) mail (eq action 'query) (not bbdb-read-only))
          (setq task (bbdb-query-create mail))
          (if (memq task '(search create update))
              (setq action task)))
        (cond ((eq task 'quit)
               (setq records-alist nil))
              ((eq task 'next)) ; do nothing
              ((not (or record mail))) ; do nothing
              ((or bbdb-read-only (eq action 'search))
               (if record (push record records)))
              ((or (eq action 'create)
                   (eq task 'create-current) ; and (eq action 'query)
                   (and record (memq action '(query update))))
               ;; If we have more than one record, all but the first
               ;; one are new.  So no need to worry about duplicates.
               (setq records
                     (nconc (bbdb-annotate-message record (nth 1 elt) action)
                            records)))))
      (if (and records (not bbdb-message-all-addresses))
            (setq records-alist nil)))

    (setq records
          ;; Sorting RECORDS is useful when RECORDS are displayed.
          (if sort (sort records 'bbdb-record-lessp)
            ;; Make RECORDS a list ordered like ADDRESS-LIST.
            ;; Useful if RECORDS are processed further.
            (nreverse records)))

    (unless bbdb-read-only
      (dolist (record records)
        (run-hook-with-args 'bbdb-notice-record-hook record)))

    records))

(defun bbdb-query-create (mail)
  "Query action for MAIL address not yet known to BBDB.
Used by `bbdb-update-records'.  Return values include:
 create-current [y] Create a new record for MAIL.
 create         [!] Switch to create mode for remaining addresses.
 search         [s] Switch to search mode for remaining addresses.
 update         [u] Switch to update mode for remaining addresses.
 next           [n] Continue with next mail address, skip MAIL.
 quit           [q] Quit, ignore all remaining MAIL addresses."
  (let ((prompt (format "%s is not in BBDB; add? (y,!,s,u,n,q,?) " mail))
        task action)
    (save-window-excursion
      (while (not action)
        (setq task nil)
        (while (not task)
          (setq task (read-key-sequence prompt))
          (setq task (if (stringp task) (aref task 0))))
        (message "") ; clear the message buffer

        (setq action
              (cond ((eq task ?y)
                     'create-current)
                    ((eq task ?!)
                     'create)
                    ((eq task ?s)
                     'search)
                    ((eq task ?u)
                     'update)
                    ((or (eq task ?n)
                         (eq task ?\s))
                     'next)
                    ((or (eq task ?q)
                         (eq task ?\a)) ; ?\a = C-g
                     'quit)
                    (t ; any other key sequence
                     (let* ((buffer (get-buffer-create " *BBDB Help*"))
                            (window (or (get-buffer-window buffer)
                                        (split-window (get-lru-window)))))
                       (with-current-buffer buffer
                         (special-mode)
                         (let (buffer-read-only)
                           (erase-buffer)
                           (insert
                            "Your answer controls how BBDB updates/searches for records.

y  Create a new record for the current address.
!  Switch to create mode.
s  Switch to search mode.
u  Switch to update mode.
n  Continue with next address, skip the current address.
q  Quit updating records.
?  This help.")
                           (set-buffer-modified-p nil)
                           (goto-char (point-min)))
                         (set-window-buffer window buffer)
                         (fit-window-to-buffer window)))
                     nil))))) ;; Try again!
    action))

(defun bbdb-annotate-message (record address-list action)
  "Anotate RECORD using ADDRESS-LIST.  If RECORD is nil, create new record.
ADDRESS-LIST has elements (NAME MAIL HEADER HEADER-CLASS MUA)
as returned by `bbdb-get-address-components'.
ACTION controls whether new records beyond RECORD may be created.
ACTION may take the values:
 update or nil  Update RECORD, but do not create new records.
 query          Query interactively whether to create new records.
 create or t    Permit creating new records.
Return the records matching ADDRESS."
  ;; NEW non-nil is possible only with ACTIONs query and create,
  ;; but ACTION update implies that RECORD exists already (NEW nil).
  (let ((new (not record))
        (record (or record (bbdb-empty-record)))
        records)

    (dolist (address address-list)
      (let* ((record record) ; possibly changed below
             (mail (nth 1 address)) ; possibly nil
             (name (unless (equal mail (nth 0 address))
                     (nth 0 address)))
             (fullname (bbdb-divide-name (or name "")))
             (fname (car fullname))
             (lname (cdr fullname))
             (old-name (bbdb-record-name record)) ; possibly ""
             (old-name-nonempty (not (string= "" old-name)))
             change add-mails add-name ignore-redundant)
        ;; Is there anything meaningful we could do with the other elements
        ;; in ADDRESS?

        ;; Analyze the name part of the record.
        (cond ((or (not name)
                   ;; The following tests can differ for more complicated names
                   (bbdb-string= name old-name)
                   (and (equal fname (bbdb-record-firstname record)) ; possibly
                        (equal lname (bbdb-record-lastname record))) ; nil
                   (member-ignore-case name (bbdb-record-aka record)))) ; do nothing

              (new ; new record
               (bbdb-record-set-field record 'name (cons fname lname)))

              ((not (setq add-name (bbdb-add-job bbdb-add-name record name)))) ; do nothing

              ((numberp add-name)
               (unless bbdb-silent
                 (message "name mismatch: \"%s\" changed to \"%s\""
                          old-name name)
                 (sit-for add-name)))

              ((bbdb-eval-spec add-name
                               (if old-name-nonempty
                                   (format "Change name \"%s\" to \"%s\"? "
                                           old-name name)
                                 (format "Assign name \"%s\" to address \"%s\"? "
                                         name (car (bbdb-record-mail record)))))
               ;; Keep old-name as AKA?
               (if (and old-name-nonempty
                        (not (member-ignore-case old-name (bbdb-record-aka record)))
                        (bbdb-eval-spec (bbdb-add-job bbdb-add-aka record old-name)
                                        (format "Keep name \"%s\" as an AKA? " old-name)))
                   (bbdb-record-set-field
                    record 'aka (cons old-name (bbdb-record-aka record))))
               (bbdb-record-set-field record 'name (cons fname lname))
               (setq change 'name))

              ;; make new name an AKA?
              ((and old-name-nonempty
                    (not (member-ignore-case name (bbdb-record-aka record)))
                    (bbdb-eval-spec (bbdb-add-job bbdb-add-aka record name)
                                    (format "Make \"%s\" an alternate for \"%s\"? "
                                            name old-name)))
               (bbdb-record-set-field
                record 'aka (cons name (bbdb-record-aka record)))
               (setq change 'name)))

        ;; Is MAIL redundant compared with the mail addresses
        ;; that are already known for RECORD?
        (if (and mail
                 (setq ignore-redundant
                       (bbdb-add-job bbdb-ignore-redundant-mails record mail)))
            (let ((mails (bbdb-record-mail-canon record))
                  (case-fold-search t) redundant ml re)
              (while (setq ml (pop mails))
                (if (and (setq re (bbdb-mail-redundant-re ml))
                         (string-match re mail))
                    (setq redundant ml mails nil)))
              (if redundant
                  (cond ((numberp ignore-redundant)
                         (unless bbdb-silent
                           (message "%s: redundant mail `%s'"
                                    (bbdb-record-name record) mail)
                           (sit-for ignore-redundant)))
                        ((or (eq t ignore-redundant)
                             bbdb-silent
                             (y-or-n-p (format "Ignore redundant mail %s?" mail)))
                         (setq mail redundant))))))

        ;; Analyze the mail part of the new record
        (cond ((or (not mail) (equal mail "???")
                   (member-ignore-case mail (bbdb-record-mail-canon record)))) ; do nothing

              (new ; new record
               (bbdb-record-set-field record 'mail (list mail)))

              ((not (setq add-mails (bbdb-add-job bbdb-add-mails record mail)))) ; do nothing

              ((numberp add-mails)
               (unless bbdb-silent
                 (message "%s: new address `%s'"
                          (bbdb-record-name record) mail)
                 (sit-for add-mails)))

              ((or (eq add-mails t) ; add it automatically
                   bbdb-silent
                   (y-or-n-p (format "Add address \"%s\" to %s? " mail
                                     (bbdb-record-name record)))
                   ;; The user decided interactively not to add MAIL
                   ;; to the existing record for NAME.  Then, if ACTION
                   ;; is create or the user confirms after query,
                   ;; we make a new record for NAME and MAIL.
                   (and (or (memq action '(t create))
                            (and (eq action 'query)
                                 (y-or-n-p
                                  (format "Create a new record for %s? "
                                          (bbdb-record-name record)))))
                        (progn
                          (setq record (bbdb-empty-record))
                          (bbdb-record-set-name record fname lname)
                          (setq new t))))

               (let ((mails (bbdb-record-mail record)))
                 (if ignore-redundant
                     ;; Does the new address MAIL make an old address redundant?
                     (let ((mail-re (bbdb-mail-redundant-re mail))
                           (case-fold-search t) okay redundant)
                       (dolist (ml mails)
                         (if (string-match mail-re ml) ; redundant mail address
                             (push ml redundant)
                           (push ml okay)))
                       (let ((form (format "redundant mail%s %s"
                                           (if (< 1 (length redundant)) "s" "")
                                           (bbdb-concat 'mail (nreverse redundant))))
                             (name (bbdb-record-name record)))
                         (if redundant
                             (cond ((numberp ignore-redundant)
                                    (unless bbdb-silent
                                      (message "%s: %s" name form)
                                      (sit-for ignore-redundant)))
                                   ((or (eq t ignore-redundant)
                                        bbdb-silent
                                        (y-or-n-p (format "Delete %s: " form)))
                                    (if (eq t ignore-redundant)
                                        (message "%s: deleting %s" name form))
                                    (setq mails okay)))))))

                 ;; then modify RECORD
                 (bbdb-record-set-field
                  record 'mail
                  (if (and mails
                           (bbdb-eval-spec (bbdb-add-job bbdb-new-mails-primary
                                                         record mail)
                                           (format "Make \"%s\" the primary address? " mail)))
                      (cons mail mails)
                    (nconc mails (list mail))))
                 (unless change (setq change t)))))

        (cond (new
               (unless bbdb-silent
                 (if (bbdb-record-name record)
                     (message "created %s's record with address \"%s\""
                              (bbdb-record-name record) mail)
                   (message "created record with naked address \"%s\"" mail)))
               (setq new nil)
               (bbdb-change-record record))

              (change
               (unless bbdb-silent
                 (cond ((eq change 'name)
                        (message "noticed \"%s\"" (bbdb-record-name record)))
                       ((bbdb-record-name record)
                        (message "noticed %s's address \"%s\""
                                 (bbdb-record-name record) mail))
                       (t
                        (message "noticed naked address \"%s\"" mail))))
               (bbdb-change-record record)))

        ;; `bbdb-notice-mail-hook' runs only if the user agreed to change
        ;; a record.  It runs for every ADDRESS.  Use ‘bbdb-notice-record-hook’
        ;; if you want to notice each record only once per message.
        ;; We make ADDRESS available to `bbdb-notice-mail-hook'
        ;; via `bbdb-update-records-address'.
        (let ((bbdb-update-records-address address))
          (run-hook-with-args 'bbdb-notice-mail-hook record))

        ;; With multiple ADDRESSes, we loop over the same RECORD multiple times.
        (bbdb-pushnewq record records)))

    ;; Return records
    records))

(defun bbdb-mua-update-records (&optional header-class action sort)
  "Wrapper for `bbdb-update-records'.
HEADER-CLASS is defined in `bbdb-message-headers'.  If it is nil,
use all classes in `bbdb-message-headers'.
ACTION is defined in `bbdb-update-records'.
If SORT is non-nil, sort records according to `bbdb-record-lessp'."
  (let ((mua (bbdb-mua)))
    (save-current-buffer
      (cond ;; VM
       ((eq mua 'vm)
        (vm-select-folder-buffer)
        (vm-check-for-killed-summary)
        (vm-error-if-folder-empty)
        (let ((enable-local-variables t))  ; ...or vm bind this to nil.
          (bbdb-update-records (bbdb-get-address-components header-class)
                               action sort)))
       ;; Gnus
       ((eq mua 'gnus)
        (set-buffer gnus-article-buffer)
        (bbdb-update-records (bbdb-get-address-components header-class)
                             action sort))
       ;; MH-E
       ((eq mua 'mh)
        (if mh-show-buffer (set-buffer mh-show-buffer))
        (bbdb-update-records (bbdb-get-address-components header-class)
                             action sort))
       ;; Rmail
       ((eq mua 'rmail)
        (set-buffer rmail-buffer)
        (bbdb-update-records (bbdb-get-address-components header-class)
                             action sort))
       ;; mu4e
       ((eq mua 'mu4e)
        (set-buffer (if (boundp 'mu4e~view-buffer-name)
                        mu4e~view-buffer-name ; old version of mu4e
                      gnus-article-buffer))
        (bbdb-update-records (bbdb-get-address-components header-class)
                             action sort))
       ;; notmuch
       ((eq mua 'notmuch)
        (bbdb-update-records (bbdb-get-address-components header-class)
                             action sort))

       ;; Wanderlust
       ((eq mua 'wl)
        (bbdb-update-records (bbdb-get-address-components header-class)
                             action sort))
       ;; Message and Mail
       ((memq mua '(message mail))
        (bbdb-update-records (bbdb-get-address-components header-class)
                             action sort))))))

(defmacro bbdb-mua-wrapper (&rest body)
  "Perform BODY in a MUA buffer."
  (declare (debug t))
  `(let ((mua (bbdb-mua)))
     ;; Here we replicate BODY multiple times which gets clumsy
     ;; for a larger BODY!
     (cond ((eq mua 'gnus)
            ;; This fails in *Article* buffers, where
            ;; `gnus-article-read-summary-keys' provides an additional wrapper
            (save-current-buffer
              (gnus-summary-select-article) ; sets buffer `gnus-summary-buffer'
              ,@body))
           ((memq mua '(mail message rmail mh vm mu4e notmuch wl))
            (cond ((eq mua 'vm) (vm-follow-summary-cursor))
                  ((eq mua 'mh) (mh-show)))
            ;; rmail, mail, message, mu4e, notmuch and wl do not require
            ;; any wrapper
            ,@body))))

(define-obsolete-function-alias 'bbdb-mua-update-interactive-p
  #'bbdb-mua-interactive-action "3.0")
(defun bbdb-mua-interactive-action ()
  "Interactive spec for arg ACTION of `bbdb-mua-display-records' and friends.
If these commands are called without a prefix, the value of their arg
ACTION is the car of the variable `bbdb-mua-interactive-action'.
Called with a prefix, the value of ACTION is the cdr of this variable."
  (let ((action (if current-prefix-arg
                    (cdr bbdb-mua-interactive-action)
                  (car bbdb-mua-interactive-action))))
    (if (eq action 'read)
        (let ((str (completing-read "Action: " '((query) (search) (create))
                                    nil t)))
          (unless (string= "" str) (intern str))) ; nil otherwise
      action)))

(defun bbdb-mua-window-p ()
  "Return lambda function matching the MUA window.
This return value can be used as arg HORIZ-P of
`bbdb-pop-up-window' and `bbdb-display-records'."
  (let ((mm-alist bbdb-mua-mode-alist)
        elt fun)
    (while (setq elt (cdr (pop mm-alist)))
      (if (memq major-mode elt)
          (setq fun `(lambda (window)
                       (with-current-buffer (window-buffer window)
                         (memq major-mode ',elt)))
                mm-alist nil)))
    fun))

;;;###autoload
(defun bbdb-mua-display-records (&optional header-class action all)
  "Display the BBDB record(s) for the addresses in this message.
This looks into the headers of a message according to HEADER-CLASS.
Then for the mail addresses found the corresponding BBDB records are displayed.
ACTION determines whether only existing BBDB records are displayed
or whether also new records are created for these mail addresses.

HEADER-CLASS is defined in `bbdb-message-headers'.  If it is nil,
use all classes in `bbdb-message-headers'.
ACTION may take the same values as `bbdb-mua-action'.
For interactive calls, see function `bbdb-mua-interactive-action'.
If ALL is non-nil, bind `bbdb-message-all-addresses' to ALL."
  (interactive (list nil (bbdb-mua-interactive-action)))
  (let ((bbdb-pop-up-window-size bbdb-mua-pop-up-window-size)
        (bbdb-message-all-addresses (or all bbdb-message-all-addresses))
        records)
    (bbdb-mua-wrapper
     (setq records (bbdb-mua-update-records header-class action t)))
    (if records (bbdb-display-records records nil nil nil (bbdb-mua-window-p)))
    records))

;; The following commands are some frontends for `bbdb-mua-display-records',
;; which is always doing the real work.  In your init file, you can further
;; modify or adapt these simple commands to your liking.

;;;###autoload
(defun bbdb-mua-display-sender (&optional action)
  "Display the BBDB record(s) for the sender of this message.
ACTION may take the same values as `bbdb-mua-action'.
For interactive calls, see function `bbdb-mua-interactive-action'."
  (interactive (list (bbdb-mua-interactive-action)))
  (bbdb-mua-display-records 'sender action))

;;;###autoload
(defun bbdb-mua-display-recipients (&optional action)
  "Display the BBDB record(s) for the recipients of this message.
ACTION may take the same values as `bbdb-mua-action'.
For interactive calls, see function `bbdb-mua-interactive-action'."
  (interactive (list (bbdb-mua-interactive-action)))
  (bbdb-mua-display-records 'recipients action))

;;;###autoload
(defun bbdb-mua-display-all-records (&optional action)
  "Display the BBDB record(s) for all addresses in this message.
ACTION may take the same values as `bbdb-mua-action'.
For interactive calls, see function `bbdb-mua-interactive-action'."
  (interactive (list (bbdb-mua-interactive-action)))
  (bbdb-mua-display-records nil action t))

;;;###autoload
(defun bbdb-mua-display-all-recipients (&optional action)
  "Display BBDB records for all recipients of this message.
ACTION may take the same values as `bbdb-mua-action'.
For interactive calls, see function `bbdb-mua-interactive-action'."
  (interactive (list (bbdb-mua-interactive-action)))
  (bbdb-mua-display-records 'recipients action t))

;; The commands `bbdb-annotate-record' and `bbdb-mua-edit-field'
;; have kind of similar goals, yet they use rather different strategies.
;; `bbdb-annotate-record' is less obtrusive.  It does not display
;; the records it operates on, nor does it display the content
;; of the field before or after adding or replacing the annotation.
;; Hence the user needs to know what she is doing.
;; `bbdb-mua-edit-field' is more explicit:  It displays the records
;; as well as the current content of the field that gets edited.

;; In principle, this function can be used not only with MUAs.
(defun bbdb-annotate-record (record annotation &optional field replace)
  "In RECORD add an ANNOTATION to field FIELD.
FIELD defaults to `bbdb-annotate-field'.
If REPLACE is non-nil, ANNOTATION replaces the content of FIELD.
If ANNOTATION is an empty string and REPLACE is non-nil, delete FIELD."
  (if (memq field '(name firstname lastname phone address xfields))
      (user-error "Field `%s' illegal" field))
  (setq annotation (bbdb-string-trim annotation))
  (cond ((memq field '(affix organization mail aka))
         (setq annotation (list annotation)))
        ((not field) (setq field bbdb-annotate-field)))
  (bbdb-record-set-field record field annotation (not replace))
  (bbdb-change-record record))

;; FIXME: For interactive calls of the following commands, the arg ACTION
;; should have the same meaning as for `bbdb-mua-display-records',
;; that is, it should use `bbdb-mua-interactive-action'.
;; But here the prefix arg is already used in a different way.
;; We could possibly solve this problem if all `bbdb-mua-*' commands
;; used another prefix arg that is consistently used only for
;; `bbdb-mua-interactive-action'.
;; Yet this prefix arg must be defined within the key space of the MUA(s).
;; This results in lots of conflicts...
;;
;; Current workaround:
;; These commands use merely the car of `bbdb-mua-interactive-action'.
;; If one day someone proposes a smart solution to this problem (suggestions
;; welcome!), this solution will hopefully include the current workaround
;; as a subset of all its features.

(defun bbdb-mua-annotate-field-interactive ()
  "Interactive specification for `bbdb-mua-annotate-sender' and friends."
  (bbdb-editable)
  (let ((field (if (eq 'all-fields bbdb-annotate-field)
                   (intern (completing-read
                            "Field: "
                            (mapcar 'symbol-name
                                    (append '(affix organization mail aka)
                                            bbdb-xfield-label-list))))
                 bbdb-annotate-field)))
    (list (read-string (format "Annotate `%s': " field))
          field current-prefix-arg
          (car bbdb-mua-interactive-action))))

;;;###autoload
(defun bbdb-mua-annotate-sender (annotation &optional field replace action)
  "Add ANNOTATION to field FIELD of the BBDB record(s) of message sender(s).
FIELD defaults to `bbdb-annotate-field'.
If REPLACE is non-nil, ANNOTATION replaces the content of FIELD.
ACTION may take the same values as `bbdb-mua-action'.
For interactive calls, use car of `bbdb-mua-interactive-action'."
  (interactive (bbdb-mua-annotate-field-interactive))
  (bbdb-mua-wrapper
   (dolist (record (bbdb-mua-update-records 'sender action))
     (bbdb-annotate-record record annotation field replace))))

;;;###autoload
(defun bbdb-mua-annotate-recipients (annotation &optional field replace
                                                action)
  "Add ANNOTATION to field FIELD of the BBDB records of message recipients.
FIELD defaults to `bbdb-annotate-field'.
If REPLACE is non-nil, ANNOTATION replaces the content of FIELD.
ACTION may take the same values as `bbdb-mua-action'.
For interactive calls, use car of `bbdb-mua-interactive-action'."
  (interactive (bbdb-mua-annotate-field-interactive))
  (bbdb-mua-wrapper
   (dolist (record (bbdb-mua-update-records 'recipients action))
     (bbdb-annotate-record record annotation field replace))))

(defun bbdb-mua-edit-field-interactive ()
  "Interactive specification for command `bbdb-mua-edit-field' and friends.
This uses `bbdb-mua-interactive-action'."
  (bbdb-editable)
  (list (if (eq 'all-fields bbdb-mua-edit-field)
            (intern (completing-read
                     "Field: "
                     (mapcar 'symbol-name
                             (append '(name affix organization aka mail)
                                     bbdb-xfield-label-list))))
          bbdb-mua-edit-field)
        (bbdb-mua-interactive-action)))

;;;###autoload
(defun bbdb-mua-edit-field (&optional field action header-class)
  "Edit FIELD of the BBDB record(s) of message sender(s) or recipients.
FIELD defaults to value of variable `bbdb-mua-edit-field'.
ACTION may take the same values as `bbdb-mua-action'.
For interactive calls, see function `bbdb-mua-interactive-action'.
HEADER-CLASS is defined in `bbdb-message-headers'.  If it is nil,
use all classes in `bbdb-message-headers'."
  (interactive (bbdb-mua-edit-field-interactive))
  (cond ((memq field '(firstname lastname address phone xfields))
         (user-error "Field `%s' not editable this way" field))
        ((not field)
         (setq field bbdb-mua-edit-field)))
  (bbdb-mua-wrapper
   (let ((records (bbdb-mua-update-records header-class action))
         (bbdb-pop-up-window-size bbdb-mua-pop-up-window-size))
     (when records
       (bbdb-display-records records nil nil nil (bbdb-mua-window-p))
       (dolist (record records)
         (bbdb-edit-field record field nil nil t))))))

;;;###autoload
(defun bbdb-mua-edit-field-sender (&optional field action)
  "Edit FIELD of record corresponding to sender of this message.
FIELD defaults to value of variable `bbdb-mua-edit-field'.
ACTION may take the same values as `bbdb-mua-action'.
For interactive calls, see function `bbdb-mua-interactive-action'."
  (interactive (bbdb-mua-edit-field-interactive))
  (bbdb-mua-edit-field field action 'sender))

;;;###autoload
(defun bbdb-mua-edit-field-recipients (&optional field action)
  "Edit FIELD of record corresponding to recipient of this message.
FIELD defaults to value of variable `bbdb-mua-edit-field'.
ACTION may take the same values as `bbdb-mua-action'.
For interactive calls, see function `bbdb-mua-interactive-action'."
  (interactive (bbdb-mua-edit-field-interactive))
  (bbdb-mua-edit-field field action 'recipients))

;; Functions for noninteractive use in MUA hooks

;;;###autoload
(defun bbdb-mua-auto-update (&optional header-class action)
  "Update BBDB automatically based on incoming and outgoing messages.
This looks into the headers of a message according to HEADER-CLASS.
Then for the mail addresses found the corresponding BBDB records are updated.
ACTION determines whether only existing BBDB records are taken
or whether also new records are created for these mail addresses.
Return matching records.

HEADER-CLASS is defined in `bbdb-message-headers'.  If it is nil,
use all classes in `bbdb-message-headers'.
ACTION may take the same values as `bbdb-mua-auto-action'.
If ACTION is nil, use `bbdb-mua-auto-action' (which see).

If `bbdb-mua-pop-up' is non-nil, BBDB pops up the *BBDB* buffer
along with the MUA window(s), displaying the matching records
using `bbdb-pop-up-layout'.
If this is nil, BBDB is updated silently.

This function is intended for noninteractive use via appropriate MUA hooks.
Call `bbdb-mua-auto-update-init' in your init file to put this function
into the respective MUA hooks.
See `bbdb-mua-display-records' and friends for interactive commands."
  (let* ((bbdb-silent-internal t)
         (records (bbdb-mua-update-records header-class
                                           (or action
                                               bbdb-mua-auto-action)))
         (bbdb-pop-up-window-size bbdb-mua-pop-up-window-size))
    (if bbdb-mua-pop-up
        (if records
              (bbdb-display-records records bbdb-pop-up-layout
                                    nil nil (bbdb-mua-window-p))
          ;; If there are no records, empty the BBDB window.
          (bbdb-undisplay-records)))
    records))

;; Should the following be replaced by a minor mode??
;; Or should we make this function interactive in some other way?

;;;###autoload
(defun bbdb-mua-auto-update-init (&rest muas)
  "For MUAS add `bbdb-mua-auto-update' to their presentation hook.
If a MUA is not an element of MUAS, `bbdb-mua-auto-update' is removed
from the respective presentation hook.

Call this function in your init file to use the auto update feature with MUAS.
This function is separate from the general function `bbdb-initialize'
as this allows one to initialize the auto update feature for some MUAs only,
for example only for outgoing messages.

See `bbdb-mua-auto-update' for details about the auto update feature."
  (dolist (mua '((message . message-send-hook)
                 (mail . mail-send-hook)
                 (rmail . rmail-show-message-hook)
                 (gnus . gnus-article-prepare-hook)
                 (mh . mh-show-hook)
                 (vm . vm-select-message-hook)
                 (wl . wl-summary-redisplay-hook)))
    (if (memq (car mua) muas)
        (add-hook (cdr mua) 'bbdb-mua-auto-update)
      (remove-hook (cdr mua) 'bbdb-mua-auto-update))))

;;;###autoload
(defun bbdb-auto-notes (record)
  "Automatically annotate RECORD based on the headers of the current message.
See the variables `bbdb-auto-notes-rules', `bbdb-auto-notes-ignore-messages'
and `bbdb-auto-notes-ignore-headers'.
For use as an element of `bbdb-notice-record-hook'."
  ;; This code re-evaluates the annotations each time a message is viewed.
  ;; It would be faster if we could somehow store (permanently?) that we
  ;; have already annotated a message.
  (let ((case-fold-search t))
    (unless (or bbdb-read-only
                ;; check the ignore-messages pattern
                (let ((ignore-messages bbdb-auto-notes-ignore-messages)
                      ignore rule)
                  (while (and (not ignore) (setq rule (pop ignore-messages)))
                    (if (cond ((functionp rule)
                               ;; RULE may use `bbdb-update-records-address'
                               (funcall rule record))
                              ((symbolp rule)
                               (eq rule (nth 4 bbdb-update-records-address)))
                              ((eq 1 (safe-length rule))
                               (bbdb-message-header-re (car rule) (cdr rule)))
                              ((eq 2 (safe-length rule))
                               (and (eq (car rule) (nth 4 bbdb-update-records-address))
                                    (bbdb-message-header-re (nth 1 rule) (nth 2 rule)))))
                        (setq ignore t)))
                  ignore))
      (bbdb-editable)

      ;; For speed-up expanded rules are stored in `bbdb-auto-notes-rules-expanded'.
      (when (and bbdb-auto-notes-rules
                 (not bbdb-auto-notes-rules-expanded))
        (let (expanded mua from-to header)
          (dolist (rule bbdb-auto-notes-rules)
            ;; Which MUA do we want?
            (if (or (stringp (car rule))
                    (stringp (nth 1 rule)))
                (setq mua t)
              (setq mua (if (symbolp (car rule)) (listp (car rule)) (car rule))
                    rule (cdr rule)))
            ;; Which FROM-TO headers do we want?
            (if (stringp (car rule))
                (setq from-to t)
              (setq from-to (car rule)
                    rule (cdr rule)))
            (setq header (car rule))
            (let (string field replace elt-e)
              (dolist (elt (cdr rule))
                (if (consp (setq string (cdr elt)))
                    (setq field (car string) ; (REGEXP FIELD-NAME STRING REPLACE)
                          replace (nth 2 string) ; perhaps nil
                          string (nth 1 string))
                  ;; else it's simple (REGEXP . STRING)
                  (setq field bbdb-default-xfield
                        replace nil))
                (push (list (car elt) field string replace) elt-e))
              (push (append (list mua from-to header) (nreverse elt-e)) expanded)))
          (setq bbdb-auto-notes-rules-expanded (nreverse expanded))))

      (dolist (rule bbdb-auto-notes-rules-expanded)
        (let ((mua (car rule)) (from-to (nth 1 rule)) (header (nth 2 rule))
              hd-val string annotation)
          (when (and (or (eq mua t)
                         (memq (nth 4 bbdb-update-records-address) mua))
                     (or (eq from-to t)
                         (member-ignore-case
                          (nth 2 bbdb-update-records-address) from-to)
                         (memq (nth 3 bbdb-update-records-address) from-to))
                     (setq hd-val (bbdb-message-header header)))
            (dolist (elt (nthcdr 3 rule))
              (when (and (string-match (car elt) hd-val)
                         (let ((ignore (cdr (assoc-string
                                             header
                                             bbdb-auto-notes-ignore-headers t))))
                           (not (and ignore (string-match ignore hd-val)))))
                (setq string (nth 2 elt)
                      annotation
                      (cond ((integerp string)
                             (match-string string hd-val))
                            ((stringp string)
                             (replace-match string nil nil hd-val))
                            ((functionp string)
                             (funcall string hd-val))
                            (t (error "Illegal value: %s" string))))
                (bbdb-annotate-record record annotation
                                      (nth 1 elt) (nth 3 elt))))))))))

;;; Mark BBDB records in the MUA summary buffer

(defun bbdb-mua-summary-unify (address)
  "Unify mail ADDRESS displayed for a message in the MUA Summary buffer.
Typically ADDRESS refers to the value of the From header of a message.
If ADDRESS matches a record in BBDB display a unified name instead of ADDRESS
in the MUA Summary buffer.

Unification uses `bbdb-mua-summary-unification-list' (see there).
The first match in this list becomes the text string displayed
for a message in the MUA Summary buffer instead of ADDRESS.
If variable `bbdb-mua-summary-mark' is non-nil use it to precede
known addresses.  Return the unified mail address.

Currently this works with Gnus and VM.  It requires the BBDB insinuation
of these MUAs.  Also, the MUA Summary format string must use
`bbdb-mua-summary-unify-format-letter' (see there)."
  ;; ADDRESS is analyzed as in `bbdb-get-address-components'.
  (let* ((data (bbdb-extract-address-components address))
         (name (car data))
         (mail (cadr data))
         (record (car (bbdb-message-search name mail)))
         (u-list bbdb-mua-summary-unification-list)
         elt val)
    (while (setq elt (pop u-list))
      (setq val (cond ((eq elt 'message-name) name)
                      ((eq elt 'message-mail) mail)
                      ((eq elt 'message-address) address)
                      (record (let ((result (bbdb-record-field record elt)))
                                (if (stringp result) result
                                  (car result)))))) ; RESULT is list.
      (if val (setq u-list nil)))
    (format "%s%s"
            (cond ((not bbdb-mua-summary-mark) "")
                  ((not record) " ")
                  ((functionp bbdb-mua-summary-mark-field)
                   (funcall bbdb-mua-summary-mark-field record))
                  ((bbdb-record-xfield record bbdb-mua-summary-mark-field))
                  (t bbdb-mua-summary-mark))
            (or val name mail address "**UNKNOWN**"))))

(defun bbdb-mua-summary-mark (address)
  "In the MUA Summary buffer mark messages matching a BBDB record.
ADDRESS typically refers to the value of the From header of a message.
If ADDRESS matches a record in BBDB return a mark, \" \" otherwise.
The mark itself is the value of the xfield `bbdb-mua-summary-mark-field'
if this xfield is in the poster's record, and `bbdb-mua-summary-mark' otherwise."
  (if (not bbdb-mua-summary-mark)
      "" ; for consistency
    ;; ADDRESS is analyzed as in `bbdb-get-address-components'.
    (let* ((data (bbdb-extract-address-components address))
           (record (car (bbdb-message-search (car data) (cadr data)))))
      (if record
          (or (when (functionp bbdb-mua-summary-mark-field)
                (funcall bbdb-mua-summary-mark-field record)
                t)
              (bbdb-record-xfield record bbdb-mua-summary-mark-field)
              bbdb-mua-summary-mark)
        " "))))

(provide 'bbdb-mua)

;;; bbdb-mua.el ends here
