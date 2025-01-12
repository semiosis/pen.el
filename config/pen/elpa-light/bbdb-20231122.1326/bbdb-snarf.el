;;; bbdb-snarf.el --- convert free-form text to BBDB records -*- lexical-binding: t -*-

;; Copyright (C) 2010-2022  Free Software Foundation, Inc.

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

;; The commands `bbdb-snarf', `bbdb-snarf-yank' and `bbdb-snarf-paragraph'
;; create BBDB records by picking the name, addresses, phones, etc.
;; out of a (buffer) string.  Things are recognized by context (e.g., URLs
;; start with http:// or www.).
;;
;; The code uses a modular format based on rules and rule elements that
;; should facilitate customization.  See `bbdb-snarf-rule-alist' for details.
;; The default rule is `bbdb-snarf-rule-default'.
;;
;; The rule `us' is intended for text that includes US addresses.
;; The rule `eu' should work out of the box for many continental
;; European countries.  It can be further customized by defining
;; a suitable postcode regexp passed to `bbdb-snarf-address-eu'.
;;
;; `mail' is a simple rule that can pick a single mail address from,
;; say, a long list of mail addresses in a message.
;;
;; The rule `vcard' is for importing vCard records into BBDB.
;; Use it with the commands `bbdb-snarf-vcard' and `bbdb-snarf-vcard-buffer'.
;;
;; The default snarf rules include the element `bbdb-snarf-sanity-check',
;; which performs sanity checks before actually creating a new record.
;; Currently, this only ignores mail addresses that match
;; `bbdb-snarf-ignore-mail-re'.  Suggestions welcome to extend this mechanism.

;;; Code:

(require 'bbdb-com)
(require 'qp)

(defcustom bbdb-snarf-rule-alist
  '((us bbdb-snarf-surrounding-space
        bbdb-snarf-phone-nanp
        bbdb-snarf-url
        bbdb-snarf-mail
        bbdb-snarf-empty-lines
        bbdb-snarf-name
        bbdb-snarf-address-us
        bbdb-snarf-empty-lines
        bbdb-snarf-notes
        bbdb-snarf-name-mail ; currently useless
        bbdb-snarf-sanity-check)
    (eu bbdb-snarf-surrounding-space
        bbdb-snarf-phone-eu
        bbdb-snarf-url
        bbdb-snarf-mail
        bbdb-snarf-empty-lines
        bbdb-snarf-name
        bbdb-snarf-address-eu
        bbdb-snarf-empty-lines
        bbdb-snarf-notes
        bbdb-snarf-name-mail ; currently useless
        bbdb-snarf-sanity-check)
   (mail bbdb-snarf-mail-address
         bbdb-snarf-sanity-check)
   (vcard bbdb-snarf-vcard-name
          bbdb-snarf-vcard-nickname
          bbdb-snarf-vcard-email
          bbdb-snarf-vcard-tel
          bbdb-snarf-vcard-adr
          bbdb-snarf-vcard-org
          bbdb-snarf-vcard-uid
          bbdb-snarf-vcard-url
          bbdb-snarf-vcard-note
          bbdb-snarf-sanity-check))
  "Alist of rules for snarfing.
Each rule is of the form (KEY FUNCTION FUNCTION ...).
The symbol KEY identifies the rule, see also `bbdb-snarf-rule-default'.

Snarfing is a cumulative process.  The text is copied to a temporary
snarf buffer that becomes current during snarfing.
Each FUNCTION is called with one arg, the RECORD we are snarfing,
and with point at the beginning of the snarf buffer.  FUNCTION should populate
the fields of RECORD.  It may delete the part of the snarf buffer
that it has processed so that the remaining FUNCTIONs operate only
on those parts that were not yet snarfed.  The order of the FUNCTION calls
in a rule is then crucial.
Unlike other parts of BBDB, FUNCTIONs need not update the cache and
hash table for RECORD which is done at the end by `bbdb-snarf'.
Rules may include a santity check for RECORD like `bbdb-snarf-santity-check'.
Usually, this should be the last FUNCTION in a rule.  This may turn RECORD
into an empty record that will be discarded."
  :group 'bbdb-utilities-snarf
  :type '(repeat (cons (symbol :tag "Key")
                       (repeat (function :tag "Snarf function")))))

(defcustom bbdb-snarf-rule-default 'us
  "Default rule for snarfing."
  :group 'bbdb-utilities-snarf
  :type 'symbol)

(defcustom bbdb-snarf-name-regexp
  "^[ \t'\"]*\\([- .,[:word:]]*[[:word:]]\\)"
  "Regexp matching a name.  Case is ignored.
The first subexpression becomes the name."
  :group 'bbdb-utilities-snarf
  :type 'regexp)

(defcustom bbdb-snarf-mail-regexp
  (concat "\\(?:\\(?:mailto:\\|e?mail:?\\)[ \t]*\\)?"
          "<?\\([^ \t\n<]+@[^ \t\n>]+\\)>?")
  "Regexp matching a mail address.  Case is ignored.
The first subexpression becomes the mail address."
  :group 'bbdb-utilities-snarf
  :type 'regexp)

(defcustom bbdb-snarf-phone-nanp-regexp
  (concat "\\(?:phone:?[ \t]*\\)?"
          "\\(\\(?:([2-9][0-9][0-9])[-. ]?\\|[2-9][0-9][0-9][-. ]\\)?"
          "[0-9][0-9][0-9][-. ][0-9][0-9][0-9][0-9]"
          "\\(?: *\\(?:x\\|ext\\.?\\) *[0-9]+\\)?\\)")
  "Regexp matching a NANP phone number.  Case is ignored.
NANP is the North American Numbering Plan used in North and Central America.
The first subexpression becomes the phone number."
  :group 'bbdb-utilities-snarf
  :type 'regexp)

(defcustom bbdb-snarf-phone-eu-regexp
  (concat "\\(?:phone?:?[ \t]*\\)?"
          "\\(\\(?:\\+[1-9]\\|(\\)[-0-9()\s]+\\)")
  "Regexp matching a European phone number.
The first subexpression becomes the phone number."
  :group 'bbdb-utilities-snarf
  :type 'regexp)

(defcustom bbdb-snarf-postcode-us-regexp
  ;; US postcode appears at end of line
  (concat "\\(\\<[0-9][0-9][0-9][0-9][0-9]"
          "\\(-[0-9][0-9][0-9][0-9]\\)?"
          "\\>\\)$")
  "Regexp matching US postcodes.
The first subexpression becomes the postcode."
  :group 'bbdb-utilities-snarf
  :type 'regexp)

(defcustom bbdb-snarf-address-us-country nil
  "Country to use for US addresses.  If nil leave country blank."
  :group 'bbdb-utilities-snarf
  :type '(choice (const :tag "Leave blank" nil)
                 (string :tag "Country")))

(defcustom bbdb-snarf-postcode-eu-regexp
  "^\\([0-9][0-9][0-9][0-9][0-9]?\\)" ; four or five digits
  "Regexp matching many European postcodes.
`bbdb-snarf-address-eu' assumes that the address appears at the beginning
of a line followed by the name of the city."
  :group 'bbdb-utilities-snarf
  :type 'regexp)

(defcustom bbdb-snarf-address-eu-country nil
  "Country to use for EU addresses.  If nil leave country blank."
  :group 'bbdb-utilities-snarf
  :type '(choice (const :tag "Leave blank" nil)
                 (string :tag "Country")))

(defcustom bbdb-snarf-default-label-alist
  '((phone . "work") (address . "work"))
  "Default labels for snarfing.
This is an alist where each element is a cons pair (FIELD . LABEL).
The symbol FIELD denotes a record field like `phone' or `address'.
The string LABEL denotes the default label for FIELD."
  :group 'bbdb-utilities-snarf
  :type '(repeat (cons (symbol :tag "Field")
                       (string :tag "Label"))))

