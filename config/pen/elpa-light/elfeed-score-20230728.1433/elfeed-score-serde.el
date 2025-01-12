;;; elfeed-score-serde.el --- SERDE `elfeed-score'  -*- lexical-binding: t; -*-

;; Copyright (C) 2021-2023 Michael Herstine <sp1ff@pobox.com>

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

;; This package provides `elfeed-score' serialization &
;; deserialization facilities.

;;; Code:
(require 'cl-lib)
(require 'elfeed-score-rules)
(require 'elfeed-score-rule-stats)

(define-obsolete-variable-alias
  'elfeed-score-score-file
  'elfeed-score-serde-score-file
  "0.7.0"
  "Refactoring elfeed-score.el.")

(defcustom elfeed-score-serde-score-file
  (concat (expand-file-name user-emacs-directory) "elfeed.score")
  "Location at which to persist scoring rules.

Set this to nil to disable automatic serialization &
deserialization of scoring rules."
  :group 'elfeed-score
  :type 'file)

(defconst elfeed-score-serde-current-format 10
  "The most recent score file format version.")

(defvar elfeed-score-serde-title-rules nil
  "List of structs each defining a scoring rule for entry titles.")

(defvar elfeed-score-serde-feed-rules nil
  "List of structs each defining a scoring rule for entry feeds.")

(defvar elfeed-score-serde-authors-rules nil
  "List of structs each defining a scoring rule for entry authors.")

(defvar elfeed-score-serde-content-rules nil
  "List of structs each defining a scoring rule for entry content.")

(defvar elfeed-score-serde-title-or-content-rules nil
  "List of structs each defining a scoring rule for entry title or content.")

(defvar elfeed-score-serde-tag-rules nil
  "List of structs each defining a scoring rule for entry tags.")

(defvar elfeed-score-serde-link-rules nil
  "List of structs each defining a scoring rule for entry links.")

(defvar elfeed-score-serde-udf-rules nil
  "List of structs each defining a scoring rule based on a user-defined function.")

(defvar elfeed-score-serde-score-mark nil
  "Score below which entries shall be marked as read.")

(defvar elfeed-score-serde-adjust-tags-rules nil
  "List of rules to be run after scoring to adjust tags based on score.")

(defsubst elfeed-score-serde--nth (x i)
  "Retrieve slot I of X."
  (if (recordp x) (aref x i) (elt x i)))

;; This implementation is more general that this package requires--
;; `elfeed-score-rules' defines its structs in terms of records &
;; reserves no slots, so I could have used a more succinct
;; implementation that just runs through the slot info with no
;; additional logic.  Still, I got interested in the CL struct
;; facility altogether & decided to try 'n come up with a general
;; implementation.
(defun elfeed-score-serde-struct-to-plist (x &rest params)
  "Serialize a CL struct X to a plist.  Keyword args in PARAMS.

The type of X is assumed to be in the first slot; if that is not
so, pass the :type keyword parameter with either an integer
giving the slot in which the type resides, or a symbol naming the
type of X.

By default, the resulting plist will just contain the state
necessary to deserialize X; the reader will have to \"just know\"
the type of X on read. To tag the plist with the type, pass the
keyword argument :type-tag with a non-nil value.  In this case,
the plist will contain a property named :_type whose value will
be the structure name.

If the struct reserved slots using the :initial-offset option,
those slots will be serialized when non-nil with names of :_n
where n is the zero-baesd slot number."

  (let ((plist)
        (type-tag (plist-get params :type-tag))
        (ty (plist-get params :type)))
    (cl-loop for i upfrom 0
             for (slot . rest) in
             (cl-struct-slot-info
              (cond
               ((integerp ty) (elfeed-score-serde--nth x ty))
               ((and ty (symbolp ty)) ty)
               (t (elfeed-score-serde--nth x 0))))
             do
             (let ((val (elfeed-score-serde--nth x i)))
               (cond
                ((eq slot 'cl-tag-slot)
                 (if type-tag
                     (setq plist (plist-put plist :_type val))))
                ((eq slot 'cl-skip-slot)
                 (if val
                     (setq plist (plist-put plist (intern (format ":_%d" i)) val))))
                (t
                 ;; We write `val' if it is *not* the default
                 (if (not (equal val (eval (car rest))))
                     (setq
                      plist
                      (plist-put plist (intern (concat ":" (symbol-name slot))) val)))))))
    (if (and type-tag (not (plist-get plist :_type)))
        (setq plist (plist-put plist :_type ty)))
    plist))

;; Similar to `elfeed-score-serde-struct-to-plist', this
;; implementation is more general than this package strictly needs.
(defun elfeed-score-serde-plist-to-struct (plist &rest params)
  "Deserialize PLIST to a struct; options in PARAMS.

PLIST is a property list presumably created by
`elfeed-score-serde-struct-to-plist': a property list containing
the state of a struct indexed by slot name.  If the struct type
reserved slots, any non-nil values should be indexed in PLIST by
:_n where n is the zero-based slot number.  The plist may,
optionally, contain the struct type indexed by :_type.

If the plist contains the type, this implementation will
deserialize the struct instance with no further information.
Else, the caller must supply the type name with the keyword
argument :type.

