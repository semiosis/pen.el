;;; elfeed-score-scoring.el --- Logic for scoring (and explaining) `elfeed' entries  -*- lexical-binding: t; -*-

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

;; Scoring logic for `elfeed-score'.

;;; Code:

(require 'elfeed-search)
(require 'elfeed-score-log)
(require 'elfeed-score-rules)
(require 'elfeed-score-rule-stats)
(require 'elfeed-score-serde)

(defface elfeed-score-scoring-explain-text-face
  '((t :inherit font-lock-comment-face))
  "Face for showing the match text in the explanation buffer."
  :group 'elfeed-score)

(defcustom elfeed-score-scoring-default-score 0
  "Default score for an Elfeed entry."
  :group 'elfeed-score
  :type 'int)

(defcustom elfeed-score-scoring-meta-keyword :elfeed-score/score
  "Default keyword for storing scores in Elfeed entry metadata."
  :group 'elfeed-score
  :type 'symbol)

(defcustom elfeed-score-scoring-meta-sticky-keyword :elfeed-score/sticky
  "Default keyword for marking scores as sticky in Elfeed entry metadata."
  :group 'elfeed-score
  :type 'symbol)

(defcustom elfeed-score-scoring-explanation-buffer-name
  "*elfeed-score-explanations*"
  "Name of the buffer to be used for scoring explanations."
  :group 'elfeed-score
  :type 'string)

(defcustom elfeed-score-scoring-manual-is-sticky
  t
  "Set to nil to make manual scores \"sticky\".

If t, scores set manually will not be overwritten by subsequent
scoring operations.  If nil, they will be (i.e. the behavior
prior to 0.7.9."
  :group 'elfeed-score
  :type 'boolean)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                        utility functions                         ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun elfeed-score-scoring-entry-is-sticky (entry)
  "Retrieve the \"sticky\" attribute from ENTRY."
  (elfeed-meta entry elfeed-score-scoring-meta-sticky-keyword))

(defun elfeed-score-scoring-set-score-on-entry (entry score &optional sticky)
  "Set the score on ENTRY to SCORE (perhaps making it STICKY).

This is the one location in `elfeed-score' that actually
manipulates scoring-related metadata on Elfeed entries.

Scores may optionally be \"sticky\": if the caller marks this
entry's score as such, subsequent invocations of this method will
be ignored unless & until `sticky' is again set to t by the
caller.  The intent of this (somewhat non-obvious) contract is to
enable manually applied scores to avoid being overwritten by
subsequent \"bulk\" operations like scoring an entire view."

  (let ((score-was-set nil))
    ;; | s\f | nil           | t                                                 |
    ;; |-----+---------------+---------------------------------------------------|
    ;; | nil | set the score | set the score *unless* the extant score is sticky |
    ;; | t   | set the score | set the score *and* mark it as sticky             |
    ;; "s\f" denotes "sticky param\feature flag"

    (if elfeed-score-scoring-manual-is-sticky
        (if sticky
            (progn
              (setf (elfeed-meta entry elfeed-score-scoring-meta-keyword) score)
              (setf (elfeed-meta entry elfeed-score-scoring-meta-sticky-keyword) t)
              (setq score-was-set t))
          (if (elfeed-meta entry elfeed-score-scoring-meta-sticky-keyword)
              (elfeed-score-log 'info "Not scoring %s(\"%s\") as %d because it already has a sticky score of %d."
                                (elfeed-entry-id entry) (elfeed-entry-title entry) score
                                (elfeed-meta entry elfeed-score-scoring-meta-keyword))
            (progn
              (setf (elfeed-meta entry elfeed-score-scoring-meta-keyword) score)
              (setq score-was-set t))))
      (progn
        (setf (elfeed-meta entry elfeed-score-scoring-meta-keyword) score)
        (setq score-was-set t)))
    (if score-was-set
        (elfeed-score-log 'info "entry %s('%s') has been given a score of %d"
                          (elfeed-entry-id entry) (elfeed-entry-title entry) score))))

(defun elfeed-score-scoring-get-score-from-entry (entry)
  "Retrieve the score from ENTRY."
  (elfeed-meta entry elfeed-score-scoring-meta-keyword elfeed-score-scoring-default-score))

(defun elfeed-score-scoring--match-text (match-text search-text match-type)
  "Test SEARCH-TEXT against MATCH-TEXT according to MATCH-TYPE.
Return nil on failure, the matched text on match."
  (cond
   ((or (eq match-type 's)
        (eq match-type 'S))
    (let ((case-fold-search (eq match-type 's)))
      (if (string-match (regexp-quote match-text) search-text)
          (match-string 0 search-text)
        nil)))
   ((or (eq match-type 'r)
        (eq match-type 'R)
        (not match-type))
    (let ((case-fold-search (eq match-type 'r)))
      (if (string-match match-text search-text)
          (match-string 0 search-text)
        nil)))
   ((or (eq match-type 'w)
        (eq match-type 'W))
    (let ((case-fold-search (eq match-type 'w)))
      (if  (string-match (word-search-regexp match-text) search-text)
          (match-string 0 search-text))))
   (t
    (error "Unknown match type %s" match-type))))

(defun elfeed-score-scoring--match-tags (entry-tags tag-rule)
  "Test a ENTRY-TAGS against TAG-RULE.

ENTRY-TAGS shall be a list of symbols, presumably the tags applied to the Elfeed
entry being scored.  TAG-RULE shall be a list of the form (boolean . (symbol...))
or nil, and is presumably a tag scoping for a scoring rule."

  (if tag-rule
      (let ((flag (car tag-rule))
            (rule-tags (cdr tag-rule))
            (apply nil))
        ;; Special case allowing this method to be called like (... (t . symbol))
        (if (symbolp rule-tags)
            (setq rule-tags (list rule-tags)))
        (while (and rule-tags (not apply))
          (if (memq (car rule-tags) entry-tags)
              (setq apply t))
          (setq rule-tags (cdr rule-tags)))
        (if flag
            apply
          (not apply)))
    t))

(defun elfeed-score-scoring--get-feed-attr (feed attr)
  "Retrieve attribute ATTR from FEED."
  (cond
   ((eq attr 't) (elfeed-feed-title feed))
   ((eq attr 'u) (elfeed-feed-url feed))
   ((eq attr 'a) (elfeed-feed-author feed))
   (t (error "Unknown feed attribute %s" attr))))

(defun elfeed-score-scoring--match-feeds (entry-feed feed-rule)
  "Test ENTRY-FEED against FEED-RULE.

ENTRY-FEED shall be an <elfeed-feed> instance.  FEED-RULE shall
be a list of the form (BOOLEAN (ATTR TYPE TEXT)...), or nil, and
is presumably the feed scoping for a scoring rule."

  (if feed-rule
      (let ((flag (car feed-rule))
            (rule-feeds (cdr feed-rule))
            (match))
        ;; Special case allowing this method to be called like (... (t 't 's "title))
        (if (symbolp (car rule-feeds))
            (setq rule-feeds (list rule-feeds)))
        (while (and rule-feeds (not match))
          (let* ((feed (car rule-feeds))
                 (attr (nth 0 feed))
                 (match-type (nth 1 feed))
                 (match-text (nth 2 feed))
                 (feed-text (elfeed-score-scoring--get-feed-attr entry-feed attr)))
            (if (elfeed-score-scoring--match-text match-text feed-text match-type)
                (setq match t)))
          (setq rule-feeds (cdr rule-feeds)))
        (if flag match (not match)))
    t))

(defun elfeed-score-scoring--concatenate-authors (authors-list)
  "Given AUTHORS-LIST, list of plists; return string of all authors concatenated."
  (mapconcat (lambda (author) (plist-get author :name)) authors-list ", "))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                  ;;
;;                   rule-specific scoring logic                    ;;
;;                                                                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Each scoring rule type TYPE corresponds to three functions: the
;; 'score', the 'explain' & the 'apply' functions. The 'score'
;; function takes an Elfeed entry & computes its core according to the
;; list of rules of type TYPE. The 'explain' function takes an entry
;; and returns a list of explanations for all the rules of type TYPE
;; that match. The 'apply' function contains the common logic for
;; iterating over the list of rules of type TYPE & determining which
;; instances match.

;; Several rule types share the same essential template: they match
;; against some textual attribute of each entry & they may be scoped
;; by tags and/or feed. This macro expands to definitions of all three
;; functions for a given rule type.

(defmacro elfeed-score-scoring--defuns (name &rest args)
  "Define scoring functions for rules named NAME; keyword ARGS defined below.

Define the 'score', 'explain' & 'apply' functions for a rule named NAME."

  (declare (indent defun))
  (let ((apply-fn (intern (format "elfeed-score-scoring--apply-%s-rules" name)))
	      (explain-fn (intern (format "elfeed-score-scoring--explain-%s" name)))
	      (score-fn (intern (format "elfeed-score-scoring--score-on-%s" name)))
	      (entry-attr-getter (plist-get args :entry-attribute))
	      (rule-list  (plist-get args :rule-list))
	      (rule-text  (plist-get args :rule-text))
	      (rule-type  (plist-get args :rule-type))
	      (rule-tags  (plist-get args :rule-tags))
	      (rule-feeds (plist-get args :rule-feeds))
	      (rule-value (plist-get args :rule-value))
        (explanation-ctor (plist-get args :explain-ctor)))
    `(progn
       (defun ,apply-fn (entry on-match)
	       (let ((attr
		            ,(if (symbolp entry-attr-getter)
		                 (list entry-attr-getter 'entry)
		               (list 'funcall entry-attr-getter 'entry))))
           (if attr
               (cl-loop for rule being the elements of ,rule-list using (index idx)
                        do
                        (let* ((match-text (,rule-text  rule))
		                           (match-type (,rule-type  rule))
		                           (tags-rule  (,rule-tags  rule))
		                           (feeds-rule (,rule-feeds rule))
		                           (matched-text
		                            (and
		                             (elfeed-score-scoring--match-tags
                                  (elfeed-entry-tags entry) tags-rule)
		                             (elfeed-score-scoring--match-feeds
                                  (elfeed-entry-feed entry) feeds-rule)
		                             (elfeed-score-scoring--match-text
                                  match-text attr match-type))))
	                        (if matched-text (funcall on-match rule matched-text idx)))))))
       (defun ,explain-fn (entry)
         (let ((hits '()))
           (,apply-fn
            entry
            (lambda (rule matched-text index)
              (setq
               hits
               (cons
                (,explanation-ctor :matched-text matched-text :rule rule :index index)
                hits))))
           hits))
       (defun ,score-fn (entry)
         (let ((score elfeed-score-scoring-default-score))
           (,apply-fn
            entry
            (lambda (rule matched-text _index)
              (let* ((value (,rule-value rule)))
                (elfeed-score-log
                 'debug
                 "%s rule '%s' matched text '%s' for entry %s('%s); \
adding %d to its score"
                 ,name (elfeed-score-rules-pp-rule-to-string rule)
                 matched-text (elfeed-entry-id entry)
                 (elfeed-entry-title entry) value)
                (setq score (+ score value))
                (elfeed-score-rule-stats-on-match rule))))
           score)))))

(elfeed-score-scoring--defuns
  "title"
  :entry-attribute elfeed-entry-title
  :rule-list elfeed-score-serde-title-rules
  :rule-text elfeed-score-title-rule-text
  :rule-type elfeed-score-title-rule-type
  :rule-tags elfeed-score-title-rule-tags
  :rule-feeds elfeed-score-title-rule-feeds
  :rule-value elfeed-score-title-rule-value
  :explain-ctor elfeed-score-make-title-explanation)

(elfeed-score-scoring--defuns
  "content"
  :entry-attribute (lambda (x) (elfeed-deref (elfeed-entry-content x)))
  :rule-list elfeed-score-serde-content-rules
  :rule-text elfeed-score-content-rule-text
  :rule-type elfeed-score-content-rule-type
  :rule-tags elfeed-score-content-rule-tags
  :rule-feeds elfeed-score-content-rule-feeds
  :rule-value elfeed-score-content-rule-value
  :explain-ctor elfeed-score-make-content-explanation)

(elfeed-score-scoring--defuns
 "authors"
 :entry-attribute (lambda (x)
                    (elfeed-score-scoring--concatenate-authors
                     (elfeed-meta x :authors)))
 :rule-list elfeed-score-serde-authors-rules
 :rule-text elfeed-score-authors-rule-text
 :rule-type elfeed-score-authors-rule-type
 :rule-tags elfeed-score-authors-rule-tags
 :rule-feeds elfeed-score-authors-rule-feeds
 :rule-value elfeed-score-authors-rule-value
 :explain-ctor elfeed-score-make-authors-explanation)

(elfeed-score-scoring--defuns
  "link"
  :entry-attribute elfeed-entry-link
  :rule-list elfeed-score-serde-link-rules
  :rule-text elfeed-score-link-rule-text
  :rule-type elfeed-score-link-rule-type
  :rule-tags elfeed-score-link-rule-tags
  :rule-feeds elfeed-score-link-rule-feeds
  :rule-value elfeed-score-link-rule-value
  :explain-ctor elfeed-score-make-link-explanation)

;; The remaining rule types are slightly different & I haven't figured
;; out how to reduce the amount of code duplication, yet.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                            feed rules                            ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun elfeed-score-scoring--apply-feed-rules (entry on-match)
  "Run all feed rules against ENTRY; invoke ON-MATCH for each match.

ON-MATCH will be invoked with the applicable rule as well as the matched text."
  (let ((feed (elfeed-entry-feed  entry)))
    (cl-loop for rule being the elements of elfeed-score-serde-feed-rules using (index idx)
             do
             (let* ((match-text   (elfeed-score-feed-rule-text rule))
		                (match-type   (elfeed-score-feed-rule-type rule))
                    (attr         (elfeed-score-feed-rule-attr rule))
                    (feed-text    (elfeed-score-scoring--get-feed-attr feed attr))
                    (tag-rule     (elfeed-score-feed-rule-tags rule))
                    (matched-text
                     (and
                      (elfeed-score-scoring--match-tags (elfeed-entry-tags entry) tag-rule)
                      (elfeed-score-scoring--match-text match-text feed-text match-type))))
               (if matched-text (funcall on-match rule matched-text idx))))))

(defun elfeed-score-scoring--explain-feed (entry)
  "Apply the feed scoring rules to ENTRY, return an explanation.

The explanation will be a list of two-tuples (i.e. a list with
two elements), one for each rule that matches.  The first element
will be the rule that matched & the second the matched text."
  (let ((hits '()))
    (elfeed-score-scoring--apply-feed-rules
     entry
     (lambda (rule match-text index)
       (setq
        hits
        (cons
         (elfeed-score-make-feed-explanation :matched-text match-text :rule rule
                                             :index index)
         hits))))
    hits))

(defun elfeed-score-scoring--score-on-feed (entry)
  "Run all feed scoring rules against ENTRY; return the summed values."
  (let ((score 0))
    (elfeed-score-scoring--apply-feed-rules
     entry
     (lambda (rule match-text _index)
       (let ((value (elfeed-score-feed-rule-value rule)))
         (elfeed-score-log
          'debug
          "feed rule '%s' matched text '%s' for entry %s('%s'); \
adding %d to its score"
          (elfeed-score-rules-pp-rule-to-string rule)
          match-text
          (elfeed-entry-id entry)
          (elfeed-entry-title entry) value)
		     (setq score (+ score value))
         (elfeed-score-rule-stats-on-match rule))))
    score))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                      title-or-content rules                      ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun elfeed-score-scoring--apply-title-or-content-rules (entry on-match)
  "Apply the title-or-content rules to ENTRY; invoke ON-MATCH for each match.

ON-MATCH will be invoked with the matching rule, the matched
text, and a boolean value indicating whether this is a title
match (t) or a content match (nil)."

  (let ((title (elfeed-entry-title entry))
        (content (elfeed-deref (elfeed-entry-content entry))))
    (cl-loop for rule being the elements of elfeed-score-serde-title-or-content-rules
             using (index idx)
             do
             (let* ((match-text    (elfeed-score-title-or-content-rule-text  rule))
		                (match-type    (elfeed-score-title-or-content-rule-type  rule))
                    (tag-rule      (elfeed-score-title-or-content-rule-tags  rule))
                    (feed-rule     (elfeed-score-title-or-content-rule-feeds rule))
                    (matched-tags  (elfeed-score-scoring--match-tags
                                    (elfeed-entry-tags entry) tag-rule))
                    (matched-feeds (elfeed-score-scoring--match-feeds
                                    (elfeed-entry-feed entry) feed-rule))
                    (matched-title
                     (and
                      matched-tags
                      matched-feeds
                      (elfeed-score-scoring--match-text match-text title match-type)))
                    (matched-content
                     (and
                      content
                      matched-tags
                      matched-feeds
                      (elfeed-score-scoring--match-text match-text content match-type)))
                    (got-title-match (and matched-tags matched-feeds matched-title))
                    (got-content-match (and content matched-tags matched-feeds
                                            matched-content)))
               (if got-title-match (funcall on-match rule matched-title t idx))
               (if got-content-match (funcall on-match rule matched-content nil idx))))))

(defun elfeed-score-scoring--explain-title-or-content (entry)
  "Apply the title-or-content scoring rules to ENTRY, return an explanation.

The explanation is a list of three-tuples: rule, matched text, t
for a title match & nil for a content match."
  (let ((hits '()))
    (elfeed-score-scoring--apply-title-or-content-rules
     entry
     (lambda (rule match-text title-match index)
       (setq
        hits
        (cons
         (elfeed-score-make-title-or-content-explanation
          :matched-text match-text :rule rule :attr (if title-match 't 'c)
          :index index)
         hits))))
    hits))

(defun elfeed-score-scoring--score-on-title-or-content (entry)
  "Run all title-or-content rules against ENTRY; return the summed values."
  (let ((score elfeed-score-scoring-default-score))
    (elfeed-score-scoring--apply-title-or-content-rules
     entry
     (lambda (rule match-text title-match _index)
       (if title-match
           (let ((value (elfeed-score-title-or-content-rule-title-value rule)))
             (elfeed-score-log 'debug "title-or-content rule '%s' matched text\
 '%s' in the title of entry '%s'; adding %d to its score"
                               (elfeed-score-rules-pp-rule-to-string rule)
                               match-text (elfeed-entry-id entry) value)
		         (setq score (+ score value))
             (elfeed-score-rule-stats-on-match rule))
         (let ((value (elfeed-score-title-or-content-rule-content-value rule)))
           (elfeed-score-log 'debug "title-or-content rule '%s' matched text\
 '%s' in the content of entry '%s'; adding %d to its score"
                             (elfeed-score-rules-pp-rule-to-string rule)
                             match-text (elfeed-entry-id entry)
                             value)
		       (setq score (+ score value))
           (elfeed-score-rule-stats-on-match rule)))))
    score))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                            UDF rules                             ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun elfeed-score-scoring--call-udf (rule entry)
  "Invoke RULE on ENTRY."

  (condition-case err
      (funcall (elfeed-score-udf-rule-function rule) entry)
    ((error)
     (let ((display-name (elfeed-score-udf-rule-display-name rule)))
       (elfeed-score-rule-stats-on-udf-error rule)
       (elfeed-score-log 'error "Error '%s' in UDF '%s': %s"
                         (car err) display-name (cdr err))
       (message "%s: %s (see the elfeed-score log for details)."
                display-name (car err))
       nil))))

(defun elfeed-score-scoring--apply-udf-rules (entry on-match)
  "Apply the udf rules to ENTRY; invoke ON-MATCH for each match.

UDF rules are slightly different than other rules in that the
rule itself decides whether it \"applies\".  While the rule
itself cna be scoped by tags and/or feed, the user-defined
function can return nil to indicate that it does not apply."

  (cl-loop for rule being the elements of elfeed-score-serde-udf-rules
           using (index idx)
           do
           (let* ((tag-rule      (elfeed-score-udf-rule-tags  rule))
                  (feed-rule     (elfeed-score-udf-rule-feeds rule))
                  (matched-tags  (elfeed-score-scoring--match-tags
                                  (elfeed-entry-tags entry) tag-rule))
                  (matched-feeds (elfeed-score-scoring--match-feeds
                                  (elfeed-entry-feed entry) feed-rule))
                  (result
                   (and
                    matched-tags
                    matched-feeds
                    (elfeed-score-scoring--call-udf rule entry))))
             (when result
               (funcall on-match rule result idx)))))

(defun elfeed-score-scoring--explain-udf (entry)
  "Apply the UDF rules to ENTRY; return an explanation."
  (let (hits)
    (elfeed-score-scoring--apply-udf-rules
     entry
     (lambda (rule result index)
       (setq
        hits
        (cons
         (elfeed-score-make-udf-explanation
          :entry-title (elfeed-entry-title entry)
          :rule rule :value result :index index)
         hits))))
    hits))

(defun elfeed-score-scoring--score-on-udf (entry)
  "Run all UDF rules against ENTRY; return the summed values."
  (let ((score elfeed-score-scoring-default-score))
    (elfeed-score-scoring--apply-udf-rules
     entry
     (lambda (rule result _index)
       (elfeed-score-log
        'debug
        "udf-rule '%s' matched entry '%s'; adding %d to its score"
        (elfeed-score-rules-pp-rule-to-string rule)
        (elfeed-entry-title entry) result)
       (setq score (+ score result))
       (elfeed-score-rule-stats-on-match rule)))
    score))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                            tags rules                            ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun elfeed-score-scoring--apply-tag-rules (entry on-match)
  "Apply the tag scoring rules to ENTRY; invoke ON-MATCH for each match.

On match, ON-MATCH will be called with the matching rule."
  (let ((tags (elfeed-entry-tags entry)))
    (cl-loop for rule being the elements of elfeed-score-serde-tag-rules using (index idx)
             do
             (let* ((rule-tags  (elfeed-score-tag-rule-tags rule))
             (got-match  (elfeed-score-scoring--match-tags tags rule-tags)))
        (if got-match (funcall on-match rule idx))))))

(defun elfeed-score-scoring--explain-tags (entry)
  "Record with tags rules match ENTRY.  Return a list of the rules that matched."
  (let ((hits '()))
    (elfeed-score-scoring--apply-tag-rules
     entry
     (lambda (rule index)
       (setq hits (cons (elfeed-score-make-tags-explanation :rule rule :index index) hits))))
    hits))

(defun elfeed-score-scoring--score-on-tags (entry)
  "Run all tag scoring rules against ENTRY; return the summed value."

  (let ((score 0))
    (elfeed-score-scoring--apply-tag-rules
     entry
     (lambda (rule _index)
       (let ((rule-value (elfeed-score-tag-rule-value rule)))
         (elfeed-score-log
          'debug "tag rule '%s' matched entry %s('%s'); adding %d to its score"
          (elfeed-score-rules-pp-rule-to-string rule)
          (elfeed-entry-id entry)
          (elfeed-entry-title entry)
          rule-value)
         (setq score (+ score rule-value))
         (elfeed-score-rule-stats-on-match rule))))
    score))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                        adjust-tags rules                         ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun elfeed-score-scoring--adjust-tags (entry score)
  "Run all tag adjustment rules against ENTRY for score SCORE."
  (dolist (adj-tags elfeed-score-serde-adjust-tags-rules)
    (let* ((thresh           (elfeed-score-adjust-tags-rule-threshold adj-tags))
           (threshold-switch (car thresh))
           (threshold-value  (cdr thresh)))
      (if (or (and threshold-switch (>= score threshold-value))
              (and (not threshold-switch) (<= score threshold-value)))
          (let* ((rule-tags   (elfeed-score-adjust-tags-rule-tags adj-tags))
                 (rule-switch (car rule-tags))
                 (actual-tags (cdr rule-tags))) ;; may be a single tag or a list!
            (if rule-switch
                (progn
                  ;; add `actual-tags'...
                  (elfeed-score-log
                   'debug "Tag adjustment rule %s matched score %d for entry \
%s(%s); adding tag(s) %s"
                   rule-tags score (elfeed-entry-id entry)
                   (elfeed-entry-title entry) actual-tags)
                  (apply #'elfeed-tag entry actual-tags)
                  (elfeed-score-rule-stats-on-match adj-tags))
              (progn
                ;; else rm `actual-tags'
                (elfeed-score-log
                 'debug "Tag adjustment rule %s matched score %d for entry \
%s(%s); removing tag(s) %s"
                 rule-tags score (elfeed-entry-id entry)
                 (elfeed-entry-title entry) actual-tags)
                (apply #'elfeed-untag entry actual-tags)
                (elfeed-score-rule-stats-on-match adj-tags))))))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                         public functions                         ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun elfeed-score-scoring-score-entry (entry)
  "Score an Elfeed ENTRY.

This function will return the entry's score, update it's meta-data, and
update the \"last matched\" time of the salient rules.

This function is used in `elfeed-new-entry-hook'."

  (let ((score (+ elfeed-score-scoring-default-score
                  (elfeed-score-scoring--score-on-title            entry)
                  (elfeed-score-scoring--score-on-feed             entry)
                  (elfeed-score-scoring--score-on-content          entry)
                  (elfeed-score-scoring--score-on-title-or-content entry)
                  (elfeed-score-scoring--score-on-authors          entry)
                  (elfeed-score-scoring--score-on-tags             entry)
                  (elfeed-score-scoring--score-on-link             entry)
                  (elfeed-score-scoring--score-on-udf              entry))))
    ;; Take care to not pass t for the `sticky' parameter!
    (elfeed-score-scoring-set-score-on-entry entry score)
    (elfeed-score-scoring--adjust-tags entry score)
	  (if (and elfeed-score-serde-score-mark
		         (< score elfeed-score-serde-score-mark))
	      (elfeed-untag entry 'unread))
    score))

(defun elfeed-score-scoring--pp-rule-match-to-string (match)
  "Pretty-print a rule explanation MATCH & return the resulting string."

  (cl-typecase match
    (elfeed-score-title-explanation
     (elfeed-score-rules-pp-title-explanation match))
    (elfeed-score-feed-explanation
     (elfeed-score-rules-pp-feed-explanation match))
    (elfeed-score-content-explanation
     (elfeed-score-rules-pp-content-explanation match))
    (elfeed-score-title-or-content-explanation
     (elfeed-score-rules-pp-title-or-content-explanation match))
    (elfeed-score-authors-explanation
     (elfeed-score-rules-pp-authors-explanation match))
    (elfeed-score-tags-explanation
     (elfeed-score-rules-pp-tags-explanation match))
    (elfeed-score-link-explanation
     (elfeed-score-rules-pp-link-explanation match))
    (elfeed-score-udf-explanation
     (elfeed-score-rules-pp-udf-explanation match))
    (t
     (error "Don't know how to pretty-print %S" match))))

(defun elfeed-score-scoring--get-match-contribution (match)
  "Retrieve the score contribution for MATCH."

  (cl-typecase match
    (elfeed-score-title-explanation
     (elfeed-score-rules-title-explanation-contrib match))
    (elfeed-score-feed-explanation
     (elfeed-score-rules-feed-explanation-contrib match))
    (elfeed-score-content-explanation
     (elfeed-score-rules-content-explanation-contrib match))
    (elfeed-score-title-or-content-explanation
     (elfeed-score-rules-title-or-content-explanation-contrib match))
    (elfeed-score-authors-explanation
     (elfeed-score-rules-authors-explanation-contrib match))
    (elfeed-score-tags-explanation
     (elfeed-score-rules-tags-explanation-contrib match))
    (elfeed-score-link-explanation
     (elfeed-score-rules-link-explanation-contrib match))
    (elfeed-score-udf-explanation
     (elfeed-score-rules-udf-explanation-contrib match))
    (t
     (error "Don't know how to evaluate %S" match))))

(defun elfeed-score-scoring-explain-entry (entry buffer-or-name)
  "Explain an Elfeed ENTRY in BUFFER-OR-NAME.

This function will apply all scoring rules to an entry, but will
not change anything (e.g.  update ENTRY's meta-data, or the
last-matched timestamp in the matching rules); instead, it will
provide a human-readable description of what would happen if
ENTRY were to be scored, presumably for purposes of debugging or
understanding of scoring rules."

  ;; Generate the list of matching rules
  (let* ((matches
          (append
           (elfeed-score-scoring--explain-title            entry)
           (elfeed-score-scoring--explain-feed             entry)
           (elfeed-score-scoring--explain-content          entry)
           (elfeed-score-scoring--explain-title-or-content entry)
           (elfeed-score-scoring--explain-authors          entry)
           (elfeed-score-scoring--explain-tags             entry)
           (elfeed-score-scoring--explain-link             entry)
           (elfeed-score-scoring--explain-udf              entry)))
         (candidate-score
          (cl-reduce
           '+
           matches
           :key #'elfeed-score-scoring--get-match-contribution
           :initial-value elfeed-score-scoring-default-score))
         (sticky (and elfeed-score-scoring-manual-is-sticky
                      (elfeed-score-scoring-entry-is-sticky entry))))
    (with-current-buffer (get-buffer-create buffer-or-name)
      (goto-char (point-max))
      (insert
       (if sticky
           (format
            (concat
             (propertize "%s" 'face 'elfeed-score-scoring-explain-text-string)
             " has a sticky score of %d\nIt *would* match %d rule")
            (elfeed-entry-title entry)
            (elfeed-score-scoring-get-score-from-entry entry)
            (length matches))
         (format
          (concat
           (propertize "%s" 'face 'elfeed-score-scoring-explain-text-face)
           " matches %d rule")
          (elfeed-entry-title entry)
          (length matches))))
      (let ((no-matches))
        (cond
         ((eq (length matches) 0)
          (insert "s.")
          (setq no-matches t))
         ((eq (length matches) 1)
          (insert " "))
         (t
          (insert "s ")))
        (unless no-matches
          (insert (format "for a score of %d:\n" candidate-score))
          (if (elfeed-score-serde-score-file-dirty-p)
              (progn
                (insert "(NB your score file is dirty; these matches correspond \
to the rules currently in-memory)\n")
                (cl-loop
                 for match being the elements of matches using (index idx)
                 do
                 (insert
                  (format "    %d. %s\n" (1+ idx)
                          (elfeed-score-scoring--pp-rule-match-to-string match)))))
            (cl-loop
             for match being the elements of matches using (index idx)
             do
             (insert
              (format "    %d. " (1+ idx)))
             (insert-text-button
              (elfeed-score-scoring--pp-rule-match-to-string match)
              'tag (elfeed-score-serde-tag-for-explanation match)
              'index (elfeed-score-rules-index-for-explanation match)
              'action
              (lambda (btn)
                (elfeed-score-scoring-visit-rule
                 (button-get btn 'tag)
                 (button-get btn 'index))))
             (insert "\n"))))))))

(defun elfeed-score-scoring-visit-rule (tag index)
  "Visit rule TAG, INDEX in the score file.

TAG (a string) shall be one of \"title\", \"content\",
\"title-or-content\", \"feed\", \"authors\", \"tag\",
\"link\", or \"udf\".  INDEX shall be the (zero-based) index of
the rule of interest within the group named by TAG in the score
file."

  (find-file elfeed-score-serde-score-file)
  (goto-char (point-min))
  (search-forward (concat "\"" tag "\""))
  (forward-sexp (1+ index))
  (back-to-indentation))

(defun elfeed-score-scoring-score-search ()
  "Score the current set of search results."

  ;; Inhibit automatic flushing of rule stats to file...
  (let ((elfeed-score-rule-stats-dirty-threshold nil))
    (dolist (entry elfeed-search-entries)
      (elfeed-score-scoring-score-entry entry))
    (elfeed-search-update t))
  ;; *Now* flush stats.
  (if elfeed-score-rule-stats-file
      (elfeed-score-rule-stats-write elfeed-score-rule-stats-file)))

(provide 'elfeed-score-scoring)
;;; elfeed-score-scoring.el ends here
