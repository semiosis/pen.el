;;; tomelr.el --- Convert S-expressions to TOML           -*- lexical-binding: t -*-

;; Copyright (C) 2022 Free Software Foundation, Inc.

;; Author: Kaushal Modi <kaushal.modi@gmail.com>
;; Version: 0.4.3
;; Package-Requires: ((emacs "26.3") (map "3.2.1") (seq "2.23"))
;; Keywords: data, tools, toml, serialization, config
;; URL: https://github.com/kaushalmodi/tomelr/

;; This file is not part of GNU Emacs.

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

;; tomelr.el is a library for converting Lisp data expressions or
;; S-expressions to TOML format (https://toml.io/en/).

;; It has one entry point `tomelr-encode' which accepts a Lisp data
;; expression, usually in an alist or plist form, and return a string
;; representing the TOML serializaitno format.

;; Example using an alist as input:
;;
;;     (tomelr-encode '((title . "My title")
;;                      (author . "Me")
;;                      (params . ((foo . 123)))))
;;
;;  Output:
;;
;;     title = "My title"
;;     author = "Me"
;;     [params]
;;       foo = 123

;; Example using an plist as input:
;;
;;     (tomelr-encode '(:title "My title"
;;                      :author "Me"
;;                      :params (:foo 123)))
;;
;;  Above snippet will give as the same TOML output shown above.

;; See the README.org on https://github.com/kaushalmodi/tomelr/ for
;; more examples and package details.

;;; Code:

(require 'json)
(require 'map)
(require 'subr-x)  ;For `string-trim' on Emacs versions 27.2 and older


;;; Variables

(defvar tomelr-false '(:false 'false)
  "S-exp values to be interpreted as TOML `false'.")