(defcustom bbdb-snarf-url 'url
  "What xfield BBDB should use for URLs, or nil to not snarf URLs."
  :group 'bbdb-utilities-snarf
  :type 'symbol)

(defcustom bbdb-snarf-url-regexp "\\(\\(?:http://\\|www\\.\\)[^ \t\n]+\\)"
  "Regexp matching a URL.  Case is ignored.
The first subexpression becomes the URL."
  :group 'bbdb-utilities-snarf
  :type 'regexp)

(defcustom bbdb-snarf-vcard 'vcard
  "Default rule for snarfing vCards."
  :group 'bbdb-utilities-vcard
  :type 'symbol)

(defcustom bbdb-snarf-vcard-adr-type-re
  (concat "\\`" (regexp-opt '("work" "home")) "\\'")
  "Regexp matching the default types for vCard property ADR."
  :group 'bbdb-utilities-vcard
  :type 'regexp)

(defcustom bbdb-snarf-vcard-tel-type-re
  (concat "\\`" (regexp-opt '("work" "home" "text" "voice"
                              "fax" "cell" "video" "pager" "textphone"))
          "\\'")
  "Regexp matching the default types for vCard property TEL."
  :group 'bbdb-utilities-vcard
  :type 'regexp)

(defcustom bbdb-snarf-ignore-mail-re
  (regexp-opt '("noreply" "no-reply" "donotreply" "do-not-reply" "notify"))
  "`bbdb-snarf-sanity-check' ignores mail addresses matching this regexp."
  :group 'bbdb-utilities-snarf
  :type 'regexp)

(defun bbdb-snarf-sanity-check (record)
  "Sanity check of snarfed RECORD.
This may turn RECORD into an empty record that will be discarded.
Usually, this should be the last element of any snarfing rule."
  ;; Fixme: Are there other things we may want to add here?
  (let (mails)
    (mapc (lambda (mail)
            (unless (string-match bbdb-snarf-ignore-mail-re mail)
              (bbdb-pushnew mail mails)))
          (nreverse (bbdb-record-mail record)))
    (setf (bbdb-record-mail record) mails)))

(defun bbdb-snarf-surrounding-space (_record)
  "Discard beginning and trailing space when snarfing RECORD."
  (while (re-search-forward "^[ \t]+" nil t)
    (replace-match ""))
  (goto-char (point-min))
  (while (re-search-forward "\\s-+$" nil t)
    (replace-match "")))

(defun bbdb-snarf-empty-lines (_record)
  "Discard empty lines when snarfing RECORD."
  (while (re-search-forward "^[ \t]*\n" nil t)
    (replace-match "")))

(defun bbdb-snarf-name (record)
  "Snarf name for RECORD."
  (if (and (not (bbdb-record-lastname record))
           (let ((case-fold-search t))
             (re-search-forward bbdb-snarf-name-regexp nil t)))
      (let ((name (match-string 1)))
        (replace-match "")
        (setq name (bbdb-divide-name name))
        (setf (bbdb-record-firstname record) (car name))
        (setf (bbdb-record-lastname record) (cdr name)))))

(defun bbdb-snarf-name-mail (record)
  "Snarf name from mail address for RECORD."
  ;; Fixme: This is currently useless because `bbdb-snarf-mail-regexp'
  ;; cannot handle names in RFC 5322-like addresses "John Smith <foo@bar.com>".
  (let ((name (bbdb-record-lastname record)))
    (when (and (not name)
               (bbdb-record-mail record)
               (setq name (car (bbdb-extract-address-components
                                (car (bbdb-record-mail record)))))
               (setq name (bbdb-divide-name name)))
      (setf (bbdb-record-firstname record) (car name))
      (setf (bbdb-record-lastname record) (cadr name)))))

(defun bbdb-snarf-mail-address (record)
  "Snarf name and mail address for RECORD."
  ;; The voodoo of `mail-extract-address-components' makes
  ;; the following quite powerful.  If this function is used as part of
  ;; a more complex rule, the buffer should be narrowed appropriately.
  (let* ((data (bbdb-extract-address-components (buffer-string)))
         (name (and (car data) (bbdb-divide-name (car data))))
         (mail (cadr data)))
    (if (string-match "@" mail)
        (progn
          (setf (bbdb-record-firstname record) (car name))
          (setf (bbdb-record-lastname  record) (cdr name))
          (setf (bbdb-record-mail record) (list (cadr data)))
          (delete-region (point-min) (point-max)))
      ;; Something went wrong
      (goto-char (point-min))
      (bbdb-snarf-mail record)
      (goto-char (point-min))
      (bbdb-snarf-name record))))

(defun bbdb-snarf-mail (record)
  "Snarf mail addresses for RECORD.
This uses the first subexpresion of `bbdb-snarf-mail-regexp'."
  (let ((case-fold-search t) mails)
    (while (re-search-forward bbdb-snarf-mail-regexp nil t)
      (push (match-string 1) mails)
      (replace-match ""))
    (setf (bbdb-record-mail record) (nconc (bbdb-record-mail record) mails))))

(defun bbdb-snarf-label (field)
  "Extract the label before point, or return default label for FIELD."
  (save-match-data
    (if (looking-back "\\(?:^\\|[,:]\\)\\([^\n,:]+\\):[ \t]*"
                      (line-beginning-position))
        (prog1 (match-string 1)
          (delete-region (match-beginning 1) (match-end 0)))
      (cdr (assq field bbdb-snarf-default-label-alist)))))

(defun bbdb-snarf-phone-nanp (record)
  "Snarf NANP phone numbers for RECORD.
NANP is the North American Numbering Plan used in North and Central America.
This uses the first subexpresion of `bbdb-snarf-phone-nanp-regexp'."
  (let ((case-fold-search t) phones)
    (while (re-search-forward bbdb-snarf-phone-nanp-regexp nil t)
      (goto-char (match-beginning 0))
      (if (save-match-data
            (looking-back "[0-9A-Z]" nil)) ;; not really an NANP phone number
          (goto-char (match-end 0))
        (push (vconcat (list (bbdb-snarf-label 'phone))
                       (save-match-data
                         (bbdb-parse-phone (match-string 1))))
              phones)
        (replace-match "")))
    (setf (bbdb-record-phone record) (nconc (bbdb-record-phone record)
                                            (nreverse phones)))))

(defun bbdb-snarf-phone-eu (record &optional phone-regexp)
  "Snarf European phone numbers for RECORD.
PHONE-REGEXP is the regexp to match a phone number.
It defaults to `bbdb-snarf-phone-eu-regexp'."
  (let ((case-fold-search t) phones)
    (while (re-search-forward (or phone-regexp
                                  bbdb-snarf-phone-eu-regexp)
                              nil t)
      (goto-char (match-beginning 0))
      (push (vector (bbdb-snarf-label 'phone)
                    (match-string 1))
            phones)
      (replace-match ""))
    (setf (bbdb-record-phone record) (nconc (bbdb-record-phone record)
                                            (nreverse phones)))))

(defun bbdb-snarf-streets (address)
  "Snarf streets for ADDRESS.  This assumes a narrowed region."
  (setf (bbdb-address-streets address) (bbdb-split "\n" (buffer-string)))
  (delete-region (point-min) (point-max)))

(defun bbdb-snarf-address-us (record)
  "Snarf a US address for RECORD."
  (let ((address (bbdb-address--make)))
    (cond ((re-search-forward bbdb-snarf-postcode-us-regexp nil t)
           ;; Streets, City, State Postcode
           (save-restriction
             (narrow-to-region (point-min) (match-end 0))
             ;; Postcode
             (goto-char (match-beginning 0))
             (setf (bbdb-address-postcode address)
                   (bbdb-parse-postcode (match-string 1)))
             ;; State
             (skip-chars-backward " \t")
             (let ((pos (point)))
               (skip-chars-backward "^ \t,")
               (setf (bbdb-address-state address)
                     (buffer-substring (point) pos)))
             ;; City
             (skip-chars-backward " \t,")
             (let ((pos (point)))
               (beginning-of-line)
               (setf (bbdb-address-city address)
                     (buffer-substring (point) pos)))
             ;; Toss it
             (forward-char -1)
             (delete-region (point) (point-max))
             ;; Streets
             (goto-char (point-min))
             (bbdb-snarf-streets address)))
          ;; Try for just Streets, City, State
          ((let (case-fold-search)
             (re-search-forward "^\\(.*\\), \\([A-Z][A-Za-z]\\)$" nil t))
           (setf (bbdb-address-city address) (match-string 1))
           (setf (bbdb-address-state address) (match-string 2))
           (replace-match "")
           (save-restriction
             (narrow-to-region (point-min) (match-beginning 0))
             (goto-char (point-min))
             (bbdb-snarf-streets address))))
    (when (bbdb-address-city address)
      (if bbdb-snarf-address-us-country
          (setf (bbdb-address-country address) bbdb-snarf-address-us-country))
      ;; Fixme: There are no labels anymore.  `bbdb-snarf-streets' snarfed
      ;; everything that was left!
      (setf (bbdb-address-label address) (bbdb-snarf-label 'address))
      (setf (bbdb-record-address record)
            (nconc (bbdb-record-address record)
                   (list address))))))

(defun bbdb-snarf-address-eu (record &optional postcode-regexp country)
  "Snarf a European address for RECORD.
POSTCODE-REGEXP is a regexp matching the postcode assumed to appear
at the beginning of a line followed by the name of the city.  This format
is used in many continental European countries.
POSTCODE-REGEXP defaults to `bbdb-snarf-postcode-eu-regexp'.
COUNTRY is the country to use.  It defaults to `bbdb-snarf-address-eu-country'."
  (when (re-search-forward (or postcode-regexp
                               bbdb-snarf-postcode-eu-regexp)
                           nil t)
    (let ((address (bbdb-address--make)))
      (save-restriction
        (goto-char (match-end 0))
        (narrow-to-region (point-min) (line-end-position))
        ;; Postcode
        (setf (bbdb-address-postcode address) (match-string 1))
        ;; City
        (skip-chars-forward " \t")
        (setf (bbdb-address-city address)
              (buffer-substring (point) (point-max)))
        ;; Toss it
        (delete-region (match-beginning 0) (point-max))
        ;; Streets
        (goto-char (point-min))
        (bbdb-snarf-streets address))
      (unless country (setq country bbdb-snarf-address-eu-country))
      (if country (setf (bbdb-address-country address) country))
      (setf (bbdb-address-label address) (bbdb-snarf-label 'address))
      (setf (bbdb-record-address record)
            (nconc (bbdb-record-address record)
                   (list address))))))

(defun bbdb-snarf-url (record)
  "Snarf URL for RECORD.
This uses the first subexpresion of `bbdb-snarf-url-regexp'."
  (when (and bbdb-snarf-url
             (let ((case-fold-search t))
               (re-search-forward bbdb-snarf-url-regexp nil t)))
    (setf (bbdb-record-xfields record)
          (nconc (bbdb-record-xfields record)
                 (list (cons bbdb-snarf-url (match-string 1)))))
    (replace-match "")))

(defun bbdb-snarf-notes (record)
  "Snarf notes for RECORD."
  (when (/= (point-min) (point-max))
    (setf (bbdb-record-xfields record)
          (nconc (bbdb-record-xfields record)
                 (list (cons bbdb-default-xfield (buffer-string)))))
    (erase-buffer)))

;; vCard format (version 4.0)
;; https://datatracker.ietf.org/doc/html/rfc6350

;; The following parsing code partly duplicates vcard-parse from GNU Elpa.
;; But we try to avoid that BBDB depends on packages outside Emacs core.
(defun bbdb-snarf-vcard-property (property &optional sep)
  "Return vCard property PROPERTY.
The return value is a list with elements (VALUE (PAR . VAL) (PAR . VAL) ...)
for each instance of PROPERTY in the vCard.  String VALUE is the value
of the instance of  PROPERTY.  With separator SEP non-nil, VALUE is a list
of split values of the instance of PROPERTY.  PAR is a parameter of the
instance of PROPERTY with value VAL.  PAR may be nil if VAL is a parameter
value that has no parameter key associated with it.
If PROPERTY is not found return nil.
Delete all instances of PROPERTY from the snarfing buffer."
  ;; Possible extensions of this code that are not yet implemented:
  ;; - Property value escaping (RFC 6350, Sec. 3.4)
  ;; - Parameter values VAL that can themselves be broken into lists
  ;;   of strings (RFC 6350, Sec. 4).
  (goto-char (point-min))
  ;; RFC 6350: property names and parameter names are case-insensitive
  ;; (relevant for parsing).  Parameter values may be case-sensitive
  ;; or case-insensitive (irrelevant for parsing).
  (let ((case-fold-search t)
        (prop-re (concat "^" property "\\>"))
        prop-list)
    (while (re-search-forward prop-re nil t)
      (let* ((beg (match-beginning 0))
             (start (match-end 0))
             (end (save-excursion
                    (re-search-forward "\n[^ ]" nil t)
                    (match-beginning 0)))
             ;; Convert physical lines to one logical line.
             (str (replace-regexp-in-string
                   "\n " "" (buffer-substring-no-properties start end)))
             par-list)
        (delete-region beg (1+ end))
        (with-temp-buffer
          (insert str)
          (goto-char (point-min))
          ;; This ignores the possiblity that `;' and `:' may appear
          ;; in parameter values that are quoted strings.  Bother?
          (while (looking-at ";\\([^;:]+\\)")
            (goto-char (match-end 0))
            (let ((par (match-string 1)))
              ;; We try to split the property parameters into pairs PAR=VAL.
              ;; If this fails, we include the dangling VAL with PAR being nil,
              ;; e.g., "work" instead of "TYPE=work".
              ;; Certain parameter values may be comma-separated lists.
              ;; Fixme: Use custom var `bbdb-vcard-parameter-sep-alist'
              ;; with elements (PAR . SEP).
              (push (if (string-match "\\`\\([^=]+\\)=\\([^=]+\\)\\'" par)
                        (cons (match-string 1 par) (match-string 2 par))
                      (cons nil par))
                    par-list)))
          (let ((value (buffer-substring-no-properties
                        (1+ (point)) (point-max)))
                (encoding (cdr (bbdb-snarf-assoc
                                "encoding" "\\`quoted-printable\\'"
                                par-list))))
            (when encoding
              (if (bbdb-string= encoding "quoted-printable")
                  ;; RFC6350 requires utf-8.
                  (setq value (decode-coding-string
                               (quoted-printable-decode-string value)
                               'utf-8))
                (user-error "Vcard encoding %s undefined" encoding)))
            ;; Again, this ignores the possiblity that `;' and `:'
            ;; may appear in property values inside quoted strings.
            (push (cons (if sep (split-string value sep) value)
                        (nreverse par-list))
                  prop-list)))))

    ;; We try to sort multiple instances of PROPERTY based on
    ;; the PREF parameter.  Absence of PREF counts as PREF=100.
    (sort (nreverse prop-list)
          (lambda (p1 p2)
            (cl-flet ((num (p)
                        (let* ((r (assoc-string "PREF" p t))
                               ;; If `string-to-number' fails it returns 0.
                               (n (or (and r (string-to-number (cdr r))) 100)))
                          (if (zerop n) 100 n))))
              (< (num p1) (num p2)))))))

(defun bbdb-snarf-assoc (key regexp alist)
  "Return the first association in ALIST with key KEY or value matching REGEXP.
In the latter case, the key of the association must be nil.  Case is ignored."
  (let ((case-fold-search t)
        done)
    (while alist
      (if (or (bbdb-string= key (caar alist))
              (and (not (caar alist))
                   (string-match regexp (cdar alist))))
          (setq done (car alist)
                alist nil)
        (setq alist (cdr alist))))
    done))

(defun bbdb-snarf-vcard-name (record)
  "Snarf vCard properties N and/or FN => BBDB name and aka."
  ;; We give the structured N property precedence over the unstructured
  ;; FN property.  This choice may depend on details.
  ;; N may be present exactly once (it should be present for X.520 cards).
  ;; One or more FNs must be present per vCard.
  ;; We process all instances of N and FN and try to avoid duplicates.
  ;; The following code is supposed to accept some variations of RFC 6350.
  (let ((fn-list (bbdb-snarf-vcard-property "FN"))
        (n-list (bbdb-snarf-vcard-property "N" ";"))
        (affix (nreverse (bbdb-record-affix record)))
        (aka (nreverse (bbdb-record-aka record)))
        first last name)
    ;; N:last;first;middle;prefix;suffix
    ;; Each of these components may have multiple values separated by ","
    ;; (not yet implemented).
    (let ((n (caar n-list)))
      (when (nth 1 n) ; N is properly structured
        (pop n-list)
        (setq last (nth 0 n)
              first (bbdb-concat " " (nth 1 n) (nth 2 n)))
        (setq name (bbdb-concat 'name-first-last first last))
        (bbdb-pushnewt (nth 3 n) affix)   ; prefix
        (bbdb-pushnewt (nth 4 n) affix))) ; suffix

    ;; FN:formatted_name
    (when (and (not name) fn-list)
      (setq name (car (pop fn-list)))
      (let ((first-last (bbdb-divide-name name)))
        (setq first (car first-last)
              last (cdr first-last))))

    ;; last attempt for NAME: try to use an unstructured property N
    (when (and (not name) (caar n-list))
      (setq name (car (pop n-list)))
      (let ((first-last (bbdb-divide-name name)))
        (setq first (car first-last)
              last (cdr first-last))))

    ;; Though N should be present only once...
    (mapc (lambda (n)
            (let* ((val (car n))
                   (a (if (not (nth 1 val))
                          (nth 0 val)
                        (bbdb-pushnewt (nth 3 val) affix) ; prefix
                        (bbdb-pushnewt (nth 4 val) affix) ; suffix
                        (bbdb-concat " " (nth 1 val) (nth 2 val) (nth 0 val)))))
              (unless (string= a name) (bbdb-pushnew a aka))))
          n-list)

    (mapc (lambda (fn) (unless (string= name (car fn))
                         (bbdb-pushnew (car fn) aka)))
          fn-list)

    (setf (bbdb-record-firstname record) first)
    (setf (bbdb-record-lastname record) last)
    (setf (bbdb-record-affix record) (nreverse affix))
    (setf (bbdb-record-aka record) (nreverse aka))))

;; The following functions use repeatedly `nreverse' so that they append
;; their stuff at the end of what we may already have in a BBDB field.
;; Note also that `bbdb-snarf-vcard-property' sorts the instances
;; of a vCard property based on the vCard PREF parameter.  Preserve this!

(defun bbdb-snarf-vcard-adr (record)
  "Snarf vCard property ADR => BBDB address."
  ;; One or more ADRs may be present per vCard.
  (let ((addresses (nreverse (bbdb-record-address record))))
    (dolist (adr (bbdb-snarf-vcard-property "ADR" ";"))
      (let ((address (bbdb-address--make))
            (adr-list (car adr))
            streets)
        ;; This code cannot (yet) handle unstructured addresses
        ;; that violate RFC 6350.
        (if (not (nth 1 adr-list))
            (progn (message "Unstructured vCard address: not implemented")
                   (sit-for 1))
          (setf (bbdb-address-label address)
                (cdr (or (bbdb-snarf-assoc "TYPE" bbdb-snarf-vcard-adr-type-re
                                           (cdr adr))
                         (assq 'address bbdb-snarf-default-label-alist))))
          ;; (0) PO box  (1) extended address  (2) street  (3) city
          ;; (4) region  (5) postal code  (6) country
          (cl-flet ((str (n) (let ((elt (nth n adr-list)))
                               (and (stringp elt) (not (string= "" elt))))))
            ;; Make "PO Box" and "Apt" customizable?
            ;; Useful values may depend on the country of ADR.
            ;; RFC 6350: the components (0) and (1) should be empty!
            (if (str 0) (push (concat "PO Box " (nth 0 adr-list)) streets))
            (if (str 1) (push (concat "Apt " (nth 1 adr-list)) streets))
            ;; (2) street may be a comma-separated list of values.
            (if (str 2) (setq streets (nconc (nreverse (split-string (nth 2 adr-list)
                                                                     "," t))
                                             streets)))
            (setf (bbdb-address-streets address) (nreverse streets))
            (if (str 3) (setf (bbdb-address-city address) (nth 3 adr-list)))
            (if (str 4) (setf (bbdb-address-state address) (nth 4 adr-list)))
            (if (str 5) (setf (bbdb-address-postcode address) (nth 5 adr-list)))
            (if (str 6) (setf (bbdb-address-country address) (nth 6 adr-list))))
          (push address addresses))))
    (setf (bbdb-record-address record) (nreverse addresses))))

;; The following functions `bbdb-snarf-vcard-...' are pretty simple.
;; It may be easier to customize these functions directly than implementing
;; some fancy user-variable-based customizations of these functions.

(defun bbdb-snarf-vcard-nickname (record)
  "Snarf vCard property NICKNAME => BBDB aka."
  ;; One or more NICKNAMEs may be present per vCard.
  (let ((aka (nreverse (bbdb-record-aka record))))
    ;; This ignores any parameters of property NICKNAME!
    (mapc (lambda (nickname) ; list of values
            (mapc (lambda (n) (bbdb-pushnew n aka))
                  (car nickname)))
          (bbdb-snarf-vcard-property "NICKNAME" ","))
    (setf (bbdb-record-aka record) (nreverse aka))))

(defun bbdb-snarf-vcard-email (record)
  "Snarf vCard property EMAIL => BBDB mail."
  ;; One or more EMAILs may be present per vCard.
  (let ((mail (nreverse (bbdb-record-mail record))))
    ;; This ignores any parameters of property EMAIL!
    (mapc (lambda (elt) (bbdb-pushnew (car elt) mail))
          (bbdb-snarf-vcard-property "EMAIL"))
    (setf (bbdb-record-mail record) (nreverse mail))))

(defun bbdb-snarf-vcard-tel (record)
  "Snarf vCard property TEL => BBDB phone."
  ;; One or more TELs may be present per vCard.
  (let ((phones (nreverse (bbdb-record-phone record))))
    (mapc (lambda (phone)
            (bbdb-pushnew
             (vconcat (list (cdr (or (bbdb-snarf-assoc
                                      "TYPE" bbdb-snarf-vcard-tel-type-re (cdr phone))
                                     (assq 'phone bbdb-snarf-default-label-alist))))
                      (bbdb-parse-phone (car phone)))
             phones))
          (bbdb-snarf-vcard-property "TEL"))
    (setf (bbdb-record-phone record) (nreverse phones))))

(defun bbdb-snarf-vcard-org (record)
  "Snarf vCard property ORG => BBDB organization."
  ;; One or more ORGs may be present per vCard.
  (let ((orgs (nreverse (bbdb-record-organization record))))
    ;; This ignores any parameters of property ORG!
    (mapc (lambda (org) ; list of values
            (mapc (lambda (o) (bbdb-pushnew o orgs))
                  (car org)))
          (bbdb-snarf-vcard-property "ORG" ";"))
    (setf (bbdb-record-organization record) (nreverse orgs))))

(defun bbdb-snarf-vcard-uid (record)
  "Snarf vCard property UID => BBDB uuid."
  ;; The vCard UID property need not be a UUID.  We use it anyway
  ;; inside BBDB for the uuid field of RECORD and hope for the best.
  ;; Uniqueness of the (U)UID is really all that matters for BBDB.
  ;; Exactly one UID may be present per vCard.
  (setf (bbdb-record-uuid record)
        (caar (bbdb-snarf-vcard-property "UID"))))

(defun bbdb-snarf-vcard-url (record)
  "Snarf vCard property URL => BBDB xfield `bbdb-snarf-url'."
  ;; One or more URLs may be present per vCard.
  (if bbdb-snarf-url
      (let ((url (nreverse (bbdb-record-xfield-split record bbdb-snarf-url))))
        (mapc (lambda (u) (bbdb-pushnew (car u) url))
              (bbdb-snarf-vcard-property "URL"))
        (bbdb-record-set-xfield record bbdb-snarf-url
                                (bbdb-concat bbdb-snarf-url (nreverse url))))))

(defun bbdb-snarf-vcard-note (record)
  "Snarf vCard property NOTE => BBDB `bbdb-default-xfield'."
  ;; One or more NOTEs may be present per vCard.
  (dolist (note (bbdb-snarf-vcard-property "NOTE"))
    ;; We could put NOTE into the xfield specified by NOTE's TYPE parameter.
    (let ((xfield bbdb-default-xfield))
      (bbdb-record-set-xfield record xfield
                              (concat (bbdb-record-xfield record xfield)
                                      "\n" (car note))))))

;; Suggestions for more functions `bbdb-snarf-vcard-...' welcome!

;;;###autoload
(defun bbdb-snarf-vcard (&optional pos rule no-display)
  "Snarf BBDB record from vCard around position POS using RULE.
The vCard is the one that contains POS or follows POS.
POS defaults to the position of point.
RULE defaults to `bbdb-snarf-vcard'.  See `bbdb-snarf-rule-alist' for details.
Return record.  Also, display the record unless NO-DISPLAY is non-nil."
  (interactive (list (point) bbdb-snarf-vcard))
  (let ((rule (or rule bbdb-snarf-vcard))
        (pos (or pos (point)))
        (beg-re "^BEGIN:VCARD$")
        (limit-re "^\\(BEGIN\\|END\\):VCARD$")
        (end-re "^END:VCARD$")
        (case-fold-search t)
        beg end)
    (save-excursion
      (goto-char pos)
      (unless (and (setq beg (or (and (looking-at beg-re) pos)
                                 (save-excursion
                                   (and (re-search-backward limit-re nil t)
                                        (match-beginning 1)))
                                 (re-search-forward beg-re nil t)))
                   (setq end (re-search-forward end-re nil t)))
        (user-error "vCard not found")))
    (bbdb-snarf (buffer-substring-no-properties beg end) rule no-display)))

;;;###autoload
(defun bbdb-snarf-vcard-buffer (&optional rule no-display)
  "Snarf BBDB records from vCards in the current buffer.
RULE defaults to `bbdb-snarf-vcard'.  See `bbdb-snarf-rule-alist' for details.
Return the records.  Also, display the records unless NO-DISPLAY is non-nil."
  (interactive (list bbdb-snarf-vcard))
  (save-excursion
    (let ((case-fold-search t)
          records)
      (goto-char (point-min))
      (while (re-search-forward "^BEGIN:VCARD$" nil t)
        (let ((record (bbdb-snarf-vcard (match-beginning 0) rule t)))
          (if record (push record records))))
      (if (and records (not no-display))
          (bbdb-display-records records))
      records)))

(defsubst bbdb-snarf-rule-interactive ()
  "Read snarf rule interactively."
  (intern
   (completing-read
    (format "Rule: (default `%s') " bbdb-snarf-rule-default)
    bbdb-snarf-rule-alist nil t nil nil
    (symbol-name bbdb-snarf-rule-default))))

;;;###autoload
(defun bbdb-snarf-paragraph (pos &optional rule no-display)
  "Snarf BBDB record from paragraph around position POS using RULE.
The paragraph is the one that contains POS or follows POS.
Interactively POS is the position of point.
RULE defaults to `bbdb-snarf-rule-default'.
See `bbdb-snarf-rule-alist' for details.
Return record.  Also, display the record unless NO-DISPLAY is non-nil."
  (interactive (list (point) (bbdb-snarf-rule-interactive)))
  (bbdb-snarf (save-excursion
                (goto-char pos)
                ;; similar to `mark-paragraph'
                (let ((end (progn (forward-paragraph 1) (point))))
                  (buffer-substring-no-properties
                   (progn (backward-paragraph 1) (point))
                   end)))
              rule no-display))

;;;###autoload
(defun bbdb-snarf-yank (&optional rule no-display)
  "Snarf a BBDB record from latest kill using RULE.
The latest kill may also be a window system selection, see `current-kill'.
RULE defaults to `bbdb-snarf-rule-default'.
See `bbdb-snarf-rule-alist' for details.
Return record.  Also, display the record unless NO-DISPLAY is non-nil."
  (interactive (list (bbdb-snarf-rule-interactive)))
  (bbdb-snarf (current-kill 0) rule no-display))

;;;###autoload
(defun bbdb-snarf (string &optional rule no-display)
  "Snarf a BBDB record in STRING using RULE.
Interactively, STRING is the current region.
RULE defaults to `bbdb-snarf-rule-default'.
See `bbdb-snarf-rule-alist' for details.
Return the record.  Also, displau the record unless NO-DISPLAY is non-nil.
Discard the record and return nil if the record does not have a name or mail."
  (interactive
   (list (buffer-substring-no-properties (region-beginning) (region-end))
         (bbdb-snarf-rule-interactive)))

  (bbdb-editable)
  (let ((record (bbdb-empty-record)))
    (with-current-buffer (get-buffer-create " *BBDB Snarf*")
      (erase-buffer)
      (insert (substring-no-properties string))
      (mapc (lambda (fun)
              (goto-char (point-min))
              (funcall fun record))
            (cdr (assq (or rule bbdb-snarf-rule-default)
                       bbdb-snarf-rule-alist))))
    ;; Discard RECORD if it does not have a name or mail.
    ;; Is this scheme too simplistic?
    (if (not (or (bbdb-record-firstname record)
                 (bbdb-record-lastname record)
                 (bbdb-record-mail record)))
        (progn (message "Snarfing failed") nil) ; return nil
      (let ((old-record (car (bbdb-message-search
                              (bbdb-concat 'name-first-last
                                           (bbdb-record-firstname record)
                                           (bbdb-record-lastname record))
                              (car (bbdb-record-mail record))))))
        (if old-record
            (setq record (bbdb-merge-records record old-record))
          (bbdb-change-record record)))
      (unless no-display
        (bbdb-display-records (list record)))
      record)))

;; Some test cases
;;
;; US:
;;
;; another test person
;; 1234 Gridley St.
;; Los Angeles, CA 91342
;; 555-1212
;; test@person.net
;; http://www.foo.bar/
;; other stuff about this person
;;
;; test person
;; 1234 Gridley St.
;; St. Los Angeles, CA 91342-1234
;; 555-1212
;; <test@person.net>
;;
;; x test person
;; 1234 Gridley St.
;; Los Angeles, California 91342-1234
;; work: 555-1212
;; home: 555-1213
;; test@person.net
;;
;; y test person
;; 1234 Gridley St.
;; Los Angeles, CA
;; 555-1212
;; test@person.net
;;
;; z test person
;; 555-1212
;; test@person.net
;;
;; EU:
;;
;; Maja Musterfrau
;; Strasse 15
;; 12345 Ort
;; +49 12345
;; phon: (110) 123 456
;; mobile: (123) 456 789
;; xxx.xxx@xxxx.xxx
;; http://www.xxx.xx
;; notes bla bla bla
;;
;; Vcard:
;; BEGIN:VCARD
;; VERSION:3.0
;; FN;Pref=1;TYPE=work:Another te
;;  st person
;; FN:Another test person
;; N:Person;another;test;Dr;Sen
;; EMAIL:foo@bar.com
;; EMAIL:bar@baz.com
;; END:VCARD

(provide 'bbdb-snarf)

;;; bbdb-snarf.el ends here