If the keyword argument :mandatory is present, it should be a
list of slot names to be checked.  If any are not present, an
error will be flagged."
  
  (let ((ty (or (plist-get plist :_type) (plist-get params :type)))
        (mandatory (plist-get params :mandatory))
        (vals))
    (cl-loop
     for i upfrom 0
     for (slot . rest) in
     (cl-struct-slot-info ty)
     do
     (cond
      ((eq slot 'cl-tag-slot)
       (setq vals (append vals (list ty))))
      ((eq slot 'cl-skip-slot)
       (setq vals (append vals (list (plist-get plist (intern (format ":_%d" i)))))))
      (t
       (let ((val
              (or
               (plist-get plist (intern (concat ":" (symbol-name slot))))
               (eval (car rest)))))
         (if (and
              mandatory
              (not val)
              (member slot mandatory))
             (error "Missing mandatory field %s" slot))
         (setq vals (append vals (list val)))))))
    (let ((seq-ty (cl-struct-sequence-type ty)))
      (cond
       ((eq seq-ty 'list) vals)
       ((eq seq-ty 'vector) (apply #'vector vals))
       (t (apply #'record (car vals) (cdr vals)))))))

(defun elfeed-score-serde--parse-title-rule-sexps (sexps)
  "Parse a list of lists SEXPS into a list of title rules.

Each sub-list shall have the form (TEXT VALUE TYPE DATE TAGS HITS
FEEDS).  NB Over the course of successive score file versions,
new fields have been added at the end so as to maintain backward
compatibility (i.e. this function can be used to read all
versions of the title rule serialization format prior to version
6).

Due to the change to storing rule stats outside the rule itself
beginning with version 8, this method will now return a list of
cons cells each of whose car is the rule structure and whose cdr
is the stats structure."
  (cl-mapcar
   (lambda (item)
     (cons
      (elfeed-score-title-rule--create :text  (nth 0 item)
                                       :value (nth 1 item)
                                       :type  (nth 2 item)
                                       :tags  (nth 4 item)
                                       :feeds (nth 6 item))
      (elfeed-score-rule-stats--create
       :date  (nth 3 item)
       :hits  (let ((hits (nth 5 item))) (or hits 0)))))
   sexps))

(defun elfeed-score-serde--parse-feed-rule-sexps (sexps)
  "Parse a list of lists SEXPS into a list of feed rules.

Each sub-list shall have the form (TEXT VALUE TYPE ATTR DATE TAGS
HITS).  NB Over the course of successive score file versions, new
fields have been added at the end so as to maintain backward
compatibility (i.e. this function can be used to read all
versions of the feed rule serialization format prior to version
6).

Due to the change to storing rule stats outside the rule itself
beginning with version 8, this method will now return a list of
cons cells each of whose car is the rule structure and whose cdr
is the stats structure."
  (cl-mapcar
   (lambda (item)
     (cons
      (elfeed-score-feed-rule--create :text  (nth 0 item)
                                      :value (nth 1 item)
                                      :type  (nth 2 item)
                                      :attr  (nth 3 item)
                                      :tags  (nth 5 item))
      (elfeed-score-rule-stats--create
       :date  (nth 4 item)
       :hits  (let ((hits (nth 6 item))) (or hits 0)))))
   sexps))

(defun elfeed-score-serde--parse-content-rule-sexps (sexps)
  "Parse a list of lists SEXPS into a list of content rules.

Each sub-list shall have the form (TEXT VALUE TYPE DATE TAGS HITS
FEEDS).  NB Over the course of successive score file versions,
new fields have been added at the end so as to maintain backward
compatibility (i.e. this function can be used to read all
versions of the content rule serialization format prior to
version 6).

Due to the change to storing rule stats outside the rule itself
beginning with version 8, this method will now return a list of
cons cells each of whose car is the rule structure and whose cdr
is the stats structure."
  (cl-mapcar
   (lambda (item)
     (cons
      (elfeed-score-content-rule--create :text  (nth 0 item)
                                         :value (nth 1 item)
                                         :type  (nth 2 item)
                                         :tags  (nth 4 item)
                                         :feeds (nth 6 item))
      (elfeed-score-rule-stats--create
       :date  (nth 3 item)
       :hits  (let ((hits (nth 5 item))) (or hits 0)))))
   sexps))

(defun elfeed-score-serde--parse-title-or-content-rule-sexps (sexps)
  "Parse a list of lists SEXPS into a list of title-or-content rules.

Each sub-list shall have the form '(TEXT TITLE-VALUE
CONTENT-VALUE TYPE DATE TAGS HITS FEEDS).  NB Over the course of
successive score file versions, new fields have been added at the
end so as to maintain backward compatibility (i.e. this function
can be used to read all versions of the title-or-content rule
serialization format prior to version 6).

Due to the change to storing rule stats outside the rule itself
beginning with version 8, this method will now return a list of
cons cells each of whose car is the rule structure and whose cdr
is the stats structure."
  (cl-mapcar
   (lambda (item)
     (cons
      (elfeed-score-title-or-content-rule--create
       :text          (nth 0 item)
       :title-value   (nth 1 item)
       :content-value (nth 2 item)
       :type          (nth 3 item)
       :tags          (nth 5 item)
       :feeds         (nth 7 item))
      (elfeed-score-rule-stats--create
       :date (nth 4 item)
       :hits (let ((hits (nth 6 item))) (or hits 0)))))
   sexps))

(defun elfeed-score-serde--parse-scoring-sexp-1 (sexp)
  "Interpret the S-expression SEXP as scoring rules version 1.

Parse version 1 of the scoring S-expression.  This function will
fail if SEXP has a \"version\" key with a value other than 1 (the
caller may want to remove it via `assoc-delete-all' or some
such).  Return a property list with the following keys & values:

    - :title : list of cons cells whose car-s are
      elfeed-score-title-rule structs & whose cdr-s are stats
      structs

    - :content : similar list of elfeed-score-content-rule &
      stats structs

    - :feed : similar list of elfeed-score-feed-rule & stats
      structs

    - :mark : score below which entries shall be marked read"

  (let (mark titles feeds content)
    (dolist (raw-item sexp)
      (let ((key  (car raw-item))
            (rest (cdr raw-item)))
        (cond
         ((string= key "version")
          (unless (eq 1 (car rest))
            (error "Unsupported score file version %s" (car rest))))
         ((string= key "title")
          (setq titles (elfeed-score-serde--parse-title-rule-sexps rest)))
         ((string= key "content")
          (setq content (elfeed-score-serde--parse-content-rule-sexps rest)))
         ((string= key "feed")
          (setq feeds (elfeed-score-serde--parse-feed-rule-sexps rest)))
         ((eq key 'mark)
          ;; set `mark' to (cdr rest) if (not mark) or (< mark (cdr rest))
          (let ((rest (car rest)))
            (if (or (not mark)
                    (< mark rest))
                (setq mark rest))))
         (t
          (error "Unknown score file key %s" key)))))
    (list
     :mark mark
     :feeds feeds
     :titles titles
     :content content)))

(defun elfeed-score-serde--parse-scoring-sexp-2 (sexp)
  "Interpret the S-expression SEXP as scoring rules version 2.

Parse version 2 of the scoring S-expression.  Return a property list
with the following keys & values:

    - :title : list of cons cells, each of whose car is an
      elfeed-score-title-rule struct & whose cdr is a stats
      struct

    - :content : similar list of cons cells containing
      elfeed-score-content-rule & stats structs

    - :title-or-content: similar list of cons cells containing
      elfeed-score-title-or-content-rule & stats structs

    - :feed : similar list of cons cells containing
      elfeed-score-feed-rule & stats structs

    - :mark : score below which entries shall be marked read"

  (let (mark titles feeds content tocs)
    (dolist (raw-item sexp)
      (let ((key  (car raw-item))
            (rest (cdr raw-item)))
        (cond
         ((string= key "version")
          (unless (eq 2 (car rest))
            (error "Unsupported score file version %s" (car rest))))
         ((string= key "title")
          (setq titles (elfeed-score-serde--parse-title-rule-sexps rest)))
         ((string= key "content")
          (setq content (elfeed-score-serde--parse-content-rule-sexps rest)))
         ((string= key "feed")
          (setq feeds (elfeed-score-serde--parse-feed-rule-sexps rest)))
         ((string= key "title-or-content")
          (setq tocs (elfeed-score-serde--parse-title-or-content-rule-sexps rest)))
         ((eq key 'mark)
          ;; set `mark' to (cdr rest) if (not mark) or (< mark (cdr rest))
          (let ((rest (car rest)))
            (if (or (not mark)
                    (< mark rest))
                (setq mark rest))))
         (t
          (error "Unknown score file key %s" key)))))
    (list
     :mark mark
     :feeds feeds
     :titles titles
     :content content
     :title-or-content tocs)))

(defun elfeed-score-serde--parse-tag-rule-sexps (sexps)
  "Parse a list of lists SEXPS into a list of tag rules.

Each sub-list shall have the form '(TAGS VALUE DATE HITS).  NB
Over the course of successive score file versions, new fields
have been added at the end so as to maintain backward
compatibility (i.e. this function can be used to read all
versions of the tag rule serialization format prior to version
6).

Due to the change to storing rule stats outside the rule itself
beginning with version 8, this method will now return a list of
cons cells each of whose car is the rule structure and whose cdr
is the stats structure."
  (cl-mapcar
   (lambda (item)
     (cons
      (elfeed-score-tag-rule--create :tags  (nth 0 item)
                                     :value (nth 1 item))
      (elfeed-score-rule-stats--create
       :date (nth 2 item)
       :hits (let ((hits (nth 5 item))) (or hits 0)))))
   sexps))

(defun elfeed-score-serde--parse-adjust-tags-rule-sexps (sexps)
  "Parse a list of lists SEXPS into a list of adjust-tags rules.

Each sub-list shall have the form '(TAGS VALUE DATE HITS).  NB
Over the course of successive score file versions, new fields
have been added at the end so as to maintain backward
compatibility (i.e. this function can be used to read all
versions of the adjust-tag rule serialization format prior to
version 6).

Due to the change to storing rule stats outside the rule itself
beginning with version 8, this method will now return a list of
cons cells each of whose car is the rule structure and whose cdr
is the stats structure."
  (cl-mapcar
   (lambda (item)
     (cons
      (elfeed-score-adjust-tags-rule--create :threshold (nth 0 item)
                                             :tags      (nth 1 item))
      (elfeed-score-rule-stats--create
       :date (nth 2 item)
       :hits (let ((hits (nth 5 item))) (or hits 0)))))
   sexps))

(defun elfeed-score-serde--parse-scoring-sexp-3 (sexp)
  "Interpret the S-expression SEXP as scoring rules version 3.

Parse version 3 of the scoring S-expression.  Return a property list
with the following keys & values:

    - :title : list of cons cells each of whose car is an
      elfeed-score-title-rule struct & each of whose cdr is a
      stats struct

    - :content : similar list of cons cells containing
      elfeed-score-content-rule & stats structs

    - :title-or-content: similar list of cons cells containing
      elfeed-score-title-or-content-rule & stats structs

    - :feed : similar list of cons cells containing
      elfeed-score-feed-rule & stats structs

    - :tag : similar list of cons cells containing
      elfeed-score-tag-rule & stats structs

    - :adjust-tags : similar list of cons cells containing
      elfeed-score-adjust-tags-rule & stats structs

    - :mark : score below which entries shall be marked read"

  (let (mark titles feeds content tocs tags adj-tags)
    (dolist (raw-item sexp)
      (let ((key  (car raw-item))
            (rest (cdr raw-item)))
        (cond
         ((string= key "version")
          (unless (eq 3 (car rest))
            (error "Unsupported score file version %s" (car rest))))
         ((string= key "title")
          (setq titles (elfeed-score-serde--parse-title-rule-sexps rest)))
         ((string= key "content")
          (setq content (elfeed-score-serde--parse-content-rule-sexps rest)))
         ((string= key "feed")
          (setq feeds (elfeed-score-serde--parse-feed-rule-sexps rest)))
         ((string= key "title-or-content")
          (setq tocs (elfeed-score-serde--parse-title-or-content-rule-sexps rest)))
         ((string= key "tag")
          (setq tags (elfeed-score-serde--parse-tag-rule-sexps rest)))
         ((string= key "adjust-tags")
          (setq adj-tags (elfeed-score-serde--parse-adjust-tags-rule-sexps rest)))
         ((eq key 'mark)
          ;; set `mark' to (cdr rest) if (not mark) or (< mark (cdr rest))
          (let ((rest (car rest)))
            (if (or (not mark)
                    (< mark rest))
                (setq mark rest))))
         (t
          (error "Unknown score file key %s" key)))))
    (list
     :mark mark
     :adjust-tags adj-tags
     :feeds feeds
     :titles titles
     :content content
     :title-or-content tocs
     :tag tags)))

(defun elfeed-score-serde--parse-authors-rule-sexps (sexps)
  "Parse a list of lists SEXPS into a list of authors rules.

Each sub-list shall have the form '(TEXT VALUE TYPE DATE TAGS
HITS FEEDS).  NB Over the course of successive score file
versions, new fields have been added at the end so as to maintain
backward compatibility (i.e. this function can be used to read
all versions of the authors rule serialization format prior to
version 6).

Due to the change to storing rule stats outside the rule itself
beginning with version 8, this method will now return a list of
cons cells each of whose car is the rule structure and whose cdr
is the stats structure."
  (cl-mapcar
   (lambda (item)
     (cons
      (elfeed-score-authors-rule--create :text  (nth 0 item)
                                         :value (nth 1 item)
                                         :type  (nth 2 item)
                                         :tags  (nth 4 item)
                                         :feeds (nth 6 item))
      (elfeed-score-rule-stats--create
       :date (nth 3 item)
       :hits (let ((hits (nth 5 item))) (or hits 0)))))
   sexps))

(defun elfeed-score-serde--parse-scoring-sexp-4 (sexp)
  "Interpret the S-expression SEXP as scoring rules version 4.

Parse version 4 of the scoring S-expression.  Return a property list
with the following keys:

    - :title : list of cons cells each of whose car is an
      elfeed-score-title-rule struct & each of whose cdr is a
      stats struct

    - :content : similar list of cons cells containing
      elfeed-score-content-rule & stats structs

    - :title-or-content: similar list of cons cells containing
      elfeed-score-title-or-content-rule & stats structs

    - :feed : similar list of cons cells containing
      elfeed-score-feed-rule & stats structs

    - :tag : similar list of cons cells containing
      elfeed-score-tag-rule & stats structs

    - :adjust-tags : similar list of cons cells containing
      elfeed-score-adjust-tags-rule & stats structs

    - :authors : similar list of cons cells containing
      elfeed-score-authors-rule & stats structs

    - :mark : score below which entries shall be marked read"

  (let (mark titles feeds content tocs authors tags adj-tags)
    (dolist (raw-item sexp)
      (let ((key  (car raw-item))
            (rest (cdr raw-item)))
        (cond
         ((string= key "version")
          (unless (or (eq 4 (car rest)) (eq 5 (car rest)))
            (error "Unsupported score file version %s" (car rest))))
         ((string= key "title")
          (setq titles (elfeed-score-serde--parse-title-rule-sexps rest)))
         ((string= key "content")
          (setq content (elfeed-score-serde--parse-content-rule-sexps rest)))
         ((string= key "feed")
          (setq feeds (elfeed-score-serde--parse-feed-rule-sexps rest)))
         ((string= key "title-or-content")
          (setq tocs (elfeed-score-serde--parse-title-or-content-rule-sexps rest)))
         ((string= key "authors")
          (setq authors (elfeed-score-serde--parse-authors-rule-sexps rest)))
         ((string= key "tag")
          (setq tags (elfeed-score-serde--parse-tag-rule-sexps rest)))
         ((string= key "adjust-tags")
          (setq adj-tags (elfeed-score-serde--parse-adjust-tags-rule-sexps rest)))
         ((eq key 'mark)
          ;; set `mark' to (cdr rest) if (not mark) or (< mark (cdr rest))
          (let ((rest (car rest)))
            (if (or (not mark)
                    (< mark rest))
                (setq mark rest))))
         (t
          (error "Unknown score file key %s" key)))))
    (list
     :mark mark
     :adjust-tags adj-tags
     :feeds feeds
     :titles titles
     :content content
     :title-or-content tocs
     :authors authors
     :tag tags)))

(defun elfeed-score-serde--plist-to-ctor (plist attrs ctor)
  "Pull ATTRS from PLIST & hand them to CTOR.

ATTRS shall be a list of keywords (:text, or :date, e.g.).  This
function creates a list of those keywords followed by that
keyword's value in PLIST (if any) & applies CTOR to that list."

  (let* ((zip (cl-mapcar
               #'cons
               attrs
               (cl-mapcar (lambda (x) (plist-get plist x)) attrs)))
         (elems))
    ;; `zip' is a list of cons cells (keyword . value)
    (while (consp zip)
      (let ((elem (pop zip)))
        (if (cdr elem)
            (setq elems (append elems (list (car elem) (cdr elem)))))))
    (apply ctor elems)))

;; For score file version 6 & 7, we need to deserialize to both a rule
;; & a stats object.
(defun elfeed-score-serde--plist-to-struct-6-7 (plist ty)
  "Deserialize PLIST to a struct of type TY in score file versions 6 & 7.

Prior to version 8 of the score file format, rule statistics were
kept with the corresponding rule and serialized to the same
property list.  Therefore, to deserialize, we need to read the
property lists into two structures: the rule & the stats.  Both
are returned as a cons cell."
  (cons
   (cond
    ((eq ty 'elfeed-score-title-rule)
     (elfeed-score-serde--plist-to-ctor
      plist '(:text :value :type :tags :feeds)
      #'elfeed-score-title-rule--create))
    ((eq ty 'elfeed-score-feed-rule)
     (elfeed-score-serde--plist-to-ctor
      plist '(:text :value :type :attr :tags)
      #'elfeed-score-feed-rule--create))
    ((eq ty 'elfeed-score-content-rule)
     (elfeed-score-serde--plist-to-ctor
      plist '(:text :value :type :tags :feeds)
      #'elfeed-score-content-rule--create))
    ((eq ty 'elfeed-score-title-or-content-rule)
     (elfeed-score-serde--plist-to-ctor
      plist '(:text :title-value :content-value :type :tags :feeds)
      #'elfeed-score-title-or-content-rule--create))
    ((eq ty 'elfeed-score-authors-rule)
     (elfeed-score-serde--plist-to-ctor
      plist '(:text :value :type :tags :feeds)
      #'elfeed-score-authors-rule--create))
    ((eq ty 'elfeed-score-tag-rule)
     (elfeed-score-serde--plist-to-ctor
      plist '(:tags :value)
      #'elfeed-score-tag-rule--create))
    ((eq ty 'elfeed-score-link-rule)
     (elfeed-score-serde--plist-to-ctor
      plist '(:text :value :type :tags :feeds)
      #'elfeed-score-link-rule--create))
    ((eq ty 'elfeed-score-adjust-tags-rule)
     (elfeed-score-serde--plist-to-ctor
      plist '(:threshold :tags)
      #'elfeed-score-adjust-tags-rule--create))
    (t
     (error "Unknown rule type %s" ty)))
   (elfeed-score-serde--plist-to-ctor
                 plist '(:hits :date) #'elfeed-score-rule-stats--create)))

(defun elfeed-score-serde--parse-scoring-sexp-6 (sexp)
  "Interpret the S-expression SEXP as scoring rules version 6.

Parse version 6 of the scoring S-expression.  Version 6
introduced keywords to the serialization format.  Return a
property list with the following keys:

    - :title : list of cons cells each of whose car is an
      elfeed-score-title-rule struct & each of whose cdr is a
      stats struct

    - :content : similar list of cons cells containing
      elfeed-score-content-rule & stats structs

    - :title-or-content: similar list of cons cells containing
      elfeed-score-title-or-content-rule & stats structs

    - :feed : similar list of cons cells containing
      elfeed-score-feed-rule & stats structs

    - :tag : similar list of cons cells containing
      elfeed-score-tag-rule & stats structs

    - :adjust-tags : similar list of cons cells containing
      elfeed-score-adjust-tags-rule & stats structs

    - :authors : similar list of cons cells containing
      elfeed-score-authors-rule & stats structs

    - :mark : score below which entries shall be marked read"

  (let (mark titles feeds content tocs authors tags adj-tags)
    (dolist (raw-item sexp)
      (let ((key  (car raw-item))
            (rest (cdr raw-item)))
        (cond
         ((string= key "version")
          (unless (eq 6 (car rest))
            (error "Unsupported score file version %s" (car rest))))
         ((string= key "title")
          (setq
           titles
           (mapcar
            (lambda (plist)
              (elfeed-score-serde--plist-to-struct-6-7 plist 'elfeed-score-title-rule))
            rest)))
         ((string= key "content")
          (setq
           content
           (mapcar
            (lambda (plist)
              (elfeed-score-serde--plist-to-struct-6-7 plist 'elfeed-score-content-rule))
            rest)))
         ((string= key "feed")
          (setq
           feeds
           (mapcar
            (lambda (plist)
              (elfeed-score-serde--plist-to-struct-6-7 plist 'elfeed-score-feed-rule))
            rest)))
         ((string= key "title-or-content")
          (setq
           tocs
           (mapcar
            (lambda (plist)
              (elfeed-score-serde--plist-to-struct-6-7
               plist 'elfeed-score-title-or-content-rule))
            rest)))
         ((string= key "authors")
          (setq
           authors
           (mapcar
            (lambda (plist)
              (elfeed-score-serde--plist-to-struct-6-7 plist 'elfeed-score-authors-rule))
            rest)))
         ((string= key "tag")
          (setq
           tags
           (mapcar
            (lambda (plist)
              (elfeed-score-serde--plist-to-struct-6-7 plist 'elfeed-score-tag-rule))
            rest)))
         ((string= key "adjust-tags")
          (setq
           adj-tags
           (mapcar
            (lambda (plist)
              (elfeed-score-serde--plist-to-struct-6-7 plist 'elfeed-score-adjust-tags-rule))
            rest)))
         ((eq key 'mark)
          ;; set `mark' to (cdr rest) if (not mark) or (< mark (cdr rest))
          (let ((rest (car rest)))
            (if (or (not mark)
                    (< mark rest))
                (setq mark rest))))
         (t
          (error "Unknown score file key %s" key)))))
    (list
     :mark mark
     :adjust-tags adj-tags
     :feeds feeds
     :titles titles
     :content content
     :title-or-content tocs
     :authors authors
     :tag tags)))

(defun elfeed-score-serde--parse-scoring-sexp-7 (sexp)
  "Interpret the S-expression SEXP as scoring rules version 7.

Parse version 7 of the scoring S-expression.  Return a property list
with the following keys:

    - :title : list of cons cells each of whose car is an
      elfeed-score-title-rule struct & each of whose cdr is a
      stats struct

    - :content : similar list of cons cells containing
      elfeed-score-content-rule & stats structs

    - :title-or-content: similar list of cons cells containing
      elfeed-score-title-or-content-rule & stats structs

    - :feed : similar list of cons cells containing
      elfeed-score-feed-rule & stats structs

    - :tag : similar list of cons cells containing
      elfeed-score-tag-rule & stats structs

    - :adjust-tags : similar list of cons cells containing
      elfeed-score-adjust-tags-rule & stats structs

    - :authors : similar list of cons cells containing
      elfeed-score-authors-rule & stats structs

    - :link : similar list of cons cells containing
      elfeed-score-link-rule & stats structs

    - :mark : score below which entries shall be marked read"

  (let (mark titles feeds content tocs authors tags links adj-tags)
    (dolist (raw-item sexp)
      (let ((key  (car raw-item))
            (rest (cdr raw-item)))
        (cond
         ((string= key "version")
          (unless (eq 7 (car rest))
            (error "Unsupported score file version %s" (car rest))))
         ((string= key "title")
          (setq
           titles
           (mapcar
            (lambda (plist)
              (elfeed-score-serde--plist-to-struct-6-7 plist 'elfeed-score-title-rule))
            rest)))
         ((string= key "content")
          (setq
           content
           (mapcar
            (lambda (plist)
              (elfeed-score-serde--plist-to-struct-6-7 plist 'elfeed-score-content-rule))
            rest)))
         ((string= key "feed")
          (setq
           feeds
           (mapcar
            (lambda (plist)
              (elfeed-score-serde--plist-to-struct-6-7 plist 'elfeed-score-feed-rule))
            rest)))
         ((string= key "title-or-content")
          (setq
           tocs
           (mapcar
            (lambda (plist)
              (elfeed-score-serde--plist-to-struct-6-7
               plist 'elfeed-score-title-or-content-rule))
            rest)))
         ((string= key "authors")
          (setq
           authors
           (mapcar
            (lambda (plist)
              (elfeed-score-serde--plist-to-struct-6-7 plist 'elfeed-score-authors-rule))
            rest)))
         ((string= key "tag")
          (setq
           tags
           (mapcar
            (lambda (plist)
              (elfeed-score-serde--plist-to-struct-6-7 plist 'elfeed-score-tag-rule))
            rest)))
         ((string= key "link")
          (setq
           links
           (mapcar
            (lambda (plist)
              (elfeed-score-serde--plist-to-struct-6-7 plist 'elfeed-score-link-rule))
            rest)))
         ((string= key "adjust-tags")
          (setq
           adj-tags
           (mapcar
            (lambda (plist)
              (elfeed-score-serde--plist-to-struct-6-7 plist 'elfeed-score-adjust-tags-rule))
            rest)))
         ((eq key 'mark)
          ;; set `mark' to (cdr rest) if (not mark) or (< mark (cdr rest))
          (let ((rest (car rest)))
            (if (or (not mark)
                    (< mark rest))
                (setq mark rest))))
         (t
          (error "Unknown score file key %s" key)))))
    (list
     :mark mark
     :adjust-tags adj-tags
     :feeds feeds
     :titles titles
     :content content
     :title-or-content tocs
     :authors authors
     :tag tags
     :link links)))

(defun elfeed-score-serde--parse-scoring-sexp-8 (sexp)
  "Interpret the S-expression SEXP as scoring rules version 8 or 9.

Parse versions 8 & 9 of the scoring S-expression.  With version 8
of the score file format, the rule stats are stored separately,
so this file won't load them.  However, it will still return
lists of cons cells (with the cdr set to nil) to allow uniform
processing in our caller):

    - :title : list of cons cells each of whose car is an
      elfeed-score-title-rule struct & each of whose cdr is nil

    - :content : similar list of cons cells containing
      elfeed-score-content-rule structs

    - :title-or-content: similar list of cons cells containing
      elfeed-score-title-or-content-rule structs

    - :feed : similar list of cons cells containing
      elfeed-score-feed-rule structs

    - :tag : similar list of cons cells containing
      elfeed-score-tag-rule structs

    - :adjust-tags : similar list of cons cells containing
      elfeed-score-adjust-tags-rule structs

    - :authors : similar list of cons cells containing
      elfeed-score-authors-rule structs

    - :link : similar list of cons cells containing
      elfeed-score-link-rule structs

    - :mark : score below which entries shall be marked read"

  (let (mark titles feeds content tocs authors tags links adj-tags)
    (dolist (raw-item sexp)
      (let ((key  (car raw-item))
            (rest (cdr raw-item)))
        (cond
         ((string= key "version")
          (unless (or (eq 9 (car rest)) (eq 8 (car rest)))
            (error "Unsupported score file version %s" (car rest))))
         ((string= key "title")
          (setq
           titles
           (mapcar
            (lambda (plist)
              (list
               (elfeed-score-serde-plist-to-struct
                plist
                :type 'elfeed-score-title-rule
                :mandatory '(text value type))))
            rest)))
         ((string= key "content")
          (setq
           content
           (mapcar
            (lambda (plist)
              (list
               (elfeed-score-serde-plist-to-struct
                plist
                :type 'elfeed-score-content-rule
                :mandatory '(text value type))))
            rest)))
         ((string= key "feed")
          (setq
           feeds
           (mapcar
            (lambda (plist)
              (list
               (elfeed-score-serde-plist-to-struct
                plist
                :type 'elfeed-score-feed-rule
                :mandatory '(text value type attr))))
            rest)))
         ((string= key "title-or-content")
          (setq
           tocs
           (mapcar
            (lambda (plist)
              (list
               (elfeed-score-serde-plist-to-struct
                plist
                :type 'elfeed-score-title-or-content-rule
                :mandatory '(text title-value content-value type))))
            rest)))
         ((string= key "authors")
          (setq
           authors
           (mapcar
            (lambda (plist)
              (list
               (elfeed-score-serde-plist-to-struct
                plist
                :type 'elfeed-score-authors-rule
                :mandatory '(text value type))))
            rest)))
         ((string= key "tag")
          (setq
           tags
           (mapcar
            (lambda (plist)
              (list
               (elfeed-score-serde-plist-to-struct
                plist
                :type 'elfeed-score-tag-rule
                :mandatory '(tags value))))
            rest)))
         ((string= key "link")
          (setq
           links
           (mapcar
            (lambda (plist)
              (list
               (elfeed-score-serde-plist-to-struct
                plist
                :type 'elfeed-score-link-rule
                :mandatory '(text value type))))
            rest)))
         ((string= key "adjust-tags")
          (setq
           adj-tags
           (mapcar
            (lambda (plist)
              (list
               (elfeed-score-serde-plist-to-struct
                plist
                :type 'elfeed-score-adjust-tags-rule
                :mandatory '(threshold tags))))
            rest)))
         ((eq key 'mark)
          ;; set `mark' to (cdr rest) if (not mark) or (< mark (cdr rest))
          (let ((rest (car rest)))
            (if (or (not mark)
                    (< mark rest))
                (setq mark rest))))
         (t
          (error "Unknown score file key %s" key)))))
    (list
     :mark mark
     :adjust-tags adj-tags
     :feeds feeds
     :titles titles
     :content content
     :title-or-content tocs
     :authors authors
     :tag tags
     :link links)))

(defun elfeed-score-serde--parse-scoring-sexp-10 (sexp)
  "Interpret the S-expression SEXP as scoring rules version 10.

Parse version 10 of the scoring S-expression, which introduced
user-defined functions.  It continues to return lists of cons
cells (with the cdr set to nil) to allow uniform processing in
our caller):

    - :title : list of cons cells each of whose car is an
      elfeed-score-title-rule struct & each of whose cdr is nil

    - :content : similar list of cons cells containing
      elfeed-score-content-rule structs

    - :title-or-content: similar list of cons cells containing
      elfeed-score-title-or-content-rule structs

    - :feed : similar list of cons cells containing
      elfeed-score-feed-rule structs

    - :tag : similar list of cons cells containing
      elfeed-score-tag-rule structs

    - :adjust-tags : similar list of cons cells containing
      elfeed-score-adjust-tags-rule structs

    - :authors : similar list of cons cells containing
      elfeed-score-authors-rule structs

    - :link : similar list of cons cells containing
      elfeed-score-link-rule structs

    - :udf : similar list of cons cells containing
      elfeed-score-udf-rule structs

    - :mark : score below which entries shall be marked read"

  (let (mark titles feeds content tocs authors tags links udfs adj-tags)
    (dolist (raw-item sexp)
      (let ((key  (car raw-item))
            (rest (cdr raw-item)))
        (cond
         ((string= key "version")
          (unless (eq 10 (car rest))
            (error "Unsupported score file version %s" (car rest))))
         ((string= key "title")
          (setq
           titles
           (mapcar
            (lambda (plist)
              (list
               (elfeed-score-serde-plist-to-struct
                plist
                :type 'elfeed-score-title-rule
                :mandatory '(text value type))))
            rest)))
         ((string= key "content")
          (setq
           content
           (mapcar
            (lambda (plist)
              (list
               (elfeed-score-serde-plist-to-struct
                plist
                :type 'elfeed-score-content-rule
                :mandatory '(text value type))))
            rest)))
         ((string= key "feed")
          (setq
           feeds
           (mapcar
            (lambda (plist)
              (list
               (elfeed-score-serde-plist-to-struct
                plist
                :type 'elfeed-score-feed-rule
                :mandatory '(text value type attr))))
            rest)))
         ((string= key "title-or-content")
          (setq
           tocs
           (mapcar
            (lambda (plist)
              (list
               (elfeed-score-serde-plist-to-struct
                plist
                :type 'elfeed-score-title-or-content-rule
                :mandatory '(text title-value content-value type))))
            rest)))
         ((string= key "authors")
          (setq
           authors
           (mapcar
            (lambda (plist)
              (list
               (elfeed-score-serde-plist-to-struct
                plist
                :type 'elfeed-score-authors-rule
                :mandatory '(text value type))))
            rest)))
         ((string= key "tag")
          (setq
           tags
           (mapcar
            (lambda (plist)
              (list
               (elfeed-score-serde-plist-to-struct
                plist
                :type 'elfeed-score-tag-rule
                :mandatory '(tags value))))
            rest)))
         ((string= key "link")
          (setq
           links
           (mapcar
            (lambda (plist)
              (list
               (elfeed-score-serde-plist-to-struct
                plist
                :type 'elfeed-score-link-rule
                :mandatory '(text value type))))
            rest)))
         ((string= key "udf")
          (setq
           udfs
           (mapcar
            (lambda (plist)
              (list
               ;; (elfeed-score-serde-plist-to-struct
               ;;  plist
               ;;  :type 'elfeed-score-udf-rule
               ;;  :mandatory '(function))
               (elfeed-score-udf-rule--create
                :function (plist-get plist :function)
                :display-name (plist-get plist :display-name)
                :tags (plist-get plist :tags)
                :feeds (plist-get plist :feeds)
                :comment (plist-get plist :comment))))
            rest)))
         ((string= key "adjust-tags")
          (setq
           adj-tags
           (mapcar
            (lambda (plist)
              (list
               (elfeed-score-serde-plist-to-struct
                plist
                :type 'elfeed-score-adjust-tags-rule
                :mandatory '(threshold tags))))
            rest)))
         ((eq key 'mark)
          ;; set `mark' to (cdr rest) if (not mark) or (< mark (cdr rest))
          (let ((rest (car rest)))
            (if (or (not mark)
                    (< mark rest))
                (setq mark rest))))
         (t
          (error "Unknown score file key %s" key)))))
    (list
     :mark mark
     :adjust-tags adj-tags
     :feeds feeds
     :titles titles
     :content content
     :title-or-content tocs
     :authors authors
     :tag tags
     :link links
     :udf udfs)))

(defun elfeed-score-serde--parse-version (sexps)
  "Retrieve the version attribute from SEXPS."
  (cond
   ((assoc 'version sexps)
    (cadr (assoc 'version sexps)))
   ((assoc "version" sexps)
    (cadr (assoc "version" sexps)))
   (t
    ;; I'm going to assume this is a new, hand-authored scoring
    ;; file, and attempt to parse it according to the latest
    ;; version spec.
    elfeed-score-serde-current-format)))

(defun elfeed-score-serde--parse-scoring-sexp (sexps)
  "Parse raw S-expressions (SEXPS) into scoring rules."
  (let ((version (elfeed-score-serde--parse-version sexps)))
    ;; I use `cl-delete' instead of `assoc-delete-all' because the
    ;; latter would entail a dependency on Emacs 26.2, which I would
    ;; prefer not to do.
    (cl-delete "version" sexps :test 'equal :key 'car)
    (cl-delete 'version sexps :test 'equal :key 'car)
    (cond
     ((eq version 1)
      (elfeed-score-serde--parse-scoring-sexp-1 sexps))
     ((eq version 2)
      (elfeed-score-serde--parse-scoring-sexp-2 sexps))
     ((eq version 3)
      (elfeed-score-serde--parse-scoring-sexp-3 sexps))
     ((eq version 4)
      (elfeed-score-serde--parse-scoring-sexp-4 sexps))
     ((eq version 5)
      ;; This is not a typo-- I want to call
      ;; `elfeed-score-serde--parse-scoring-sexp-4' even when the score file
      ;; format is 5.  The difference in the two formats is that
      ;; version 5 adds new fields to the end of several rule types;
      ;; the first-level structure of the s-expression doesn't
      ;; change.  So if an old version of `elfeed-score' tried to read
      ;; version 5, it wouldn't encounter an error, it would just
      ;; silently ignore those new fields. I don't think this is what
      ;; the user would want (especially since their new attributes
      ;; would be lost the first time their old `elfeed-score' writes
      ;; out their scoring rules), so I bumped the version to 5 (to
      ;; keep old versions from even trying to read it) but I can
      ;; still use the same first-level parsing logic.
      (elfeed-score-serde--parse-scoring-sexp-4 sexps))
     ((eq version 6)
      (elfeed-score-serde--parse-scoring-sexp-6 sexps))
     ((eq version 7)
      (elfeed-score-serde--parse-scoring-sexp-7 sexps))
     ((eq version 8)
      (elfeed-score-serde--parse-scoring-sexp-8 sexps))
     ;; Again not a typo-- version 9 adds a new optional field
     ;; (:comment) to the end of each struct type; so old versions of
     ;; elfeed-score will silently ignore, which I don't think we
     ;; want.
     ((eq version 9)
      (elfeed-score-serde--parse-scoring-sexp-8 sexps))
     ((eq version elfeed-score-serde-current-format)
      (elfeed-score-serde--parse-scoring-sexp-10 sexps))
     (t
      (error "Unknown version %s" version)))))

(defun elfeed-score-serde--parse-score-file (score-file)
  "Parse SCORE-FILE.

Internal.  This is the core score file parsing routine.  Opens
SCORE-FILE, reads the contents as a Lisp form, and parses that
into a property list with the following properties:

    - :content
    - :feeds
    - :authors
    - :mark
    - :titles
    - :adjust-tags
    - :title-or-content
    - :tags
    - :links
    - :udf
    - :version"

  (let* ((sexp
          (car
           (read-from-string
            (with-temp-buffer
              (insert-file-contents score-file)
              (buffer-string)))))
         (version (elfeed-score-serde--parse-version sexp)))
    (unless (eq version elfeed-score-serde-current-format)
      (let ((backup-name (format "%s.~%d~" score-file version)))
        (message "elfeed-score will upgrade your score file to version %d; \
a backup file will be left in %s."
                 elfeed-score-serde-current-format backup-name)
        (condition-case
         data
         (copy-file score-file backup-name)
         (error
          (message "Tried to backup your score file to %s but failed: %s."
                   backup-name (cadr data))))))
    (plist-put (elfeed-score-serde--parse-scoring-sexp sexp) :version version)))

(defvar elfeed-score-serde--last-load-time nil
  "Last score file load time.

The time at which the in-memory rules were most recently loaded
from score file, expressed as the number of seconds since Unix
epoch (float).")

(defun elfeed-score-serde-load-score-file (score-file)
  "Load SCORE-FILE into our internal scoring rules.

Read SCORE-FILE, store scoring rules into
`elfeed-score-serde-*-rules'.  If SCORE-FILE is in an archaic
format (which is to say its version is less than
`elfeed-score-serde-current-format') SCORE-FILE will be upgraded
to the current format.  A backup will be left in the same
directory, and the file will be re-written in the most recent
format."

  ;; The need to support all former serialization formats has
  ;; complicated this method considerably.  We begin by parsing
  ;; SCORE-FILE into a property list.  Outside of :version & :mark,
  ;; each property is a list of cons cells.  This odd format is due to
  ;; the fact that prior to score file version 8, rule stats were
  ;; stored in the score file alongside the rules themselves.  Today,
  ;; they're stored separately, but we have to handle both cases.

  ;; Consequently, the parsing routine returns lists of cons cells. In
  ;; all cases, the car of each cell will point to a scoring rule.  If
  ;; SCORE-FILE is in a version less than 8, the cdr will point to the
  ;; stats struct we created therefrom. In 8 & above, the cdr will
  ;; just be nil.

  (let ((entries (elfeed-score-serde--parse-score-file score-file)))
    (setq elfeed-score-serde-score-mark             (plist-get entries :mark)
          elfeed-score-serde-title-rules            (cl-mapcar #'car (plist-get entries :titles))
          elfeed-score-serde-feed-rules             (cl-mapcar #'car (plist-get entries :feeds))
          elfeed-score-serde-content-rules          (cl-mapcar #'car (plist-get entries :content))
          elfeed-score-serde-title-or-content-rules (cl-mapcar #'car (plist-get entries :title-or-content))
          elfeed-score-serde-tag-rules              (cl-mapcar #'car (plist-get entries :tag))
          elfeed-score-serde-authors-rules          (cl-mapcar #'car (plist-get entries :authors))
          elfeed-score-serde-link-rules             (cl-mapcar #'car (plist-get entries :link))
          elfeed-score-serde-udf-rules              (cl-mapcar #'car (plist-get entries :udf))
          elfeed-score-serde-adjust-tags-rules      (cl-mapcar #'car (plist-get entries :adjust-tags)))
    ;; & update the stats.
    (cl-mapcar
     (lambda (cell) (if (cdr cell) (elfeed-score-rule-stats-set (car cell) (cdr cell))))
     (plist-get entries :titles))
    (cl-mapcar
     (lambda (cell) (if (cdr cell) (elfeed-score-rule-stats-set (car cell) (cdr cell))))
     (plist-get entries :feeds))
    (cl-mapcar
     (lambda (cell) (if (cdr cell) (elfeed-score-rule-stats-set (car cell) (cdr cell))))
     (plist-get entries :content))
    (cl-mapcar
     (lambda (cell) (if (cdr cell) (elfeed-score-rule-stats-set (car cell) (cdr cell))))
     (plist-get entries :title-or-content))
    (cl-mapcar
     (lambda (cell) (if (cdr cell) (elfeed-score-rule-stats-set (car cell) (cdr cell))))
     (plist-get entries :tag))
    (cl-mapcar
     (lambda (cell) (if (cdr cell) (elfeed-score-rule-stats-set (car cell) (cdr cell))))
     (plist-get entries :authors))
    (cl-mapcar
     (lambda (cell) (if (cdr cell) (elfeed-score-rule-stats-set (car cell) (cdr cell))))
     (plist-get entries :link))
    (cl-mapcar
     (lambda (cell) (if (cdr cell) (elfeed-score-rule-stats-set (car cell) (cdr cell))))
     (plist-get entries :udf))
    (cl-mapcar
     (lambda (cell) (if (cdr cell) (elfeed-score-rule-stats-set (car cell) (cdr cell))))
     (plist-get entries :adjust-tags))
    ;; If this is an upgrade in file format; re-write the score file in the new
    ;; format right away (https://github.com/sp1ff/elfeed-score/issues/12)
    (unless (eq elfeed-score-serde-current-format (plist-get entries :version))
      (elfeed-score-serde-write-score-file score-file))
    ;; Note the file modification time
    (setq
     elfeed-score-serde--last-load-time
     (float-time (file-attribute-modification-time (file-attributes score-file))))))

(defun elfeed-score-serde-tag-for-rule (rule)
  "Return the score file tag corresponding to RULE."
  (cl-typecase rule
    (elfeed-score-title-rule            "title")
    (elfeed-score-feed-rule             "feed")
    (elfeed-score-content-rule          "content")
    (elfeed-score-title-or-content-rule "title-or-content")
    (elfeed-score-authors-rule          "authors")
    (elfeed-score-tag-rule              "tag")
    (elfeed-score-link-rule             "link")
    (elfeed-score-udf-explanation       "udf")
    (t
     (error "Unknown rule type %s" rule))))

(defun elfeed-score-serde-tag-for-explanation (explanation)
  "Return the score file tag corresponding to EXPLANATION."
  (cl-typecase explanation
    (elfeed-score-title-explanation            "title")
    (elfeed-score-feed-explanation             "feed")
    (elfeed-score-content-explanation          "content")
    (elfeed-score-title-or-content-explanation "title-or-content")
    (elfeed-score-authors-explanation          "authors")
    (elfeed-score-tags-explanation             "tag")
    (elfeed-score-link-explanation             "link")
    (elfeed-score-udf-explanation              "udf")
    (t
     (error "Unknown explanation type %s" explanation))))

(defun elfeed-score-serde-score-file-dirty-p ()
  "Return t if the score file has been modified since last loaded.

If the score file has never been loaded this function will return t."
  (and elfeed-score-serde-score-file
       (> (float-time
           (file-attribute-modification-time
            (file-attributes elfeed-score-serde-score-file)))
          (or elfeed-score-serde--last-load-time 0.0))))

(defun elfeed-score-serde-write-score-file (score-file)
  "Write the current scoring rules to SCORE-FILE."
  (interactive
   (list
    (read-file-name "score file: " nil elfeed-score-score-file t
                    elfeed-score-score-file)))
  (elfeed-score-rule-stats--sexp-to-file
   (list
    (list 'version elfeed-score-serde-current-format)
    (append
     '("title")
     (mapcar
      #'elfeed-score-serde-struct-to-plist
      elfeed-score-serde-title-rules))
    (append
     '("content")
     (mapcar
      #'elfeed-score-serde-struct-to-plist
      elfeed-score-serde-content-rules))
    (append
     '("title-or-content")
     (mapcar
      #'elfeed-score-serde-struct-to-plist
      elfeed-score-serde-title-or-content-rules))
    (append
     '("tag")
     (mapcar
      #'elfeed-score-serde-struct-to-plist
      elfeed-score-serde-tag-rules))
    (append
     '("authors")
     (mapcar
      #'elfeed-score-serde-struct-to-plist
      elfeed-score-serde-authors-rules))
    (append
     '("feed")
     (mapcar
      #'elfeed-score-serde-struct-to-plist
      elfeed-score-serde-feed-rules))
    (append
     '("link")
     (mapcar
      #'elfeed-score-serde-struct-to-plist
      elfeed-score-serde-link-rules))
    (append
     '("udf")
     (mapcar
      #'elfeed-score-serde-struct-to-plist
      elfeed-score-serde-udf-rules))
    (list 'mark elfeed-score-serde-score-mark)
    (append
     '("adjust-tags")
     (mapcar
      #'elfeed-score-serde-struct-to-plist
      elfeed-score-serde-adjust-tags-rules)))
   score-file
   ";;; Elfeed score file                                     -*- lisp -*-\n"))

(defun elfeed-score-serde-cleanup-stats ()
  "Remove any stats that are no longer relevant.

The hash table in which we store rule statistics can become
out-of-date as the set of rules changes, in that the hash table
may contain entries for rules that no longer exist.  That is
generally harmless, inasmuch as it won't produce incorrect
behavior.  Any operation that depends on the hash table having no
stale entries, however, should invoke this method first to
guarantee that.  Additionally, this method should be invoked
periodically simply to prevent the hash table from growing
without bound."

  (elfeed-score-rule-stats-clean
   (append
    elfeed-score-serde-title-rules
    elfeed-score-serde-feed-rules
    elfeed-score-serde-authors-rules
    elfeed-score-serde-content-rules
    elfeed-score-serde-title-or-content-rules
    elfeed-score-serde-tag-rules
    elfeed-score-serde-link-rules
    elfeed-score-serde-udf-rules
    elfeed-score-serde-adjust-tags-rules)))

(defun elfeed-score-serde-add-rule (rule)
  "Add RULE to the current set of scoring rules.

Add RULE to the appropriate list of scoring rules.  If
`elfeed-score-serde-score-file' is non-nil, check that the file
it names has not been modified since we last read it-- if it has
been refuse to update the in-memory rule set.  Otherwise, update
the in-memory rules & re-write the score file."

  ;; If `elfeed-score-serde-score-file' is non-nil, check to see if
  ;; it's been modified since we last loaded it.
  (if (elfeed-score-serde-score-file-dirty-p)
      (error
       (concat "%s has been modified since last loaded (or was never loaded "
               "in the first place); either re-load it or move it out of "
               "the way")
       elfeed-score-serde-score-file))
  ;; Update the relevant list
  (cl-typecase rule
    (elfeed-score-title-rule
     (setq
      elfeed-score-serde-title-rules
      (cons rule elfeed-score-serde-title-rules)))
    (elfeed-score-feed-rule
     (setq
      elfeed-score-serde-feed-rules
      (cons rule elfeed-score-serde-feed-rules)))
    (elfeed-score-content-rule
     (setq
      elfeed-score-serde-content-rules
      (cons rule elfeed-score-serde-content-rules)))
    (elfeed-score-title-or-content-rule
     (setq
      elfeed-score-serde-title-or-content-rules
      (cons rule elfeed-score-serde-title-or-content-rules)))
    (elfeed-score-authors-rule
     (setq
      elfeed-score-serde-authors-rules
      (cons rule elfeed-score-serde-authors-rules)))
    (elfeed-score-tag-rule
     (setq
      elfeed-score-serde-tag-rules
      (cons rule elfeed-score-serde-tag-rules)))
    (elfeed-score-link-rule
     (setq
      elfeed-score-serde-link-rules
      (cons rule elfeed-score-serde-link-rules)))
    (elfeed-score-udf-rule
     (setq
      elfeed-score-serde-udf-rules
      (cons rule elfeed-score-serde-udf-rules)))
    (t
     (error "Unknown rule type %s" rule)))
  ;; Now write out the new score file & update
  ;; `elfeed-score-serde--last-load-time'.
  (if elfeed-score-serde-score-file
      (progn
        (elfeed-score-serde-write-score-file elfeed-score-serde-score-file)
        (setq
         elfeed-score-serde--last-load-time
         (float-time (file-attribute-modification-time
                      (file-attributes elfeed-score-serde-score-file)))))))

(provide 'elfeed-score-serde)
;;; elfeed-score-serde.el ends here