(defvar tomelr-encoding-default-indentation "  "
  "String used for a single indentation level during encoding.
This value is repeated for each further nested element.")

(defvar tomelr-coerce-to-types '(boolean integer)
  "List of TOML types to which the TOML strings will be attempted to be coerced.

Valid symbols that can be present in this list: boolean, integer, float

For example, if this list contains `boolean' and if a string
value is exactly \"true\", it will coerce to TOML boolean
`true'.")

(defvar tomelr-indent-multi-line-strings nil
  "Indent the multi-line TOML strings when non-nil.

This option injects spaces after each newline to present the
multi-line strings in a more readable format.

*Note: This option should be set to non-nil only if the TOML
string data is insensitive to horizontal space.  Good examples of
this would be Org, Markdown or HTML strings.")

;;;; Internal Variables
(defvar tomelr--print-indentation-prefix "\n"
  "String used to start indentation during encoding.")

(defvar tomelr--print-indentation-depth -1
  "Current indentation level during encoding.
Dictates repetitions of `tomelr-encoding-default-indentation'.")

(defvar tomelr--print-table-hierarchy ()
  "Internal variable used to save TOML Table hierarchies.
This variable is used for both TOML Tables and Arrays of TOML
Tables.")

(defvar tomelr--print-keyval-separator " = "
  "String used to separate key-value pairs during encoding.")

(defvar tomelr--date-time-regexp
  (concat "\\`[[:digit:]]\\{4\\}-[[:digit:]]\\{2\\}-[[:digit:]]\\{2\\}"
          "\\(?:[T ][[:digit:]]\\{2\\}:[[:digit:]]\\{2\\}:[[:digit:]]\\{2\\}\\(?:\\.[[:digit:]]+\\)*"
          "\\(?:Z\\|[+-][[:digit:]]\\{2\\}:[[:digit:]]\\{2\\}\\)*\\)*\\'")
  "Regexp to match RFC 3339 formatted date-time with offset.

- https://toml.io/en/v1.0.0#offset-date-time
- https://tools.ietf.org/html/rfc3339#section-5.8

Examples:
  1979-05-27
  1979-05-27T07:32:00Z
  1979-05-27 07:32:00Z
  1979-05-27T00:32:00-07:00
  1979-05-27T00:32:00.999999+04:00.")



;;; Error conditions

(define-error 'tomelr-error "Unknown TOML error")
(define-error 'tomelr-key-format "Bad TOML object key" 'tomelr-error)



;;; Utilities

(defmacro tomelr--with-output-to-string (&rest body)
  "Eval BODY in a temporary buffer bound to `standard-output'.
Return the resulting buffer contents as a string."
  (declare (indent 0) (debug t))
  `(with-output-to-string
     (with-current-buffer standard-output
       ;; This affords decent performance gains.
       (setq-local inhibit-modification-hooks t)
       ,@body)))

(defmacro tomelr--with-indentation (&rest body)
  "Eval BODY with the TOML encoding nesting incremented by one step.
This macro sets up appropriate variable bindings for
`tomelr--print-indentation' to produce the correct indentation."
  (declare (debug t) (indent 0))
  `(let ((tomelr--print-indentation-depth (1+ tomelr--print-indentation-depth)))
     ,@body))

(defun tomelr--print-indentation ()
  "Insert the current indentation for TOML encoding at point."
  (insert tomelr--print-indentation-prefix)
  (dotimes (_ tomelr--print-indentation-depth)
    (insert tomelr-encoding-default-indentation)))



;;; Encoding

;;;; Booleans
(defun tomelr--print-boolean (object)
  "Insert TOML boolean true or false at point if OBJECT is a boolean.
Return nil if OBJECT is not recognized as a TOML boolean."
  (prog1 (setq object (cond ((or
                              (eq object t)
                              (and (member 'boolean tomelr-coerce-to-types)
                                   (member object '("true" true))))
                             "true")
                            ((or
                              (member object tomelr-false)
                              (and (member 'boolean tomelr-coerce-to-types)
                                   (member object '("false" false))))
                             "false")))
    (and object (insert object))))

;;;; Strings
(defun tomelr--print-string (string)
  "Insert a TOML representation of STRING at point.

Return the same STRING passed as input."
  ;; (message "[tomelr--print-string DBG] string = `%s'" string)
  (let ((special-chars '((?b . ?\b)     ;U+0008
                         (?f . ?\f)     ;U+000C
                         (?\\ . ?\\)))
        (special-chars-re (rx (in ?\" ?\\ cntrl ?\u007F))) ;cntrl is same as (?\u0000 . ?\u001F)
        ;; Use multi-line string quotation if the string contains a "
        ;; char or a newline - """STRING""".
        (multi-line (string-match-p "\n\\|\"" string))
        begin-q end-q)

    (cond
     (multi-line
      ;; From https://toml.io/en/v1.0.0#string, Any Unicode
      ;; character may be used except those that must be escaped:
      ;; backslash and the control characters other than tab, line
      ;; feed, and carriage return (U+0000 to U+0008, U+000B,
      ;; U+000C, U+000E to U+001F, U+007F).
      (setq special-chars-re (rx (in ?\\
                                     (?\u0000 . ?\u0008)
                                     ?\u000B ?\u000C
                                     (?\u000E . ?\u001F)
                                     ?\u007F)))

      (setq begin-q "\"\"\"\n")
      (setq end-q "\"\"\"")
      (when tomelr-indent-multi-line-strings
        (let (;; Fix the indentation of multi-line strings to 2
              ;; spaces. If the indentation is increased to 4 or more
              ;; spaces, those strings will get parsed as code blocks
              ;; by Markdown parsers.
              (indentation "  "))
          (setq string
                (concat
                 indentation ;Indent the first line in the multi-line string
                 (replace-regexp-in-string
                  "\\(\n\\)\\([^\n]\\)"  ;Don't indent blank lines
                  (format "\\1%s\\2" indentation)
                  string)
                 "\n" indentation ;Indent the closing """ at the end of the multi-line string
                 )))))
     (t                                 ;Basic quotation "STRING"
      (push '(?\" . ?\") special-chars)
      (push '(?t . ?\t) special-chars) ;U+0009
      (push '(?n . ?\n) special-chars) ;U+000A
      (push '(?r . ?\r) special-chars) ;U+000D
      (setq begin-q "\"")
      (setq end-q begin-q)))

    (and begin-q (insert begin-q))
    (goto-char (prog1 (point) (princ string)))
    (while (re-search-forward special-chars-re nil :noerror)
      (let ((char (preceding-char)))
        (delete-char -1)
        (insert ?\\ (or
                     ;; Escape special characters
                     (car (rassq char special-chars))
                     ;; Fallback: UCS code point in \uNNNN form.
                     (format "u%04x" char)))))
    (and end-q (insert end-q))
    string))

(defun tomelr--print-stringlike (object &optional key-type)
  "Insert OBJECT encoded as a TOML string at point.

Possible values of KEY-TYPE are `normal-key', `table-key',
`table-array-key', or nil.

Return nil if OBJECT cannot be encoded as a TOML string."
  ;; (message "[tomelr--print-stringlike DBG] object = %S (type = %S) key type = %S"
  ;;          object (type-of object) key-type)
  (let ((str (cond ;; Object is a normal, TT or TTA key
              (key-type
               (cond
                ((stringp object)
                 (if (string-match-p "\\`[A-Za-z0-9_-]+\\'" object)
                     ;; https://toml.io/en/v1.0.0#keys
                     ;; Bare keys may only contain ASCII letters, ASCII digits,
                     ;; underscores, and dashes (A-Za-z0-9_-).
                     object
                   ;; Wrap string in double-quotes if it
                   ;; doesn't contain only A-Za-z0-9_- chars.
                   (format "\"%s\"" object)))
                ;; Plist keys as in (:foo 123)
                ((keywordp object)
                 (string-trim-left (symbol-name object) ":"))
                ;; Alist keys as in ((foo . 123))
                ((symbolp object)
                 (symbol-name object))
                (t
                 (user-error "[tomelr--print-stringlike] Unhandled case of key-type"))))

              ;; Cases where object is a key value.
              ((symbolp object)
               (symbol-name object))
              ((stringp object)
               object))))
    ;; (message "[tomelr--print-stringlike DBG] str = %S" str)
    (when (member key-type '(table-key table-array-key))
      ;; (message "[tomelr--print-stringlike DBG] %S is symbol, type = %S, depth = %d"
      ;;          object key-type tomelr--print-indentation-depth)
      (if (null (nth tomelr--print-indentation-depth tomelr--print-table-hierarchy))
          (setq tomelr--print-table-hierarchy
                (append tomelr--print-table-hierarchy (list str)))

        ;; Throw away table keys collected at higher depths, if
        ;; any, from earlier runs of this function.
        (setq tomelr--print-table-hierarchy
              (seq-take tomelr--print-table-hierarchy (1+ tomelr--print-indentation-depth)))
        (setf (nth tomelr--print-indentation-depth tomelr--print-table-hierarchy) str))
      ;; (message "[tomelr--print-stringlike DBG] table hier: %S" tomelr--print-table-hierarchy)
      )
    (cond
     ;; TT keys
     ((equal key-type 'table-key)
      (princ (format "[%s]" (string-join tomelr--print-table-hierarchy "."))))
     ;; TTA keys
     ((equal key-type 'table-array-key)
      (princ (format "[[%s]]" (string-join tomelr--print-table-hierarchy "."))))
     ;; Normal keys (Alist and Plist keys)
     ((equal key-type 'normal-key)
      (princ str))
     (str
      (cond
       ((or
         ;; RFC 3339 Date/Time
         (string-match-p tomelr--date-time-regexp str)

         ;; Coercing
         ;; Integer that can be stored in the system as a fixnum.
         ;; For example, if `object' is "10040216507682529280" that
         ;; needs more than 64 bits to be stored as a signed
         ;; integer, it will be automatically stored as a float.
         ;; So (integerp (string-to-number object)) will return nil
         ;; [or `fixnump' instead of `integerp' in Emacs 27 or
         ;; newer].
         ;; https://github.com/toml-lang/toml#integer
         ;; Integer examples: 7, +7, -7, 7_000
         (and (or (symbolp object)
                  (member 'integer tomelr-coerce-to-types))
              (string-match-p "\\`[+-]?[[:digit:]_]+\\'" str)
              (if (functionp #'fixnump) ;`fixnump' and `bignump' get introduced in Emacs 27.x
                  (fixnump (string-to-number str))
                ;; On older Emacsen, `integerp' behaved the same as the
                ;; new `fixnump'.
                (integerp (string-to-number str)))))
        (princ str))
       (t
        (tomelr--print-string str))))
     (t
      nil))))

(defun tomelr--print-key (key &optional key-type)
  "Insert a TOML key representation of KEY at point.

KEY-TYPE represents the type of key: `normal-key', `table-key' or
`table-array-key'.

Signal `tomelr-key-format' if it cannot be encoded as a string."
  (or (tomelr--print-stringlike key key-type)
      (signal 'tomelr-key-format (list key))))

;;;; Objects
;; `tomelr-alist-p' is a slightly modified version of `json-alist-p'.
;; It fixes this scenario: (json-alist-p '((:a 1))) return t, which is wrong.
;; '((:a 1)) is an array of plist format maps, and not an alist.
;; (tomelr-alist-p '((:a 1))) returns nil as expected.
(defun tomelr-alist-p (list)
  "Non-nil if and only if LIST is an alist with simple keys."
  (declare (pure t) (side-effect-free error-free))
  (while (and (consp (car-safe list))
              (not (json-plist-p (car-safe list)))
              (atom (caar list)))
    ;; (message "[tomelr-alist-p DBG] INSIDE list = %S, car = %S, caar = %S, atom of caar = %S"
    ;;          list (car-safe list) (caar list) (atom (caar list)))
    (setq list (cdr list)))
  ;; (message "[tomelr-alist-p DBG] out 2 list = %S, is alist? %S" list (null list))
  (null list))

(defun tomelr-toml-table-p (object)
  "Return non-nil if OBJECT can represent a TOML Table.

Recognize both alist and plist format maps as TOML Tables.

Examples:

- Alist format: \\='((a . 1) (b . \"foo\"))
- Plist format: \\='(:a 1 :b \"foo\")"
  (or (tomelr-alist-p object)
      (json-plist-p object)))

(defun tomelr--print-pair (key val)
  "Insert TOML representation of KEY - VAL pair at point."
  (let ((key-type (cond
                   ((tomelr-toml-table-p val) 'table-key)
                   ((tomelr-toml-table-array-p val) 'table-array-key)
                   (t 'normal-key))))
    ;; (message "[tomelr--print-pair DBG] key = %S, val = %S, key-type = %S"
    ;;          key val key-type)
    (when val                     ;Don't print the key if val is nil
      (tomelr--print-indentation) ;Newline before each key in a key-value pair
      (tomelr--print-key key key-type)
      ;; Skip putting the separator for table and table array keys.
      (unless (member key-type '(table-key table-array-key))
        (insert tomelr--print-keyval-separator))
      (tomelr--print val))))

(defun tomelr--print-map (map)
  "Insert a TOML representation of MAP at point.
This works for any MAP satisfying `mapp'."
  ;; (message "[tomelr--print-map DBG] map = %S" map)
  (unless (map-empty-p map)
    (tomelr--with-indentation
      (map-do #'tomelr--print-pair map))))

;;;; Lists (including alists and plists)
(defun tomelr--print-list (list)
  "Insert a TOML representation of LIST at point."
  (cond ((tomelr-toml-table-p list)
         (tomelr--print-map list))
        ((listp list)
         (tomelr--print-array list))
        ((signal 'tomelr-error (list list)))))

;;;; Arrays
(defun tomelr-toml-table-array-p (object)
  "Return non-nil if OBJECT can represent a TOML Table Array.

Definition of a TOML Table Array (TTA):

- OBJECT is TTA if it is of type ((TT1) (TT2) ..) where each element is a
  TOML Table (TT)."
  (when (or (listp object)
            (vectorp object))
    (seq-every-p
     (lambda (elem) (tomelr-toml-table-p elem))
     object)))

(defun tomelr--print-tta-key ()
  "Print TOML Table Array key."
  ;; (message "[tomelr--print-array DBG] depth = %d" tomelr--print-indentation-depth)
  ;; Throw away table keys collected at higher depths, if
  ;; any, from earlier runs of this function.
  (setq tomelr--print-table-hierarchy
        (seq-take tomelr--print-table-hierarchy (1+ tomelr--print-indentation-depth)))

  (tomelr--print-indentation)
  (insert
   (format "[[%s]]" (string-join tomelr--print-table-hierarchy "."))))

(defun tomelr--print-array (array)
  "Insert a TOML representation of ARRAY at point."
  ;; (message "[tomelr--print-array DBG] array = %S, TTA = %S"
  ;;          array (tomelr-toml-table-array-p array))
  (cond
   ((tomelr-toml-table-array-p array)
    (unless (= 0 (length array))
      (let ((first t))
        (mapc (lambda (elt)
                (if first
                    (setq first nil)
                  (tomelr--print-tta-key))
                (tomelr--print elt))
              array))))
   (t
    (insert "[")
    (unless (= 0 (length array))
      (tomelr--with-indentation
        (let ((first t))
          (mapc (lambda (elt)
                  (if first
                      (setq first nil)
                    (insert ", "))
                  (tomelr--print elt))
                array))))
    (insert "]"))))

;;;; Print wrapper
(defun tomelr--print (object)
  "Insert a TOML representation of OBJECT at point.
See `tomelr-encode' that returns the same as a string."
  (cond ((tomelr--print-boolean object))
        ((listp object)         (tomelr--print-list object))
        ((tomelr--print-stringlike object))
        ((numberp object)       (prin1 object))
        ((arrayp object)        (tomelr--print-array object))
        ((signal 'tomelr-error (list object)))))



;;; User API
(defun tomelr-encode (object)
  "Return a TOML representation of OBJECT as a string.
If an error is detected during encoding, an error based on
`tomelr-error' is signaled."
  (setq tomelr--print-table-hierarchy ())
  (string-trim
   (tomelr--with-output-to-string (tomelr--print object))))


(provide 'tomelr)

;;; tomelr.el ends here
