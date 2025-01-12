;;; ebdb.el --- Contact management package           -*- lexical-binding: t; -*-

;; Copyright (C) 2016-2023  Free Software Foundation, Inc.

;; Version: 0.8.20
;; Package-Requires: ((emacs "25.1") (seq "2.15"))

;; Maintainer: Eric Abrahamsen <eric@ericabrahamsen.net>

;; Author: Eric Abrahamsen <eric@ericabrahamsen.net>
;; Keywords: convenience mail

;; URL: https://github.com/girzel/ebdb

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

;; This package began as a port of the Insidious Big Brother Database
;; (by Jamie Zawinski and Roland Winkler) using EIEIO, Emacs' newish
;; object-orientation library.  Eventually it developed to the point
;; where a separate package seemed to make most sense.  But the basic
;; behavior of the package, and the look of the *EBDB* buffer, are
;; still very much indebted to the original library.  Some of the
;; original files have been directly copied over and renamed -- where
;; applicable, the names of the authors of the original libraries have
;; been noted.

;; This file contains the basic data structures and behavior for EBDB,
;; including the class definitions for databases, records, and fields.

;; The order of appearance of code in this file is mostly determined
;; by the order in which the compiler wants to see things.

;;; Code:

(require 'timezone)
(require 'cl-lib)
(require 'seq)
(require 'map)
(require 'calendar)
(require 'subr-x)
(require 'pcase)
(require 'eieio)
(require 'eieio-base)
(require 'eieio-opt)
(require 'mailabbrev)

;; Pacify the compiler.
(autoload 'ebdb-i18n-countries "ebdb-i18n")
(autoload 'widget-group-match "wid-edit")
(autoload 'ebdb-migrate-from-bbdb "ebdb-migrate")
(autoload 'eieio-customize-object "eieio-custom")
(autoload 'diary-ordinal-suffix "diary-lib")
(autoload 'org-agenda-list "org-agenda")
(autoload 'org-make-tags-matcher "org")
(defvar ebdb-i18n-countries)
(defvar ebdb-i18n-countries-pref-scripts)

;; These are the most important internal variables, holding EBDB's
;; data structures.

(defvar ebdb-db-list nil
  "The list of currently-loaded EBDB databases.")

(defvar ebdb-record-tracker nil
  "A list of all the loaded records.")

(defvar ebdb-hashtable (make-hash-table :test #'equal)
  "Hash table for EBDB records.
Hashes the fields first-last-name, last-first-name, organization, aka,
and mail.")

(defvar ebdb-org-hashtable (make-hash-table :size 500 :test #'equal)
  "Hash table of role relationships.
Keys are string UUIDs of organizations. Values are lists
of (record-uuid . role-field). Hashtable entries are created and
deleted by the `ebdb-init-field' and `ebdb-delete-field' methods
of the `ebdb-field-role' field class.")

(defvar ebdb-relation-hashtable (make-hash-table :size 500 :test #'equal)
  "Hash table of record relationships.
Keys are the related records' UUIDs, values are the relation
fields themselves.")

;;; Internal variables
(eval-and-compile
  (defvar ebdb-debug t
    "Enable debugging if non-nil during compile time.
You really should not disable debugging.  But it will speed things up."))

(defvar ebdb-silent-internal nil
  "Bind this to t to quiet things down - do not set it.
See also `ebdb-silent'.")

(defvar ebdb-dwim-completion-cache nil
  "A list of strings as returned by `ebdb-dwim-mail'.
As mail field instances are created, a \"dwim\"-style string is
added here, for use in `completion-at-point' in mail buffers.")

(defvar ebdb-read-string-override nil
  "An overriding prompt for `ebdb-read-string'.
This is bound dynamically around code that will end up calling
`ebdb-read-string'.  It can be a plain string, in which case the
value will replace the existing prompt.  It can also be a cons
of (STRING . POSITION), where POSITION can be one of the symbols
`append' or `prepend', in which case STRING will be concatenated
with the existing prompt as appropriate.")

;; Custom groups

(defgroup ebdb-eieio nil
  "Options for an EIEIO version of EBDB."
  :group 'ebdb)

(defcustom ebdb-sources (locate-user-emacs-file "ebdb")
  "User option specifying EBDB database sources.
It can be a single element, or a list of elements.  If an element
is a string, it is treated as a filename, and used to create an
instance of `ebdb-db-file'.

Elements can also be instances of subclasses of `ebdb-db'.
Currently, the only subclass is `ebdb-db-file', though you can
create your own.  When EBDB is loaded, the `ebdb-db-load' method
will be called on each of class instances."
  :group 'ebdb-eieio
  ;; Apparently we can't specify EBDB objects here.
  :type '(choice (file :tag "File")
		; (ebdb-db :tag "EBDB database instance")
		 (repeat (file :tag "File")
		  ;; (choice (file :tag "File")
		  ;; 	  (ebdb-db :tag "EBDB database instance"))
		  )))

(defcustom ebdb-auto-merge-records nil
  "If non-nil, automatically merge multiple records with the same UUID.
If you are using multiple databases, and intend to keep some
records in more than one database at once, you can set this to t
to have EBDB treat records with identical UUIDs as \"the same\"
record, and merge them automatically when the databases are
loaded.  If it is nil, you'll be prompted to do an interactive
merge.

Merging is currently \"dumb\", ie the record with the older
timestamp is essentially deleted and replaced by the newer.
Future merging strategies may be smarter."
  :group 'ebdb-eieio
  :type 'boolean)

(defcustom ebdb-save-on-exit nil
  "If non-nil, automatically save EBDB when exiting Emacs.
The user is always prompted to save the EBDB as part of the Emacs
shutdown process anyway, reducing the usefulness of this option.
If you're using EBDB without opening `ebdb-mode' buffers, you
might consider setting it to t."
  :group 'ebdb-eieio
  :type 'boolean)

(defcustom ebdb-default-record-class 'ebdb-record-person
  "The default class to use for new records."
  :group 'ebdb-eieio
  :type '(restricted-sexp
	  :match-alternatives ((lambda (cls)
				 (and cls
				      (child-of-class-p
				       cls 'ebdb-record))))))

(defcustom ebdb-default-name-class 'ebdb-field-name-complex
  "The default name class to use for person records.

Organization names are currently hard-coded to use
`ebdb-field-name-simple'."
  :group 'ebdb-eieio
  :type '(restricted-sexp
	  :match-alternatives ((lambda (cls)
				 (and cls
				      (child-of-class-p
				       cls 'ebdb-field-name))))))

(defcustom ebdb-default-mail-class 'ebdb-field-mail
  "The default class to use for mail fields."
  :group 'ebdb-eieio
  :type '(restricted-sexp
	  :match-alternatives ((lambda (cls)
				 (and cls
				      (child-of-class-p
				       cls 'ebdb-field-mail))))))

(defcustom ebdb-default-phone-class 'ebdb-field-phone
  "The default class to use for phone fields."
  :group 'ebdb-eieio
  :type '(restricted-sexp
	  :match-alternatives ((lambda (cls)
				 (and cls
				      (child-of-class-p
				       cls 'ebdb-field-phone))))))

(defcustom ebdb-default-address-class 'ebdb-field-address
  "The default class to use for address fields."
  :group 'ebdb-eieio
  :type '(restricted-sexp
	  :match-alternatives ((lambda (cls)
				 (and cls
				      (child-of-class-p
				       cls 'ebdb-field-address))))))

(defcustom ebdb-default-notes-class 'ebdb-field-notes
  "The default class to use for notes fields."
  :group 'ebdb-eieio
  :type '(restricted-sexp
	  :match-alternatives ((lambda (cls)
				 (and cls
				      (child-of-class-p
				       cls 'ebdb-field-notes))))))

(defcustom ebdb-try-speedups nil
  "When non-nil, try to speed up loading by disabling checks.
This will set `eieio-skip-typecheck' when loading databases.  The
type checks are done for a reason, it's possible this might lead
to errors or database corruption."
  :group 'ebdb-eieio
  :type 'boolean)

;; Do not use this to prevent writing of object-names via
;; `eieio-print-object-name', older Emacs will choke if it's not
;; present.
(defcustom ebdb-vacuum-databases t
  "When non-nil, minimize the size of database files.
This option only has an effect in Emacs>27.  At present it
prevents indentation from being written to the persistence files;
in the future more shrinkage may be possible."
  :group 'ebdb-eieio
  :type 'boolean)

(defcustom ebdb-print-object-name t
  "When non-nil, print object names in the database files.
This is an EBDB-specific version of the option
`eieio-print-object-name', which only exists in Emacs 27 or
higher.  It will have no effect in earlier versions of Emacs, but
do note that Emacs 26 or lower REQUIRES that the name be present,
and will raise an error if it is not.  If there's a chance that a
database might be written by a newer Emacs, and read by an older,
do not set this to nil."
  :group 'ebdb-eieio
  :type 'boolean)

(defgroup ebdb nil
  "EBDB customizations"
  :group 'news
  :group 'mail)

(defgroup ebdb-record-edit nil
  "Variables that affect the editing of EBDB records."
  :group 'ebdb)

(defgroup ebdb-sendmail nil
  "Variables that affect sending mail."
  :group 'ebdb)

(defgroup ebdb-snarf nil
  "Customizations for EBDB snarf."
  :group 'ebdb)
(put 'ebdb-snarf-snarf 'custom-loads '(ebdb-snarf))

(defgroup ebdb-search nil
  "Customizations for EBDB searching."
  :group 'ebdb)

(defgroup ebdb-utilities nil
  "Customizations for EBDB utilities."
  :group 'ebdb)

(defgroup ebdb-utilities-anniv nil
  "Customizations for EBDB anniversaries."
  :group 'ebdb)

(defgroup ebdb-utilities-dialing nil
  "EBDB customizations for phone number dialing."
  :group 'ebdb-utilities)

(defgroup ebdb-utilities-ispell nil
  "Customizations for EBDB ispell interface"
  :group 'ebdb-utilities)
(put 'ebdb-utilities-ispell 'custom-loads '(ebdb-ispell))

(defgroup ebdb-utilities-pgp nil
  "Customizations for EBDB pgp"
  :group 'ebdb-utilities)
(put 'ebdb-utilities-pgp 'custom-loads '(ebdb-pgp))

;;; Customizable variables
(defcustom ebdb-image nil
  "The default method for displaying record images.
If a record is given a `ebdb-field-image' field, the value of
that field specifies how or where to find the image for the
record.  This option provides a default for that value.

If the field value is `name' or `fl-name', the first and last
name of the record are used as file name.  If it is `lf-name',
the last and first name of the record are used as file name.

If it is a string, that string is assumed to be a filename and
the file is searched in the directories in `ebdb-image-path'.
File name suffixes are appended according to
`ebdb-image-suffixes'.  See `locate-file'.

If it is nil, the method `ebdb-field-image-function' will be
called with two arguments: the image field and the record.  The
function should return either a filename, or actual image data."
  :group 'ebdb-record-edit
  :type '(choice (const :tag "Use built-in function" nil)
		 (string :tag "File name")
                 (const name)
		 (const fl-name)
		 (const lf-name)))

(defcustom ebdb-uuid-function "uuidgen"
  "Function used for creating a UUID for records.
If a string, assume a system executable.  If a symbol, assume an
elisp function for creating UUIDs.  For instance, `org-id-uuid'
is a good candidate."
  :group 'ebdb
  :type '(choice (string :tag "System executable name")
                 (function :tag "Function creating UUIDs")))

(defcustom ebdb-record-self nil
  "The UUID of the record representing the user.
See the docstring of `ebdb-user-mail-address-re' for possible uses."
  :group 'ebdb
  :type 'string)

(defcustom ebdb-country-list nil
  "A list of country names known to EBDB.
This is a list of simple strings, which do not change EBDB's
behavior in any way.  You can also require the \"ebdb-i18n\"
library for more internationally-aware functionality, in which
case this variable will be ignored."
  :group 'ebdb
  :type '(repeat string))

(defcustom ebdb-default-address-format-function #'ebdb-format-address-default
  "Default function used to format an address.
This function produces a string that looks more or less like a US
address.  Either write a custom function to format all addresses,
or load `ebdb-i18n' to format addresses based on country-specific
rules."

  :group 'ebdb
  :type 'function)

(defcustom ebdb-auto-revert nil
  "If t revert unchanged database without querying.

If t and a database file has changed on disk, while the database
has not been modified inside Emacs, revert the database
automatically.  If nil or the database has been changed inside
Emacs, always query before reverting."

  :group 'ebdb
  :type
  '(choice (const :tag "Revert unchanged database without querying"
		  t)
	   (const :tag "Ask before reverting database" nil)))

(defcustom ebdb-use-diary t
  "If non-nil add anniversary field values to the diary."
  :group 'ebdb-utilities-anniv
  :type 'boolean)

(make-obsolete-variable
 'ebdb-use-diary
 "Add %%(ebdb-diary-anniversaries) to your diary or to Org" "0.8")

(defcustom ebdb-anniversary-md-format "%B %d"
  "Format string used for displaying month-day anniversary dates.
See the docstring of `format-time-string' for the meaning of
various formatting escapes, but keep in mind that only month and
day values are available."
  :group 'ebdb-utilities-anniv
  :type 'string)

(defcustom ebdb-anniversary-ymd-format "%B %d, %Y"
  "Format string used for displaying year-month-day anniversary dates.
See the docstring of `format-time-string' for the meaning of
various formatting escapes, but keep in mind that only year,
month, and day values are available."
  :group 'ebdb-utilities-anniv
  :type 'string)

(defvar ebdb-diary-entries (make-hash-table :test #'equal)
  "Hash table holding anniversary entries for the diary.
Keys are dates in the format (MONTH DAY YEAR), values are lists
of anniversary strings.  Instances of `ebdb-field-anniversary'
fields can push descriptive strings into the hash entries for
their dates.  Also see `ebdb-diary-anniversaries'.")

(defcustom ebdb-before-load-hook nil
  "Hook run before loading databases."
  :group 'ebdb
  :type 'hook)

(defcustom ebdb-after-load-hook nil
  "Hook run after loading databases."
  :group 'ebdb
  :type 'hook)

(defcustom ebdb-before-save-hook nil
  "Hook run before saving all databases."
  :type 'hook)

(defcustom ebdb-after-save-hook nil
  "Hook run after saving all databases."
  :type 'hook)

(defvar ebdb-create-hook nil
  "*Hook run each time a new EBDB record is created.
Run with one argument, the new record.  This is called before the record is
added to the database, followed by a call of `ebdb-change-hook'.

If a record has been created by analyzing a mail message, hook functions
can use the variable `ebdb-update-records-address' to determine the header
and class of the mail address according to `ebdb-message-headers'.")

(defvar ebdb-change-hook nil
  "*Hook run each time a EBDB record is changed.
Run with one argument, the record.  This is called before the database
is modified.  If a new ebdb record is created, `ebdb-create-hook' is called
first, followed by a call of this hook.")

(defcustom ebdb-time-format "%Y-%m-%d %T %z"
  "The EBDB time stamp format.
Used for human-readable display of timestamp values."
  :group 'ebdb
  :type 'string)

(defcustom ebdb-after-change-hook nil
  "Hook run each time a EBDB record is changed.
Run with one argument, the record.  This is called after the database
is modified.  So if you want to modify a record when it is created or changed,
use instead `ebdb-create-hook' and / or `ebdb-change-hook'."
  :group 'ebdb
  :type 'hook)

;; These two hooks could actually be done away with, and replaced by
;; method overloads on `ebdb-db-load'.  But users will probably be
;; more familiar with hooks than with method overloading.
(defcustom ebdb-before-load-db-hook nil
  "Hook run before each database is loaded.
Run with one argument, the database being loaded."
  :group 'ebdb
  :type 'hook)

(defcustom ebdb-after-load-db-hook nil
  "Hook run after each database is loaded.
Run with one argument, the database being loaded."
  :group 'ebdb
  :type 'hook)

(defcustom ebdb-before-save-db-hook nil
  "Hook run before each database is saved.
Run with one argument, the database being saved."
  :group 'ebdb
  :type 'hook)

(defcustom ebdb-after-save-db-hook nil
  "Hook run after each database is saved.
Run with one argument, the database being saved."
  :group 'ebdb
  :type 'hook)

(defcustom ebdb-initialize-hook nil
  "Normal hook run after the EBDB initialization function `ebdb-initialize'."
  :group 'ebdb
  :type 'hook)

(defcustom ebdb-silent nil
  "If t, EBDB suppresses all its informational messages and queries.
Be very very certain you want to set this to t, because it will suppress
queries to alter record names, assign names to addresses, etc.
Lisp Hackers: See also `ebdb-silent-internal'."
  :group 'ebdb
  :type '(choice (const :tag "Run silently" t)
                 (const :tag "Disable silent running" nil)))

(defcustom ebdb-search-transform-functions nil
  "Functions used to transform strings during searching.
Each time the user enters a search search string during
interactive search, that string will be passed through each of
the functions in this list, which have a chance to modify the
string somehow before it is actually matched against field
values.

Each function should accept a single argument, a string, and
return the transformed string.  If the criteria for any given
search is not a string, it will not be passed through these
functions."

  :group 'ebdb-search
  :type '(repeat :tag "String transformation function" function))

(defcustom ebdb-case-fold-search (default-value 'case-fold-search)
  "Value of `case-fold-search' used when searching EBDB records."

  :group 'ebdb-search
  :type 'boolean)

(defcustom ebdb-char-fold-search nil
  "If t, record searches will use character folding.

Character folding means that, for instance, searches for \"i\"
will match \"ì\", and so on.  This may slow searching down."

  :group 'ebdb-search
  :type 'boolean)

(defcustom ebdb-hash-extra-predicates nil
  "Extra predicates when looking up entries in the EBDB hashtable.

Predicates are used to filter results from the hashtable,
ensuring that string lookups only return the results they're
meant to.

This option should be a list of conses, where the car is a
symbol, and the cdr is a lambda form which accepts the string key
and a record, and returns t if the key is acceptable for
returning that record."
  :group 'ebdb-search
  :package-version "0.2"
  :type '(repeat (cons symbol function)))

(defcustom ebdb-signal-program (executable-find "signal-cli")
  "The name of the signal-cli program, if installed.

This program must be present in order to send text messages
through the Signal service."
  :group 'ebdb-utilities-dialing
  :type 'string)

(defcustom ebdb-info-file nil
  "Location of the ebdb info file, if it's not in the standard place."
  :group 'ebdb
  :type '(choice (const :tag "Standard location" nil)
                 (file :tag "Nonstandard location")))

(defcustom ebdb-canonical-hosts
  ;; Example
  (regexp-opt '("cs.cmu.edu" "ri.cmu.edu"))
  "Regexp matching the canonical part of the domain part of a mail address.
If the domain part of a mail address matches this regexp, the domain
is replaced by the substring that actually matched this address.

Used by  `ebdb-canonicalize-mail-1'.  See also `ebdb-ignore-redundant-mails'."
  :group 'ebdb-utilities
  :type '(regexp :tag "Regexp matching sites"))

(defcustom ebdb-canonicalize-mail-function nil
  "If non-nil, it should be a function of one arg: a mail address string.
When EBDB is parsing mail addresses, the corresponding mail
addresses are passed to this function first.  It acts as a kind
of \"filter\" to transform the mail addresses before they are
compared against or added to the database.  See
`ebdb-canonicalize-mail-1' for a more complete example.  If this
function returns nil, EBDB assumes that there is no mail address.

See also `ebdb-ignore-redundant-mails'."
  :group 'ebdb-utilities
  :type 'function)

(defcustom ebdb-message-clean-name-function 'ebdb-message-clean-name-default
  "Function to clean up the name in the header of a message.
It takes one argument, the name as extracted by
`mail-extract-address-components'."
  :group 'ebdb-utilities
  :type 'function)

(defsubst ebdb-record-self ()
  "Return the \"self\" record."
  (ebdb-gethash ebdb-record-self 'uuid))

;;; Record editing

(defcustom ebdb-default-separator '("[,;]" ", ")
  "The default field separator.  It is a list (SPLIT-RE JOIN).
This is used for fields which do not have an entry in `ebdb-separator-alist'."
  :group 'ebdb-record-edit
  :type '(list regexp string))

(defcustom ebdb-separator-alist
  '((record "\n\n" "\n\n") ; used by `ebdb-copy-fields-as-kill'
    (name-first-last "[ ,;]" " ")
    (name-last-first "[ ,;]" ", ")
    (name-field ":\n" ":\n") ; used by `ebdb-copy-fields-as-kill'
    (phone "[,;]" ", ")
    (address ";\n" ";\n")
    (organization "[,;]" ", ")
    (aka "[,;]" ", ")
    (mail "[,;]" ", ")
    (ebdb-field-tags ":" ":")
    (mail-alias "[,;]" ", ")
    (vm-folder "[,;]" ", ")
    (birthday "\n" "\n")
    (wedding "\n" "\n")
    (anniversary "\n" "\n")
    (notes "\n" "\n"))
  "Alist of field separators.
Each element is of the form (FIELD SPLIT-RE JOIN).
For fields lacking an entry here `ebdb-default-separator' is used instead."
  :group 'ebdb-record-edit
  :type '(repeat (list symbol regexp string)))

(defcustom ebdb-completion-ignore-case t
  "EBDB-specific value of `completion-ignore-case'.
This has an effect when entering field data with completion, for
instance anniversary months or address countries."
  :group 'ebdb-record-edit
  :type 'boolean)

(defcustom ebdb-image-path nil
  "List of directories to search for `ebdb-image'."
  :group 'ebdb-record-edit
  :type '(repeat (directory)))

(defcustom ebdb-image-suffixes '(".png" ".jpg" ".gif" ".xpm")
  "List of file name suffixes searched for `ebdb-image'."
  :group 'ebdb-record-edit
  :type '(repeat (string :tag "File suffix")))

(defcustom ebdb-read-name-articulate nil
  "Specify how to read record names.

If nil, read full names as single strings, and parse them
accordingly.  If t, the user will be prompted separately for each
field of the name.

If this option is nil, and the user enters a single string, the
resulting name field will be an instance of
`ebdb-field-name-simple'.  Even if this option is t, the user can
still trigger the creation of a simple name field by entering a
single string for the surname, and nothing else."
  :group 'ebdb-record-edit
  :type 'boolean)

(defcustom ebdb-lastname-prefixes
 '("von" "van" "de" "di")
  "List of lastname prefixes recognized in name fields.
Used to enhance dividing name strings into firstname and lastname parts.
Case is ignored."
  :group 'ebdb-record-edit
  :type '(repeat string))

(defcustom ebdb-lastname-re
  (concat "[- \t]*\\(\\(?:\\<"
          (regexp-opt ebdb-lastname-prefixes)
          ;; Last names can contain hyphens and apostrophes.
          "\\>[- \t]+\\)?\\w[[:word:]'-]+\\)\\>")
  "Regexp matching the last name of a full name.
Its first parenthetical subexpression becomes the last name."
  :group 'ebdb-record-edit
  :type 'regexp)

(defcustom ebdb-lastname-suffixes
 '("Jr" "Sr" "II" "III")
  "List of lastname suffixes recognized in name fields.
Used to dividing name strings into firstname and lastname parts.
All suffixes are complemented by optional `.'.  Case is ignored."
  :group 'ebdb-record-edit
  :type '(repeat string))

(defcustom ebdb-lastname-suffix-re
  (concat "[-,. \t/\\]+\\("
          (regexp-opt ebdb-lastname-suffixes)
          ;; suffices are complemented by optional `.'.
          "\\.?\\)\\W*\\'")
  "Regexp matching the suffix of a last name.
Its first parenthetical subexpression becomes the suffix."
  :group 'ebdb-record-edit
  :type 'regexp)

(defcustom ebdb-allow-duplicates nil
  "When non-nil EBDB allows records with duplicate names and email addresses.
In rare cases, this may lead to confusion with EBDB's MUA interface."
  :group 'ebdb-record-edit
  :type 'boolean)

(defcustom ebdb-address-label-list '("home" "work" "other")
  "List of labels for Address field."
  :group 'ebdb-record-edit
  :type '(repeat string))

(defcustom ebdb-phone-label-list '("home" "work" "cell" "fax" "other")
  "List of labels for Phone field."
  :group 'ebdb-record-edit
  :type '(repeat string))

(defcustom ebdb-default-country "Emacs";; what do you mean, it's not a country?
  "Default country to use for addresses."
  :group 'ebdb-record-edit
  :type '(choice (const :tag "None" nil)
                 (string :tag "Default Country")))

(defcustom ebdb-default-phone-country nil
  "Default country to use for phone numbers.
Should be an integer representing the country code for phone
numbers.

If EBDB can't determine the country when parsing a phone number,
it will assume this default, if set.  When displaying phone
numbers, the country code will be omitted if it matches this
option."
  :group 'ebdb-record-edit
  :type '(choice (const :tag "None" nil)
                 (integer :tag "Default Country")))

(defcustom ebdb-default-user-field 'ebdb-field-notes
  "Default field when editing EBDB records."
  :group 'ebdb-record-edit
  :type '(symbol :tag "Field"))

(defcustom ebdb-url-valid-schemes '("http:" "https:" "irc:")
  "Strings matching acceptable URL schemes.
Strings should not be regular expressions.  They should include
the colon character."

  :group 'ebdb-record-edit
  :type '(repeat string))

(defcustom ebdb-mail-avoid-redundancy nil
  "How to handle the name part of `ebdb-dwim-mail'.

If nil, always return both name and mail.  If value is mail-only
never use full name.  Other non-nil values mean do not use full
name in mail address when same as mail."
  :group 'ebdb-sendmail
  :type '(choice (const :tag "Allow redundancy" nil)
                 (const :tag "Never use full name" mail-only)
                 (const :tag "Avoid redundancy" t)))

(defcustom ebdb-complete-mail t
  "If non-nil composition MUAs will complete EBDB contacts.
Completion takes place within mail headers that specify one or
more message recipients.  A value of `capf' will add an EBDB
collection to `completion-at-point-functions'.  Any other non-nil
value will override \"TAB\" to call `ebdb-complete-mail'."
  :group 'ebdb-sendmail
  :type '(choice (const :tag "Use `ebdb-complete-mail'" t)
		 (const :tag "Do not complete mail addresses" nil)
		 (const :tag "Use completion at point" capf)))

(defcustom ebdb-completion-list t
  "Controls the behaviour of function `ebdb-complete-mail'.
If a list of symbols, it specifies which fields to complete.  Symbols include
  name (= record's display name)
  alt-names (= any other names the record has)
  organization
  mail (= all email addresses of each record)
  primary (= first email address of each record)
If t, completion is done for all of the above.
If nil, no completion is offered."
  ;; These symbols match the fields for which EBDB provides entries in
  ;; `ebdb-hash-table'.
  :group 'ebdb-sendmail
  :type '(choice (const :tag "No Completion" nil)
                 (const :tag "Complete across all fields" t)
                 (repeat :tag "Field"
                         (choice (const name)
                                 (const alt-names)
                                 (const organization)
                                 (const primary)
                                 (const mail)))))

(defcustom ebdb-complete-mail-allow-cycling 5
  "If non-nil, cycle mail addresses when completing mails.
If `ebdb-complete-mail' is set to `capf', this option can be set
to an integer number, specifying that completion should take
place when there are that many completion candidates or fewer.
Otherwise, cycling will take place among all a single contact's
email addresses."
  :group 'ebdb-sendmail
  :type '(choice (const :tag "Never cycle" nil)
		 (const :tag "Always cycle" t)
		 (number :tag "Cycle for this many candidates or fewer")))

(defcustom ebdb-complete-mail-hook nil
  "List of functions called after a successful completion."
  :group 'ebdb-sendmail
  :type 'hook)

(defcustom ebdb-mail-abbrev-expand-hook nil
  ;; Replacement for function `mail-abbrev-expand-hook'.
  "Function (not hook) run each time an alias is expanded.
The function is called with two args: the alias and the list of
corresponding mail addresses."
  :group 'ebdb-sendmail
  :type 'function)

(defcustom ebdb-completion-display-record t
  "If non-nil, `ebdb-complete-mail' will display records after completion."
  :group 'ebdb-sendmail
  :type '(choice (const :tag "Update the EBDB buffer" t)
                 (const :tag "Do not update the EBDB buffer" nil)))

(defvar ebdb-update-unchanged-records nil
  "If non-nil update unchanged records in the database.
Normally calls of `ebdb-change-hook' and updating of a record are suppressed,
if an editing command did not really change the record.  Bind this to t
if you want to call `ebdb-change-hook' and update the record unconditionally.")

(defvar ebdb-street-list nil
  "List of streets known to EBDB.")

(defvar ebdb-locality-list nil
  "List of localities (towns or cities) known to EBDB.")

(defvar ebdb-region-list nil
  "List of regions (states or provinces) known to EBDB.")

(defvar ebdb-postcode-list nil
  "List of post codes known to EBDB.")

;;; Define some of our own errors. A few of these should never be
;;; shown to the user, they're for internal flow control.

;; Error parent
(define-error 'ebdb-error "EBDB error")

(define-error 'ebdb-duplicate-uuid "Duplicate EBDB UUID" 'ebdb-error)

(define-error 'ebdb-related-unfound "Could not find related record" 'ebdb-error)

(define-error 'ebdb-unsynced-db "EBDB DB unsynced" 'ebdb-error)

(define-error 'ebdb-disabled-db "EBDB DB disabled" 'ebdb-error)

(define-error 'ebdb-readonly-db "EBDB DB read-only" 'ebdb-error)

(define-error 'ebdb-unacceptable-field "EBDB record cannot accept field" 'ebdb-error)

(define-error 'ebdb-empty "Empty value" 'ebdb-error)

(define-error 'ebdb-unparseable "Unparseable value" 'ebdb-error)

;;; Utility functions and macros

;;;###autoload
(defsubst ebdb-records (&optional record-class child-p)
  "Return a list of all EBDB records; load databases if necessary.
This function also notices if databases are out of sync.

If RECORD-CLASS is given, only return records of this class or,
if CHILD-P is non-nil, one of its subclasses."
  (unless ebdb-db-list
    (ebdb-load))
  (if record-class
      (seq-filter
       (lambda (r)
	 (if child-p
	     (object-of-class-p r record-class)
	   (same-class-p r record-class)))
       ebdb-record-tracker)
   ebdb-record-tracker))

(defmacro ebdb-error-retry (&rest body)
  "Repeatedly execute BODY ignoring errors till no error occurs."
  `(catch '--ebdb-error-retry--
     (while t
       (condition-case --c--
           (throw '--ebdb-error-retry-- (progn ,@body))
         (ebdb-unparseable
	  (ding)
	  (message "Error: %s" (nth 1 --c--))
	  (sit-for 2))))))

(defmacro ebdb-with-exit (&rest body)
  "Execute BODY, returning nil on quit or an empty value."
  `(condition-case nil
       ,@body
     ((quit ebdb-empty)
      nil)))

(defmacro ebdb-loop-with-exit (&rest body)
  "Repeat BODY, accumulating the results in a list.
\\<minibuffer-mode-map>Return when the user either hits
\\[keyboard-quit], or enters an empty field value."
  `(let (acc)
     (catch '--ebdb-loop-exit--
       (condition-case nil
	   (while t
	     (push ,@body acc))
	 ((quit ebdb-empty)
	  (throw '--ebdb-loop-exit-- (nreverse acc)))))))

(defmacro ebdb-debug (&rest body)
  "Execute BODY just like `progn' with debugging capability.
Debugging is enabled if variable `ebdb-debug' is non-nil during compile.
You really should not disable debugging.  But it will speed things up."
  (declare (indent 0))
  (if ebdb-debug ; compile-time switch
      `(let ((debug-on-error t))
         ,@body)))

(defmacro ebdb-pushnew (element place)
  `(cl-pushnew ,element ,place :test #'equal))

(defmacro ebdb-delete-from-list (element list-var)
  "Remove ELEMENT from LIST-VAR, if present.
Test for presence is done with `equal'."
  (macroexp-let2 nil element element
    `(when ,element
       ,(gv-letplace (getter setter) list-var
	  (funcall setter `(delete ,element ,getter))))))

;;; Struct and object definitions.

;; The calls to `cl-defstruct' and `defclass' are all up here
;; together, to help with order of definition.

(cl-defstruct ebdb-record-cache
  "Structure holding cached values for a record."
  (name-string "" :type string :documentation
	       "Canonical name string")
  (alt-names nil :type list :documentation
	     "List of alternate names")
  (organizations nil :type list :documentation
		 "List of related organization name strings")
  ;; FIXME: Nothing seems to use this mail-aka information.  Delete
  ;; it, and/or consider a general re-working of how EBDB handles
  ;; name-mail pairs.
  (mail-aka nil :type list :documentation
	    "List of akas associated with mail addresses")
  (mail-canon nil :type list :documentation
	      "List of all record's mail addresses")
  ;; FIXME: Erm, we don't sort EBDB records at all!  And setting a
  ;; single string as a sortkey is way too limiting: instead offer
  ;; multiple sorting strategies.
  (sortkey nil :type string :documentation
	   "String used for sorting record against other records")
  (databases nil :type list :documentation
	     "List of database instances this record belongs to"))

(defclass ebdb-field ()
  ((actions
    :type (list-of cons)
    :allocation :class
    :initform nil
    :documentation
    "A list of actions which this field can perform.  Each list
  element is a cons of string name and function name.")
   (comment
    :type (or null string)
    :custom (choice (const :tag "No comment" nil)
		    (string :tag "Comment"))
    :initarg :comment
    :initform nil
    :documentation
    "Arbitrary comment on this field value"))
  :abstract t :documentation "Abstract class for EBDB fields.
  Subclass this to produce real field types.")

(defclass ebdb-record (eieio-instance-tracker)
  ((uuid
    :initarg :uuid
    :type (or null ebdb-field-uuid)
    :initform nil)
   (tracking-symbol
    :initform 'ebdb-record-tracker)
   (creation-date
    :initarg :creation-date
    :type (or null ebdb-field-creation-date)
    :initform nil)
   (timestamp
    :initarg :timestamp
    :type (or null ebdb-field-timestamp)
    :initform nil)
   (fields
    :initarg :fields
    :type (list-of ebdb-field-user)
    :initform nil
    :documentation "This slot contains all record fields except
    those built in to record subclasses.")
   (image
    :initarg :image
    :type (or null ebdb-field-image)
    :initform nil)
   (notes
    :initarg :notes
    :type (or null ebdb-field-notes)
    :initform nil
    :documentation "User notes for this contact.")
   (dirty
    :initarg :dirty
    :type boolean
    :initform nil
    :documentation "Does this record have changed fields?")
   (cache
    :initarg :cache
    :type (or null ebdb-record-cache)
    :initform nil
    ))
  :abstract t
  :allow-nil-initform t
  :documentation "An abstract base class for creating EBDB
  records.")

(define-inline ebdb-record-databases (record)
  "Record cache function: return RECORD's databases."
  (inline-quote (ebdb-record-cache-databases (slot-value ,record 'cache))))

(define-inline ebdb-record-mail-aka (record)
  "Record cache function: return mail-aka for RECORD."
  (inline-quote (ebdb-record-cache-mail-aka (slot-value ,record 'cache))))

(define-inline ebdb-record-mail-canon (record)
  "Record cache function: return all RECORD's mail addresses."
  (inline-quote (ebdb-record-cache-mail-canon (slot-value ,record 'cache))))

(define-inline ebdb-record-alt-names (record)
  "Record cache function: return all RECORD's alternative names."
  (inline-quote (ebdb-record-cache-alt-names (slot-value ,record 'cache))))

(define-inline ebdb-record-name-string (record)
  "Record cache function: return RECORD's name as a string."
  (inline-quote (ebdb-record-cache-name-string (slot-value ,record 'cache))))

(define-inline ebdb-record-organizations (record)
  "Record cache function: return RECORD's organizations.
Returns a list of strings."
  (inline-quote (ebdb-record-cache-organizations (slot-value ,record 'cache))))

(define-inline ebdb-record-sortkey (record)
  "Record cache function: return RECORD's string sortkey."
  (inline-quote (ebdb-record-cache-sortkey (slot-value ,record 'cache))))

(cl-defgeneric ebdb-init-field (field record)
  "Initialize FIELD.
What this means is entirely dependent upon the field class in
question.  Often it involves manipulating secondary data
structures such as label lists.  If RECORD is given, it may also
involve using FIELD as a hash value to get to RECORD.")

(cl-defmethod ebdb-init-field (_field-value _record)
  "Catch-all `ebdb-init-field' method for fields.
This method may also get called on field values that aren't
actually `ebdb-field' instances -- for instance, plain strings.
In those cases, assume we don't need to do anything."
  t)

(cl-defmethod ebdb-field-readable-name ((field (subclass ebdb-field)))
  "Return a human-readable string label for this class.
Mostly used for allowing users to pick which field type they want
to add to a record."
  ;; Why is there no non-private access to this?  The `class-option'
  ;; function is mentioned in the EIEIO manual, but doesn't exist.
  (eieio--class-option (find-class field) :human-readable))

(cl-defmethod ebdb-field-readable-name ((field ebdb-field))
  (ebdb-field-readable-name (eieio-object-class field)))

(cl-defmethod ebdb-field-readable-name ((_field (eql string)))
  "Value")

(cl-defgeneric ebdb-parse (field-class str &optional slots)
  "Attempt to construct an instance of FIELD-CLASS using STR.
Implementations should extract information from STR and put it
into SLOTS, provided that SLOTS does not already contain relevant
values (ie, parsing should not override what's already in SLOTS).
Then call `cl-call-next-method' with the new values.")

(cl-defmethod ebdb-parse :around (_field-class _str &optional _slots)
  (save-match-data
    (cl-call-next-method)))

(cl-defmethod ebdb-parse ((field-class (subclass ebdb-field)) str &optional slots)
  "Create the actual field instance."
  (condition-case nil
      (apply #'make-instance field-class slots)
    (error (signal 'ebdb-unparseable (list str)))))

(cl-defmethod ebdb-parse :before ((_field-class (subclass ebdb-field)) str &optional _slots)
  (when (or (null str)
	    (string-empty-p str))
    (signal 'ebdb-empty (list "Empty string cannot be parsed"))))

;;; Errors

;; I haven't figured this out quite yet.  What I want to do is avoid
;; raising errors for *some* methods, with *some* classes; right now
;; all errors are suppressed.  It doesn't seem very easy to specialize
;; on methods and classes here: the GENERIC argument that's passed in
;; to the methods below is the full struct of the generic itself.
;; Presumably I'll have to look into that struct?  Or maybe I should
;; just write bottom-level do-nothing methods for the cases where I
;; don't want to raise an error.  I guess I'll do that for
;; `ebdb-delete-field' and `ebdb-init-field', for the base
;; `ebdb-field' class.

;; (cl-defmethod cl-no-applicable-method (_generic &rest _args)
;;   "Don't raise errors for unimplemented methods."
;;   (message "All no-applicable-method errors are swallowed."))

;; (cl-defmethod cl-no-next-method (_generic _method &rest _args)
;;   "Don't raise errors for non-existent next methods."
;;   (message "All no-next-method errors are swallowed."))

;; There used to be a `destructor' method, but it's been marked
;; obsolete as of 25.2.  There may be a `delete-instance' method, but
;; then again there may not.  Handle it ourselves.

(cl-defgeneric ebdb-delete-field (field &optional record unload)
  "Delete FIELD.
Often involves un-hashing RECORD against the field value, or
removing labels from label lists.

If UNLOAD is true, it indicates that RECORD is only being
unloaded, not actually deleted.")

(cl-defmethod ebdb-delete-field ((field ebdb-field) &optional _record _unload)
  "User-level deletion routine for FIELD.
Override this to do any necessary cleanup work after FIELD is
removed."
  (delete-instance field))

(cl-defmethod ebdb-delete-field ((_field string) &optional _record _unload)
  t)

(cl-defmethod delete-instance ((_field ebdb-field) &rest _args)
  t)

(cl-defgeneric ebdb-read (class &optional slots obj)
  "Prompt the user for values to create an instance of CLASS.
SLOTS are a plist of slot values; OBJ is an optional existing
object of type CLASS, from which to draw default values during
prompting.")

(cl-defmethod ebdb-read ((class (subclass ebdb-field)) &optional slots _obj)
  "Complete the read/object creation process for a field of CLASS.
Earlier subclasses of `ebdb-field' will have read all the
necessary values into SLOTS; this base method is simply
responsible for creating the field object.

The OBJ argument is used when editing existing fields: OBJ is the
old field.  By now we've sucked all the useful information out of
it, and if this process is successful it will get deleted."
  (apply #'make-instance class slots))

(cl-defmethod ebdb-read :around ((_cls (subclass ebdb-field))
				 &optional _slots _obj)
  (let ((completion-ignore-case ebdb-completion-ignore-case))
    (cl-call-next-method)))

;; Pretty much everything in here should implement an `ebdb-string'
;; method.
(cl-defgeneric ebdb-string (obj)
  "Return a string representing OBJ.")

;; Sometimes it might already be a string.
(cl-defmethod ebdb-string ((str string))
  str)

;; Generics for fields.  Not all field classes will implement these
;; methods.  `ebdb-action' should raise an error (to be caught and
;; displayed at top level) when there is no applicable action method,
;; so we don't actually define a base method. `ebdb-notice' shouldn't
;; raise an error if it's not implemented, so we define a do-nothing
;; base method.

(cl-defmethod ebdb-action ((field ebdb-field) record &optional idx)
  "Perform an \"action\" from those listed in FIELD's action slot.
If IDX is provided, it is an index indicating which of the action
functions to call.  Otherwise, call the car of the list."
  (let* ((actions (slot-value field 'actions))
	 (pair (when actions
		 (if idx (or (nth idx actions) (last actions)) (car actions)))))
    (when pair
      (funcall (cdr pair) record field))))

(cl-defgeneric ebdb-notice-field (field &optional type record)
  "\"Notice\" FIELD.
This means that a message involving RECORD has been viewed, or
that a MUA has otherwise decided that something significant to
RECORD has taken place.  It is up to the class of FIELD to decide
what, if anything, to do about this.

TYPE is a further indicator of how RECORD was noticed: in normal
MUAs it is one of the symbols \\='sender or \\='recipient.")

(cl-defmethod ebdb-notice-field ((_field ebdb-field)
				 &optional _type _record)
  "Ask FIELD of RECORD to react to RECORD being \"noticed\".
When the user receives an email from or cc'd to RECORD, that
record will call `ebdb-notice' on all its fields, and give them a
chance to react somehow.  TYPE is one of the symbols \\='sender or
\\='recipient, indicating which message header the record was found
in."
  nil)

;; See actual implementation down below `ebdb-field-user' definition.
(cl-defgeneric ebdb-field-compare (field1 field2)
  "Return non-nil if FIELD1 should be sorted before FIELD2."
  (:method (_field1 _field2)
	   nil))


;;; The UUID field.

;; This was originally just a string-value slot, but it was such a
;; pain in the neck differentiating between strings and fields that
;; I'm just making it a field.  Who knows, it might come in handy later.

(defclass ebdb-field-uuid (ebdb-field)
  ((uuid
    :type string
    :initarg :uuid
    :initform ""))
  :human-readable "uuid")

(cl-defmethod ebdb-string ((field ebdb-field-uuid))
  (slot-value field 'uuid))

;;; The labeled abstract class.  Used as a mixin.

(defclass ebdb-field-labeled ()
  ((label
    :initarg :label
    :custom (choice (const :tag "Empty" nil)
		    string)
    :initform nil
    :documentation "String label")
   (label-list
    :initform nil
    :type (or null symbol)
    :allocation :class
    :documentation
    "This class-allocated slot points to a variable holding a
    list of known string labels for objects of the subclass."))
  :abstract t
  :documentation "A field with a string label.")

(cl-defmethod ebdb-read :around ((class (subclass ebdb-field-labeled)) &optional slots obj)
  "Prompt for a label for a new object of class CLASS.
OBJ is used as as a default, and the results are stored in SLOTS.

All subclasses of `ebdb-field-labeled' should have a \\='label-list
slot pointing to a var holding known labels for that class.  This
method checks that the label is known, and asks for confirmation
if it isn't.

This method also signals the \\='ebdb-empty error if the user gives
an empty string as a label, which allows interruption of the read
process."
  ;; FIXME: Now that labels are read after the main class, this should
  ;; be an :after method.
  (let* ((field (cl-call-next-method class slots obj))
	 (labels (symbol-value (oref-default class label-list)))
	 (human-readable (ebdb-field-readable-name class))
	 (label (or
		 (when obj (slot-value obj 'label))
		 (slot-value field 'label))))
    (setq label (ebdb-with-exit
		 (ebdb-read-string
		  (if (stringp human-readable)
		      (format "%s label" (capitalize human-readable))
		    "Label")
		  label labels nil)))
    (when (and label
	       (or
		(member label labels)
		(yes-or-no-p
		 (format "%s is not a known label, define it? " label))))
      (setf (slot-value field 'label) label))
    field))

(cl-defmethod ebdb-init-field ((field ebdb-field-labeled) _record)
  "Add FIELD's label to its class label list."
  (let ((label-var (slot-value field 'label-list)))
    (cl-pushnew (slot-value field 'label) (symbol-value label-var)
		:test #'equal)
    (cl-call-next-method)))

(cl-defmethod ebdb-field-label ((field ebdb-field-labeled))
  "Return a string label for FIELD."
  (or (slot-value field 'label)
      (ebdb-field-readable-name (eieio-object-class field))))

;; Backwards-compatibility upgrade.  `ebdb-field-labeled' used to
;; subclass `eieio-named', but apparently that was a bit of a misuse,
;; so we need to upgrade the :object-name slot name to :label instead.
(cl-defmethod initialize-instance ((field ebdb-field-labeled)
				   &optional slots)
  (let ((obj-name (plist-get slots :object-name))
	p)
    (when obj-name
      (while slots
	(when (not (eq :object-name (car slots)))
	  (setq p (plist-put p (car slots) (nth 1 slots))))
	(setq slots (cddr slots)))
      (when obj-name
	(setq p (plist-put p :label obj-name))))
    (cl-call-next-method field (or p slots))))

;; The obfuscated field type.  This is a little goofy, but might come
;; in handy.

(defclass ebdb-field-obfuscated (ebdb-field)
  nil
  :abstract t
  :documentation
  "A field class mixin that prevents the contents from being
  displayed in the *EBDB* buffer.  Use for mildly sensitive
  information.")

;; The singleton field type.  Records may only have one instance of
;; fields of this type.  (Unrelated to `eieio-singleton'.)

;; There's a method of `ebdb-record-insert-field' for this class down
;; under the definition of `ebdb-record'.
(defclass ebdb-field-singleton (ebdb-field)
  nil
  :abstract t
  :documentation
  "A field class mixin that ensures a record can only have one
  instance of that field class.")

;; User-defined fields.  There are two kinds.  The first is
;; `ebdb-field-user', which provides no information about labels or
;; slots, but simply gives us the right to live in the "fields" slot
;; of records.  It must be subclassed to be useful.

;; The second is the `ebdb-field-user-simple', which subclasses
;; `ebdb-field-user' and `ebdb-field-labeled'.  This class should
;; *not* be subclassed; it's the class that collects all the basic
;; label-plus-value fields that users might want to add.  Instances
;; have no particular behavior, they're just key-value pairs.

(defclass ebdb-field-user (ebdb-field)
  nil
  :abstract t
  :documentation
  "Fields that should be user-editable, but need more complicated
  slot structures than the simple \"value\" provided by
  `ebdb-field-user-simple', can subclass this class.  Any field
  class that subclasses this will be offered as a choice to the
  user when inserting new fields.")

(cl-defmethod ebdb-field-compare ((field1 ebdb-field-user)
				  (field2 ebdb-field-user))
  "By default, order by field class."
  (string< (symbol-name (eieio-object-class-name field1))
	   (symbol-name (eieio-object-class-name field2))))

(defvar ebdb-user-label-list nil
  "List of existing labels of user fields.")

(defclass ebdb-field-user-simple (ebdb-field-labeled ebdb-field-user)
  ((label-list :initform 'ebdb-user-label-list)
   (value
    :initarg :value
    :type (or atom list)
    :initform ""
    :custom string
    :documentation "The value of this user-defined field."))
  :human-readable "user field")

(cl-defmethod ebdb-string ((field ebdb-field-user-simple))
  (let ((val (slot-value field 'value)))
    (if (stringp val)
	val
      (ebdb-concat (intern-soft (slot-value field 'label)) val))))

;; TODO: Maybe replicate the ability to insert a lisp sexp directly,
;; in interactive mode?
(cl-defmethod ebdb-read ((class (subclass ebdb-field-user-simple)) &optional slots obj)
  (unless (plist-get slots :value)
    (let ((default (when obj (ebdb-string obj))))
      (setq slots (plist-put slots :value (ebdb-read-string "Value" default)))))
  (cl-call-next-method class slots obj))

;;; The name fields.  One abstract base class, and two instantiable
;;; subclasses.

(defclass ebdb-field-name (ebdb-field)
  nil
  :abstract t
  :documentation "Abstract base class for creating record
  names.")

(cl-defmethod ebdb-parse ((class (subclass ebdb-field-name)) str &optional slots)
  "Examine STR and try to interpret it as a name.
This method dispatches to the equivalent method of either the
simple or complex name class."
  ;; Right now, all we do is send the input to field-name-simple if
  ;; there are no spaces in it, otherwise to field-name-complex.  If
  ;; "slots" is t, that means we've already been through the
  ;; upper-level methods.
  (let ((input (string-trim str)))
    (cond (slots
	   (cl-call-next-method class str slots))
	  ((string-match-p "[[:space:]]" input)
	   (ebdb-parse ebdb-default-name-class input slots))
	  (t
	   (ebdb-parse 'ebdb-field-name-simple input slots)))))

(cl-defmethod cl-print-object ((name ebdb-field-name) stream)
  (princ (format "#<%S %s>"
		 (eieio-object-class-name name)
		 (ebdb-string name))
	 stream))

(defclass ebdb-field-name-simple (ebdb-field-name)
  ((name
    :type string
    :initarg :name
    :custom string
    :initform ""))
  :documentation "A name class for \"simple\" names: ie plain
  strings."
  :human-readable "nickname")

(cl-defmethod ebdb-string ((name ebdb-field-name-simple))
  (slot-value name 'name))

(cl-defmethod ebdb-read ((class (subclass ebdb-field-name-simple))
			 &optional slots obj)
  (let ((name (ebdb-read-string "Name" (when obj (slot-value obj 'name)))))
    (cl-call-next-method class (plist-put slots :name name) obj)))

(cl-defmethod ebdb-init-field ((name ebdb-field-name-simple) record)
  (ebdb-puthash (ebdb-string name) record)
  (cl-call-next-method))

(cl-defmethod ebdb-delete-field ((name ebdb-field-name-simple) record
				 &optional _unload)
  (ebdb-remhash (ebdb-string name) record)
  (cl-call-next-method))

(cl-defmethod ebdb-parse ((class (subclass ebdb-field-name-simple)) str &optional slots)
  (unless (plist-get slots :name)
    (setq slots (plist-put slots :name str)))
  (cl-call-next-method class str slots))

(defclass ebdb-field-name-complex (ebdb-field-name)
  ((surname
    :initarg :surname
    :type (or null string)
    :custom (choice (const :tag "No surname" nil)
		    (string :tag "Surname"))
    :initform nil)
   (given-names
    :initarg :given-names
    :type (list-of string)
    :custom (repeat (string :tag "Name"))
    :initform nil)
   (prefix
    :initarg :prefix
    :type (or null string)
    :custom (choice (const :tag "No prefix" nil)
		    (string :tag "Prefix"))
    :initform nil)
   (suffix
    :initarg :suffix
    :type (or null string)
    :custom (choice (const :tag "No suffix" nil)
		    (string :tag "Suffix"))
    :initform nil))
  :documentation "A name class for \"complex\", ie structured,
  names."
  :human-readable "alt name")

(cl-defmethod initialize-instance ((field ebdb-field-name-complex) &optional slots)
  "\"Upgrade\" routine to remove the `affix' slot, which never made sense."
  ;; Both `prefix' and `suffix' are types of "affix", we didn't need a
  ;; separate `affix' slot.  Turn it into a `suffix' instead.
  (let ((aff (plist-get slots :affix))
	(pref (plist-get slots :prefix)))
    (when aff
      (cl-remf slots :affix)
      (setq slots (plist-put slots :prefix
			     (if pref
				 (format "%s %s" pref aff)
			       aff)))))
  (cl-call-next-method field slots))

(cl-defmethod ebdb-name-last ((name ebdb-field-name-complex))
  "Return the surname of this name field."
  (with-slots (surname prefix) name
    (if prefix
	(concat prefix " " surname)
      surname)))

(cl-defmethod ebdb-name-given ((name ebdb-field-name-complex) &optional full)
  "Return the given names of this name field.
If FULL is t, return all the given names, otherwise just the
first one."
  (let ((given (slot-value name 'given-names)))
    (when given
      (if full
	  (mapconcat #'identity given " ")
	(car given)))))

(cl-defmethod ebdb-name-lf ((name ebdb-field-name-complex) &optional full)
  "Format NAME with surname first.
Surname comes first, followed by a comma and then the given name
or names.  Only the first given name is used, unless FULL is
non-nil.

The name suffix (Jr., III, etc) is not used.  The prefix (di,
von, van, etc) is output according to an arcane set of rules,
loosely based on the MLA handbook, about when the prefix should
be considered part of the surname and when not."
  (with-slots (surname prefix) name
    (let* ((given-string (ebdb-name-given name full))
	   (case-fold-search nil)
	   (cap-prefix (and prefix
			    (string-match-p "^[[:upper:]]" prefix))))
      ;; Basically, if the prefix is capitalized, we treat it as part
      ;; of the surname, otherwise not.  There's more to it than that,
      ;; but let's wait for someone to complain
      (concat (when cap-prefix (concat prefix " "))
	      surname
	      (when given-string (format ", %s" given-string))
	      (when (and prefix (null cap-prefix))
		(concat " " prefix))))))

(cl-defmethod ebdb-name-fl ((name ebdb-field-name-complex) &optional full)
  (let ((given (ebdb-name-given name full)))
    (with-slots (prefix surname suffix) name
      (ebdb-string-trim
       (concat (when given
		 (format "%s " given))
	       ;; Prefix is already included in `ebdb-name-last'.
	       (ebdb-name-last name)
	       (when suffix
		 (format ", %s" suffix)))))))

(cl-defmethod ebdb-string ((name ebdb-field-name-complex))
  "Produce a canonical string for NAME."
  ;; This is the crux of things, really.  This is the method that
  ;; produces the name you'll see in the *EBDB* buffer, so this is the
  ;; bit that should be most customizable, and most flexible.  This
  ;; value also gets stored in the cache.
  (ebdb-name-fl name t))

(cl-defmethod ebdb-init-field ((name ebdb-field-name-complex) record)
  (let ((lf-full (ebdb-name-lf name t))
	(fl-full (ebdb-name-fl name t))
	(fl (ebdb-name-fl name)))
    (ebdb-puthash lf-full record)
    (ebdb-puthash fl-full record)
    ;; Also hash against "first last", as an alternate search
    ;; strategy.
    (ebdb-puthash fl record)
    (ebdb-pushnew lf-full (ebdb-record-alt-names record))
    (ebdb-pushnew fl-full (ebdb-record-alt-names record))
    (ebdb-pushnew fl (ebdb-record-alt-names record)))
  (cl-call-next-method))

(cl-defmethod ebdb-delete-field ((name ebdb-field-name-complex)
				 record &optional _unload)
  (let ((lf-full (ebdb-name-lf name t))
	(fl-full (ebdb-name-fl name t))
	(fl (ebdb-name-fl name)))
    (ebdb-remhash lf-full record)
    (ebdb-remhash fl-full record)
    (ebdb-remhash fl record)
    (ebdb-delete-from-list lf-full (ebdb-record-alt-names record))
    (ebdb-delete-from-list fl-full (ebdb-record-alt-names record))
    (ebdb-delete-from-list fl (ebdb-record-alt-names record)))
  (cl-call-next-method))

(cl-defmethod ebdb-read ((class (subclass ebdb-field-name-complex))
			 &optional slots obj)
  (if ebdb-read-name-articulate
      (let* ((surname-default (when obj (ebdb-name-last obj)))
	     (given-default (when obj (ebdb-name-given obj t)))
	     (surname (ebdb-read-string "Surname" surname-default))
	     (given-names (ebdb-read-string "Given name(s)" given-default)))
	(setq slots (plist-put slots :surname surname))
	(setq slots (plist-put slots :given-names (split-string given-names)))
	(cl-call-next-method class slots obj))
    (ebdb-parse class (ebdb-read-string "Name" (when obj (ebdb-string obj))) slots)))

(cl-defmethod ebdb-parse ((class (subclass ebdb-field-name-complex)) str &optional slots)
  (pcase-let ((`(,surname ,given-names ,suffix ,prefix)
	       (ebdb-divide-name str)))
    (unless (plist-member slots :given-names)
      (setq slots (plist-put slots :given-names
			     given-names)))
    (unless (plist-member slots :prefix)
      (setq slots (plist-put slots :prefix
			     prefix)))
    (unless (plist-member slots :surname)
      (setq slots (plist-put slots :surname
			     (or surname ""))))
    (unless (plist-member slots :suffix)
      (setq slots (plist-put slots :suffix suffix)))
    (cl-call-next-method class str slots)))

;;; Role fields.

(defvar ebdb-role-label-list nil)

(defclass ebdb-field-role (ebdb-field-labeled ebdb-field)
  ((label-list :initform 'ebdb-role-label-list)
   (record-uuid
    :initarg :record-uuid
    :type (or null string)
    :initform nil)
   (org-uuid
    :initarg :org-uuid
    :type (or null string)
    :initform nil)
   (mail
    :initarg :mail
    :type (or null ebdb-field-mail)
    :initform nil)
   (fields
    :initarg :fields
    :type (list-of ebdb-field)
    :initform nil)
   (defunct
     :initarg :defunct
     :type boolean
     :custom boolean
     :initform nil
     :documentation "If t, this role is considered defunct (ie
     the person left their job, etc).  Fields in the \"fields\"
     slot will generally be ignored by the rest of EBDB.")
   (actions
    :initform '(("Display role relation" . ebdb-follow-related))))
  :documentation "This class represents a relationship between
  the record which owns this field, and the
  `ebdb-record-organization' pointed to by the \"org-uuid\"
  slot.  The \"mail\" slot holds the record's organizational
  email address.  The \"fields\" slot holds whatever extra fields
  might be relevant to the role."
  :human-readable "role")

(cl-defmethod ebdb-init-field ((role ebdb-field-role) record)
  (with-slots (org-uuid mail (role-record-uuid record-uuid)) role
    (let* (;; TODO: Guard against org-entry not being found.
	   (org-entry (gethash org-uuid ebdb-org-hashtable))
	   (record-uuid (ebdb-record-uuid record))
	   (org-string
	    (condition-case nil
		(ebdb-record-name-string
		 (ebdb-record-related record role))
	      (ebdb-related-unfound
	       "record not loaded"))))

      ;; Setting the 'record-uuid slot value when it wasn't set before
      ;; technically means that the record is now "dirty".  That's
      ;; okay in our current database implementation, because
      ;; `ebdb-record-insert-field' first calls
      ;; `ebdb-db-add-record-field', which sets the record "dirty",
      ;; and then calls this `ebdb-init' method -- ie, record is
      ;; "dirty" when we get here.  Theoretically, however, nothing in
      ;; `ebdb-init-field' should change a record's slots.
      (unless role-record-uuid
	(setf role-record-uuid record-uuid))
      (ebdb-pushnew org-string
		    (ebdb-record-organizations record))
      ;; Init the role mail against the record.
      (when (and mail (slot-value mail 'mail))
	(ebdb-init-field mail record))
      ;; Make sure this role is in the `ebdb-org-hashtable'.
      (unless (member role org-entry)
	(push role org-entry))
      (puthash org-uuid org-entry ebdb-org-hashtable)))
  (cl-call-next-method))

(cl-defmethod ebdb-delete-field ((role ebdb-field-role) record &optional unload)
  (let* ((org-uuid (slot-value role 'org-uuid))
	 (org-string
	  (condition-case nil
	      (ebdb-record-name-string
	       (ebdb-record-related record role))
	    (ebdb-related-unfound
	     nil)))
	 (org-entry (gethash org-uuid ebdb-org-hashtable))
	 (record-uuid (ebdb-record-uuid record)))
    (setq org-entry (delete role org-entry))
    (if org-entry
	(puthash org-uuid org-entry ebdb-org-hashtable)
      (remhash org-uuid ebdb-org-hashtable))
    (when (and org-string
	       (null (assoc-string
		      record-uuid
		      (object-assoc-list 'record-uuid org-entry))))
      ;; RECORD no long has any roles at ORG.
      (ebdb-delete-from-list org-string
			     (ebdb-record-organizations record))))
  (when (slot-value role 'mail)
    (ebdb-delete-field (slot-value role 'mail) record unload))
  (cl-call-next-method))

(cl-defmethod ebdb-read ((role (subclass ebdb-field-role)) &optional slots obj)
  (let ((org-id (or (plist-get slots :org-uuid)
		    (if obj (slot-value obj 'org-uuid)
		      (ebdb-record-uuid (ebdb-prompt-for-record
					 nil 'ebdb-record-organization)))))
	(mail (or (plist-get slots :mail)
		  (ebdb-with-exit
		   (ebdb-read ebdb-default-mail-class nil
			      (when obj (slot-value obj 'mail)))))))
    (when mail
      (setq slots (plist-put slots :mail mail)))
    (setq slots (plist-put slots :org-uuid org-id))
    (cl-call-next-method role slots obj)))

(cl-defmethod ebdb-string ((role ebdb-field-role))
  "Display a string for this ROLE."
  ;; This is used in person records headers, so it just shows the
  ;; organization name. Perhaps this could have a multi-line option
  ;; later.
  (let ((rec (ebdb-gethash (slot-value role 'record-uuid) 'uuid)))
    (condition-case nil
	(ebdb-record-name-string
	 (ebdb-record-related rec role))
      (ebdb-related-unfound
       "record not loaded"))))

;;; Mail fields.

;; Instead of one field holding many mail addresses, this is one field
;; per address.

(defclass ebdb-field-mail (ebdb-field)
  ((aka
    :initarg :aka
    :type (or null string)
    :custom (choice (const :tag "None" nil)
		    (string :tag "Mail AKA"))
    :initform nil
    :documentation "Alternate contact name for this address.")
   (mail
    :initarg :mail
    :type string
    :custom string
    :initform ""
    :documentation "Email address")
   (priority
    :initarg :priority
    :type (or null symbol)
    :initform 'normal
    :custom (choice (const :tag "Normal priority" normal)
		    (const :tag "Primary address" primary)
		    (const :tag "Defunct address" defunct))
    :documentation
    "The priority of this email address. The symbol 'normal means
    normal priority, 'defunct means the address will not be
    offered for completion, and 'primary means this address will
    be used as the default.  Only one of a record's addresses can
    be set to 'primary.")
   (actions :initform '(("Compose mail" . ebdb-field-mail-compose))))
  :documentation "A field representing a single email address."
  :human-readable "mail")

(cl-defmethod ebdb-init-field ((field ebdb-field-mail) record)
  (with-slots (aka mail) field
    (ebdb-puthash mail record)
    (ebdb-pushnew mail (ebdb-record-mail-canon record))
    (ebdb-pushnew (ebdb-dwim-mail record field) ebdb-dwim-completion-cache)
    (when aka
      (ebdb-puthash aka record)
      (ebdb-pushnew aka (ebdb-record-mail-aka record)))))

(cl-defmethod ebdb-delete-field ((field ebdb-field-mail) record &optional _unload)
  (with-slots (aka mail) field
    (when aka
      (ebdb-remhash aka record)
      (ebdb-delete-from-list aka (ebdb-record-mail-aka record)))
    (setq ebdb-dwim-completion-cache (delete (ebdb-dwim-mail record field)
					     ebdb-dwim-completion-cache))
    (ebdb-remhash mail record)
    (ebdb-delete-from-list mail (ebdb-record-mail-canon record)))
  (cl-call-next-method))

(cl-defmethod ebdb-string ((mail ebdb-field-mail))
  (with-slots (aka mail) mail
    (if aka
	(concat aka " <" mail ">")
      mail)))

(cl-defmethod ebdb-read ((class (subclass ebdb-field-mail)) &optional slots obj)
  (let* ((default (when obj (ebdb-string obj)))
	 (input (ebdb-read-string "Mail address" default))
	 (bits (ebdb-decompose-ebdb-address input))
	 (mail (nth 1 bits)))
    ;; (unless (or ebdb-allow-duplicates
    ;; 		(and obj
    ;; 		     (equal mail (slot-value obj 'mail))))
    ;;   (when (ebdb-gethash mail '(mail))
    ;; 	(error "Address %s belongs to another record" mail)))
    (when (car bits)
      (setq slots (plist-put slots :aka (car bits))))
    (setq slots (plist-put slots :mail mail))
    (when obj
      (setq slots (plist-put slots :priority (slot-value obj 'priority))))
    (cl-call-next-method class slots obj)))

(cl-defmethod ebdb-parse ((class (subclass ebdb-field-mail))
			  (str string)
			  &optional slots)
  "Parse STR as though it were a mail field."
  (pcase-let
      ((`(,name ,mail) (ebdb-decompose-ebdb-address str)))
    (unless mail
      (signal 'ebdb-unparseable (list str)))
    (unless (plist-get slots :mail)
      (setq slots (plist-put slots :mail mail)))
    (unless (plist-get slots :aka)
      (setq slots (plist-put slots :aka name)))
    (cl-call-next-method class str slots)))

(cl-defmethod ebdb-field-compare ((m-left ebdb-field-mail)
				  (m-right ebdb-field-mail))
  "Sort M-LEFT and M-RIGHT by their priority slot.
Primary sorts before normal sorts before defunct."
  (let ((l-p (slot-value m-left 'priority))
	(r-p (slot-value m-right 'priority)))
    (or (and (memq r-p '(normal defunct))
	     (eq l-p 'primary))
	(and (eq r-p 'defunct)
	     (eq l-p 'normal)))))

(cl-defmethod cl-print-object ((mail ebdb-field-mail) stream)
  (princ (format "#<%S %s>"
		 (eieio-object-class-name mail)
		 (slot-value mail 'mail))
	 stream))

;;; Address fields

(defclass ebdb-field-address (ebdb-field-labeled ebdb-field)
  ((label-list :initform 'ebdb-address-label-list)
   (streets
    :initarg :streets
    :type (list-of string)
    :initform nil
    :custom (repeat string)
    :accessor ebdb-address-streets
    :documentation "A list of strings representing the street address(es).")
   (neighborhood
    :initarg :neighborhood
    :type string
    :initform ""
    :custom string
    :accessor ebdb-address-neighborhood
    :documentation "Smaller area within the locality.")
   (locality
    :initarg :locality
    :type string
    :initform ""
    :custom string
    :accessor ebdb-address-locality
    :documentation "City, town, village, etc.")
   (region
    :initarg :region
    :type string
    :initform ""
    :custom string
    :accessor ebdb-address-region
    :documentation "State, province, region, etc.")
   (postcode
    :initarg :postcode
    :type string
    :initform ""
    :custom string
    :accessor ebdb-address-postcode)
   (country
    :initarg :country
    :type (or string symbol)
    :initform ""
    :custom (choice (symbol)
		    (string))
    :accessor ebdb-address-country
    :documentation "Country, represented either by a symbol (see ebdb-i18n.el) or a string."))
  :documentation "A field representing an address."
  :human-readable "address")

(cl-defmethod ebdb-init-field ((address ebdb-field-address) _record)
  (with-slots (streets locality region postcode country) address
    (dolist (s streets)
      (ebdb-pushnew s ebdb-street-list))
    (when locality
     (ebdb-pushnew locality ebdb-locality-list))
    (when (stringp country)
     (ebdb-pushnew country ebdb-country-list))
    (when region
     (ebdb-pushnew region ebdb-region-list))
    (when postcode
     (ebdb-pushnew postcode ebdb-postcode-list))))

(cl-defmethod ebdb-read ((class (subclass ebdb-field-address)) &optional slots obj)
  (let* ((ebdb-read-string-override '("Address" . prepend))
	 (streets
	  (if (plist-member slots :streets)
	      (plist-get slots :streets)
	    (ebdb-edit-address-street (when obj (ebdb-address-streets obj)))))
	 (locality
	  (if (plist-member slots :locality)
	      (plist-get slots :locality)
	    (or
	     (ebdb-with-exit
	      (ebdb-read-string "Town/City"
				(when obj (ebdb-address-locality obj)) ebdb-locality-list))
	     "")))
	 (neighborhood
	  (if (plist-member slots :neighborhood)
	      (plist-get slots :neighborhood)
	    (or
	     (ebdb-with-exit
	      (ebdb-read-string "Neighborhood/Suburb/Zone"
				(when obj (ebdb-address-neighborhood obj))))
	     "")))
	 (region
	  (if (plist-member slots :region)
	      (plist-get slots :region)
	    (or (ebdb-with-exit
		 (ebdb-read-string "State/Province"
				   (when obj (ebdb-address-region obj)) ebdb-region-list))
		"")))
	 (postcode
	  (if (plist-member slots :postcode)
	      (plist-get slots :postcode)
	    (or (ebdb-with-exit
		 (ebdb-read-string "Postcode"
				   (when obj (ebdb-address-postcode obj))
				   ebdb-postcode-list))
		"")))
	 (country
	  (if (plist-member slots :country)
	      (plist-get slots :country)
	    (or
	     (ebdb-with-exit
	      (ebdb-read-string "Country"
				(if obj (slot-value obj 'country)
				  ebdb-default-country)
				ebdb-country-list))
	     ""))))

    (cl-call-next-method
     class
     `(:streets ,streets
		:locality ,locality
		:neighborhood ,neighborhood
		:label ,(plist-get slots :label)
		:region ,region
		:postcode ,postcode
		:country ,country)
     obj)))

(defun ebdb-edit-address-street (streets)
  "Edit list STREETS."
  (let ((n 0) street list)
    (condition-case nil
	(while t
	  (setq street
		(ebdb-read-string
		 (format "Street, line %d" (1+ n))
		 (nth n streets) ebdb-street-list))
	  (push street list)
	  (setq n (1+ n)))
      ((ebdb-empty quit) nil))
    (if list
	(reverse list)
      (signal 'ebdb-empty (list 'ebdb-field-address)))))

(cl-defmethod ebdb-string ((address ebdb-field-address))
  (funcall ebdb-default-address-format-function address))

(defun ebdb-format-address-default (address)
  "Return formatted ADDRESS as a string.
This is the default format; it is used in the US, for example.
The result looks like this:
       label: street
              street
              ...
              locality, region postcode
              country.

Note that the neighborhood is not output by default, though it
may be for certain countries, when using EBDB
internationalization."
  (let ((country (ebdb-address-country address))
        (streets (ebdb-address-streets address)))
    (when (symbolp country)
      (require 'ebdb-i18n)
      (setq country (car-safe (rassq
			       country
			       (ebdb-i18n-countries)))))
    (concat (if streets
                (concat (mapconcat #'identity streets "\n") "\n"))
            (ebdb-concat ", " (ebdb-address-locality address)
                         (ebdb-concat " " (ebdb-address-region address)
                                      (ebdb-address-postcode address)))
            (unless (or (not country) (string= "" country))
              (concat "\n" country)))))

;;; Phone fields

(defclass ebdb-field-phone (ebdb-field-labeled ebdb-field)
  ((label-list :initform 'ebdb-phone-label-list)
   (country-code
    :initarg :country-code
    :type (or null number)
    :custom (choice (const :tag "Empty" nil)
		    (integer :tag "Country code"))
    :initform nil)
   (area-code
    :initarg :area-code
    :type (or null number)
    :custom (choice (const :tag "Empty" nil)
		    (integer :tag "Area code"))
    :initform nil)
   (number
    :initarg :number
    :type (or null string)
    :custom (choice (const :tag "Empty" nil)
		    (string :tag "Number"))
    :initform nil)
   (extension
    :initarg :extension
    :type (or null number)
    :custom (choice (const :tag "Empty" nil)
		    (integer :tag "Extension"))
    :initform nil)
   (actions
    :initform '(("Dial phone number" . ebdb-field-phone-dial)
		("Send text via Signal" . ebdb-field-phone-signal-text))))
  :human-readable "phone")

(cl-defmethod ebdb-string ((phone ebdb-field-phone))
  "Display the value of this phone number as a string."
  (with-slots (country-code area-code number extension) phone
    (let (outstring)
      (when extension
	(push (format "X%d" extension) outstring))
      (when number
	(push number outstring))
      (when area-code
	(push (format "(%d) " area-code) outstring))
      (when (and country-code
		 (null (eql country-code
			    ebdb-default-phone-country)))
	(push (format "+%d " country-code) outstring))
      (when outstring
	(apply #'concat outstring)))))

(cl-defmethod ebdb-read ((class (subclass ebdb-field-phone)) &optional slots obj)
  (let* ((ebdb-read-string-override '("Phone" . prepend))
	 (country
	  (or (and obj
		   (slot-value obj 'country-code))
	      (plist-get slots :country-code)))
	 (area
	  (or (and obj
		   (slot-value obj 'area-code))
	      (plist-get slots :area-code)))
	 (prompt
	  (concat "Number"
		  (when country
		    (format " +%d" country))
		  ;; Why aren't we allowing them to change the area
		  ;; code?
		  (when area
		    (format " (%d)" area))))
	 (default (when obj (slot-value obj 'number))))
    (ebdb-error-retry
     (ebdb-parse class
		 (ebdb-read-string prompt default)
		 slots))))

(cl-defmethod ebdb-parse ((class (subclass ebdb-field-phone))
			  (string string)
			  &optional slots)

  (let ((country-regexp "\\+(?\\([0-9]\\{1,3\\}\\))?[ \t]+")
	(area-regexp "(?\\([0-9]\\{1,4\\}\\)[-)./ \t]+")
        (ext-regexp "[ \t]?e?[xX]t?\\.?[ \t]?\\([0-9]+\\)"))
    (with-temp-buffer
      (insert (ebdb-string-trim string))
      (goto-char (point-min))
      (unless (plist-member slots :country-code)
	(if (looking-at country-regexp)
	    (progn
	      (setq slots
		    (plist-put slots :country-code (string-to-number (match-string 1))))
	      (goto-char (match-end 0)))
	  (when ebdb-default-phone-country
	    (plist-put slots :country-code ebdb-default-phone-country))))
      (unless (plist-member slots :area-code)
	(when (looking-at area-regexp)
	  ;; Bit of a hack.  If we seem to have an area code, but there
	  ;; are fewer than six digits *after* the area code, assume
	  ;; it's not an area code at all, but part of the actual
	  ;; number.
	  (unless
	      (save-excursion
		(goto-char (match-end 0))
		(save-match-data
		  (< (abs (- (point)
			     (or (when (re-search-forward ext-regexp (point-max) t)
				   (goto-char (match-beginning 0))
				   (point))
				 (point-max))))
		     6)))
	    (setq slots
		  (plist-put slots :area-code (string-to-number (match-string 1))))
	    (goto-char (match-end 0)))))
      ;; There is no full regexp for the main phone number.  We just
      ;; chomp up everything that comes after the area code, until we
      ;; hit an extension, or the end of the buffer.  All phone slots
      ;; but "number" are actually saved as numbers.  The "number" is
      ;; saved as a string, partially because it isn't really a
      ;; number, partially because if it's too long Emacs turns it
      ;; into a float, which is a pain in the ass.
      (when (and (< (point) (point-max))
		 (re-search-forward
		  (format "\\([-[:digit:][:blank:]]+\\)\\(%s\\)?[[:blank:]]*\\'"
			  ext-regexp)))
	(unless (plist-member slots :number)
	  (setq slots
		(plist-put
		 slots :number
		 (replace-regexp-in-string
		  "[^[:digit:]]" "" (match-string 1)))))
	(unless (or (plist-member slots :extension)
		    (null (match-string 2)))
	  (setq slots
		(plist-put slots :extension
			   (string-to-number
			    (match-string 2)))))))
    (cl-call-next-method class string slots)))

(cl-defmethod cl-print-object ((phone ebdb-field-phone) stream)
  (princ (format "#<%S %s>"
		 (eieio-object-class-name phone)
		 (ebdb-string phone))
	 stream))

;;; Notes field

(defclass ebdb-field-notes (ebdb-field)
  ((notes
    :type string
    :initarg :notes
    :custom string
    :initform ""
    :documentation "User notes on this contact."))
  :human-readable "notes")

(cl-defmethod ebdb-string ((notes ebdb-field-notes))
  (slot-value notes 'notes))

(cl-defmethod ebdb-read ((class (subclass ebdb-field-notes)) &optional slots obj)
  (let ((default (when obj (ebdb-string obj))))
    (cl-call-next-method class
			 (plist-put slots :notes (ebdb-read-string "Notes" default))
			 obj)))

(cl-defmethod ebdb-parse ((class (subclass ebdb-field-notes))
			  (str string)
			  &optional slots)
  (cl-call-next-method class str (plist-put slots :notes str)))

(cl-defgeneric ebdb-record-update-notes (record note &optional replace)
  "Convenience function for updating a record's notes field.
NOTE will appended to REC's existing notes field (or added as a
new notes field, if REC didn't already have one.

If optional arg REPLACE is non-nil, replace any existing notes.")

(cl-defmethod ebdb-record-update-notes ((rec ebdb-record)
					(note string)
					&optional replace)
  (let ((existing (ebdb-record-field rec 'notes)))
    (if existing
	(ebdb-record-change-field
	 rec existing
	 (ebdb-parse ebdb-default-notes-class
		     (if replace
			 note
		       (concat (ebdb-string existing) note))))
      (ebdb-record-insert-field
       rec (ebdb-parse ebdb-default-notes-class note)))))

;;; Timestamp field

;; For both these fields, I'd actually prefer to store
;; seconds-since-epoch in the actual backend, for ease of use.  The
;; human-readable date string could be output in `ebdb-string'.

(defclass ebdb-field-timestamp (ebdb-field)
  ((timestamp
    :initarg :timestamp
    :type list
    :initform nil))
  :human-readable "timestamp")

(cl-defmethod ebdb-stamp-time ((field ebdb-field-timestamp))
  (ebdb-update-timestamp-field field 'timestamp))

(defun ebdb-update-timestamp-field (ts slot)
  (setf (slot-value ts slot) (current-time)))

(cl-defmethod ebdb-string ((field ebdb-field-timestamp))
  (format-time-string ebdb-time-format (slot-value field 'timestamp)))

;;; Creation date field

;; This doesn't really do anything, but who knows who might want to
;; override it for their own nefarious purposes?

(defclass ebdb-field-creation-date (ebdb-field-timestamp)
  nil
  :human-readable "creation date")

;;; Anniversary field

;; The `ebdb-notice-field' method could let you know when you get an
;; email from someone and it happens to be their birthday.

(defvar ebdb-anniversary-label-list '("birthday" "marriage" "death"))

(defclass ebdb-field-anniversary (ebdb-field-labeled ebdb-field-user)
  ((label-list :initform 'ebdb-anniversary-label-list)
   (date
    :initarg :date
    :type list
    :custom (choice (list
		     (integer :tag "Month")
		     (integer :tag "Day"))
		    (list
		     (integer :tag "Month")
		     (integer :tag "Day")
		     (integer :tag "Year")))
    :documentation
    "A list of numbers representing a date, either (month day)
    or (month day year)")
   (calendar
    :initarg :calendar
    :type symbol
    :initform 'gregorian
    :custom symbol
    :documentation "The calendar to which this date applies.")
   (actions
    :initform '(("Browse date in calendar" . ebdb-field-anniversary-calendar)
		("Browse date in Org agenda" . ebdb-field-anniversary-agenda))))
  :human-readable "anniversary")

(cl-defmethod initialize-instance ((field ebdb-field-anniversary) &optional slots)
  "Migrate from previous single-integer date value to (day month year) list.
This allows for anniversaries where we don't know the year.
Eventually this method will go away."
  (when (integerp (plist-get slots :date))
    (setq slots (plist-put slots :date
			   (calendar-gregorian-from-absolute
			    (plist-get slots :date)))))
  (cl-call-next-method field slots))

(cl-defmethod ebdb-read ((class (subclass ebdb-field-anniversary)) &optional slots obj)
  ;; Fake `calendar-read-date' to make the year optional.
  (let* ((year (ebdb-with-exit
		(read-number "Year (C-g to omit): "
			     (when obj (nth 2 (slot-value obj 'date))))))
	 (month (cdr (assoc-string
		      (completing-read
		       "Month: "
		       (mapcar #'list (append
				       calendar-month-name-array nil))
		       nil t (when obj
			       (aref
				calendar-month-name-array
				(1- (nth 0 (slot-value obj 'date)))))
		       nil)
		      (calendar-make-alist
		       calendar-month-name-array 1)
		      t)))
	 (last (calendar-last-day-of-month
		;; If no year, assume a non-leap year.
		month (or year 2017)))
	 (day (with-no-warnings ; `with-suppressed-warnings' is too new.
		(calendar-read (format "Day (1-%d): " last)
			       (lambda (x) (and (< 0 x)
						(<= x last)))
			       (when obj (number-to-string
					  (nth 1 (slot-value obj 'date))))))))
    (cl-call-next-method class
			 (plist-put slots :date
				    (list month day year))
			 obj)))

(defun ebdb-diary-anniversaries (&optional mark)
  (with-no-warnings
    (defvar date)
    (defvar original-date))
  (let ((entries (gethash (seq-subseq date 0 2) ebdb-diary-entries)))
    (when (and (null (calendar-leap-year-p (nth 2 date)))
	       (= 3 (nth 0 date)) (= 1 (nth 1 date)))
      ;; If it's not a leap year, we "shift" all anniversaries for Feb
      ;; 29th onto Mar 1.
      (setq entries (append entries (gethash '(2 29) ebdb-diary-entries))))
    (when entries
      (cons mark
	    (mapconcat (pcase-lambda (`(,field ,record))
			 (if (bound-and-true-p original-date)
			     ;; If we have `original-date', we're
			     ;; displaying the diary list, so we need
			     ;; the detailed string.
			     (ebdb-field-anniv-diary-entry
			      field record (nth 2 date))
			   ;; If not, we're just marking dates on the
			   ;; calendar, so any non-nil response value is
			   ;; fine.
			   t))
		       entries "; ")))))

(cl-defmethod ebdb-init-field ((anniv ebdb-field-anniversary) record)
  (with-slots (date) anniv
    (push (list anniv record)
	  (gethash (seq-subseq date 0 2) ebdb-diary-entries))))

(cl-defmethod ebdb-string ((ann ebdb-field-anniversary))
  (let* ((date (slot-value ann 'date))
	 (bits `(0 0 0
		   ,(nth 1 date)
		   ,(car date)
		   ,(or (nth 2 date) 0)
		   nil nil nil))
	 (encoded (condition-case nil
		      (encode-time bits)
		    (wrong-number-of-arguments
		     ;; Emacs <=26
		     (apply #'encode-time bits)))))
    (format-time-string
     (if (nth 2 date)
	 ebdb-anniversary-ymd-format
       ebdb-anniversary-md-format)
     encoded)))

(cl-defmethod ebdb-delete-field ((anniv ebdb-field-anniversary)
				 record &optional _unload)
  (with-slots (date) anniv
    (puthash (seq-subseq date 0 2)
	     (seq-remove (lambda (e)
			   (equal e (list anniv record)))
			 (gethash (seq-subseq date 0 2) ebdb-diary-entries))
	     ebdb-diary-entries)))

;;; Id field

;; Used for recording an ID or tax id number.  Ie, national
;; identification numbers, SSNs, TINs, UTRs, and so on.

(defvar ebdb-id-label-list '("SSN" "TIN" "ID" "UTR" "passport")
  "List of known ID labels.")

(defclass ebdb-field-id (ebdb-field-labeled ebdb-field-obfuscated ebdb-field-user)
  ((label-list :initform 'ebdb-id-label-list)
   (id-number
    :type string
    :custom string
    :initarg :id-number
    :initform ""
    :documentation "The ID number itself.")
   (issue-date
    :initarg :issue-date
    :type (or nil list)
    :custom (choice (const :tag "None" nil)
		    (list
		     (integer :tag "Month")
		     (integer :tag "Day")
		     (integer :tag "Year")))
    :initform nil)
   (expiration-date
    :initarg :expiration-date
    :type (or nil list)
    :custom (choice (const :tag "None" nil)
		    (list
		     (integer :tag "Month")
		     (integer :tag "Day")
		     (integer :tag "Year")))
    :initform nil))
  :human-readable "id number")

(cl-defmethod ebdb-read ((class (subclass ebdb-field-id)) &optional slots obj)
  (unless (plist-get slots :id-number)
    (setq slots
	  (plist-put slots :id-number
		     (ebdb-read-string
		      "ID number"
		      (when obj (slot-value obj 'id-number))))))
  (unless (plist-get slots :issue-date)
    (setq slots
	  (plist-put slots :issue-date
		     (let ((minibuffer-default-prompt-format
			    " for issue date, default %s"))
		       (calendar-read-date
			nil
			(when obj (slot-value obj 'issue-date)))))))
  (unless (plist-get slots :expiration-date)
    (setq slots
	  (plist-put slots :expiration-date
		     (let ((minibuffer-default-prompt-format
			     " for expiration date, default %s"))
		       (calendar-read-date
			nil
			(when obj (slot-value obj 'expiration-date)))))))
  (cl-call-next-method class slots obj))

(cl-defmethod ebdb-string ((field ebdb-field-id))
  (slot-value field 'id-number))

;;; Relationship field

;; This is a bit different from the organization role field, mostly
;; just meant for family relationships or similar things.

(defvar ebdb-relation-label-list '("father" "mother" "sister" "brother"
				   "son" "daughter" "aunt" "uncle"
				   "grandmother" "grandfather" "wife" "husband"))

(defclass ebdb-field-relation (ebdb-field-labeled ebdb-field)
  ((label-list :initform 'ebdb-relation-label-list)
   (rel-uuid
    :initarg :rel-uuid
    :type string
    :initform ""
    :documentation "The UUID of the target record.")
   (rel-label
    :initarg :rel-label
    :type string
    :custom string
    :initform ""
    :documentation "The label on the \"other side\" of the
    relation, pointing at this record.")
   (actions
    :initform '(("Follow relationship" . ebdb-follow-related))))
  :human-readable "relationship")

(cl-defmethod ebdb-read ((class (subclass ebdb-field-relation)) &optional slots obj)
  (let* ((rec (if obj
		  (slot-value obj 'rel-uuid)
		(ebdb-record-uuid (ebdb-prompt-for-record
				   nil ebdb-default-record-class))))
	 (rel-label (ebdb-read-string "Reverse label (for the other record)"
				      (when obj
					(slot-value obj 'rel-label))
				      ebdb-relation-label-list)))
    (setq slots (plist-put slots :rel-uuid rec))
    (setq slots (plist-put slots :rel-label rel-label))
    (cl-call-next-method class slots obj)))

(cl-defmethod ebdb-string ((rel ebdb-field-relation))
  (let ((rec (ebdb-gethash (slot-value rel 'rel-uuid) 'uuid)))
    (if rec
	(ebdb-string rec)
      "record not loaded")))

(cl-defmethod ebdb-init-field ((rel ebdb-field-relation) record)
  "Initialize REL related field for RECORD.
Adds relation information to the `ebdb-relation-hashtable'."
  (push (cons (ebdb-record-uuid record) rel)
	(gethash (slot-value rel 'rel-uuid) ebdb-relation-hashtable)))

(cl-defmethod ebdb-delete-field ((rel ebdb-field-relation) record
				 &optional _unload)
  "Delete REL related field on RECORD.
Removes relation information from the
`ebdb-relation-hashtable'."
  (setf (gethash (slot-value rel 'rel-uuid)
		 ebdb-relation-hashtable)
	(delete (cons (ebdb-record-uuid record) rel)
		(gethash (slot-value rel 'rel-uuid)
			 ebdb-relation-hashtable))))

;; Image field

(defclass ebdb-field-image (ebdb-field)
  ((image
    :type (or null string symbol)
    :initarg :image
    ;; "`," is used to trick EIEIO into evaluating the form.
    :initform `,ebdb-image))
  :human-readable "image")

(cl-defmethod ebdb-read ((image (subclass ebdb-field-image)) &optional slots obj)
  (let ((existing (when obj (slot-value obj 'image)))
	value)
    (setq value
	  (cond
	   ((or (stringp existing)
		(yes-or-no-p "Find image file? "))
	    (read-file-name "Image file: " ebdb-image-path existing 'confirm))
	   ((yes-or-no-p "Use name format? ")
	    (intern (completing-read "Format: " '(name fl-name lf-name) nil t existing)))
	   (t
	    (message "Image will be found using `ebdb-field-image-function'.")
	    nil)))
    (cl-call-next-method image (plist-put slots :image value) obj)))

(cl-defmethod ebdb-string ((field ebdb-field-image))
  (let ((image (slot-value field 'image)))
      (format (if (stringp image) "Image file: %s" "Image format: %s") image)))

;; URL field

(defvar ebdb-url-label-list '("homepage")
  "List of known URL labels.")

(defclass ebdb-field-url (ebdb-field-labeled ebdb-field-user)
  ((label-list
    :initform 'ebdb-url-label-list)
   (url
    :type string
    :initarg :url
    :custom string
    :initform "")
   (actions
    :initform '(("Browse URL" . ebdb-field-url-browse))))
  :human-readable "URL")

(cl-defmethod ebdb-read ((class (subclass ebdb-field-url)) &optional slots obj)
  (let ((url (ebdb-read-string "Url" (when obj (slot-value obj 'url)))))
    (cl-call-next-method class (plist-put slots :url url) obj)))

(cl-defmethod ebdb-string ((field ebdb-field-url))
  (slot-value field 'url))

(cl-defmethod ebdb-parse ((class (subclass ebdb-field-url))
			  (str string)
			  &optional slots)
  "Parse a URL.
See `ebdb-url-valid-schemes' for a list of acceptable schemes."
  (when (null (plist-get slots :url))
    (if (string-match-p (regexp-opt ebdb-url-valid-schemes) str)
	(setq slots (plist-put slots :url (string-trim str)))
      (signal 'ebdb-unparseable (list "invalid URL scheme"))))
  (cl-call-next-method class str slots))

;; Location field

;; Should this be a singleton?  But a record might have more than one
;; "usual location".
(defclass ebdb-field-location (ebdb-field-user)
  ((location-label
    :initarg :location-label
    :initform ""
    :type string
    :custom string
    :documentation "A human-readable location description")
   (location-geo
    :initarg :location-geo
    :initform nil
    :type (or list nil)
    :custom '(choice (const :tag "Empty" nil)
		    ((cons number number) :tag "Geo coordinate pair"))
    :documentation "Geo coordinates as a cons of two numbers.")
   (timezone
    :initarg :timezone
    :initform ""
    :type string
    :custom string
    :documentation "Timezone in tzdata/Olson format, eg \"Europe/Berlin\".")
   (actions :initform '(("Display current time" . ebdb-location-current-time))))
  :documentation "Field holding location data for the record.
  Data is in three parts: an arbitrary location string, a cons of
  lat/long geodata, and a tzdata/Olson timezone string."
  :human-readable "location")

(cl-defmethod ebdb-read ((class (subclass ebdb-field-location)) &optional
			 slots obj)
  (let ((label (or (plist-get slots :location-label)
		   (ebdb-read-string "Location label"
				     (when obj (slot-value
						obj 'location-label)))))
	(geo (or (plist-get slots :location-geo)
		 (ebdb-with-exit
		  (ebdb-read-string "Location geo (C-g to skip)"
				    (when obj (slot-value
					       obj 'location-geo))))))
	(tz (or (plist-get slots :timezone)
		(ebdb-with-exit
		 (ebdb-read-string
		  "Timezone (eg \"Europe/Berlin\"; C-g to skip): "
		  (when obj (slot-value obj 'timezone)))))))
    (cl-call-next-method class `(:location-label ,label
						 :location-geo ,geo
						 :timezone ,tz)
			 obj)))

(cl-defmethod ebdb-string ((field ebdb-field-location))
  (with-slots (location-label timezone) field
    (concat location-label (when timezone
			     (format ": %s" timezone)))))

;; Gender field

(defclass ebdb-field-gender (ebdb-field-user
			     ebdb-field-singleton)
  ((gender
    :initarg :gender
    :initform 'unknown
    :type symbol
    :custom (choice
	     ;; Can we make the gender choices a defcustom and
	     ;; construct this automatically?
	     (const :tag "Female" female)
	     (const :tag "Male" male)
	     (const :tag "Other" other)
	     (const :tag "Unknown" unknown)
	     (const :tag "Not applicable" na))))
  :documentation
  "A field holding a record's gender."
  :human-readable "gender")

(cl-defmethod ebdb-read ((class (subclass ebdb-field-gender)) &optional slots obj)
  (let* ((choices
	  '(("female" . female)
	    ("male" . male)
	    ("other" . other)
	    ("unknown" . unknown)
	    ("not applicable" . na)))
	 (gender (cdr
		  (assoc-string
		   (ebdb-read-string "Gender"
				     (when obj (rassoc (slot-value obj 'gender)
						       choices))
				     choices
				     t)
		   choices))))
    (cl-call-next-method class (plist-put slots :gender gender) obj)))

(cl-defmethod ebdb-string ((field ebdb-field-gender))
  (symbol-name (slot-value field 'gender)))

;; Language field

;; People should be able to put anything they want in here, but
;; ideally we'd do something special for the ISO 639-1 codes:

;; https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes

(defclass ebdb-field-language (ebdb-field-user)
  ((language
    :initarg :language
    :type string
    :custom string))
  :human-readable "language"
  :documentation "A field specifying a language that can be used
  to communication with this contact.")

(cl-defmethod ebdb-string ((field ebdb-field-language))
  (slot-value field 'language))

(cl-defmethod ebdb-read ((class (subclass ebdb-field-language)) &optional slots obj)
  (let ((lang (ebdb-read-string
	       "Language: " (when obj (slot-value obj 'language))
	       language-info-alist nil)))
    (cl-call-next-method class (plist-put slots :language lang) obj)))

;;; Bank account field

(defclass ebdb-field-bank-account (ebdb-field-user)
  ((bank-name
    :initarg :bank-name
    :type string
    :custom string
    :documentation "Bank name")
   (bank-address
    :initarg :bank-address
    :type (or null ebdb-field-address)
    :initform nil
    ;; :custom (choice ebdb-field-address
    ;; 		    (const :tag "No address" nil))
    :documentation "Bank address")
   (routing-aba
    :initarg :routing-aba
    :type (or string null)
    :initform nil
    :custom (choice string
		    (const :tag "None" nil))
    :documentation "Routing number or ABA")
   (swift-bic
    :initarg :swift-bic
    :type (or string null)
    :initform nil
    :custom (choice string
		    (const :tag "None" nil))
    :documentation "SWIFT or BIC code, for international transfers")
   (account-name
    :initarg :account-name
    :type string
    :custom string
    :documentation "Name of account")
   (account-numbers
    :initarg :account-numbers
    :type list
    :custom (repeat (cons (string :tag "Account label")
			  (string :tag "Account number")))
    :documentation "A list of account labels and numbers/IBANs")
   (notes
    :initarg :notes
    :type (or null ebdb-field-notes)
    ;; :custom (choice ebdb-field-notes
    ;; 		    (const :tag "No notes" nil))
    :initform nil
    :documentation "Additional notes"))
  :human-readable "bank account"
  :documentation "A field holding information for a bank account.")

(cl-defmethod ebdb-read ((class (subclass ebdb-field-bank-account))
			 &optional slots obj)
  (let ((bank-name (or (plist-get slots :bank-name)
		       (ebdb-read-string "Bank name"
					 (when obj (slot-value obj 'bank-name)))))
	(bank-address (or (plist-get slots :bank-address)
			  (ebdb-with-exit
			   (ebdb-read 'ebdb-field-address '(:label "office")
				      (when obj (slot-value obj 'bank-address))))))
	(routing-aba (or (plist-get slots :routing-aba)
			 (ebdb-with-exit
			  (ebdb-read-string "Routing or ABA number"
					    (when obj (slot-value obj 'routing-aba))))))
	(swift-bic (or (plist-get slots :swift-bic)
		       (ebdb-with-exit
			(ebdb-read-string "SWIFT or BIC code"
					  (when obj (slot-value obj 'swift-bic))))))
	(account-name (or (plist-get slots :account-name)
			  (ebdb-read-string "Account name"
					    (when obj (slot-value obj 'account-name)))))
	(account-numbers
	 (or (plist-get slots :account-numbers)
	     (ebdb-loop-with-exit
	      (cons (ebdb-read-string "Account label (eg. \"checking\"): ")
		    (ebdb-read-string "Account number/IBAN")))))
	(notes (or (plist-get slots :notes)
		   (ebdb-with-exit
		    (ebdb-read 'ebdb-field-notes nil
			       (when obj (slot-value obj 'notes)))))))
    (cl-call-next-method
     class
     `(:bank-name ,bank-name
		  :bank-address ,bank-address
		  :routing-aba ,routing-aba
		  :swift-bic ,swift-bic
		  :account-name ,account-name
		  :account-numbers ,account-numbers
		  :notes ,notes)
     obj)))

(cl-defmethod ebdb-string ((acct ebdb-field-bank-account))
  (with-slots (bank-name bank-address routing-aba swift-bic
			 account-name account-numbers notes)
      acct
    (concat bank-name "\n"
	    (when bank-address (format "%s\n" (ebdb-string bank-address)))
	    "\n"
	    (when routing-aba
	      (format "Routing/ABA: %s\n" routing-aba))
	    (when swift-bic
	      (format "SWIFT/BIC: %s\n" swift-bic))
	    "\n" account-name "\n"
	    (mapconcat
	     (lambda (a)
	       (format "%s: %s" (car a) (cdr a)))
	     account-numbers "\n")
	    (when notes
	      (format "\n%s\n" (ebdb-string notes))))))

;; Tags field.

;; This field class holds a list of tags that apply to the record.
;; The main advantage is custom searching that lets users search on
;; multiple tags with inclusion and exclusion.

(defvar ebdb-tags nil
  "Variable holding tags defined for EBDB records.")

(defclass ebdb-field-tags (ebdb-field-user ebdb-field-singleton)
  ((tags
    :initarg :tags
    :initform nil
    :type list
    :custom (repeat string)
    :documentation
    "List of string tags."))
  :documentation "A field class holding a list of string tags
   for a record.  Also see `ebdb-org-field-tags', which behaves
   like this class but also completes on tags defined in Org
   files."
  :human-readable "tags")

(cl-defmethod ebdb-string ((field ebdb-field-tags))
  (ebdb-concat 'ebdb-field-tags (slot-value field 'tags)))

(cl-defmethod ebdb-read ((field (subclass ebdb-field-tags)) &optional slots obj)
  (let ((crm-separator (cadr (assq 'ebdb-field-tags ebdb-separator-alist))))
    (cl-call-next-method
     field
     (if (plist-member slots :tags)
	 slots
       (plist-put slots :tags
		  (completing-read-multiple
		   (format "Tags (separate with \"%s\"): " crm-separator)
		   ebdb-tags
		   nil nil
		   (when obj (ebdb-string obj))))))))

(cl-defmethod ebdb-parse ((field (subclass ebdb-field-tags))
			  str &optional slots)
  (unless (plist-get slots :tags)
    (setq slots (plist-put
		 slots :tags
		 (split-string
		  str
		  (nth 1 (assq 'ebdb-field-tags ebdb-separator-alist))))))
  (cl-call-next-method field str slots))

(cl-defmethod ebdb-search-read ((_class (subclass ebdb-field-tags)))
  (let ((search-string (ebdb-read-string
			"Search for tags (eg +tag1-tag2|tag3): ")))
    (if (string-match-p "[-+|&]" search-string)
	(cdr
	 ;; Thank you Org!
	 (org-make-tags-matcher search-string))
      search-string)))

(cl-defmethod ebdb-field-search ((field ebdb-field-tags)
				 func)
  ;; This guard should be a specializer in the arglist, but the
  ;; "function" specializer doesn't appear to work.
  (when (functionp func)
    ;; The t and 1 are bogus arguments to fool the matcher into thinking
    ;; we're dealing an Org heading.
    (funcall func t (slot-value field 'tags) 1)))

(cl-defmethod ebdb-field-search ((field ebdb-field-tags)
				 (tag string))
  (seq-find (lambda (tg) (string-match-p tag tg))
	    (slot-value field 'tags)))

(cl-defmethod ebdb-init-field ((field ebdb-field-tags) record)
  (let ((tags (slot-value field 'tags)))
    (dolist (tag tags)
      (add-to-list 'ebdb-tags tag)
      (ebdb-puthash tag record))))

(cl-defmethod ebdb-delete-field ((field ebdb-field-tags) record &optional _unload)
  (dolist (tag (slot-value field 'tags))
    (ebdb-remhash tag record)))

(cl-defgeneric ebdb-record-add-tag (record tag)
  "Convenience function for tagging a record.
Adds string TAG to RECORD's list of tags.")

(cl-defmethod ebdb-record-add-tag ((rec ebdb-record)
				   (tag string))
  (let ((existing (car-safe (ebdb-record-field rec 'ebdb-field-tags))))
    (if existing
	(ebdb-record-change-field
	 rec existing
	 (make-instance 'ebdb-field-tags :tags
			(cons tag (slot-value existing 'tags))))
      (ebdb-record-insert-field
       rec (ebdb-parse 'ebdb-field-tags tag)))))

;;; Fields that change EBDB's behavior.

;;; Mail aliases

;; As alias fields are initialized or deleted, they modify
;; `ebdb-mail-alias-alist', which is read by `ebdb-mail-aliases'
;; later.

(defvar ebdb-mail-alias-alist nil
  "An alist holding all alias definitions from EBDB.
Each element looks like: (alias (rec1 addr1) (rec2 addr2) ...).

Instead of actual records, the rec1, rec2 elements can also be
record uuids.")

(defclass ebdb-field-mail-alias (ebdb-field-user)
  ((alias
    :type string
    :initarg :alias
    :custom string
    :documentation
    "A mail alias for this record.")
   (address
    :type (or null ebdb-field-mail)
    :initarg :address
    :documentation. "The mail address to use with this record."))
  :human-readable "mail alias"
  :documentation "A field holding a single mail alias for a
  record.  The field holds the alias string, and an optional
  mail address to use with that alias.")

(cl-defmethod ebdb-read ((class (subclass ebdb-field-mail-alias)) &optional slots obj)
  (let ((alias (ebdb-read-string "Alias" (when obj (slot-value obj 'alias))
				 (mapcar #'car ebdb-mail-alias-alist))))
    (cl-call-next-method class (plist-put slots :alias alias) obj)))

(cl-defmethod ebdb-string ((field ebdb-field-mail-alias))
  (with-slots (alias address) field
    (if address (format
		 "%s: %s"
		 alias (ebdb-string address))
      alias)))

(cl-defmethod ebdb-init-field ((field ebdb-field-mail-alias) record)
  (with-slots (alias address) field
    (let ((existing (assoc alias ebdb-mail-alias-alist)))
      (if existing
	  (setcdr existing (cons (list record address) (cdr existing)))
	(push (list alias (list record address)) ebdb-mail-alias-alist)))))

(cl-defmethod ebdb-delete-field ((field ebdb-field-mail-alias)
				 record &optional _unload)
  (with-slots (alias address) field
    (let* ((existing (assoc alias ebdb-mail-alias-alist))
	   (entry (assq record (cdr-safe existing))))
      (if entry
	  (setcdr existing (remove entry (cdr existing)))
	(setq ebdb-mail-alias-alist
	      (delq existing ebdb-mail-alias-alist))))))

;; Passports

(defclass ebdb-field-passport (ebdb-field-id)
  ((label :initform "passport")
   (country
    :type string
    :initarg :country
    :custom string
    :initform ""))
  :human-readable "passport")

;; Passports didn't used to inherit from `ebdb-field-id', and the
;; number slot was named differently.  Also, we used to store dates as
;; absolutes (integers) which eventually seemed like a bad idea; now
;; switched to calendar format.
(cl-defmethod make-instance :around ((cls (subclass ebdb-field-passport))
				     &rest slots)
  (when (plist-get slots :number)
    (setf (nth (cl-position :number slots) slots) :id-number))
  (when (numberp (plist-get slots :issue-date))
    (setq slots (plist-put slots
			   :issue-date
			   (calendar-gregorian-from-absolute
			    (plist-get slots :issue-date)))))
  (when (numberp (plist-get slots :expiration-date))
    (setq slots (plist-put slots
			   :expiration-date
			   (calendar-gregorian-from-absolute
			    (plist-get slots :expiration-date)))))
  (apply #'cl-call-next-method cls slots))

(cl-defmethod ebdb-read ((class (subclass ebdb-field-passport)) &optional slots obj)
  (unless (plist-get slots :country)
    (setq slots (plist-put slots :country
			   (ebdb-read-string
			    "Country" (when obj (slot-value obj 'country))))))
  (cl-call-next-method class slots obj))

(cl-defmethod ebdb-string ((field ebdb-field-passport))
  (with-slots (country id-number issue-date expiration-date) field
    (format "(%s) %s\nIssued: %s\nExpires: %s"
	    country id-number
	    (format-time-string
	     "%F" (apply #'encode-time 0 0 0
			 (nth 1 issue-date)
			 (nth 0 issue-date)
			 (last issue-date)))
	    (format-time-string
	     "%F" (apply #'encode-time 0 0 0
			 (nth 1 expiration-date)
			 (nth 0 expiration-date)
			 (last expiration-date))))))

;;; Records

;; The basic, abstract `ebdb-record' class should require no user
;; interaction, and has no real user-facing fields (except for the
;; "fields" bucket, of course).  It takes care of all the fundamental
;; setup and housekeeping automatically.

(cl-defgeneric ebdb-init-record (record)
  "Initialize RECORD.
Specific behavior is determined by subclass, but usually involves
setting up RECORD's cache, and calling `ebdb-init-field' on the
record's fields.

Note this specifically does *not* hash the record against its
UUID -- this is done earlier in the process, by the record's
database(s).")

(cl-defgeneric ebdb-delete-record (record &optional db unload)
  "Delete RECORD.
This goes through a series of deletion routines, removing RECORD
from its respective databases, un-hashing its uuid, running
`ebdb-delete-field' on its fields, etc.

If DB is given, only delete RECORD from DB.

If UNLOAD is non-nil, we should only unload RECORD, not delete it
altogether.")

(cl-defgeneric ebdb-record-change-name (record name)
  "Change RECORD's name to NAME.
NAME can be an instance of `ebdb-field-name' or one of its
subclasses, or it can be a string, in which case the class of
RECORD is responsible for parsing it correctly.")

(cl-defmethod ebdb-record-uuid ((record ebdb-record))
  (let ((uuid-field (slot-value record 'uuid)))
    (when uuid-field
     (slot-value uuid-field 'uuid))))

(cl-defmethod ebdb-read ((class (subclass ebdb-record)) &optional slots)
  "Create a new record of class CLASS from the values in SLOTS."
  ;; All the other `ebdb-read' methods for record subclasses "bottom
  ;; out" here, and create a record.
  (let ((notes (ebdb-with-exit (ebdb-read ebdb-default-notes-class))))
    (when notes
      (setq slots (plist-put slots :notes notes)))
    (apply #'make-instance class slots)))

(cl-defmethod ebdb-delete-record ((record ebdb-record) &optional db unload)
  (let ((dbs (if db (if (consp db) db (list db))
	       (ebdb-record-databases record)))
	(uuid (ebdb-record-uuid record)))
    ;; If DB is passed in, assume that it will be responsible for
    ;; calling `ebdb-db-remove-record'.
    (unless db
      (dolist (db dbs)
	(ebdb-db-remove-record db record)))
    (dolist (field (slot-value record 'fields))
      (ebdb-delete-field field record unload))
    (ebdb-remhash uuid record)
    (delete-instance record)))

(cl-defmethod initialize-instance ((record ebdb-record) &optional slots)
  "Initialize RECORD.
Adds a cache to the cache slot, and ensures the \\='timestamp and
\\='creation-date slots are filled."
  ;; This is the very first thing that happens to a record after it is
  ;; created (whether manually or loaded).
  (let ((cache (make-ebdb-record-cache)))
    (setq slots (plist-put slots :cache cache))
    (unless (plist-get slots :timestamp)
      (setq slots
	    (plist-put slots :timestamp
		       (make-instance 'ebdb-field-timestamp)))
      (ebdb-stamp-time (plist-get slots :timestamp))
      (setf (slot-value record 'dirty) t))
    (unless (plist-get slots :creation-date)
      (setq slots
	    (plist-put slots :creation-date
		       (make-instance 'ebdb-field-creation-date)))
      (ebdb-stamp-time (plist-get slots :creation-date))
      (setf (slot-value record 'dirty) t))
    (cl-call-next-method record slots)))

(cl-defmethod ebdb-init-record ((record ebdb-record))
  "Initialize RECORD after loading or creation."
  (dolist (field (ebdb-record-user-fields record))
    (ebdb-init-field field record))
  (ebdb-record-set-sortkey record))

(cl-defmethod ebdb-merge ((left ebdb-record)
			  (right ebdb-record)
			  &optional _auto)
  (with-slots (creation-date fields notes)
      right
    (with-slots ((lcreation-date creation-date)
		 (lfields fields)
		 (lnotes notes))
	left
      (let ((c-time (slot-value creation-date 'timestamp))
	    (lc-time (slot-value lcreation-date 'timestamp)))
	;; We're merging all values into LEFT.
	(setf (slot-value left 'creation-date)
	      (if (or (equal lc-time c-time)
		      (time-less-p c-time lc-time))
		  creation-date
		lcreation-date))
	(ebdb-stamp-time left)
	(setf (slot-value left 'fields)
	      (delete-dups
	       (append fields lfields)))
	(when (or notes lnotes)
	  (when (null (equal notes lnotes))
	    (setf (slot-value left 'notes)
		  (make-instance
		   ebdb-default-notes-class
		   :notes
		   (concat (when notes (ebdb-string notes)) " "
			   (when lnotes (ebdb-string lnotes))))))))))
  left)

(cl-defmethod ebdb-stamp-time ((record ebdb-record))
  (ebdb-stamp-time (slot-value record 'timestamp)))

(cl-defgeneric ebdb-record-field-slot-query (record-class &optional query alist)
  "Ask RECORD-CLASS for information about its interactively-settable fields.
If QUERY is nil, simply return ALIST, which is a full list of
acceptable fields.  Each list element is a cons of the form (SLOT
. FIELDCLASS), meaning that RECORD-CLASS can accept fields of
class FIELDCLASS in SLOT.

If QUERY is non-nil, it should be a cons of either \\='(SLOT . nil),
or \\='(nil . FIELDCLASS).  The \"nil\" is the value to query for:
either \"which slot can accept this field class\", or \"which
fieldclass is appropriate for this slot\".  The return value in
either case is a cons with both slot and fieldclass filled in.")

(cl-defgeneric ebdb-record-insert-field (record field &optional slot)
  "Insert FIELD into RECORD.
If SLOT is given, insert FIELD into that slot.  Otherwise, the
slot will be found programmatically.")

(cl-defgeneric ebdb-record-delete-field (record field &optional slot)
  "Delete FIELD from RECORD.
If SLOT is given, delete FIELD from that slot.  Otherwise, the
slot will be found programmatically.")

(cl-defgeneric ebdb-record-change-field (record old-field &optional new-field)
  "Change RECORD's field OLD-FIELD.
If NEW-FIELD is given, OLD-FIELD will be replaced with NEW-FIELD.
Otherwise, the user will be prompted to create a new field, using
OLD-FIELD's values as defaults.")

(cl-defmethod ebdb-record-insert-field ((record ebdb-record)
					(field ebdb-field)
					&optional slot)
  "Add FIELD to RECORD's SLOT."
  ;; First, the databases "actually" add the field to the record, ie
  ;; persistence.  The rest of this method is just updating the
  ;; existing record instance with the new field.
  (dolist (db (ebdb-record-databases record))
    (when field
      (setq field (ebdb-db-add-record-field db record slot field))))
  (when field
    (condition-case nil
	;; We don't know if slot holds a single field, or a list of
	;; fields.  This is a hack.
	(object-add-to-list record slot field)
      (invalid-slot-type
       (setf (slot-value record slot) field)))
    (ebdb-init-field field record))
  field)

(cl-defmethod ebdb-record-insert-field :around ((record ebdb-record)
						(field ebdb-field)
						&optional slot)
  (let ((real-slot
	 (or slot
	     (car (ebdb-record-field-slot-query
		   (eieio-object-class record)
		   `(nil . ,(eieio-object-class field)))))))
    (cl-call-next-method record field real-slot)))

(cl-defmethod ebdb-record-delete-field ((record ebdb-record)
					(field ebdb-field)
					&optional slot)
  "Delete FIELD from RECORD's SLOT, or set SLOT to nil, if no FIELD."
  ;; We don't use `slot-makeunbound' because that's a huge pain in the
  ;; ass, and why would anyone want those errors?
  (dolist (db (ebdb-record-databases record))
    (ebdb-db-remove-record-field db record slot field))
  (if (listp (slot-value record slot))
      (object-remove-from-list record slot field)
    (setf (slot-value record slot) nil))
  (ebdb-delete-field field record))

(cl-defmethod ebdb-record-delete-field :around ((record ebdb-record)
						(field ebdb-field)
						&optional slot)
  (let ((real-slot
	 (or slot
	     (car (ebdb-record-field-slot-query
		   (eieio-object-class record)
		   `(nil . ,(eieio-object-class field)))))))
    (cl-call-next-method record field real-slot)))

(cl-defmethod ebdb-record-change-field ((record ebdb-record)
					(old-field ebdb-field)
					&optional new-field)
  "Change the values of FIELD belonging to RECORD."
  (let* ((fieldclass (eieio-object-class old-field))
	 (new-field (or new-field (ebdb-read fieldclass nil old-field))))
    (when (or (null (equal old-field new-field))
	      ebdb-update-unchanged-records)
      (ebdb-record-delete-field record old-field)
      (ebdb-record-insert-field record new-field)
      new-field)))

(cl-defmethod ebdb-record-field-slot-query ((_class (subclass ebdb-record))
					    &optional query alist)
  (let ((alist (append
		'((notes . ebdb-field-notes)
		  (image . ebdb-field-image))
		alist))
	user-class)
    ;; Pick up all externally-defined user fields.
    (dolist (f (eieio-build-class-alist 'ebdb-field-user t))
      (setq user-class (intern (car f)))
      (unless (or (rassq user-class alist)
		  ;; Temporary hack, see comment on
		  ;; `ebdb-org-field-tags' class definition in
		  ;; ebdb-org.el.
		  (eql user-class 'ebdb-org-field-tags))
	(push (cons 'fields user-class) alist)))
    ;; Look, Ma, I used pcase!
    (pcase query
      (`(nil . ,cls)
       (or (rassq cls alist)
	   (rassq (ebdb-foo-in-list-p cls (mapcar #'cdr alist))
		  alist)
	   (signal 'ebdb-unacceptable-field (list cls))))
      (`(,slot . nil)
       (or (assq slot alist)
	   (signal 'ebdb-unacceptable-field (list slot))))
      (_ alist))))

(cl-defgeneric ebdb-record-current-fields (record &optional f-list all)
  "Return an alist of all RECORD's current fields.
Each element of the alist is a cons of (slot-name
. field-instance), where slot-name is a symbol, and
field-instance is an instance of a subclass of `ebdb-field'.
These conses are collected in F-LIST.

If ALL is non-nil, really return all of RECORD's fields.  If nil,
only return fields that are suitable for user editing.")

(cl-defmethod ebdb-record-current-fields ((record ebdb-record)
					  &optional f-list all)
  "This is the \"bottom-most\" implementation of this method."
  (with-slots (fields image timestamp creation-date uuid notes) record
    (dolist (f fields)
      (push `(fields . ,f) f-list))
    (when image
      (push `(image . ,image) f-list))
    (when all
      (push `(timestamp . ,timestamp) f-list)
      (push `(creation-date . ,creation-date) f-list)
      (push `(uuid . ,uuid) f-list))
    (when notes
      (push (cons 'notes notes) f-list)))
  f-list)

(cl-defmethod cl-print-object ((record ebdb-record) stream)
  (princ (format "#<%S %s>"
		 (eieio-object-class-name record)
		 (ebdb-record-name-string record))
	 stream))

(cl-defgeneric ebdb-record-related (record field)
  "Return the record related to RECORD, according to FIELD.
This method is implemented for role fields, and relation fields.
It is responsible for returning the related record as specified
by the field, or else raising the error `ebdb-related-unfound'.")

(cl-defmethod ebdb-record-related ((_record ebdb-record)
				   (_field ebdb-field))
  "Provide a base method that raises `ebdb-related-unfound'."
  (signal 'ebdb-related-unfound '("Related record not found")))

;; The following functions are here because they need to come after
;; `ebdb-record' has been defined.

(cl-defmethod ebdb-location-current-time ((rec ebdb-record)
					  (field ebdb-field-location))
  "Display the current time for REC.
Uses the timezone value present in FIELD, and raises an error if
there is no timezone value."
  (with-slots (timezone) field
    (if timezone
	(message "%s's current time is: %s"
		 (ebdb-string rec)
		 (format-time-string "%c" nil timezone))
      (signal 'ebdb-error (list "No timezone present")))))

(cl-defmethod ebdb-record-insert-field ((record ebdb-record)
					(field ebdb-field-singleton)
					&optional _slot)
  "Prevent RECORD from having more than one instance of FIELD."
  (let ((existing (ebdb-record-field record (eieio-object-class field))))
    ;; Using a class name with `ebdb-record-field' always returns a
    ;; list.
    (when existing
      (dolist (f existing)
       (ebdb-record-delete-field record f)))
    (condition-case nil
	(cl-call-next-method)
      ;; Put the old one back if something goes wrong.  There should
      ;; only be one field instance, so we blindly use `car'.
      (error (ebdb-record-insert-field record (car existing))))))

(cl-defmethod ebdb-field-image-get ((field ebdb-field-image) (record ebdb-record))
  "Return the image for image field FIELD.
This function returns an actual image, suitable for display with
`insert-image'."
  (let* ((image-slot (slot-value field 'image))
	 (name-instance (slot-value record 'name))
	 (image
	  (cond ((stringp image-slot)
		 image-slot)
		((memq image-slot '(name fl-name lf-name))
		 (cond ((or (eq image-slot 'name)
			    (null (cl-typep name-instance
					    'ebdb-field-name-complex)))
			(ebdb-string name-instance))
		       ((eq image-slot 'lf-name)
			(ebdb-name-lf name-instance))
		       ((eq image-slot 'fl-name)
			(ebdb-name-fl name-instance))))
		(t
		 (ebdb-field-image-function field record)))))
    (when image
      (create-image
       (if (stringp image)
	   (if (file-name-absolute-p image)
	       image
	     (locate-file image ebdb-image-path
			  ebdb-image-suffixes))
	 image)))))

(cl-defmethod ebdb-field-image-function ((_field ebdb-field-image) (_record ebdb-record))
  "Return image data for RECORD from image field FIELD.
The return value of this function will be passed to
`create-image', which see.  It can either be an image file name,
or actual image data."
  ;; Unimplemented.
  nil)

;; See http://www.ietf.org/rfc/rfc3966.txt
(cl-defmethod ebdb-field-phone-dial ((_record ebdb-record)
				     (phone ebdb-field-phone))
  "Make some attempt to call this PHONE number."
  (with-slots (country-code area-code number extension) phone
    (browse-url
     (concat
      "tel:"
      (when country-code (format "+%d" country-code))
      (when area-code (number-to-string area-code))
      number
      (when extension (format ";ext=%d" extension))))))

(cl-defmethod ebdb-field-url-browse ((_record ebdb-record)
				     (field ebdb-field-url))
  (browse-url (slot-value field 'url)))

(cl-defmethod ebdb-field-anniversary-calendar ((_record ebdb-record)
					       (field ebdb-field-anniversary))
  "Go to the date of anniversary FIELD in the calendar.
If FIELD doesn't specify a year, use the current year."
  (let* ((date (slot-value field 'date))
	 (this-year (nth 5 (decode-time (current-time))))
	 (year (+ this-year
		  ;; If this year's occurrence is already in the past,
		  ;; use next year's.
		  (if (time-less-p
		       (encode-time
			1 1 1 (nth 1 date) (nth 0 date) this-year)
		       nil)
		      1 0))))
    (calendar)
    (calendar-goto-date
     (append (seq-subseq date 0 2) (list year)))))

(cl-defmethod ebdb-field-anniversary-agenda ((_record ebdb-record)
					     (field ebdb-field-anniversary))
  "Go to the date of anniversary FIELD in the Org agenda.
If FIELD doesn't specify a year, use the current year."
  (let* ((date (slot-value field 'date))
	 (this-year (nth 5 (decode-time (current-time))))
	 (year (+ this-year
		  (if (time-less-p
		       (encode-time
			1 1 1 (nth 1 date) (nth 0 date) this-year)
		       nil)
		      1 0))))
    (org-agenda-list
     nil
     (format "%d-%d-%d" year (nth 0 date) (nth 1 date)))))

(cl-defmethod ebdb-field-anniv-diary-entry ((field ebdb-field-anniversary)
					    (record ebdb-record)
					    &optional now-year)
  "Produce a diary entry for FIELD's date.
The entry is a string noting how many years have passed for
RECORD's FIELD anniversary, relative to NOW-YEAR."
  ;; Essentially a re-write of `diary-anniversary'.
  (pcase-let* ((`(,_ ,_ ,year) (slot-value field 'date))
	       (label (slot-value field 'label))
	       (num-years (when (and year now-year)
			    (- now-year year))))
    (concat (format "%s's " (ebdb-string record))
	    (when year
	      (format "%d%s " num-years (diary-ordinal-suffix num-years)))
	    label
	    (unless (string= label "birthday")
	      " anniversary"))))

;;; `ebdb-record' subclasses

(defclass ebdb-record-entity (ebdb-record)
  ((mail
    :initarg :mail
    :type (list-of ebdb-field-mail)
    :initform nil)
   (phone
    :initarg :phone
    :type (list-of ebdb-field-phone)
    :initform nil)
   (address
    :initarg :address
    :type (list-of ebdb-field-address)
    :initform nil)
   (organizations
    :initarg :organizations
    :type (list-of ebdb-field-role)
    :initform nil)
   (relations
    :initarg :relations
    :type (list-of ebdb-field-relation)
    :initform nil))
  :allow-nil-initform t
  :abstract t
  :documentation "An abstract class representing basic entities
  that have mail, phone and address fields.")

(cl-defmethod ebdb-init-record ((record ebdb-record-entity))
  (dolist (phone (slot-value record 'phone))
    (ebdb-init-field phone record))
  (dolist (mail (slot-value record 'mail))
    (ebdb-init-field mail record))
  (dolist (address (slot-value record 'address))
    (ebdb-init-field address record))
  (cl-call-next-method))

;; `ebdb-read' is only called for records on first creation, so we
;; don't have to worry about existing objects.

(cl-defmethod ebdb-read ((class (subclass ebdb-record-entity)) &optional slots)
  "Prompt for the basic slot values of `ebdb-record-entity'."
  (let ((mail (ebdb-loop-with-exit
	       (ebdb-read ebdb-default-mail-class)))
	(phone (ebdb-loop-with-exit
		(ebdb-read ebdb-default-phone-class)))
	(address (ebdb-loop-with-exit
		  (ebdb-read ebdb-default-address-class))))
    (when mail
      (setf (slot-value (car mail) 'priority) 'primary))
    (setq slots (plist-put slots :mail mail))
    (setq slots (plist-put slots :phone phone))
    (setq slots (plist-put slots :address address))
    (cl-call-next-method class slots)))

(cl-defmethod ebdb-delete-record ((record ebdb-record-entity) &optional _db unload)
  (dolist (mail (slot-value record 'mail))
    (ebdb-delete-field mail record unload))
  (dolist (field (ebdb-record-user-fields record))
    (ebdb-delete-field field record unload))
  ;; Maybe should also be calling `ebdb-delete-field' on the phone and
  ;; address fields, just in case.
  (cl-call-next-method))

(cl-defmethod ebdb-merge ((left ebdb-record-entity)
			  (right ebdb-record-entity)
			  &optional auto)
  (with-slots (mail phone address) right
    (with-slots ((lmail mail) (lphone phone) (laddress address)) left
      (setf (slot-value left 'mail) (delete-dups (append mail lmail)))
      (setf (slot-value left 'phone) (delete-dups (append phone lphone)))
      (setf (slot-value left 'address) (delete-dups (append address laddress)))))
  (cl-call-next-method left right auto))

(cl-defmethod ebdb-record-field-slot-query ((class (subclass ebdb-record-entity)) &optional query alist)
  (cl-call-next-method
   class
   query
   (append
    `((mail . ebdb-field-mail)
      (phone . ebdb-field-phone)
      (address . ebdb-field-address)
      (organizations . ebdb-field-role)
      (relations . ebdb-field-relation))
    alist)))

(cl-defmethod ebdb-record-current-fields ((record ebdb-record-entity)
					  &optional f-list all)
  (with-slots (mail phone address organizations relations) record
    (dolist (m mail)
      (push `(mail . ,m) f-list))
    (dolist (p phone)
      (push `(phone . ,p) f-list))
    (dolist (a address)
      (push `(address . ,a) f-list))
    (dolist (o organizations)
      (push `(organizations . ,o) f-list))
    (dolist (r relations)
      (push `(relations . ,r) f-list)))
  (cl-call-next-method record f-list all))

(cl-defmethod ebdb-record-change-name ((record ebdb-record-entity)
				       (name ebdb-field-name))
  (when (slot-value record 'name)
    (ebdb-record-delete-field record (slot-value record 'name) 'name))
  (setf (ebdb-record-name-string record)
	(ebdb-string name))
  (ebdb-record-insert-field record name 'name))

(cl-defgeneric ebdb-compose-mail (records &rest args)
  "Prepare to compose a mail message to RECORDS.
Mail-sending MUAs can override this method to do extra setup
before/after message composition, by using a &context specializer
on eg. the value of `read-mail-command'.  The default
implementation turns RECORDS in a string of mail addresses, then
passes that along with ARGS to `compose-mail'.")

(cl-defmethod ebdb-compose-mail ((records list) &rest args)
  (let ((to (mapconcat #'ebdb-dwim-mail records ", ")))
    (ebdb-compose-mail to args)))

(cl-defmethod ebdb-compose-mail ((to string) &rest args)
  (apply #'compose-mail to args))

(cl-defgeneric ebdb-field-mail-compose (record mail &rest args)
  "Begin composing a message to RECORD's mail field MAIL.
ARGS are passed to `ebdb-compose-mail', and then to
`compose-mail'."
  (:method ((record ebdb-record-entity)
	    (mail ebdb-field-mail)
	    &rest args)
	   (apply #'ebdb-compose-mail (ebdb-dwim-mail record mail) args)))

;; This needs to be a :before method so that the 'address slot is
;; filled by the time we call `ebdb-init-field'.
(cl-defmethod ebdb-record-insert-field :before ((record ebdb-record-entity)
					       (field ebdb-field-mail-alias)
					       &optional _slot)
  "After inserting a new alias field, prompt the user for which
  address to use with it."
  (unless (and (slot-boundp field 'address)
	       (slot-value field 'address))
   (let ((mail (ebdb-record-one-mail record t)))
     (when mail
      (setf (slot-value field 'address) mail)))))

;; TODO: There's no reason why the aka slot can't belong to
;; `ebdb-record-entity'.  In fact, what we ought to do is put both the
;; 'name and the 'aka slots on `ebdb-record-entity', and have both
;; slot types set to `ebdb-field-name'.  Or why not just get rid of
;; the 'aka slot altogether, and put extra name instances in 'fields?
;; What's the point of keeping them in an extra slot?

(defclass ebdb-record-person (ebdb-record-entity)
  ((name
    :initarg :name
    :type (or null ebdb-field-name-complex)
    :initform nil)
   (aka
    :initarg :aka
    :type (list-of ebdb-field-name)
    :initform nil
    :accessor ebdb-record-aka))
  :allow-nil-initform t
  :documentation "A record class representing a person.")

(cl-defmethod ebdb-string ((record ebdb-record-person))
  "Return a readable string label for RECORD."
  (ebdb-record-name-string record))

(cl-defmethod ebdb-read ((class (subclass ebdb-record-person)) &optional slots)
  "Read the name slot for a \"person\" record."
  (let* ((name (ebdb-read ebdb-default-name-class (plist-get slots :name))))
    (cl-call-next-method
     class (plist-put slots :name name))))

(cl-defmethod ebdb-init-record ((record ebdb-record-person))
  (with-slots (name aka relations organizations) record
    (when name
      (ebdb-init-field name record)
      (setf (ebdb-record-name-string record) (ebdb-string name)))
    (dolist (f (append aka relations organizations))
      (ebdb-init-field f record)))
  (cl-call-next-method))

(cl-defmethod ebdb-delete-record ((record ebdb-record-person) &optional _db unload)
  (with-slots (name aka relations organizations) record
    (when name
      (ebdb-delete-field name record unload))
    (dolist (f (append aka relations organizations))
      (ebdb-delete-field f record unload)))
  (cl-call-next-method))

(cl-defmethod ebdb-merge ((left ebdb-record-person)
			  (right ebdb-record-person)
			  &optional auto)
  "Merge person RIGHT into LEFT, and return LEFT."
  (with-slots ((rname name)
	       (raka aka)
	       (rrelations relations)
	       (rorganizations organizations))
      right
    (with-slots ((lname name)
		 (laka aka)
		 (lrelations relations)
		 (lorganizations organizations))
	left

      (if auto
	  (object-add-to-list left 'aka rname)

	(unless (equal rname lname)
	  (let ((prefix (format "Merging %s with %s:"
				(ebdb-record-name-string right)
				(ebdb-record-name-string left))))
	    (if (yes-or-no-p (format "%s Use %s as primary name? "
				     prefix (ebdb-record-name-string right)))
		(progn
		  (ebdb-record-change-name left rname)
		  (when (yes-or-no-p
			 (format "%s Keep %s as an aka? "
				 prefix (ebdb-record-name-string left)))
		    (object-add-to-list left 'aka lname)))
	      (when (yes-or-no-p
		     (format "%s Keep %s as an aka? "
			     prefix (ebdb-record-name-string right)))
		(object-add-to-list left 'aka rname))))))

      (setf (slot-value left 'relations)
	    (delete-dups (append rrelations lrelations)))
      (setf (slot-value left 'organizations)
	    (delete-dups (append rorganizations lorganizations)))))
  (cl-call-next-method left right auto))

(cl-defmethod ebdb-record-field-slot-query ((class (subclass ebdb-record-person)) &optional query alist)
  (cl-call-next-method
   class
   query
   (append
    '((aka . ebdb-field-name-complex)
      (aka . ebdb-field-name-simple))
    alist)))

(cl-defmethod ebdb-record-firstname ((rec ebdb-record-person) &optional full)
  (when (slot-value rec 'name)
    (ebdb-name-given (slot-value rec 'name) full)))

(cl-defmethod ebdb-record-lastname ((rec ebdb-record-person))
  (when (slot-value rec 'name)
    (ebdb-name-last (slot-value rec 'name))))

(cl-defmethod ebdb-record-current-fields ((record ebdb-record-person)
					  &optional f-list all)
  (with-slots (name aka) record
    (push `(name . ,name) f-list)
    (dolist (a aka)
      (push `(aka . ,a) f-list)))
  (cl-call-next-method record f-list all))

(cl-defmethod ebdb-record-change-name ((record ebdb-record-person)
				       (name-string string))
  (let ((name (ebdb-parse ebdb-default-name-class name-string)))
    (ebdb-record-change-name record name)))

(cl-defmethod ebdb-record-related ((record ebdb-record-person)
				   (field ebdb-field-relation))
  "Return the record that's related to RECORD according to FIELD.
If FIELD is owned by RECORD, return the record pointed to by
FIELD's `rel-uuid' slot.  Otherwise return the record that owns
FIELD."
  ;; The format of the `ebdb-relation-hashtable' could
  ;; probably be reconsidered, this is a bit gross.  If we do
  ;; a `rel-uuid' hashtable lookup, the value looks like:

  ;; ((SRC-UUID  . REL-FIELD) (SRC-UUID . REL_FIELD))

  ;; So we get the SRC-UUID via (rassq FIELD HASH_VALUE).
  (let* ((rel-uuid (slot-value field 'rel-uuid))
	 (target-uuid (if (equal (ebdb-record-uuid record)
				 rel-uuid)
			  (car-safe
			   (rassq field
				  (gethash rel-uuid ebdb-relation-hashtable)))
			(slot-value field 'rel-uuid))))
    (or (ebdb-gethash target-uuid 'uuid)
	(signal 'ebdb-related-unfound (list field)))))

(cl-defmethod ebdb-record-related ((_record ebdb-record-person)
				   (field ebdb-field-role))
  (or
   (ebdb-gethash (slot-value field 'org-uuid) 'uuid)
   (signal 'ebdb-related-unfound (list (slot-value field 'org-uuid)))))

(cl-defmethod ebdb-init-field ((name ebdb-field-name-simple)
			       (record ebdb-record-person))
  (ebdb-pushnew
   (format "%s %s"
	   (ebdb-string name)
	   (ebdb-name-last (slot-value record 'name)))
   (ebdb-record-alt-names record))
  ;; FIXME: Also add nickname-plus-surname to the hashtable.
  (cl-call-next-method))

(cl-defmethod ebdb-init-field ((name ebdb-field-name-simple)
			       (record ebdb-record-person))
  "Add a \"nickname-plus-lastname\" to the hash table."
  (when-let ((last-name (ebdb-record-lastname record)))
    (ebdb-puthash (concat (ebdb-string name) " " last-name)
		  record))
  (cl-call-next-method))

(cl-defmethod ebdb-delete-field ((name ebdb-field-name-simple)
				 (record ebdb-record-person)
				 &optional _unload)
  (ebdb-delete-from-list
   (format "%s %s" (ebdb-string name)
	   (ebdb-name-last (slot-value record 'name)))
   (ebdb-record-alt-names record))
  (cl-call-next-method))

;;; other record subclasses.

(defclass ebdb-field-domain (ebdb-field)
  ((domain
    :initarg :domain
    :type string
    :initform ""
    :documentation)
   (actions
    :initform '(("Browse domain" . ebdb-field-domain-browse))))
  :human-readable "domain"
  :documentation "An organization's domain name.  Useful for
  automatically constructing a homepage for the organization, or
  email addresses for member person records.")

(cl-defmethod ebdb-read ((domain (subclass ebdb-field-domain)) &optional slots obj)
  (cl-call-next-method
   domain
   (plist-put slots :domain
	      (ebdb-read-string "Domain"
				(when obj (slot-value obj 'domain))))
   obj))

(cl-defmethod ebdb-string ((domain ebdb-field-domain))
  (slot-value domain 'domain))

(defclass ebdb-record-organization (ebdb-record-entity)
  ((name
    :initarg :name
    :type (or null ebdb-field-name-simple)
    :initform nil
    :documentation "The name of this organization.")
   (domain
    :initarg :domain
    :type (or null ebdb-field-domain)
    :initform nil
    :documentation "The base domain name for this organization.
    This can be used to open the organization's web page, and
    also as a default for email addresses of people with roles
    tied to this organization."))
  :allow-nil-initform t
  :documentation "A record class representing an organization.")

(cl-defmethod ebdb-init-record ((record ebdb-record-organization))
  (let ((name (slot-value record 'name)))
    (ebdb-init-field name record)
    (setf (ebdb-record-name-string record)
	  (ebdb-string name))
    (cl-call-next-method)))

(cl-defmethod ebdb-delete-record ((org ebdb-record-organization) &optional _db unload)
  (let* ((uuid (ebdb-record-uuid org))
	 (org-entry (gethash uuid ebdb-org-hashtable))
	 record)
    (remhash uuid ebdb-org-hashtable)
    (when (and org-entry
	       (null unload)
    	       (yes-or-no-p (format "Delete all roles associated with %s"
    				    (ebdb-string org))))
      (dolist (r org-entry)
    	(setq record (ebdb-gethash (slot-value r 'record-uuid) 'uuid))
    	(ebdb-record-delete-field record r 'organizations)))
    (cl-call-next-method)))

(cl-defmethod ebdb-string ((record ebdb-record-organization))
  "Return a string representation of RECORD."
  (ebdb-record-name-string record))

(cl-defmethod ebdb-read ((class (subclass ebdb-record-organization)) &optional slots)
  (let ((name (ebdb-read 'ebdb-field-name-simple slots
			 (plist-get slots :name)))
	(domain (ebdb-with-exit (ebdb-read 'ebdb-field-domain))))
    (setq slots (plist-put slots :name name))
    (when domain
      (setq slots (plist-put slots :domain domain)))
    (cl-call-next-method class slots)))

(cl-defmethod ebdb-merge ((left ebdb-record-organization)
			  (right ebdb-record-organization)
			  &optional auto)
  "Merge organization RIGHT into LEFT, and return LEFT."
  (let ((roles (append (gethash (ebdb-record-uuid left) ebdb-org-hashtable)
		       (gethash (ebdb-record-uuid right) ebdb-org-hashtable)))
	(l-uuid (ebdb-record-uuid left)))
    (with-slots (name domain) right
      (when (or auto (yes-or-no-p (format "Use name %s? " (ebdb-string name))))
	(ebdb-record-change-name left name))
      (when (and domain
		 (or auto (yes-or-no-p (format "Use domain %s? " domain))))
	(setf (slot-value left 'domain) domain)))
    (when (and roles (or auto (yes-or-no-p
			       (format "Move all person roles from %s to %s"
				       (ebdb-string right)
				       (ebdb-string left)))))
      (dolist (r roles)
	(setf (slot-value r 'org-uuid) l-uuid))
      (puthash l-uuid roles ebdb-org-hashtable)))
  (cl-call-next-method))

(cl-defmethod ebdb-record-field-slot-query ((class (subclass ebdb-record-organization))
					    &optional query alist)
  (cl-call-next-method
   class
   query
   (append
    '((domain . ebdb-field-domain))
    alist)))

(cl-defmethod ebdb-record-change-name ((record ebdb-record-organization)
				       (name-string string))
  (let ((name (ebdb-parse 'ebdb-field-name-simple name-string)))
    (ebdb-record-change-name record name)))

(cl-defmethod ebdb-record-current-fields ((record ebdb-record-organization)
					  &optional f-list all)
  (with-slots (name domain) record
    (push `(name . ,name) f-list)
    (when domain
      (push `(domain . ,domain) f-list)))
  (cl-call-next-method record f-list all))

(cl-defmethod ebdb-record-search ((record ebdb-record-organization)
				  (_type (eql organization))
				  (regex string))
  (or (string-match-p regex (ebdb-record-name-string record))
      (and (slot-value record 'domain)
	   (string-match-p regex (ebdb-string (slot-value record 'domain))))))

(cl-defmethod ebdb-record-search ((record ebdb-record-organization)
				  (_type (eql mail))
				  (regexp string))
  (let ((domain (slot-value record 'domain)))
    (or (and domain (string-match-p regexp (ebdb-string domain)))
	(cl-call-next-method))))

(cl-defmethod ebdb-field-domain-browse ((_record ebdb-record-organization)
					(domain ebdb-field-domain))
  "Construct a URL from field DOMAIN, and browse it."
  ;; Assume http will redirect to https as necessary.  Bad?
  (let ((domain (slot-value domain 'domain)))
    (when domain
      (browse-url (concat "http://" domain)))))

(cl-defmethod ebdb-record-adopt-role-fields ((record ebdb-record-person)
					     (org ebdb-record-organization)
					     &optional _prompt)
  "Go through all of RECORDs fields and see if any of them should
be moved to a role at ORG.

Currently only works for mail fields."
  (let ((roles (slot-value record 'organizations))
	(org-domain (slot-value org 'domain))
	mail-domain)
    (dolist (r roles)
      (when (and (string= (slot-value r 'org-uuid) (ebdb-record-uuid org))
		 org-domain)
	(dolist (m (ebdb-record-mail record t))
	  (setq mail-domain (cadr (split-string (slot-value m 'mail) "@")))
	  (when (and mail-domain
		     (string-match-p mail-domain
				     (ebdb-string org-domain))
		     (yes-or-no-p (format "Move %s's address %s to role at %s? "
					  (ebdb-string record)
					  (ebdb-string m)
					  (ebdb-string org))))
	    (setf (slot-value r 'mail) m)
	    (ebdb-record-delete-field record m)
	    (ebdb-init-field r record)))))))

(cl-defmethod ebdb-record-related ((record ebdb-record-organization)
				   (field ebdb-field-role))
  ;; Role fields can point to or from an organization; figure out
  ;; which this is.
  (let* ((this-uuid (ebdb-record-uuid record))
	 (rec-uuid (slot-value field 'record-uuid))
	 (org-uuid (slot-value field 'org-uuid))
	 (wanted (if (equal this-uuid rec-uuid) org-uuid rec-uuid)))
    (or
     (ebdb-gethash wanted 'uuid)
     (signal 'ebdb-related-unfound (list wanted)))))

(cl-defmethod ebdb-record-add-org-role ((record ebdb-record-person)
				     (org ebdb-record-organization)
				     &optional mail fields)
  "Convenience function for creating a role relationship between RECORD and ORG.

MAIL and/or FIELDS, if present, should be a list of field
instances to add as part of the role."
  (let ((role (make-instance 'ebdb-field-role
			     :org-uuid (ebdb-record-uuid org)
			     :record-uuid (ebdb-record-uuid record))))
    (when fields
      (dolist (f fields)
	(object-add-to-list role 'fields f)))
    (when mail
      (setf (slot-value role 'mail) mail))
    (ebdb-record-insert-field record role 'organizations)
    (ebdb-init-field role record)))

(defclass ebdb-record-mailing-list (ebdb-record)
  ((name
    :type ebdb-field-name-simple
    :initarg :name
    :initform nil)
   (id
    :type ebdb-field-domain
    :initarg :id
    :initform nil)
   (posting-address
    :type ebdb-field-mail
    :initarg :posting-address
    :initform nil)
   (unsubscribe-address
    :type ebdb-field-mail
    :initarg :unsubscribe-address
    :initform nil)
   (unsubscribe-url
    :type ebdb-field-url
    :initarg :unsubscribe-url
    :initform nil)
   (user-address
    :type ebdb-field-mail
    :initarg :user-address
    :initform nil)
   (archive-url
    :type ebdb-field-url
    :initarg :archive-url
    :initform nil))
  :allow-nil-initform t
  :documentation "A record class representing a mailing list.")

(cl-defmethod ebdb-read ((class (subclass ebdb-record-mailing-list)) &optional slots)
  (let ((name (ebdb-read 'ebdb-field-name-simple))
	(id (let ((ebdb-read-string-override "Mailing list id"))
	      (ebdb-read 'ebdb-field-domain)))

	(posting-address
	 (let ((ebdb-read-string-override "Posting address"))
	   (ebdb-with-exit
	    (ebdb-read 'ebdb-field-mail))))

	(user-address
	 (let ((ebdb-read-string-override "Address to post from"))
	   (ebdb-with-exit
	    (ebdb-read
	     'ebdb-field-mail nil
	     (ebdb-parse 'ebdb-field-mail user-mail-address)))))

	(archive-url
	 (let ((ebdb-read-string-override "Archive URL"))
	   (ebdb-with-exit
	    (ebdb-read 'ebdb-field-url)))))
    (setq slots (list :name name :id id :posting-address posting-address
		      :user-address user-address :archive-url archive-url))
    (cl-call-next-method class slots)))

(cl-defmethod ebdb-init-record ((record ebdb-record-mailing-list))
  (with-slots (name posting-address) record
    (ebdb-init-field name record)
    (ebdb-init-field posting-address record)))

(cl-defmethod ebdb-string ((record ebdb-record-mailing-list))
  (with-slots (name id) record
    (if (and name id)
	(concat name " " id)
      (or name id))))

;;; Merging

;; There should be two kinds of merging: interactive and automatic.
;; Interactive merging is for when you actually have duplicate records
;; for the same entity -- this is just a mistake, and should be
;; handled interactively.  Automatic merging happens when you've put a
;; single record in multiple databases, and they've gotten out of
;; sync.  The merging process detects this by checking the 'uuid and
;; 'timestamp

(defun ebdb-check-uuid (uuid)
  "Ensure that UUID hasn't been seen before.
If it has, raise an error containing the record that already has
that uuid."
  (let ((dup (ebdb-gethash uuid 'uuid)))
    (when dup
      (signal 'ebdb-duplicate-uuid
	      (list dup)))))

(defun ebdb-make-uuid (&optional prefix)
  "Create and return a new UUID.
This depends on the value of `ebdb-uuid-function'.  When that
variable is a string, assume the string refers to a system
executable.  When a symbol, assume an Elisp function.  If
optional argument PREFIX is given, add that prefix to the uuid
string."
  (let ((prefix-string (unless (string-empty-p prefix)
			 (concat prefix "-")))
	(uid
	 (cond
	  ((and (stringp ebdb-uuid-function)
		(executable-find ebdb-uuid-function))
	   (shell-command-to-string
	    (executable-find ebdb-uuid-function)))
	  ((functionp ebdb-uuid-function)
	   (funcall ebdb-uuid-function))
	  (t (ebdb--make-uuid)))))
    (concat prefix-string
	    (replace-regexp-in-string
	     "[\n\t ]+" ""
	     uid))))

;; Stolen directly and with no shame from Org.
(defun ebdb--make-uuid ()
  "Return string with random (version 4) UUID."
  (let ((rnd (md5 (format "%s%s%s%s%s%s%s"
			  (random)
			  (current-time)
			  (user-uid)
			  (emacs-pid)
			  (user-full-name)
			  user-mail-address
			  (recent-keys)))))
    (format "%s-%s-4%s-%s%s-%s"
	    (substring rnd 0 8)
	    (substring rnd 8 12)
	    (substring rnd 13 16)
	    (format "%x"
		    (logior
		     #b10000000
		     (logand
		      #b10111111
		      (string-to-number
		       (substring rnd 16 18) 16))))
	    (substring rnd 18 20)
	    (substring rnd 20 32))))

;;; The database class(es)

(defclass ebdb-db (eieio-persistent)
  ;; Is there a need for a "remote" slot?
  ((label
    :initarg :label
    :initform ""
    :type string)
   (uuid
    :initarg :uuid
    :initform nil
    :type (or null ebdb-field-uuid)
    :documentation
    "A unique identifier for this database.")
   (file-header-line
    :initform ";; EBDB file-persistent database")
   (sync-time
    :type (or null cons)
    :initarg :sync-time
    :initform nil
    :documentation "The date/time at which this database was last synced with its source.")
   (records
    :initarg :records
    :initform nil
    :type (list-of ebdb-record)
    :documentation
    "The records stored in this database.")
   (read-only
    :initarg :read-only
    :initform nil
    :type boolean
    :custom boolean
    :documentation
    "Is this database read-only?")
   (version
    :initarg :version
    :type string
    :initform "0.1"
    :documentation
    "The version number of this database.")
   (uuid-prefix
    :initarg :uuid-prefix
    :type string
    :initform ""
    :custom string
    :documentation
    "A string prefix to be added to all UUIDs generated for
    records created in this database.")
   (buffer-char
    :initarg :buffer-char
    :type (or null character)
    :initform nil
    :custom (choice (const :tag "None" nil)
		    (character :tag "Character"))
    :documentation
    "A single character used in the *EBDB* buffer to indicate the
    database(s) to which a record belongs.")
   (dirty
    :initarg :dirty
    :initform nil
    :type boolean
    :documentation
    "Set to t when the database has unsaved data.")
   (auto-save
    :initarg :auto-save
    :initform t
    :type boolean
    :custom boolean
    :documentation
    "Set to t to have this database auto save itself.  Databases
    that are disabled or read-only will not be saved.")
   (disabled
    :initarg :disabled
    :initform nil
    :type boolean
    :custom boolean
    :documentation
    "When t, records will not be loaded from or saved to this
    database.  Use `ebdb-disable-database' to disable the
    database immediately.")
   (record-class
    :initarg :record-class
    ;; I don't think I can actually set this to `ebdb-record': the
    ;; type needs to be a class, not an instance.  Can I do that?
    :type symbol
    ;; "`," is used to trick EIEIO into evaluating the form.
    :initform `,ebdb-default-record-class
    :custom symbol
    :documentation
    "The default EIEIO class for records in this database.  Must
    be a subclass of `ebdb-record'."))

  "The base class for the EBDB database store.  This class should
not be instantiated directly, subclass it instead."
  :allow-nil-initform t
  :abstract t)

(cl-defmethod initialize-instance ((db ebdb-db) &optional slots)
  "Make sure DB has a uuid.
Also switch old :object-name slot name to :label."
  (let ((obj-name (plist-get slots :object-name))
	p)
    (unless (and (slot-boundp db 'uuid)
		 (slot-value db 'uuid))
      (setf (slot-value db 'uuid)
	    (make-instance 'ebdb-field-uuid
			   :uuid (ebdb-make-uuid
				  (slot-value db 'uuid-prefix)))))
    (while slots
      (when (not (eq :object-name (car slots)))
	(setq p (plist-put p (car slots) (nth 1 slots))))
      (setq slots (cddr slots)))
    (when obj-name
      (setq p (plist-put p :label obj-name)))
    (cl-call-next-method db p)))

;;; Home-made auto saving for `eieio-persistent' objects.  The
;;; `ebdb-db-save' :after method deletes the auto save file, and the
;;; `ebdb-load' function checks for (and loads) any existing auto save
;;; files.

(defun ebdb-db-make-auto-save-file-name (filename)
  "Make an auto save file name from FILENAME."
  ;; What I'd really like to do, obviously, is to use the built in
  ;; `make-auto-save-file-name'.  You can't pass that function your
  ;; own filename, though, so we'll make a (highly) watered-down
  ;; version of that.
  (let ((expanded (expand-file-name filename)))
    (concat (file-name-directory expanded)
	    "#"
	    (file-name-nondirectory expanded)
	    "#")))

(cl-defmethod ebdb-db-do-auto-save ((db ebdb-db))
  (let* ((orig-file (slot-value db 'file))
	 (auto-save-file
	  (ebdb-db-make-auto-save-file-name
	   orig-file)))
    (eieio-persistent-save db auto-save-file)
    ;; The call to `eieio-persistent-save' sets the 'file slot to the
    ;; auto-save-file name, for some reason, see FIXME in there.
    ;; Setting it back ought to have us covered.
    (setf (slot-value db 'file) orig-file)))

(defun ebdb-auto-save-databases ()
  "Auto-save all EBDB databases.
Run as a hook in the `auto-save-hook"
  (dolist (d ebdb-db-list)
    (with-slots (auto-save disabled read-only) d
      (when (and auto-save
		 (null disabled)
		 (null read-only)
		 (ebdb-db-dirty d)
		 (null (ebdb-db-unsynced d)))
	(ebdb-db-do-auto-save d)))))

(add-hook 'auto-save-hook #'ebdb-auto-save-databases)

;;; Database subclasses will have their own specialization of
;;; `ebdb-db-load', which is responsible for somehow getting the
;;; records into the DB's "records" slot.  Once that's done, they
;;; should call `cl-call-next-method' to run the methods below.

(cl-defmethod ebdb-db-unsynced ((db ebdb-db))
  "Check if DB is out of sync.
Returns t if DB's persistence file has been accessed since the
last time DB was loaded.

This is the base implementation, which only checks if DB's
persistence file has been accessed.  Subclasses should combine
this check with their own check to see if their records are
somehow out of sync.

\"Unsynced\" is different from \"dirty\".  Dirty just means the
DB has unsaved changes.  Unsynced means that saving those
changes (or re-loading the database from its source) would
overwrite data somewhere."
  (let* ((file-attrs
	  (file-attributes
	   (expand-file-name (slot-value db 'file))))
	 (file-mod-time
	  ;; This accessor was added in 26.1, we support Emacs 25.
	  (if (fboundp 'file-attribute-modification-time)
	      (file-attribute-modification-time file-attrs)
	    (nth 5 file-attrs))))
    (and file-mod-time
	 (time-less-p (slot-value db 'sync-time) file-mod-time))))

(cl-defmethod ebdb-db-dirty ((db ebdb-db))
  "Return t if DB is marked dirty, or contains any dirty records."
  (or (slot-value db 'dirty)
      (ebdb-dirty-records (slot-value db 'records))))

(cl-defmethod ebdb-db-load ((db ebdb-db))
  ;; By this stage, all of DB's records should be in the 'records
  ;; slot.  This happens automatically with `ebdb-db-file'; other
  ;; subclasses should overload this method to load their records.
  (ebdb-db-load-records db (slot-value db 'records)))

(cl-defgeneric ebdb-db-load-records (db records)
  "Load RECORDS into DB.
This method is responsible for adding DB to records' caches,
checking their uuid, and hashing the uuid.  It happens at two
different points: after loading DB, and when adding a record to
DB.")

(cl-defmethod ebdb-db-load-records ((db ebdb-db) records)
  (dolist (rec records t)

    ;; Cycle over each loaded record.
    (condition-case err
	(progn
	  ;; Tell it about the database.
	  (cl-pushnew db (ebdb-record-databases rec))

	  ;; Make sure its UUID is unique.  Doesn't create new UUIDs.
	  (ebdb-check-uuid (ebdb-record-uuid rec))

	  ;; Hash the record against its UUID.  This provides some
	  ;; speedup in the later initialization process.
	  (ebdb-puthash (ebdb-record-uuid rec) rec))

      (ebdb-duplicate-uuid
       ;; There's a duplicate, decide what to do about it.  In the
       ;; following, "double" refers to the already-loaded record that
       ;; has the same uuid.  We start off assuming that we will
       ;; delete this existing "double", and replace it with the
       ;; newly-loaded record ("rec").
       (let* ((double (cadr err))
	      (delete-double t)
	      (recs-equal (equal (clone rec :cache nil)
				 (clone double :cache nil)))
	      deleter keeper)

	 ;; If any of the double's databases are read-only, we should
	 ;; switch our assumptions about which record to delete.  This
	 ;; at least gives us a fighting chance to update a writeable
	 ;; database from a read-only one, and avoid an error.
	 (dolist (d (ebdb-record-databases double))
	   (when (slot-value d 'read-only)
	     (setq delete-double nil)))

	 ;; If the records are the same, it doesn't matter which we
	 ;; delete, so don't change our assumption.
	 (unless recs-equal

	   ;; But if double is newer, we still need to keep it.
	   (unless (ebdb-record-compare rec double 'timestamp)
	     (setq delete-double nil)))

	 (setq deleter (if delete-double double rec)
	       keeper (if delete-double rec double))

	 ;; Merge the records, either automatically or
	 ;; interactively, depending on the value of
	 ;; `ebdb-auto-merge-records'.
	 (unless recs-equal
	   (setq keeper (ebdb-merge keeper deleter ebdb-auto-merge-records)))

	 ;; Make sure the right record is hashed against the duplicate uuid.
	 (ebdb-puthash (ebdb-record-uuid keeper) keeper)

	 (dolist (d (ebdb-record-databases deleter))
	   ;; Use low-level functions for this so we don't set the
	   ;; database dirty.
	   (object-remove-from-list d 'records deleter)
	   (object-add-to-list d 'records keeper)
	   (cl-pushnew d (ebdb-record-databases keeper))
	   (ebdb-delete-record deleter d t)))))))

(cl-defmethod ebdb-db-unload ((db ebdb-db))
  "Unload database DB.
This involves going through DB's records and removing each one
that doesn't belong to a different database."
  (dolist (r (slot-value db 'records))
    ;; Only disappear the record if it doesn't belong to any other
    ;; databases.
    (if (= 1 (length (ebdb-record-databases r)))
	(ebdb-delete-record r db t)
      (ebdb-delete-from-list db (ebdb-record-databases r)))))

(defun ebdb-db-reload (db)
  "Reload DB.
This consists of unloading all DB's records, re-reading its
database definition from file, and then reloading all the
records."
  (let ((elt (cl-position db ebdb-db-list)))
    (ebdb-db-unload db)
    (setq db (eieio-persistent-read (slot-value db 'file) 'ebdb-db t))
    ;; Stick DB back where it came from.
    (setcar (nthcdr elt ebdb-db-list) db)
    (ebdb-db-load db)
    (ebdb-initialize (slot-value db 'records))))

(cl-defmethod ebdb-record-compare ((left ebdb-record)
				   (right ebdb-record)
				   (_test (eql timestamp)))
  "Test if record LEFT is newer than record RIGHT."
  (let ((left-time (slot-value (slot-value left 'timestamp) 'timestamp))
	(right-time (slot-value (slot-value right 'timestamp) 'timestamp)))
    (or (equal left-time right-time)
	(time-less-p left-time right-time))))

(cl-defmethod ebdb-db-load :after ((db ebdb-db))
  (setf (slot-value db 'sync-time) (current-time))
  (run-hook-with-args 'ebdb-after-read-db-hook db))

;; This is totally goofy, it's just replacing the method overloading
;; mechanism with the hook mechanism.
(cl-defmethod ebdb-db-load :before ((db ebdb-db))
  (run-hook-with-args 'ebdb-before-read-db-hook db))

(cl-defgeneric ebdb-db-editable (db &optional noerror reload)
  "If DB can't be edited, signal an error.
This method is called before most operations that would alter DB.

With optional argument NOERROR, return nil instead of signalling
an error.  With optional argument RELOAD, reload DB if it is out
of sync but has no local modifications.")

(cl-defmethod ebdb-db-editable ((db ebdb-db) &optional noerror reload)
  (let ((err
	 (cond ((slot-value db 'read-only)
		'ebdb-readonly-db)
	       ((slot-value db 'disabled)
		'ebdb-disabled-db)
	       ((ebdb-db-unsynced db)
		(if (and (null (ebdb-db-dirty db))
			 reload)
		    (progn
		      (ebdb-db-reload db)
		      nil)
		  'ebdb-unsynced-db))
	       (t nil))))
    (or (not err)
	(if noerror
	    nil
	  (signal err (list db))))))

(cl-defgeneric ebdb-db-save (db &optional prompt force)
  "Save DB to its persistence file.
When PROMPT is non-nil, prompt the user before saving (currently
unimplemented).  When FORCE is non-nil, save regardless of
whether the database is dirty or not, and ignore all database
errors.

This method is only responsible for saving the database
definition to disk.  Database subclasses are responsible for
saving or otherwise persisting their records, and setting
their :records slot to nil before calling this method with
`cl-call-next-method'.  They can either catch errors thrown by
the persistent save, or allow them to propagate.")

(cl-defmethod ebdb-db-save :before ((db ebdb-db) &optional _prompt force)
  "Prepare DB to be saved.
Possibly raise an error if the database is not editable.  Lastly
run `ebdb-before-save-db-hook'."
  (when (and (null force)
	     (ebdb-db-dirty db))
    (ebdb-db-editable db))
  (run-hook-with-args 'ebdb-before-save-db-hook db))

(cl-defmethod ebdb-db-save ((db ebdb-db) &optional _prompt force)
  "Mark DB and all its records as \"clean\" after saving."
  (let ((recs (ebdb-dirty-records (slot-value db 'records)))
	(eieio-print-indentation (null ebdb-vacuum-databases))
	(eieio-print-object-name ebdb-print-object-name))
    (when (or force recs (slot-value db 'dirty))
      (setf (slot-value db 'dirty) nil)
      (dolist (r recs)
	(setf (slot-value r 'dirty) nil))
      (condition-case err
	  (eieio-persistent-save db)
	(error
	 (setf (slot-value db 'dirty) t)
	 (dolist (r recs)
	   (setf (slot-value r 'dirty) t))
	 (signal 'error err))))))

(cl-defmethod ebdb-db-save :after ((db ebdb-db) &optional _prompt _force)
  "After saving DB, also delete its auto-save file, if any.
Also run `ebdb-after-save-db-hook'."
  (let ((auto-save-file
	 (ebdb-db-make-auto-save-file-name
	  (slot-value db 'file))))
    (setf (slot-value db 'sync-time) (current-time))
    (when (file-exists-p auto-save-file)
      (delete-file auto-save-file))
    (run-hook-with-args 'ebdb-after-save-db-hook db)))

(cl-defgeneric ebdb-db-add-record (db record)
  "Associate RECORD with DB.")

(cl-defgeneric ebdb-db-remove-record (db record)
  "Disassociate RECORD from DB.")

(cl-defmethod ebdb-db-add-record :before ((db ebdb-db) _record)
  (ebdb-db-editable db))

(cl-defmethod ebdb-db-remove-record :before ((db ebdb-db) _record)
  (ebdb-db-editable db))

(cl-defmethod ebdb-db-add-record ((db ebdb-db) record)
  ;; This function gets called when creating a new record, and also
  ;; when "adopting" an existing record.  In the first case, it
  ;; won't have a UUID slot.
  (unless (slot-value record 'uuid)
    (setf (slot-value record 'uuid)
	  (make-instance
	   'ebdb-field-uuid
	   :uuid (ebdb-make-uuid (slot-value db 'uuid-prefix))))
    (ebdb-puthash (ebdb-record-uuid record) record))
  (object-add-to-list db 'records record)
  (cl-pushnew db (ebdb-record-databases record))
  (setf (slot-value db 'dirty) t)
  ;; TODO: Is there any need to sort the DB's records after insertion?
  ;; What about sorting ebdb-record-tracker?
  record)

(cl-defmethod ebdb-db-remove-record ((db ebdb-db) record)
  (object-remove-from-list db 'records record)
  (ebdb-delete-from-list db (ebdb-record-databases record))
  (setf (slot-value db 'dirty) t)
  record)

(cl-defmethod ebdb-db-add-record-field :before ((db ebdb-db) record _slot _field)
  (ebdb-db-editable db)
  (ebdb-stamp-time record))

(cl-defmethod ebdb-db-remove-record-field :before ((db ebdb-db) record _slot _field)
  (ebdb-db-editable db)
  (ebdb-stamp-time record))

(cl-defmethod ebdb-string ((db ebdb-db))
  (format "Database: %s" (slot-value db 'file)))

(cl-defgeneric ebdb-db-disable (db)
  "Disable DB.
DB will be unconditionally saved to disk as part of the disable
process.")

(cl-defmethod ebdb-db-disable ((db ebdb-db))
  (setf (slot-value db 'disabled) t)
  (ebdb-db-save db nil t)
  (ebdb-db-unload db))

(cl-defmethod ebdb-db-customize ((db ebdb-db))
  (eieio-customize-object db))

(defun ebdb-customize-database (db)
  "Use the customization interface to edit slot values of DB."
  (interactive (list (ebdb-prompt-for-db)))
  (ebdb-db-customize db))

(cl-defmethod eieio-done-customizing ((db ebdb-db))
  (setf (slot-value db 'dirty) t)
  (cl-call-next-method))

;;; Subclasses of `ebdb-db'.

;; File-based database, keeping its records in-file.

(defclass ebdb-db-file (ebdb-db)
  nil
  :documentation "A `ebdb-db' subclass that saves records
  directly in its persistence file.")

(cl-defmethod cl-print-object ((db ebdb-db) stream)
  (princ (format "#<%S %s %d records>"
		 (eieio-object-class-name db)
                 (when (slot-boundp  db 'file)
                   (slot-value db 'file))
		 (length (slot-value db 'records)))
	 stream))

;; `ebdb-db-file' doesn't need a `ebdb-db-load' method.  Its records
;; are stored in its persistence file, directly in the :records slot,
;; so simply reading the object in with `eieio-persistent-read' does
;; all the set up we need.

(cl-defmethod initialize-instance ((db ebdb-db-file) &optional slots)
  (let ((label (concat "File: " (plist-get slots :file))))
    (setq slots (plist-put slots :label label))
    (cl-call-next-method db slots)))

(cl-defmethod ebdb-db-add-record ((db ebdb-db-file) record)
  "Mark DB and RECORD as \"dirty\" until saved."
  (setf (slot-value record 'dirty) t)
  (setf (slot-value db 'dirty) t)
  (cl-call-next-method))

(cl-defmethod ebdb-db-remove-record ((db ebdb-db-file) _record)
  "Mark DB as \"dirty\" until saved."
  (setf (slot-value db 'dirty) t)
  (cl-call-next-method))

(cl-defmethod ebdb-db-add-record-field
    ((db ebdb-db-file) record _slot field)
  (setf (slot-value record 'dirty) t)
  (setf (slot-value db 'dirty) t)
  field)

(cl-defmethod ebdb-db-remove-record-field
    ((db ebdb-db-file) record _slot _field)
  (setf (slot-value record 'dirty) t)
  (setf (slot-value db 'dirty) t)
  t)

(cl-defmethod object-write ((record ebdb-record) &optional comment)
  "Don't write RECORD's cache to file."
  ;; Instead, write a clone of RECORD with the cache slot blanked out.
  (let ((clone (clone record :cache nil)))
    (cl-call-next-method clone comment)))

(defun ebdb-clear-vars ()
  "Set all internal EBDB vars to nil."
  (setq ebdb-db-list nil
	ebdb-record-tracker nil)
  (clrhash ebdb-org-hashtable)
  (clrhash ebdb-hashtable)
  (clrhash ebdb-diary-entries)
  (clrhash ebdb-relation-hashtable))

;; Changing which database a record belongs to.

(defun ebdb-move-record (record to-db)
  "Move RECORD from its existing database to TO-DB."
  ;; It's not quite right to assume that we're *only* removing the
  ;; record from the first db in its list of dbs.
  (let ((existing (car (ebdb-record-databases record))))
    (unless (equal existing to-db)
      (ebdb-db-add-record to-db record)
      (ebdb-db-remove-record existing record))))

(defun ebdb-copy-record (record to-db)
  "Copy RECORD into TO-DB."
  (ebdb-db-add-record to-db record))

;;; Utility functions

(cl-defgeneric ebdb-foo-in-list-p (foo list)
  "Check if FOO (a class type or class instance) is in LIST.")

(cl-defmethod ebdb-foo-in-list-p ((cls (subclass ebdb-field))
				  list)
  "Check if CLS belongs to one of the classes in LIST.
CLS is \"in\" list if its class name appears directly in the
list, or if it is a subclass of one of the classes in LIST.
Return CLS, or nil."
  (catch 'member
    ;; First the easy check.
    (when (memq cls list)
      (throw 'member cls))
    ;; Then the slightly more exhaustive check.
    (dolist (c list)
      (when (and (class-p c)
		 (child-of-class-p cls c))
	(throw 'member cls)))))

(cl-defmethod ebdb-foo-in-list-p ((obj ebdb-field)
				  list)
  "Check if OBJ belongs to one of the classes in LIST.
OBJ is \"in\" list if its class name appears directly in the
list, or if it is a subclass of one of the classes in LIST, or if
one of the symbols in LIST matches it in some other way.  Return
the class symbol of OBJ, or nil."
  (let ((cls-symbol (eieio-object-class-name obj)))
    ;; First, check the class
    (or (ebdb-foo-in-list-p cls-symbol list)
	(catch 'member
	  ;; Then the full object check.
	  (when
	      (or (and (memq 'mail list)
		       (object-of-class-p obj 'ebdb-field-mail))
		  (and (memq 'role list)
		       (object-of-class-p obj 'ebdb-field-role))
		  (and (memq 'phone list)
		       (object-of-class-p obj 'ebdb-field-phone))
		  (and (memq 'address list)
		       (object-of-class-p obj 'ebdb-field-address))
		  (and (memq 'notes list)
		       (object-of-class-p obj 'ebdb-field-notes))
		  (and (memq 'tags list)
		       (object-of-class-p obj 'ebdb-field-tags))
		  (and (memq 'mail-primary list)
		       (object-of-class-p obj 'ebdb-field-mail)
		       (eq 'primary (slot-value obj 'priority)))
		  (and (memq 'mail-defunct list)
		       (object-of-class-p obj 'ebdb-field-mail)
		       (eq 'defunct (slot-value obj 'priority)))
		  (and (memq 'mail-not-defunct list)
		       (object-of-class-p obj 'ebdb-field-mail)
		       (null (eq 'defunct (slot-value obj 'priority))))
		  (and (memq 'role-defunct list)
		       (object-of-class-p obj 'ebdb-field-role)
		       (slot-value obj 'defunct))
		  (and (memq 'role-not-defunct list)
		       (object-of-class-p obj 'ebdb-field-role)
		       (null (slot-value obj 'defunct))))
	    (throw 'member cls-symbol))))))

(defun ebdb-dirty-dbs (&optional dbs)
  "Return all databases marked \"dirty\"."
  (let (dirty)
    (dolist (d (or dbs ebdb-db-list))
      (when (ebdb-db-dirty d)
	(push d dirty)))
    dirty))

(defun ebdb-unsynced-dbs (&optional dbs)
  "Return any databases that are out of sync with their source."
  (let (unsynced)
    (dolist (d (or dbs ebdb-db-list))
      (when (ebdb-db-unsynced d)
	(push d unsynced)))
    unsynced))

(defun ebdb-prompt-for-record (&optional records class prompt)
  "Prompt for a single record, and return it.
If RECORDS is a list of records, offer choices from that list.
If CLASS is given, only offer choices that are an instance of
that class, or its subclasses.  If PROMPT is given, use that as
the prompt."
  (let* ((recs (or records (ebdb-records)))
	 (pairs
	  (mapcan
	   (lambda (r)
	     (mapcar
	      (lambda (s)
		(cons s (ebdb-record-uuid r)))
	      (delete-dups
	       (cons
		(ebdb-string r)
		(ebdb-record-alt-names r)))))
	   (if class
	       (seq-filter
		(lambda (r)
		  (object-of-class-p r class))
		recs)
	     recs)))
	 (result
	  (completing-read
	   (or prompt "Choose record: ")
	   pairs)))
    (ebdb-gethash (cdr (assoc-string result pairs)) 'uuid)))

(defun ebdb-prompt-for-field-type (fields)
  "Prompt the user for a field from FIELDS.
Returns a list of (\"label\" slot . field-class)."
  ;; Fields that have labels will provide those labels as a sort of
  ;; "second level" of choice. So our top-level choices should be:
  ;; mail, address, phone, notes, all subclasses of ebdb-field-user,
  ;; and then the labels in ebdb-user-label-list. With a
  ;; non-completing string assumed to be a new label for a
  ;; ebdb-user-field-simple.

  (let* (field field-list choice)
    (dolist (c fields)
      ;; Find a less-ugly way of doing this.
      (setq field (cdr c))
      (unless (or (eq field 'ebdb-field-user-simple)
		  (eq field 'ebdb-field-creation-date)
		  (eq field 'ebdb-field-timestamp))
	(push (list (ebdb-field-readable-name field) c) field-list)))
    (dolist (l ebdb-user-label-list)
      (push (list l (cons 'fields 'ebdb-field-user-simple)) field-list))
    (setq choice
	  (completing-read
	   "Choose field type: "
	   field-list))
    (or (assoc choice field-list)
	(list choice (cons 'fields 'ebdb-field-user-simple)))))

(defun ebdb-prompt-for-db (&optional db-list shortcut)
  "Prompt the user to choose a database.
Possible choices come from `ebdb-db-list', or from DB-LIST, if
that argument is given.  If SHORTCUT is non-nil, don't bother
prompting if there's only one database."
  (unless (or db-list ebdb-db-list)
    (ebdb-load))
  (let ((collection (or db-list ebdb-db-list))
	db-string)
    (if (and shortcut (= 1 (length collection)))
	(car collection)
      (setq db-string
	    (ebdb-read-string "Choose a database"
			      nil
			      (mapcar
			       (lambda (d)
				 (slot-value d 'label))
			       collection)
			      t))
      (object-assoc db-string 'label collection))))

(defun ebdb-record-one-mail (record &optional
				    prompt primary-only no-roles defunct)
  "Return a single mail address to use for RECORD.
If RECORD only has one address, return that directly.  If PROMPT
is non-nil, ask the user which address to use.  Otherwise, return
the record's primary address, or the first of the list of
addresses, if none are primary.  If PRIMARY-ONLY is non-nil,
return nil if RECORD has no primary address.  NO-ROLES and
DEFUNCT function as in `ebdb-record-mail'."
  (let ((mails (ebdb-record-mail record no-roles nil defunct)))
    (when mails
      (cond
       ((= 1 (length mails))
	(car mails))
       (prompt
	(let ((mail-alist (mapcar
			   (lambda (m) (cons (ebdb-string m) m))
			   mails)))
	  (cdr (assoc (ebdb-read-string
		       (format "Mail address for %s: "
			       (ebdb-string record))
		       nil mail-alist t)
		      mail-alist))))
       (primary-only
	(object-assoc 'primary 'priority mails))
       (t (or (object-assoc 'primary 'priority mails)
	      (car mails)))))))

(defun ebdb-dirty-records (&optional records)
  "Return all records with unsaved changes.
If RECORDS are given, only search those records."
  (seq-filter
   (lambda (r)
     (slot-value r 'dirty))
   (or records ebdb-record-tracker)))

;;; Getters

;; TODO: Use :accessor tags for the simple cases.

(defun ebdb-record-user-fields (record)
  (slot-value record 'fields))

(defun ebdb-record-user-field (record label)
  (object-assoc (if (stringp label)
		    label
		  (symbol-name label))
		'label (ebdb-record-user-fields record)))

(defun ebdb-record-address (record &optional label)
  (let ((addresses (slot-value record 'address)))
    (if label
	(object-assoc label 'label addresses)
      addresses)))

(defun ebdb-record-phone (record &optional label)
  (let ((phones (slot-value record 'phone)))
    (if label
	(object-assoc label 'label phones)
      phones)))

(cl-defgeneric ebdb-record-mail (record &optional no-roles label defunct)
  "Return a list of all RECORD's mail fields.
If NO-ROLES is non-nil, exclude mail fields from RECORD's roles.
If LABEL is a string, return the mail with that label.  If
DEFUNCT is non-nil, also consider RECORD's defunct mail
addresses.  Sort mails by descending priority.")

(cl-defmethod ebdb-record-mail :around ((_record ebdb-record)
					&optional _no-roles label defunct)
  (let ((found (cl-call-next-method)))
    (unless defunct
      (setq found
	    (seq-filter (lambda (m)
			  (null (eq (slot-value m 'priority) 'defunct)))
			found)))
    (if label
	(object-assoc label 'label found)
      (sort (copy-sequence found) #'ebdb-field-compare))))

(cl-defmethod ebdb-record-mail :around ((record ebdb-record-entity)
					&optional _no-roles _label _defunct)
  (let ((found (cl-call-next-method)))
    (append found (slot-value record 'mail))))

(cl-defmethod ebdb-record-mail ((_record ebdb-record-organization)
				&optional _no-roles _label _defunct)
  nil)

(cl-defmethod ebdb-record-mail ((record ebdb-record-person)
				&optional no-roles _label _defunct)
  (unless no-roles
    (delete nil (mapcar (lambda (role) (slot-value role 'mail))
		       (slot-value record 'organizations)))))

(cl-defmethod ebdb-record-mail ((record ebdb-record-mailing-list)
				&optional _no-roles _label _defunct)
  (slot-value record 'posting-address))



;;; Mail and completion stuff.

(defun ebdb-dwim-mail (record &optional mail)
  ;; Do What I Mean!
  "Return a string to use as the mail address of RECORD.
However, if both the first name and last name are constituents of
the address as in John.Doe@Some.Host, and
`ebdb-mail-avoid-redundancy' is non-nil, then the address is used
as is.  If `ebdb-mail-avoid-redundancy' is \\='mail-only the name is
never included.  MAIL may be a mail address to be used for
RECORD.  If MAIL is nil use RECORD's primary mail address.  If
MAIL is the symbol `prompt', prompt the user for a mail address
to use."
  (unless (ebdb-field-mail-p mail)
    (setq mail (ebdb-record-one-mail record (eq mail 'prompt) t)))
  (unless mail (error "Record has no mail addresses"))
  (let* ((name-base (or (slot-value mail 'aka)
			(ebdb-record-name-string record)))
	 (mail (slot-value mail 'mail))
	 (name
	  (cond
	   ((or (eq 'mail-only ebdb-mail-avoid-redundancy)
		(and ebdb-mail-avoid-redundancy
		     (string-match-p
		      (regexp-quote
		       (replace-regexp-in-string
			"\s" "" name-base))
		      (replace-regexp-in-string
		       "[-._]" "" (car (split-string mail "@"))))))
	    nil)
	   (name-base)
	   (t nil))))
    (if name
	(progn
	  ;; If the name contains backslashes or double-quotes, backslash them.
	  (setq name (replace-regexp-in-string "[\\\"]" "\\\\\\&" name))
	  ;; If the name contains control chars or RFC822 specials, it needs
	  ;; to be enclosed in quotes.  This quotes a few extra characters as
	  ;; well (!,%, and $) just for common sense.
	  ;; `define-mail-alias' uses regexp "[^- !#$%&'*+/0-9=?A-Za-z^_`{|}~]".

	  (format (if (string-match "[][[:cntrl:]\177[:punct:][:nonascii:]]" name)
		      "\"%s\" <%s>"
		    "%s <%s>")
		  name mail))
      mail)))

(defun ebdb-mail-dwim-completion-at-point-function ()
  "Complete text at point as a mail \"dwim\" string.
The completed strings are of the form \"Firstname Lastname
<name@example.org>\".  For use in `completion-at-point-functions'
in `message-mode' or `mail-mode'.

Also see the variable `ebdb-ignore-redundant-mails'."
  (when (let ((mail-abbrev-mode-regexp
	       "^\\(Resent-\\)?\\(To\\|B?Cc\\|Reply-To\\|From\\|Mail-Followup-To\\|Mail-Copies-To\\):"))
          (mail-abbrev-in-expansion-header-p))
    (let* ((start
	    (save-excursion
	      ;; Headers can be multi-line, but if we've wrapped there
	      ;; should always be something on the current line.
	      (re-search-backward ",[[:blank:]]?\\|:[[:blank:]]?"
				  (line-beginning-position) t)
	      (match-end 0)))
	   (end (save-excursion
		  (goto-char (line-end-position))
		  (max start (point)))))
      (list start end #'ebdb-mail-dwim-collection-function
	    (list :exclusive 'no)))))

(defun ebdb-mail-dwim-collection-function (str pred action)
  "Function that pretends to be a completion table."
  (let ((completion-ignore-case t))
    (if (eq action 'metadata)
	'(metadata . ((category . ebdb-contact)))
      (complete-with-action action ebdb-dwim-completion-cache str pred))))

(add-to-list 'completion-category-defaults
	     `(ebdb-contact (styles substring basic)
			    (cycle . ,ebdb-complete-mail-allow-cycling)))

(defun ebdb-record-completion-table (str pred action)
  "Function used as a completion table for EBDB records.
STR is used to search the database.  The return value is the
completed name string."
  (let* ((completion-ignore-case ebdb-case-fold-search)
	 (newstring (concat "^" str))
	 ;; Completion searches the database, but we only use "fast
	 ;; lookup" search clauses which use the hashtable, instead of
	 ;; cycling over all records one by one.  Still pretty slow,
	 ;; though.  Also unfortunate is that EBDB has a broader
	 ;; concept of "matching string" than the completion
	 ;; framework, which will later filter out strings that we
	 ;; consider matching (e.g. according to character folding, or
	 ;; romanization of non-English scripts).  Perhaps we could
	 ;; make our own completion style to take care of that.
	 (strings
	  (mapcar #'ebdb-string
		  (if (string-empty-p str)
		      (ebdb-records)
		    (ebdb-search
		     (ebdb-records)
		     (append
		      (list `(ebdb-field-name ,newstring)
			    `(ebdb-field-mail ,newstring)
			    `(ebdb-field-tags ,newstring))
		      (mapcar (lambda (f)
				(list f newstring))
			      ebdb-hash-extra-predicates)))))))
    (if (eq action 'metadata)
	'(metadata . ((category . ebdb-contact)))
      (complete-with-action action strings str pred))))

;;;###autoload
(defun ebdb-completion-predicate (key records)
  "Check if KEY is a value key to return RECORDS.
For use as the third argument to `completing-read'.
Obey `ebdb-completion-list'."
  (cond ((null ebdb-completion-list)
         nil)
        ((eq t ebdb-completion-list)
         t)
        (t
         (catch 'ebdb-hash-ok
	   (dolist (record records)
	     (ebdb-hash-p key record ebdb-completion-list))
	   nil))))


;;; Dialing and texting.

(defun ebdb-signal-get-number (record &optional no-prompt)
  "Extract a usable Signal number from RECORD.
If any of RECORD's phone numbers have \"signal\" label, use that.
Alternately, if there is only one phone labeled \"cell\" or
\"mobile\", use that.  Alternately, if NO-PROMPT is nil, prompt
for a number.

The number is returned as a properly-formatted string, with
leading \"+\"."

  (let* ((all-phones (slot-value record 'phone))
	 (phone
	  (car-safe
	   (or (object-assoc "signal" 'label all-phones)
	       (seq-filter
		(lambda (p)
		  (member (slot-value p 'label)
			  '("cell" "mobile")))
		all-phones))))
	 (number
	  (and phone
	       (with-slots (country-code area-code number) phone
		 (concat (format "+%d" country-code)
			 (and area-code
			      (number-to-string area-code))
			 number)))))
    (or number
	(and (null no-prompt)
	     (ebdb-read-string "Use phone number")))))

(cl-defmethod ebdb-field-phone-signal-text ((_record ebdb-record-entity)
					    (phone-field ebdb-field-phone))
  "Use the Signal protocol to compose a text message.
PHONE-FIELD will be the number used as the recipient.

This is a field action version of `ebdb-signal-text', see that
command's docstring for more details."
  (let ((sender
	 (or (and ebdb-record-self
		  (ebdb-signal-get-number
		   (ebdb-record-self)
		   t))
	     (ebdb-read-string
	      "Number to send from (or set `ebdb-record-self'): ")))
	(recipients
	 (list (with-slots (country-code area-code number) phone-field
		 (concat (format "+%d" country-code)
			 (and area-code
			      (number-to-string area-code))
			 number))))
	(message (ebdb-read-string "Message contents"))
	(attachments
	 (ebdb-loop-with-exit
	  (expand-file-name
	   (read-file-name "Attach file (C-g when done): "
			   nil nil nil)))))
    (if ebdb-signal-program
	(ebdb--signal-text sender message recipients attachments)
      (message "Please set `ebdb-signal-program'"))))

(defun ebdb--signal-text (sender message recipients &optional attachments)
  "Internal function for actually sending the SMS.
Arguments SENDER, MESSAGE, RECIPIENTS and optional ATTACHMENTS
are passed directly to the Signal executable."
  (let ((command
	 (concat ebdb-signal-program
		 (format " -u %s -m %s" sender message)
		 (when attachments
		   (concat " -a "
			   (mapconcat #'identity attachments " ")
			   " "))
		 (mapconcat #'identity recipients " "))))
    (shell-command command nil " *EBDB Signal Errors*")))



;;; Helper functions

(defun ebdb-string-trim (string &optional null)
  "Remove leading and trailing whitespace and all properties from STRING.
If STRING is nil return an empty string unless NULL is non-nil."
  (if (null string)
      (unless null "")
    (setq string (substring-no-properties (string-trim string)))
    (unless (and null (string-empty-p string))
      string)))

(defsubst ebdb-string= (str1 str2)
  "Return t if strings STR1 and STR2 are equal, ignoring case."
  (and (stringp str1) (stringp str2)
       (eq t (compare-strings str1 0 nil str2 0 nil t))))

(defun ebdb-split (separator string)
  "Split STRING into list of substrings bounded by matches for SEPARATORS.
SEPARATOR may be a regexp.  SEPARATOR may also be a symbol
\(a field name).  Then look up the value in `ebdb-separator-alist'
or use `ebdb-default-separator'.
Whitespace around SEPARATOR is ignored unless SEPARATOR matches
the string \" \\t\\n\".
Almost the inverse function of `ebdb-concat'."
  (if (symbolp separator)
      (setq separator (car (or (cdr (assq separator ebdb-separator-alist))
                               ebdb-default-separator))))
  (unless (string-match separator " \t\n")
    (setq separator (concat "[ \t\n]*" separator "[ \t\n]*")))
  ;; `split-string' applied to an empty STRING gives nil.
  (split-string (ebdb-string-trim string) separator t))

(defun ebdb-concat (separator &rest strings)
  "Concatenate STRINGS to a string sticking in SEPARATOR.
STRINGS may be strings or lists of strings.  Empty strings are ignored.
SEPARATOR may be a string.
SEPARATOR may also be a symbol (a field name).  Then look up the value
of SEPARATOR in `ebdb-separator-alist' or use `ebdb-default-separator'.
The inverse function of `ebdb-split'."
  (if (symbolp separator)
      (setq separator (nth 1 (or (cdr (assq separator ebdb-separator-alist))
                                 ebdb-default-separator))))
  (mapconcat #'identity
             (delete "" (apply #'append (mapcar (lambda (x)
                                                  (if (stringp x) (list x) x))
                                                strings)))
	     separator))

(defun ebdb-list-strings (list)
  "Remove all elements from LIST which are not non-empty strings."
  (let (new-list)
    (dolist (elt list)
      (if (and (stringp elt) (not (string= "" elt)))
          (push elt new-list)))
    (nreverse new-list)))

(defun ebdb-read-string (prompt &optional init collection require-match)
  "Read a string, trimming whitespace and text properties.
PROMPT is a string to prompt with, and should not include a final
\": \".  INIT appears as initial input which is useful for
editing existing records.  COLLECTION and REQUIRE-MATCH have the
same meaning as in `completing-read'."
  (setq prompt
	(concat
	 (pcase ebdb-read-string-override
	   (`,(and str (pred stringp)) str)
	   (`(,str . append)
	    (concat prompt " " str))
	   (`(,str . prepend)
	    (concat str " " (downcase prompt)))
	   (_ prompt))
	 ": "))
  (let ((string
	 (ebdb-string-trim
	  (if collection
	      ;; Hack: In `minibuffer-local-completion-map' remove
	      ;; the binding of SPC to `minibuffer-complete-word'
	      ;; and of ? to `minibuffer-completion-help'.
	      (let ((completion-ignore-case ebdb-completion-ignore-case))
		(minibuffer-with-setup-hook
		    (lambda ()
		      (use-local-map
		       (let ((map (make-sparse-keymap)))
			 (set-keymap-parent map (current-local-map))
			 (define-key map " " nil)
			 (define-key map "?" nil)
			 map)))
		  (completing-read
		   prompt collection nil require-match init)))
	    (read-string prompt init)))))
    (if (string-blank-p string)
	(signal 'ebdb-empty (list prompt))
      string)))

;; FIXME: Get rid of this add-job and eval-spec stuff.
(defsubst ebdb-add-job (spec record string)
  "Internal function: Evaluate SPEC for RECORD and STRING.
If SPEC is a function call it with args RECORD and STRING.  Return value.
If SPEC is a regexp, return \\='query unless SPEC matches STRING.
Otherwise return SPEC.
Used with variable `ebdb-add-name' and friends."
  (cond ((functionp spec)
         (funcall spec record string))
        ((stringp spec)
         (unless (string-match spec string) 'query)) ; be least aggressive
        (spec)))

(defsubst ebdb-eval-spec (spec prompt)
  "Internal function: Evaluate SPEC using PROMPT.
Return t if either SPEC equals t, or SPEC equals \\='query and `ebdb-silent'
is non-nil or `y-or-no-p' returns t using PROMPT.
Used with return values of `ebdb-add-job'."
  (or (eq spec t)
      (and (eq spec 'query)
           (or ebdb-silent (y-or-n-p prompt)))))

(defun ebdb-clean-address-components (components)
  "Clean mail address COMPONENTS.
COMPONENTS is a list (FULL-NAME CANONICAL-ADDRESS) as returned
by `mail-extract-address-components'.
Pass FULL-NAME through `ebdb-message-clean-name-function'
and CANONICAL-ADDRESS through `ebdb-canonicalize-mail-function'."
  (list (if (car components)
            (if ebdb-message-clean-name-function
                (funcall ebdb-message-clean-name-function (car components))
              (car components)))
        (if (cadr components)
            (if ebdb-canonicalize-mail-function
                (funcall ebdb-canonicalize-mail-function (cadr components))
              ;; Minimalistic clean-up
              (ebdb-string-trim (cadr components))))))

(defun ebdb-extract-address-components (address &optional all)
  "Given an RFC-822 address ADDRESS, extract full name and canonical address.
This function behaves like `mail-extract-address-components', but it passes
its return value through `ebdb-clean-address-components'.
See also `ebdb-decompose-ebdb-address'.

If optional argument ALL is non-nil, pass it to
`mail-extract-address-components' to extract multiple addresses."
  (if all
      (mapcar #'ebdb-clean-address-components
              (mail-extract-address-components address t))
    (ebdb-clean-address-components (mail-extract-address-components address))))

;; Inspired by `gnus-extract-address-components' from gnus-utils.
(defun ebdb-decompose-ebdb-address (mail)
  "Given an RFC-822 address MAIL, extract full name and canonical address.
In general, this function behaves like the more sophisticated function
`mail-extract-address-components'.  Yet for an address `<Joe_Smith@foo.com>'
lacking a real name the latter function returns the name \"Joe Smith\".
This is useful when analyzing the headers of email messages we receive
from the outside world.  Yet when analyzing the mail addresses stored
in EBDB, this pollutes the mail-aka space.  So we define here
an intentionally much simpler function for decomposing the names
and canonical addresses in the mail field of EBDB records."
  (let (name address)
    ;; First get rid of any "mailto:" in the string.
    (setq mail (replace-regexp-in-string "mailto:" "" mail))
    ;; Then find the address - the thing with the @ in it.
    (cond (;; Check `<foo@bar>' first in order to handle the quite common
	   ;; form `"abc@xyz" <foo@bar>' (i.e. `@' as part of a comment)
	   ;; correctly.
	   (string-match "<\\([^@ \t<>]+[!@][^@ \t<>]+\\)>" mail)
	   (setq address (match-string 1 mail)))
	  ((string-match "\\b[^@\" \t<>]+[!@][^@\" \t<>]+\\b" mail)
	   (setq address (match-string 0 mail))))
    ;; Then check whether the `name <address>' format is used.
    (and address
	 ;; Linear white space is not required.
	 (string-match (concat "[ \t]*<?" (regexp-quote address) ">?\\'") mail)
	 (setq name (substring mail 0 (match-beginning 0)))
         ;; Strip any quotes mail the name.
         (string-match "^\".*\"$" name)
         (setq name (substring name 1 (1- (match-end 0)))))
    ;; If not, then check whether the `address (name)' format is used.
    (or name
	(and (string-match "(\\([^)]+\\))" mail)
	     (setq name (match-string 1 mail))))
    (list (if (null address)
	      mail
	    (unless
		(or (equal name "")
		    (equal name address))
	      name))
	  address)))

;;; Massage of mail addresses

(defun ebdb-canonicalize-mail-1 (address)
  "Canonicalize ADDRESS.
This is an example of `ebdb-canonicalize-mail-function'.  It's
probably too specific to be useful for the general user, but can
be taken as a source of inspiration for what's possible."
  (setq address (ebdb-string-trim address))
  (cond
   ;; Rewrite mail-drop hosts.
   ;; RW: The following is now also handled by `ebdb-ignore-redundant-mails'
   ((string-match
     (concat "\\`\\([^@%!]+@\\).*\\.\\(" ebdb-canonical-hosts "\\)\\'")
     address)
    (concat (match-string 1 address) (match-string 2 address)))
   ;;
   ;; Here at Lucid, our workstation names sometimes get into our mail
   ;; addresses in the form "jwz%thalidomide@lucid.com" (instead of simply
   ;; "jwz@lucid.com").  This removes the workstation name.
   ((string-match "\\`\\([^@%!]+\\)%[^@%!.]+@\\(lucid\\.com\\)\\'" address)
    (concat (match-string 1 address) "@" (match-string 2 address)))
   ;;
   ;; Another way that our local mailer is misconfigured: sometimes addresses
   ;; which should look like "user@some.outside.host" end up looking like
   ;; "user%some.outside.host" or even "user%some.outside.host@lucid.com"
   ;; instead.  This rule rewrites it into the original form.
   ((string-match "\\`\\([^@%]+\\)%\\([^@%!]+\\)\\(@lucid\\.com\\)?\\'" address)
    (concat (match-string 1 address) "@" (match-string 2 address)))
   ;;
   ;; Sometimes I see addresses like "foobar.com!user@foobar.com".
   ;; That's totally redundant, so this rewrites it as "user@foobar.com".
   ((string-match "\\`\\([^@%!]+\\)!\\([^@%!]+[@%]\\1\\)\\'" address)
    (match-string 2 address))
   ;;
   ;; Sometimes I see addresses like "foobar.com!user".  Turn it around.
   ((string-match "\\`\\([^@%!.]+\\.[^@%!]+\\)!\\([^@%]+\\)\\'" address)
    (concat (match-string 2 address) "@" (match-string 1 address)))
   ;;
   ;; The mailer at hplb.hpl.hp.com tends to puke all over addresses which
   ;; pass through mailing lists which are maintained there: it turns normal
   ;; addresses like "user@foo.com" into "user%foo.com@hplb.hpl.hp.com".
   ;; This reverses it.  (I actually could have combined this rule with
   ;; the similar lucid.com rule above, but then the regexp would have been
   ;; more than 80 characters long...)
   ((string-match "\\`\\([^@!]+\\)%\\([^@%!]+\\)@hplb\\.hpl\\.hp\\.com\\'"
          address)
    (concat (match-string 1 address) "@" (match-string 2 address)))
   ;;
   ;; Another local mail-configuration botch: sometimes mail shows up
   ;; with addresses like "user@workstation", where "workstation" is a
   ;; local machine name.  That should really be "user" or "user@netscape.com".
   ;; (I'm told this one is due to a bug in SunOS 4.1.1 sendmail.)
   ((string-match "\\`\\([^@%!]+\\)[@%][^@%!.]+\\'" address)
    (match-string 1 address))
   ;;
   ;; Sometimes I see addresses like "foo%somewhere%uunet.uu.net@somewhere.else".
   ;; This is silly, because I know that I can send mail to uunet directly.
   ((string-match ".%uunet\\.uu\\.net@[^@%!]+\\'" address)
    (concat (substring address 0 (+ (match-beginning 0) 1)) "@UUNET.UU.NET"))
   ;;
   ;; Otherwise, leave it as it is.
   (t address)))

(defun ebdb-message-clean-name-default (name)
  "Default function for `ebdb-message-clean-name-function'.
This strips garbage from the user full NAME string."
  ;; Remove leading non-alphanumeric chars
  (if (string-match "\\`[^[:alnum:]]+" name)
      (setq name (substring name (match-end 0))))

  (if (string-match "^\\([^@]+\\)@" name)
      ;; The name is really a mail address and we use the part preceding "@".
      ;; Everything following "@" is ignored.
      (setq name (match-string 1 name)))

  ;; Replace "firstname.surname" by "firstname surname".
  ;; Do not replace ". " with " " because that could be an initial.
  (setq name (replace-regexp-in-string "\\.\\([^ ]\\)" " \\1" name))

  ;; Replace tabs, spaces, and underscores with a single space.
  (setq name (replace-regexp-in-string "[ \t\n_]+" " " name))

  ;; Remove trailing comments separated by "(" or " [-#]"
  ;; This does not work all the time because some of our friends in
  ;; northern europe have brackets in their names...
  (if (string-match "[^ \t]\\([ \t]*\\((\\| [-#]\\)\\)" name)
      (setq name (substring name 0 (match-beginning 1))))

  ;; Remove phone extensions (like "x1234" and "ext. 1234")
  (let ((case-fold-search t))
    (setq name (replace-regexp-in-string
                "\\W+\\(x\\|ext\\.?\\)\\W*[-0-9]+" "" name)))

  ;; Remove trailing non-alphanumeric chars
  (if (string-match "[^[:alnum:]]+\\'" name)
      (setq name (substring name 0 (match-beginning 0))))

  ;; Remove text properties
  (substring-no-properties name))

;; `ebdb-hashtable' associates with each KEY a list of matching records.
;; KEY includes fl-name, lf-name, organizations, AKAs and email addresses.
;; When loading the database the hash table is initialized by calling
;; `ebdb-hash-record' for each record.  This function is also called
;; when new records are added to the database.

(defun ebdb-puthash (key record)
  "Associate RECORD with KEY in `ebdb-hashtable'.
KEY must be a string or nil.  Empty strings and nil are ignored."
  (if (and key (not (string-empty-p key))) ; do not hash empty strings
      (let* ((key (downcase key))
	     (records (gethash key ebdb-hashtable)))
	(puthash key (if records (cl-pushnew record records)
                       (list record))
		 ebdb-hashtable))))

(defun ebdb-gethash (key &optional predicate)
  "Return records associated with KEY in `ebdb-hashtable'.
KEY must be a string or nil.  Empty strings and nil are ignored.
PREDICATE may take the same values as `ebdb-completion-list'.  If
predicate is the single symbol uuid, this function returns a
single record, otherwise returns a list."
  (when (and key (not (string-empty-p key)))
    (let* ((key (downcase key))
           (all-records (gethash key ebdb-hashtable))
           records)
      (if (or (not predicate) (eq t predicate))
          all-records
        (if (eql predicate 'uuid)
	    ;; We could conceivably do a bit of sanity checking here.
	    ;; All-records should only be a list of one.
	    (car all-records)
	  (dolist (record all-records records)
	    (if (catch 'ebdb-hash-ok
		  (ebdb-hash-p key record predicate))
		(push record records))))))))

(defun ebdb-hash-p (key record predicate)
  "Throw `ebdb-hash-ok' non-nil if KEY matches RECORD according to PREDICATE.
PREDICATE may take the same values as the elements of `ebdb-completion-list'."
  (if (and (seq-intersection '(name ebdb-field-name) predicate)
           (ebdb-string= key (or (ebdb-record-name-string record) "")))
      (throw 'ebdb-hash-ok 'name))
  (if (seq-intersection '(organization ebdb-field-role) predicate)
      (mapc (lambda (organization) (if (ebdb-string= key organization)
                                       (throw 'ebdb-hash-ok 'organization)))
            (ebdb-record-organization record)))
  (if (memq 'alt-names predicate)
      (mapc (lambda (name) (if (ebdb-string= key (ebdb-string name))
                              (throw 'ebdb-hash-ok 'alt-names)))
            (ebdb-record-alt-names record)))
  (if (and (seq-intersection '(primary mail-primary) predicate)
           (ebdb-string= key (car (ebdb-record-mail-canon record))))
      (throw 'ebdb-hash-ok 'primary))
  (if (seq-intersection '(mail ebdb-field-mail) predicate)
      (mapc (lambda (mail) (if (ebdb-string= key mail)
                               (throw 'ebdb-hash-ok 'mail)))
            (ebdb-record-mail-canon record)))
  (dolist (elt ebdb-hash-extra-predicates)
    (when (and (memq (car elt) predicate)
	       (funcall (cdr elt) key record))
      (throw 'ebdb-hash-ok (car elt))))
  nil)

(defun ebdb-remhash (key record)
  "Remove RECORD from list of records associated with KEY.
KEY must be a string or nil.  Empty strings and nil are ignored."
  (if (and key (not (string-empty-p key)))
      (let* ((key (downcase key))
	     (records (gethash key ebdb-hashtable)))
        (when records
          (setq records (delq record records))
          (if records
              (puthash key records ebdb-hashtable)
            (remhash key ebdb-hashtable))))))

(defun ebdb-hash-update (record old new)
  "Update hash for RECORD.
Remove OLD, insert NEW.  Both OLD and NEW are lists of values."
  (dolist (elt old)
    (ebdb-remhash elt record))
  (dolist (elt new)
    (ebdb-puthash elt record)))

(defun ebdb-check-name (first last &optional record)
  "Check whether the name FIRST LAST is a valid name.
This throws an error if the name is already used by another record
and `ebdb-allow-duplicates' is nil.  If RECORD is non-nil, FIRST and LAST
may correspond to RECORD without raising an error."
  ;; Are there more useful checks for names beyond checking for duplicates?
  (unless ebdb-allow-duplicates
    (let* ((name (ebdb-concat 'name-first-last first last))
           (records (ebdb-gethash name '(name alt-names))))
      (if (or (and (not record) records)
              (remq record records))
          (error "%s is already in EBDB" name)))))

(cl-defmethod ebdb-record-set-sortkey ((record ebdb-record-person))
  "Record cache function: Set and return RECORD's sortkey."
  (setf
   (ebdb-record-sortkey record)
   (downcase (ebdb-name-lf (slot-value record 'name)))))

(cl-defmethod ebdb-record-set-sortkey ((record ebdb-record-organization))
  (setf
   (ebdb-record-sortkey record)
   (downcase (ebdb-string (slot-value record 'name)))))

(cl-defgeneric ebdb-record-field (record field)
  "For RECORD return the value of FIELD.
FIELD may be a slot-name symbol, in which case the value of that
slot, if any, is returned.  It can be a string, in which case it
is interpreted as a label for one of RECORD's user fields.  It
can also be the symbol name of a user-field class, in which case
all the record's instances of that class are returned.  It can
also be one of the special symbols below.

 firstname     Return the first name of RECORD
 lastname      Return the last name of RECORD
 name-lf       Return the full name of RECORD (last name first)
 aka-all       Return the list of AKAs plus mail-akas.
 mail-aka      Return the list of name parts in mail addresses
 mail-primary  Return the record's primary mail address
 mail-canon    Return the list of canonical mail addresses.")

(cl-defmethod ebdb-record-field ((record ebdb-record)
				 (field symbol))
  (pcase field
    ('firstname (ebdb-record-firstname record))
    ('lastname (ebdb-record-lastname record))
    ('mail-canon (ebdb-record-mail-canon record)) ; derived (cached) field
    ;; Mail is special-cased, because mail addresses can come from
    ;; more than one slot.
    ('mail (ebdb-record-mail record nil nil t))
    ('mail-primary (ebdb-record-one-mail record nil t))
    ('mail-aka (ebdb-record-mail-aka record)) ; derived (cached) field
    ('aka-all  (append (ebdb-record-aka record) ; derived field
		       (ebdb-record-mail-aka record)))
    ;; Otherwise assume it is a valid slot name.
    (_
     (when (and (slot-exists-p record field)
		(slot-boundp record field))
       (slot-value record field)))))

(cl-defmethod ebdb-record-field ((record ebdb-record)
				 (f-class (subclass ebdb-field-user)))
  "Return all RECORD's fields that are of class F-CLASS."
  (seq-filter
   (lambda (f)
     (object-of-class-p f f-class))
   (ebdb-record-user-fields record)))

(cl-defmethod ebdb-record-field ((record ebdb-record)
				 (label string))
  "Return all RECORD's fields that have label LABEL."
  (ebdb-record-user-field record label))

;;; Parsing other things

(defun ebdb-divide-name (string)
  "Divide STRING into its component parts.
Return name as a list of (SURNAME GIVEN-NAMES SUFFIX PREFIX).
SURNAME is always a string (possibly empty).  GIVEN-NAMES, if
present, is a list of first names.  GIVEN-NAMES and SUFFIX may be
nil.

During parsing `case-fold-search' is non-nil, with the exception
that a string of all-upper-case letters will be assumed (a la UN
usage) to represent the surname."
  (let ((case-fold-search t)
	given suffix prefix)
    ;; Separate a suffix.
    (when (string-match ebdb-lastname-suffix-re string)
      (setq suffix (match-string 1 string)
            string (substring string 0 (match-beginning 0))))
    (if (let ((case-fold-search nil))
	  ;; If there's an all-upper-case word, it's the last name.
	  (string-match
	   "[ \t\n]*\\([[:upper:]]+[[:upper:]-']+\\)\\>[ \t\n]*"
	   string))
	(setq given (concat (substring string 0 (match-beginning 1))
			    " "
			    (substring string (match-end 1)))
	      string (capitalize (match-string 1 string)))
      (cond ((string-match
	      (concat "\\`" ebdb-lastname-re ",[ \t\n]*\\(.+\\)\\'")
	      string)
             ;; If STRING contains a comma, this probably means that STRING
             ;; is of the form "Last, First".
             (setq given (match-string 2 string)
                   string (match-string 1 string)))
            ((string-match (concat ebdb-lastname-re "[ ,]*\\'") string)
             (setq given (and (not (zerop (match-beginning 0)))
                              (substring string 0 (match-beginning 0)))
                   string (match-string 1 string)))))
    (setq given (when given (split-string given nil t)))
    (cond ((string-match (concat "\\`" (regexp-opt ebdb-lastname-prefixes) " ") string)
	   (setq prefix (substring string 0 (match-end 0))
		 string (substring string (match-end 0))))
	  ((and (>= (length given) 2)
		(member-ignore-case (car (last given)) ebdb-lastname-prefixes))
	   (setq prefix (car (last given))
		 given (butlast given))))
    (list (ebdb-string-trim string)
	  given suffix prefix)))

(defsubst ebdb-record-lessp (record1 record2)
  (string< (ebdb-record-sortkey record1)
           (ebdb-record-sortkey record2)))


;;; Reading and Writing the EBDB

;; Loading and initialization is slow.  Mostly loading.  In my own
;; case, setting `eieio-skip-typecheck' to t dropped overall load
;; times from 2.5 seconds to 2 seconds.  Otherwise, if we want to find
;; further speedups, we could try overriding `object-write' for ebdb
;; classes and see if it's possible to write an object that can be
;; read faster.

;;;###autoload
(defun ebdb-load ()
  "Load all databases listed in `ebdb-sources'.
All the important work is done by the `ebdb-db-load' method."
  (let ((sources (if (listp ebdb-sources)
		     ebdb-sources
		   (list ebdb-sources)))
	(eieio-skip-typecheck ebdb-try-speedups)
	db-file-regexp)
    ;; Check if we're re-loading.
    (when (and ebdb-db-list
	       (object-assoc t 'dirty ebdb-db-list))
      ;; Later we'll give users the option to discard unsaved data.
      (error "Databases have unsaved data, save first"))
    (message "Loading EBDB sources...")
    (ebdb-clear-vars)
    (run-hooks 'ebdb-before-load-hook)
    (dolist (s sources)
      (cond ((stringp s)
	     (if (file-exists-p s)
		 ;; Handle auto-saved databases.
		 (let ((auto-save-file (ebdb-db-make-auto-save-file-name s))
		       (orig-filename s))
		   (if (and (file-exists-p auto-save-file)
			    (yes-or-no-p (format "Recover auto-save file for %s? " s)))
		       (progn (setq s (eieio-persistent-read auto-save-file 'ebdb-db t))
			      (setf (slot-value s 'file) orig-filename)
			      (setf (slot-value s 'dirty) t))
		     (setq s (eieio-persistent-read s 'ebdb-db t))))
	       ;; Handle new/nonexistent databases.
	       (when (yes-or-no-p (format "%s does not exist, create? " s))
		 (setq s (make-instance 'ebdb-db-file :file s :dirty t))
		 ;; Try to get it on disk first.
		 (ebdb-db-save s))))
	    ((null (and (eieio-object-p s)
			(object-of-class-p s 'ebdb-db)))
	     (error "Source %s must be a filename or instance of `ebdb-db'" s)))
      ;; Now load it.
      (if (null (slot-value s 'disabled))
	  (ebdb-db-load s)
	(message "%s is currently disabled." (ebdb-string s))
	;; Remove this database's records from
	;; `ebdb-record-tracker'.
	(mapc #'delete-instance (slot-value s 'records))
	(sit-for 2))
      (cl-pushnew s ebdb-db-list))

    (message "Initializing EBDB records...")
    (if (fboundp 'make-thread)
	(let ((thread (make-thread #'ebdb-initialize-threadwise)))
	  (thread-join thread))
      (ebdb-initialize))
    (message "Initializing EBDB records... done")
    ;; Users will expect the same ordering as `ebdb-sources'
    (setq ebdb-db-list (nreverse ebdb-db-list))
    (setq db-file-regexp
	  (regexp-opt (mapcar (lambda (db)
				(expand-file-name
				 (slot-value db 'file)))
			      ebdb-db-list)))
    ;; If users look at the database files, they should be read as
    ;; utf-8-emacs.
    (push
     (cons db-file-regexp 'utf-8-emacs)
     auto-coding-alist)
    ;; There's now a `lisp-data-mode'.
    (when (fboundp 'lisp-data-mode)
      (push
       (cons db-file-regexp 'lisp-data-mode)
       auto-mode-alist))
    (run-hooks 'ebdb-after-load-hook)
    (add-hook 'kill-emacs-hook #'ebdb-save-on-emacs-exit)
    (length ebdb-record-tracker)))

;; If we wanted to make it seem like EBDB was loading faster, we could
;; defer calls to `ebdb-initialize' until the first time the database
;; is searched.
(defun ebdb-initialize (&optional records)
  "After all databases are loaded, initialize the records.
This results in the creation of all the secondary data
structures: label lists, `ebdb-org-hashtable', record caches,
etc.  If optional argument RECORDS is given, only initialize
those records."
  (mapc #'ebdb-init-record (or records ebdb-record-tracker)))

(defun ebdb-initialize-threadwise (&optional records)
  "Exactly the same as `ebdb-initialize', but yields thread.
If Emacs has threading, then `ebdb-load' will call this function
in its own thread, and the thread will be yielded after every ten
record initializations.  Note that by itself this will have no
impact whatsoever on EBDB load times.  It's up to the user to
interleave it with other thread-yielding operations to create an
actual speedup.  If optional argument RECORDS is given, only
initialize those records."
  (let ((c 0))
    (mapc
     (lambda (r)
       (ebdb-init-record r)
       (when (= (mod (cl-incf c) 10) 0)
	 (thread-yield)))
     (or records ebdb-record-tracker))))



;;; Citing EBDB records

;; "Citation" means inserting some sort of string representing the
;; record(s) into the current buffer.

(defun ebdb-cite-records (&optional records arg kill)
  "Insert a string representation of RECORDS at point.
If ARG (the prefix arg) is given, strings are in \"list style\",
ie separated by newlines.  Otherwise they are \"inline style\".
If KILL is non-nil, put the string on the kill ring instead of
inserting it."
  (interactive (list (ebdb-prompt-for-record)
		     current-prefix-arg))
  (let ((recs (if (listp records) records (list records)))
	(style (if arg 'list 'inline))
	usable str m)
    (dolist (r recs)
      (when (setq m (ebdb-record-mail r))
	(push (cons r (or (object-assoc 'primary 'priority m)
			  (car m)))
	      usable)))
    (setq str (ebdb-records-cite style usable))
    (if kill
	(progn
	  (kill-new str)
	  (message "Citation added to kill ring"))
      (insert str))))

(cl-defgeneric ebdb-records-cite (style records)
  "Return mode-appropriate mail strings for RECORDS.
STYLE is a symbol, one of \\='inline or \\='list.  This is interpreted
differently by different major modes; the default looks like
\"Firstname Lastname <email@address.com>\".

This is a generic function that dispatches on the value of
`major-mode'.  It only inserts names and mail addresses.")

(cl-defmethod ebdb-records-cite ((_style (eql list))
				 (records list))
  (mapconcat (lambda (pair)
	       (format "%s <%s>"
		       ;; TODO: Wrap non-ASCII record names in double
		       ;; quotes?
		       (ebdb-string (car pair))
		       (ebdb-string (cdr pair))))
	     records "\n"))

(cl-defmethod ebdb-records-cite ((_style (eql inline))
				 (records list))
  (mapconcat (lambda (pair)
	       (format "%s <%s>"
		       (ebdb-string (car pair))
		       (ebdb-string (cdr pair))))
	     records ", "))

(cl-defmethod ebdb-records-cite ((_style (eql list))
				 (records list)
				 &context (major-mode org-mode))
  (mapconcat (lambda (pair)
	       (format "- [[mailto:%s][%s]]"
		       (slot-value (cdr pair) 'mail)
		       (ebdb-string (car pair))))
	     records "\n"))

(cl-defmethod ebdb-records-cite ((_style (eql inline))
				 (records list)
				 &context (major-mode org-mode))
  (mapconcat (lambda (pair)
	       (format "[[mailto:%s][%s]]"
		       (slot-value (cdr pair) 'mail)
		       (ebdb-string (car pair))))
	     records ", "))

(cl-defmethod ebdb-records-cite ((_style (eql list))
				 (records list)
				 &context (major-mode html-mode))
  (mapconcat (lambda (pair)
	       (format "<li><a href=\"mailto:%s>%s</a></li>"
		       (slot-value (cdr pair) 'mail)
		       (ebdb-string (car pair))))
	     records "\n"))

(cl-defmethod ebdb-records-cite ((_style (eql inline))
				 (records list)
				 &context (major-mode html-mode))
  (mapconcat (lambda (pair)
	       (format "<a href=\"mailto:%s>%s</a>"
		       (slot-value (cdr pair) 'mail)
		       (ebdb-string (car pair))))
	     records ", "))



;;; Saving EBDB.

(defun ebdb-save (&optional interactive)
  "Save the EBDB if it is modified.
If INTERACTIVE is non-nil, report progess.  If it is 4,
additionally prompt to save each database individually."
  ;; TODO: Reimplement ebdb-remote-file, or otherwise do something
  ;; about that.
  (when interactive
    (message "Saving the EBDB..."))
  (run-hooks 'ebdb-before-save-hook)
  (dolist (s ebdb-db-list)
    (ebdb-db-save s (eq interactive 4)))
  (run-hooks 'ebdb-after-save-hook)
  (when interactive
    (message "Saving the EBDB... done")))

(defun ebdb-save-on-emacs-exit ()
  "Possibly save EBDB when exiting Emacs.
See option `ebdb-save-on-exit'."
  (when ebdb-save-on-exit
    ;; `kill-emacs-hook' functions should not interact with the user.
    (ebdb-save)))


;;; Searching EBDB

(defvar ebdb-search-invert nil
  "Bind to t to invert the result of `ebdb-search'.")

(defun ebdb-parse-search-string (str)
  "Parse STR as a search on multiple fields.
STR should contain some number of <key>:<value> pairs, where key
is the name of a field class, or a field class shortcut such as
\"name\" or \"mail\", and the value is an arbitrary string value
to search on.

Values containing spaces should be enclosed in double quotes.

Returns a list of (field value) pairs suitable for searching."
  (let (parsed)
    (with-temp-buffer
      (insert str)
      (goto-char (point-min))
      (skip-syntax-forward " ")
      (while (re-search-forward
	      "\\([[:ascii:]-]+\\):\\(?:\"\\(?2:[^\"]+\\)\"\\|\\(?2:[^[:space:]]+\\)\\)"
	      (point-max) t)
	(let* ((key-string (match-string 1))
	       (sym (or (and (string-match-p "ebdb-field-" key-string)
			     (intern-soft key-string))
			(intern-soft (format "ebdb-field-%s" key-string)))))
	  (if (and (class-p sym)
		   (child-of-class-p sym 'ebdb-field))
	      (push (list sym
			  (match-string 2))
		    parsed)
	    (signal 'ebdb-unparseable
		    (list "Invalid search key" key-string))))))
    parsed))

;; Char folding: a simplified version of what happens in char-fold.el.

(defconst ebdb-char-fold-table
  (eval-when-compile
    (let ((tbl (make-char-table 'char-fold-table))
	  (uni (unicode-property-table-internal 'decomposition))
	  ;; Lowercase and uppercase alphabet.
	  (target-seq (append (number-sequence 65 90)
			      (number-sequence 97 122))))

      ;; I don't understand what's happening here, but it's necessary.
      (let ((func (char-table-extra-slot uni 1)))
	(map-char-table (lambda (char v)
                          (when (consp char)
                            (funcall func (car char) v uni)))
			uni))
      ;; Create lists of equivalent chars, keyed to the most basic
      ;; ascii letter.
      (map-char-table
       (lambda (char decomp)
	 (when (consp decomp)
	   (when (symbolp (car decomp))
	     (setq decomp (cdr decomp)))
	   (when (memq (car decomp) target-seq)
	     (aset tbl (car decomp)
		   (cons char
			 (aref tbl (car decomp)))))))
       uni)
      ;; Then turn the lists into regexps.
      (map-char-table
       (lambda (char dec-list)
	 (let ((re (regexp-opt (cons (char-to-string char)
				     (mapcar #'string dec-list)))))
           (aset tbl char re)))
       tbl)
      tbl))
  "Char-table holding regexps used in char fold searches.
Keys are characters in the upper- and lower-case ascii ranges.
Values are a regexp matching all characters that decompose to the
key character.")

(defun ebdb-char-fold-to-regexp (string)
  "A highly simplified version of `char-fold-to-regexp'.
Only converts characters in STRING that decompose to the range
[a-zA-Z]."
  (let ((out nil)
	(end (length string))
	char
	(i 0))
    (while (< i end)
      (setq char (aref string i))
      (push
       (or (aref ebdb-char-fold-table char)
	   (string char))
       out)
      (cl-incf i))
    (setq out (apply #'concat (nreverse out)))
    (if (> (length out) 5000)
        (regexp-quote string)
      out)))

(defun ebdb-message-search (name mail)
  "Return list of EBDB records matching NAME and/or MAIL.
First try to find a record matching both NAME and MAIL.
If this fails try to find a record matching MAIL.
If this fails try to find a record matching NAME.
NAME may match FIRST_LAST, LAST_FIRST or AKA.

This function performs a fast search using `ebdb-hashtable'.
NAME and MAIL must be strings or nil.
See `ebdb-search' for searching records with regexps."
  (when (or name mail)
    (unless ebdb-db-list
      (ebdb-load))
    (let ((mrecords (if mail (ebdb-gethash mail '(mail))))
          (nrecords (if name (ebdb-gethash name '(name alt-names)))))
      ;; (1) records matching NAME and MAIL
      (or (and mrecords nrecords
               (let (records)
                 (dolist (record nrecords)
                   (mapc (lambda (mr) (if (and (eq record mr)
                                               (not (memq record records)))
                                          (push record records)))
                         mrecords))
                 records))
          ;; (2) records matching MAIL
          mrecords
          ;; (3) records matching NAME
          nrecords))))

(defun ebdb-search (records clauses &optional invert)
  "Search RECORDS for records matching CLAUSES.
Each element of CLAUSES is either a two-element list of (symbol
criteria), which will be used to make a call to
`ebdb-record-search', or it is a callable, which will be called
with a record as the argument.  All other values will be
interpreted as t, ie the record passes.

If the car of a clause is one of `ebdb-field-name',
`ebdb-field-mail', `ebdb-field-tags', or is present in the assoc
list `ebdb-hash-extra-predicates', this function will try to use
the `ebdb-hashtable' to do a fast lookup.  The criteria must be a
string, and must begin with a leading \"^\", ie, the search
string must be a prefix of the sought string.

With optional argument INVERT, invert the search results."
  ;; In the following "fast lookup" means we use the search criteria
  ;; to pull results from the `ebdb-hashtable'.  "Slow lookup" means
  ;; we loop over all the records and test each one.
  (let ((case-fold-search ebdb-case-fold-search)
	new-clauses completed-strings recs)
    ;; Fast lookups won't work with INVERT.
    (if invert
	(setq new-clauses clauses)
      ;; Try the fast lookups.
      (pcase-dolist (`(,key ,crit) clauses)
	(or
	 ;; Either we get some records out the fast lookup...
	 (and (stringp crit)
	      (string-prefix-p "^" crit)
	      (or (ebdb-foo-in-list-p
		   key (list 'ebdb-field-name
			     'ebdb-field-mail
			     'ebdb-field-tags))
		  (assoc key ebdb-hash-extra-predicates))
	      (setq completed-strings
		    (all-completions (downcase (substring crit 1))
				     ebdb-hashtable)
		    recs
		    (delq nil
			  (apply
			   #'append
			   (cons recs
				 (mapcar
				  (lambda (c)
				    (ebdb-gethash c (list key)))
				  completed-strings))))))
	 ;; ...or we leave the clause and do a slow lookup on it.
	 (push (list key crit) new-clauses))))
    ;; Handle transformations of search strings.
    (when ebdb-search-transform-functions
      (dolist (c new-clauses)
	(when (and (consp c)
		   (stringp (cadr c)))
	  (dolist (func ebdb-search-transform-functions)
	    (setf (cadr c) (funcall func (cadr c)))))))
    (when ebdb-char-fold-search
      (dolist (c new-clauses)
	(when (and (consp c)
		   (stringp (cadr c)))
	  (setf (cadr c) (ebdb-char-fold-to-regexp (cadr c))))))
    (when new-clauses
      (setq recs
	    (append
	     recs
	     (seq-filter
	      (lambda (r)
		(unless (member r recs)
		  (eql (null invert)
		       (catch 'found
			 (condition-case nil
			     (dolist (c new-clauses)
			       (pcase c
				 (`(,type ,criteria)
				  (and (ebdb-record-search r type criteria)
				       (throw 'found t)))
				 (`,(and func (pred functionp))
				  (and (funcall func r)
				       (throw 'found t)))
				 (_ t)))
			   (cl-no-applicable-method nil))))))
	      records))))
    (delete-dups recs)))

(cl-defgeneric ebdb-field-search (field criterion)
  "Return t if search CRITERION somehow matches the value of
  FIELD.")

(cl-defgeneric ebdb-record-search (record type criterion)
  "Return t if CRITERION matches RECORD, given TYPE.")

(cl-defmethod ebdb-field-search ((field ebdb-field) (regex string))
  (condition-case nil
      (or (string-empty-p regex)
	  (string-match-p regex (ebdb-string field)))
    (cl-no-applicable-method nil)))

(cl-defmethod ebdb-field-search ((field ebdb-field-labeled) (pair cons))
  (let ((label (car pair))
	(value (cdr pair)))
    (and (or (null label)
	     (string-empty-p label)
	     (string-match-p label (slot-value field 'label)))
	 (or (null value)
	     (ebdb-field-search field value)))))

(cl-defmethod ebdb-field-search ((field ebdb-field-labeled)
				 (regexp string))
  (or (string-match-p regexp (ebdb-string field))
      (and (stringp (slot-value field 'label))
	   (string-match-p regexp (slot-value field 'label)))
      (cl-call-next-method)))

(cl-defmethod ebdb-field-search ((_field ebdb-field-name-complex) _regex)
  "Short-circuit the plain field search for names.
The record itself performs more complex searches on cached name
values, by default the search is not handed to the name field itself."
  nil)

(cl-defmethod ebdb-record-search ((record ebdb-record)
				  (_type (subclass ebdb-field-name))
				  (regexp string))
  (or (string-match-p regexp (or (ebdb-record-name-string record) ""))
      (seq-find
       (lambda (n)
	 (string-match-p regexp n))
       (ebdb-record-alt-names record))
      (ebdb-field-search (slot-value record 'name) regexp)))

(cl-defmethod ebdb-record-search ((record ebdb-record-person)
				  (_type (subclass ebdb-field-name))
				  (regexp string))
  ;; First pass the search to the more general method, and only really
  ;; search the names if we don't find anything.

  ;; This is done to allow overrides of `ebdb-field-search' for names
  ;; to kick in.  It makes the exhaustive search slower, though.
  (or (cl-call-next-method)
      (cl-some
       (lambda (name)
	 (ebdb-field-search name regexp))
       (slot-value record 'aka))))

(cl-defmethod ebdb-record-search ((record ebdb-record)
				  (_type (subclass ebdb-field-notes))
				  (regexp string))
  (let ((notes (slot-value record 'notes)))
    (when notes
      (ebdb-field-search notes regexp))))

(cl-defmethod ebdb-record-search ((record ebdb-record-entity)
				  (_type (subclass ebdb-field-phone))
				  (regexp string))
  (let ((phones (ebdb-record-phone record)))
    (if phones
	(or (string-match-p regexp "")
	    (catch 'found
	      (dolist (ph phones)
		(when (ebdb-field-search ph regexp)
		  (throw 'found t))))))))

(cl-defmethod ebdb-record-search ((record ebdb-record-entity)
				  (_type (subclass ebdb-field-address))
				  (regexp string))
  (let ((adds (ebdb-record-address record)))
    (if adds
	(or (string-match-p regexp "")
	    (catch 'found
	      (dolist (a adds)
		(when (ebdb-field-search a regexp)
		  (throw 'found t))))))))

(cl-defmethod ebdb-record-search ((record ebdb-record-entity)
				  (_type (subclass ebdb-field-mail))
				  (regexp string))
  (let ((mails (ebdb-record-mail record nil nil t)))
    (if mails
	(or (string-match-p regexp "")
	    (catch 'found
	      (dolist (m mails)
		(when (ebdb-field-search m regexp)
		  (throw 'found t))))))))

(cl-defmethod ebdb-record-search ((org ebdb-record-organization)
				  (_type (subclass ebdb-field-domain))
				  (criterion string))
  (let ((dom (slot-value org 'domain)))
    (and dom
	 (string-match-p criterion (ebdb-string dom)))))

(cl-defmethod ebdb-record-search ((record ebdb-record-person)
				  (_type (eql organization))
				  (regexp string))
  (seq-find
   (lambda (o)
     (string-match-p regexp o))
   (ebdb-record-organizations record)))

(cl-defmethod ebdb-record-search ((record ebdb-record-organization)
				  (_type (eql organization))
				  (regexp string))
  (ebdb-record-search record 'ebdb-field-name regexp))

(cl-defmethod ebdb-record-search ((record ebdb-record)
				  (cls (subclass ebdb-field-user))
				  criterion)
  (catch 'found
    (dolist (f (ebdb-record-user-fields record))
      (when (and (object-of-class-p f cls)
		 (ebdb-field-search f criterion))
	(throw 'found t)))))

(cl-defmethod ebdb-record-search ((record ebdb-record-person)
				  (_type (eql organization))
				  (regex string))
  (or (seq-find (lambda (org)
		  (string-match-p regex org))
		(ebdb-record-organizations record))
      (string-match-p regex "")))

(cl-defmethod ebdb-record-search ((record ebdb-record)
				  (_type (eql dirty))
				  _criterion)
  (slot-value record 'dirty))

(cl-defmethod ebdb-record-search ((record ebdb-record)
				  (_type (eql database))
				  (db ebdb-db))
  (member db (ebdb-record-databases record)))

(cl-defmethod ebdb-record-search ((record ebdb-record)
				  (_type (eql record-class))
				  (class symbol))
  (object-of-class-p record class))


(cl-defgeneric ebdb-search-read (field-class)
  "Prompt user for a string to match against instances of FIELD-CLASS.
In most cases this is a simple regexp, but field classes can
prompt users for more complex search criteria, if necessary.")

(cl-defmethod ebdb-search-read ((cls (subclass ebdb-field)))
  (read-string (format "Search records with %s %smatching regexp: "
		       (ebdb-field-readable-name cls)
		       (if ebdb-search-invert "not " ""))))

(cl-defmethod ebdb-search-read ((_cls (subclass ebdb-field-mail)))
  (let ((ebdb-completion-list '(mail)))
    (completing-read
     (format "Search records with mail %smatching regexp: "
	     (if ebdb-search-invert "not " ""))
     ebdb-hashtable #'ebdb-completion-predicate)))

(cl-defmethod ebdb-search-read ((field string))
  "Read regexp to search FIELD values of records."
  (read-string (format "Search records with %s %smatching regexp: "
                       field
                       (if ebdb-search-invert "not " ""))))

(cl-defmethod ebdb-search-read ((_all symbol))
  "Read regexp to search across all records."
  (read-string (format "Search records %smatching regexp: "
                       (if ebdb-search-invert "not " ""))))

(cl-defmethod ebdb-search-read :around (_source)
  "Trim string search criteria."
  (let ((criterion (cl-call-next-method)))
    (if (stringp criterion)
	(string-trim criterion)
      criterion)))

(provide 'ebdb)
;;; ebdb.el ends here
