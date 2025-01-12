;;; elfeed-score-maint.el --- Helpers for maintaining `elfeed-score' rules  -*- lexical-binding: t; -*-

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

;; This package contains utility functions for reporting on
;; `elfeed-score' rules.

;;; Code:

(require 'elfeed-score-rules)
(require 'elfeed-score-scoring)
(require 'elfeed-score-serde)
(require 'elfeed-score-rule-stats)

(require 'elfeed-show)

(defun elfeed-score-maint--get-last-match-date (rule)
  "Retrieve the time at which RULE was last matched.

Return the time, in seconds since epoch, at which RULE was most
recently matched against an entry (floating point).  Note that
RULE may be any rule struct."

  (let ((stats (elfeed-score-rule-stats-get rule)))
    (if stats
        (elfeed-score-rule-stats-date stats)
      0.0)))

(defun elfeed-score-maint--get-hits (rule)
  "Retrieve the number of times RULE has matched an entry.

Note that RULE may be an instance of any rule structure."

  (let ((stats (elfeed-score-rule-stats-get rule)))
    (if stats
        (elfeed-score-rule-stats-hits stats)
      0)))

(defun elfeed-score-maint--sort-rules-by-last-match (rules)
  "Sort RULES in decreasing order of last match.

Note that RULES need not be homogeneous; it may contain rule
structs of any kind understood by
`elfeed-score-maint--get-last-match-date'."
  (sort
   rules
   (lambda (lhs rhs)
     (> (elfeed-score-maint--get-last-match-date lhs)
        (elfeed-score-maint--get-last-match-date rhs)))))

(defun elfeed-score-maint--sort-rules-by-hits (rules)
  "Sort RULES in decreasing order of match hits.

Note that RULES need not be homogeneous; it may contain rule
structs of any kind understood by
`elfeed-score-maint--get-hits'."
  (sort
   rules
   (lambda (lhs rhs)
     (> (elfeed-score-maint--get-hits lhs)
        (elfeed-score-maint--get-hits rhs)))))

(defun elfeed-score-maint--display-rules-by-last-match (rules title)
  "Sort RULES in decreasing order of last match; display results as TITLE."
  (let ((rules (elfeed-score-maint--sort-rules-by-last-match rules))
	      (results '())
	      (max-text 0))
    (cl-dolist (rule rules)
      (let* ((pp (elfeed-score-rules-pp-rule-to-string rule))
	           (lp (length pp)))
	      (if (> lp max-text) (setq max-text lp))
	      (setq
	       results
	       (append
          results
          (list (cons (format-time-string "%a, %d %b %Y %T %Z" (elfeed-score-maint--get-last-match-date rule)) pp))))))
    (with-current-buffer-window title nil nil
      (let ((fmt (format "%%28s: %%-%ds\n" max-text)))
	      (cl-dolist (x results)
	        (insert (format fmt (car x) (cdr x))))
        (special-mode)))))

(defun elfeed-score-maint--display-rules-by-match-hits (rules title)
  "Sort RULES in decreasing order of match hits; display results as TITLE."
  (let ((rules (elfeed-score-maint--sort-rules-by-hits rules))
	      (results '())
	      (max-text 0)
        (max-hits 0))
    (cl-dolist (rule rules)
      (let* ((pp (elfeed-score-rules-pp-rule-to-string rule))
	           (lp (length pp))
             (hits (elfeed-score-maint--get-hits rule)))
	      (if (> lp max-text) (setq max-text lp))
        (if (> hits max-hits) (setq max-hits hits))
	      (setq results (append results (list (cons hits pp))))))
    (with-current-buffer-window title nil nil
      (let ((fmt (format "%%%dd: %%-%ds\n" (ceiling (log max-hits 10)) max-text)))
	      (cl-dolist (x results)
	        (insert (format fmt (car x) (cdr x))))
        (special-mode)))))

(defun elfeed-score-maint--rules-for-keyword (key)
  "Retrieve the list of rules corresponding to keyword KEY."
  (cond
   ((eq key :title) elfeed-score-serde-title-rules)
   ((eq key :feed) elfeed-score-serde-feed-rules)
   ((eq key :content) elfeed-score-serde-content-rules)
   ((eq key :title-or-content) elfeed-score-serde-title-or-content-rules)
   ((eq key :authors) elfeed-score-serde-authors-rules)
   ((eq key :tag) elfeed-score-serde-tag-rules)
   ((eq key :adjust-tags) elfeed-score-serde-adjust-tags-rules)
   (t
    (error "Unknown keyword %S" key))))

(defun elfeed-score-maint-display-rules-by-last-match (&optional category)
  "Display all scoring rules in descending order of last match.

CATEGORY may be used to narrow the scope of rules displayed.  If
nil, display all rules.  If one of the following symbols, display
only that category of rules:

    :title
    :feed
    :content
    :title-or-content
    :authors
    :tag
    :adjust-tags

Finally, CATEGORY may be a list of symbols in the preceding
list, in which case the union of the corresponding rule
categories will be displayed."

  (interactive)
  (let ((rules
	       (cond
	        ((not category)
	         (append elfeed-score-serde-title-rules elfeed-score-serde-feed-rules
		               elfeed-score-serde-content-rules
		               elfeed-score-serde-title-or-content-rules
		               elfeed-score-serde-authors-rules elfeed-score-serde-tag-rules
		               elfeed-score-serde-adjust-tags-rules))
	        ((symbolp category)
	         (elfeed-score-maint--rules-for-keyword category))
	        ((listp category)
	         (cl-loop for sym in category
		                collect (elfeed-score-maint--rules-for-keyword sym)))
	        (t
	         (error "Invalid argument %S" category)))))
    (elfeed-score-maint--display-rules-by-last-match rules "elfeed-score Rules by Last Match")))

(defun elfeed-score-maint-display-rules-by-match-hits (&optional category)
  "Display all scoring rules in descending order of match hits.

CATEGORY may be used to narrow the scope of rules displayed.  If
nil, display all rules.  If one of the following symbols, display
only that category of rules:

    :title
    :feed
    :content
    :title-or-content
    :authors
    :tag
    :adjust-tags

Finally, CATEGORY may be a list of symbols in the preceding
list, in which case the union of the corresponding rule
categories will be displayed."

  (interactive)
  (let ((rules
	       (cond
	        ((not category)
	         (append elfeed-score-serde-title-rules elfeed-score-serde-feed-rules
		               elfeed-score-serde-content-rules
		               elfeed-score-serde-title-or-content-rules
		               elfeed-score-serde-authors-rules elfeed-score-serde-tag-rules
		               elfeed-score-serde-adjust-tags-rules))
	        ((symbolp category)
	         (elfeed-score-maint--rules-for-keyword category))
	        ((listp category)
	         (cl-loop for sym in category
		                collect (elfeed-score-maint--rules-for-keyword sym)))
	        (t
	         (error "Invalid argument %S" category)))))
    (elfeed-score-maint--display-rules-by-match-hits rules "elfeed-score Rules by Match Hits")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                   interactive scoring functions                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defcustom elfeed-score-maint-default-match-type 's
  "Default match type for interactively added rules.

Must be one of 's, 'S, 'r, 'R, 'w or 'W, for case-insensitive or
case-sensitive substring, regexp or whole-word match,
respectively."
  :group 'elfeed-score
  :type '(choice (const s) (const S) (const r) (const R) (const w) (const W)))

(defcustom elfeed-score-maint-default-scope-to-feed 'no
  "Control whether intreractively added rules are scoped to the current feed.

Must  be one of 'yes, 'no, or 'ask."
  :group 'elfeed-score
  :type '(choice (const yes) (const no) (const ask)))

(defcustom elfeed-score-maint-default-scope-to-tags 'no
  "Control whether intreractively added rules are scoped to the current tag set.

Must  be one of 'yes, 'no, or 'ask."
  :group 'elfeed-score
  :type '(choice (const yes) (const no) (const ask)))

(defcustom elfeed-score-maint-default-feed-attribute 'u
  "Default attribute against which to score feeds.

Must be one of 't, 'u or 'a for title, URL or author,
respectively."
  :group 'elfeed-score
  :type '(choice (const t) (const u) (const a)))

(defmacro elfeed-score-maint--mk-interactive (name &rest body)
  "Define a function from NAME using BODY to gather parameters."

  (declare (indent defun))

  (let ((fn (intern (format "elfeed-score-maint-add-%s-rule" name)))
        (doc
         (format
          "Add title & content rule (TITLE-VALUE, CONTENT-VALUE), poss IGNORE-DEFAULTS.

Interactively add a new %s rule
based on the current Elfeed entry.  This command can be invoked
interactively in a few ways:

    With no prefix argument at all: the match values & text must
    be supplied interactively.  Other rule attributes will be
    gathered according to their corresponding \"default\" user
    options (on which more below).

    With a numeric prefix argument: the prefix argument's value
    will be used as match value.  The match text must still be
    entered interactively.  Other rule attributes will be
    gathered according to their corresponding \"default\" user
    options (on which more below).

    One or more \\[universal-argument]]s: the match values & text
    must be supplied interactively.  All defaults will be ignored
    and the other rule attributes can be entered interactively.

When called non-interactively, defaults will be respected, except
that any option set to 'ask will be interepreted as 'no.
Consider calling `elfeed-score-serde-add-rule' directly, in the
non-interactive case." name)))

    `(defun ,fn (value &optional ignore-defaults called-interactively)
       ,doc
       (interactive
        (append
         (cond
          ;; NB (listp nil) => t, so this conditional has to appear before listp!
          ;; Could still be '-... what to do with that?
          ;; No prefix arg => read score value, respect defaults.
          ((or (not current-prefix-arg) (eq current-prefix-arg '-))
           (list
            (read-number "Value: ")
            nil))
          ;; C-u(s) => read the score value, ignore defaults.
          ((listp current-prefix-arg)
           (list
            (read-number "Value: " (prefix-numeric-value current-prefix-arg))
            t))
          ;; Prefix arg => use that as the score value, respect defaults.
          ((integerp current-prefix-arg)
           (list current-prefix-arg nil)))
         ;; Per `called-interactively-p':
         ;;     Instead of using this function, it is cleaner and more
         ;;     reliable to give your function an extra optional
         ;;     argument whose ‘interactive’ spec specifies non-nil
         ;;     unconditionally ("p" is a good way to do this), or via
         ;;     (not (or executing-kbd-macro noninteractive)).
         (list (not (or executing-kbd-macro noninteractive)))))

       (if (elfeed-score-serde-score-file-dirty-p)
           ;; If the score file is dirty, and we were *not* called
           ;; interactively, just move forward & let
           ;; `elfeed-score-serde-add-rule' deal with it.
           (if (and called-interactively
                    (yes-or-no-p "The score file has been modified since last \
loaded; reload now? "))
               (elfeed-score-serde-load-score-file elfeed-score-serde-score-file)))

       (let* ((use-defaults (not (and ignore-defaults called-interactively)))
              (rule ,@body))
         (elfeed-score-serde-add-rule rule))
       (elfeed-score-scoring-score-search))))

(defun elfeed-score-maint--initial-text (entry)
  "Retrieve an initial guess at the match text from ENTRY."
  (if (and elfeed-show-entry
           (mark)
           (or mark-active mark-even-if-inactive))
      (buffer-substring-no-properties (mark) (point))
    (elfeed-entry-title entry)))

;; `elfeed-score-maint-add-title-rule'
(elfeed-score-maint--mk-interactive
 title
 (let ((entry (or elfeed-show-entry (elfeed-search-selected t))))
   (unless entry
     (error "No Elfeed entry here?"))
   (let* ((initial-text (elfeed-score-maint--initial-text entry))
          (match-text
           (if called-interactively
               (read-string "Match text: " initial-text)
             initial-text))
          (match-type
           (if use-defaults
               elfeed-score-maint-default-match-type
             (intern
              (completing-read
               "Match type: "
               '(("s" s) ("S" S) ("r" r) ("R" R) ("w" w) ("W" W)) nil t "s"))))
          (scope-to-feed
           (if use-defaults
               (eq elfeed-score-maint-default-scope-to-feed 'yes)
             (y-or-n-p "Scope this rule to this entry's feed? ")))
          (scope-to-tags
           (if use-defaults
               (eq elfeed-score-maint-default-scope-to-tags 'yes)
             (cl-mapcar
              #'intern
              (split-string
               (read-from-minibuffer
	              "Scope by tags (clear to not scope): "
	              (string-join
		             (cl-mapcar
		              (lambda (x) (pp-to-string x))
		              (elfeed-entry-tags entry))
		             " ")))))))
     (elfeed-score-title-rule--create
      :text match-text
      :value value
      :type match-type
      :tags
      (if scope-to-tags
          (cons t scope-to-tags))
      :feeds
      (if scope-to-feed
          (cons
           t
           (list
            (list 'u 'S (elfeed-entry-feed-id entry)))))))))

;; `elfeed-score-maint-add-content-rule'
(elfeed-score-maint--mk-interactive
 content
 (let ((entry elfeed-show-entry))
   (unless entry
     (error "No Elfeed entry here?"))
   
   (let* ((initial-text
           (if (and elfeed-show-entry
                    (mark)
                    (or mark-active mark-even-if-inactive))
               (buffer-substring-no-properties (mark) (point))
             (elfeed-deref (elfeed-entry-content entry))))
          (match-text
           (if called-interactively
               (read-string "Match text: " initial-text)
             initial-text))
          (match-type
           (if use-defaults
               elfeed-score-maint-default-match-type
             (intern
              (completing-read
               "Match type: "
               '(("s" s) ("S" S) ("r" r) ("R" R) ("w" w) ("W" W)) nil t "s"))))
          (scope-to-feed
           (if use-defaults
               (eq elfeed-score-maint-default-scope-to-feed 'yes)
             (y-or-n-p "Scope this rule to this entry's feed? ")))
          (scope-to-tags
           (if use-defaults
               (eq elfeed-score-maint-default-scope-to-tags 'yes)
             (cl-mapcar
              #'intern
              (split-string
               (read-from-minibuffer
	              "Scope by tags (clear to not scope): "
	              (string-join
		             (cl-mapcar
		              (lambda (x) (pp-to-string x))
		              (elfeed-entry-tags entry))
		             " ")))))))
     (elfeed-score-content-rule--create
      :text match-text
      :value value
      :type match-type
      :tags
      (if scope-to-tags
          (cons t scope-to-tags))
      :feeds
      (if scope-to-feed
          (cons
           t
           (list
            (list 'u 'S (elfeed-entry-feed-id entry)))))))))

;; `elfeed-score-maint-add-feed-rule'
(elfeed-score-maint--mk-interactive
 feed
 (let ((entry (or elfeed-show-entry (elfeed-search-selected t))))
   (unless entry
     (error "No Elfeed entry here?"))
   (let* ((feed (elfeed-entry-feed entry))
          (attr
           (if use-defaults
               elfeed-score-maint-default-feed-attribute
             (intern
              (completing-read
               "Feed attribute: "
               '(("t" . t) ("u" . u) ("a" . a)) nil t "u"))))
          (match-text
           (if use-defaults
               (cond
                ((eq attr 't) (elfeed-feed-title feed))
                ((eq attr 'u) (elfeed-feed-url feed))
                (t (elfeed-feed-author feed)))
             (read-string
              "Match text: "
              (cond
               ((eq attr 't) (elfeed-feed-title feed))
               ((eq attr 'u) (elfeed-feed-url feed))
               (t (elfeed-feed-author feed))))))
          (match-type
           (if use-defaults
               elfeed-score-maint-default-match-type
             (intern
              (completing-read
               "Match type: "
               '(("s" s) ("S" S) ("r" r) ("R" R) ("w" w) ("W" W)) nil t "s"))))
          (scope-to-tags
           (if use-defaults
               (eq elfeed-score-maint-default-scope-to-tags 'yes)
             (cl-mapcar
              #'intern
              (split-string
               (read-from-minibuffer
	              "Scope by tags (clear to not scope): "
	              (string-join
		             (cl-mapcar
		              (lambda (x) (pp-to-string x))
		              (elfeed-entry-tags entry))
		             " ")))))))
     (elfeed-score-feed-rule--create
      :text match-text
      :value value
      :type match-type
      :attr attr
      :tags scope-to-tags))))

;; `elfeed-score-maint-add-authors-rule'
(elfeed-score-maint--mk-interactive
 authors
 (let ((entry (or elfeed-show-entry (elfeed-search-selected t))))
   (unless entry
     (error "No Elfeed entry here?"))
   (let* ((initial-text (elfeed-score-scoring--concatenate-authors
                         (elfeed-meta entry :authors)))
          (match-text
           (if called-interactively
               (read-string "Match text: " initial-text)
             initial-text))
          (match-type
           (if use-defaults
               elfeed-score-maint-default-match-type
             (intern
              (completing-read
               "Match type: "
               '(("s" s) ("S" S) ("r" r) ("R" R) ("w" w) ("W" W)) nil t "s"))))
          (scope-to-feed
           (if use-defaults
               (eq elfeed-score-maint-default-scope-to-feed 'yes)
             (y-or-n-p "Scope this rule to this entry's feed? ")))
          (scope-to-tags
           (if use-defaults
               (eq elfeed-score-maint-default-scope-to-tags 'yes)
             (cl-mapcar
              #'intern
              (split-string
               (read-from-minibuffer
	              "Scope by tags (clear to not scope): "
	              (string-join
		             (cl-mapcar
		              (lambda (x) (pp-to-string x))
		              (elfeed-entry-tags entry))
		             " ")))))))
     (elfeed-score-authors-rule--create
      :text match-text
      :value value
      :type match-type
      :tags scope-to-tags
      :feeds scope-to-feed))))

;; `elfeed-score-maint-add-tag-rule'
(elfeed-score-maint--mk-interactive
 tag
 (let ((entry (or elfeed-show-entry (elfeed-search-selected t))))
   (unless entry
     (error "No Elfeed entry here?"))
   (let ((match-tags
          (if use-defaults
              (delq 'unread (elfeed-entry-tags entry))
            (cl-mapcar
              #'intern
              (split-string
               (read-from-minibuffer
	              "Tags: "
	              (string-join
		             (cl-mapcar
		              (lambda (x) (pp-to-string x))
		              (delq 'unread (elfeed-entry-tags entry)))
		             " ")))))))
     (elfeed-score-tag-rule--create
      :tags (cons t match-tags)
      :value value))))

;; `elfeed-score-main-add-link-rule'
(elfeed-score-maint--mk-interactive
 link
 (let ((entry (or elfeed-show-entry (elfeed-search-selected t))))
   (unless entry
     (error "No Elfeed entry here?"))
   (let* ((initial-text (elfeed-entry-link entry))
          (match-text
           (if called-interactively
               (read-string "Match text: " initial-text)
             initial-text))
          (match-type
           (if use-defaults
               elfeed-score-maint-default-match-type
             (intern
              (completing-read
               "Match type: "
               '(("s" s) ("S" S) ("r" r) ("R" R) ("w" w) ("W" W)) nil t "s"))))
          (scope-to-feed
           (if use-defaults
               (eq elfeed-score-maint-default-scope-to-feed 'yes)
             (y-or-n-p "Scope this rule to this entry's feed? ")))
          (scope-to-tags
           (if use-defaults
               (eq elfeed-score-maint-default-scope-to-tags 'yes)
             (cl-mapcar
              #'intern
              (split-string
               (read-from-minibuffer
	              "Scope by tags (clear to not scope): "
	              (string-join
		             (cl-mapcar
		              (lambda (x) (pp-to-string x))
		              (elfeed-entry-tags entry))
		             " ")))))))
     (elfeed-score-link-rule--create
      :text match-text
      :value value
      :type match-type
      :tags scope-to-tags
      :feeds scope-to-feed))))

;; `title-or-content-rule' is special since it has two values
(defun elfeed-score-maint-add-title-or-content-rule (title-value
                                                     content-value
                                                     &optional
                                                     ignore-defaults
                                                     called-interactively)
  "Add title & content rule (TITLE-VALUE, CONTENT-VALUE), poss IGNORE-DEFAULTS.
CALLED-INTERACTIVELY is as per usual.

Interactively add a new `elfeed-score-title-or-content-rule'
based on the current Elfeed entry.  This command can be invoked
interactively in a few ways:

    With no prefix argument at all: the match values & text must
    be supplied interactively.  Other rule attributes will be
    gathered according to their corresponding \"default\" user
    options (on which more below).

    With a numeric prefix argument: the prefix argument's value
    will be used as both the title & content match values.  The
    match text must still be entered interactively.  Other rule
    attributes will be gathered according to their corresponding
    \"default\" user options (on which more below).

    One or more \\[universal-argument]]s: the match values & text
    must be supplied interactively.  All defaults will be ignored
    and the other rule attributes can be entered interactively.

When called non-interactively, defaults will be respected, except
that any option set to 'ask will be interepreted as 'no.
Consider calling `elfeed-score-serde-add-rule' directly, in the
non-interactive case."
  
  (interactive
   (append
    (cond
     ;; NB (listp nil) => t, so this conditional has to appear before listp!
     ;; Could still be '-... what to do with that?
     ;; No prefix arg => read score values, respect defaults.
     ((or (not current-prefix-arg) (eq current-prefix-arg '-))
      (list
       (read-number "Title value: ")
       (read-number "Content value: ")
       nil))
     ;; C-u(s) => read the score values, ignore defaults.
     ((listp current-prefix-arg)
      (list
       (read-number "Title value: " (prefix-numeric-value current-prefix-arg))
       (read-number "Content value: " (prefix-numeric-value current-prefix-arg))
       t))
     ;; Prefix arg => use that as the score value, respect defaults.
     ((integerp current-prefix-arg)
      (list current-prefix-arg current-prefix-arg nil)))
    (list (not (or executing-kbd-macro noninteractive)))))

  (if (elfeed-score-serde-score-file-dirty-p)
      ;; If the score file is dirty, and we were *not* called
      ;; interactively, just move forward & let
      ;; `elfeed-score-serde-add-rule' deal with it.
      (if (and called-interactively
               (yes-or-no-p "The score file has been modified since last \
loaded; reload now? "))
          (elfeed-score-serde-load-score-file elfeed-score-serde-score-file)))

  (let* ((use-defaults (not (and ignore-defaults called-interactively)))
         (rule
          (let ((entry (or elfeed-show-entry (elfeed-search-selected t))))
            (unless entry
              (error "No Elfeed entry here?"))
            ;; If we're showing an entry, and the mark is active, use
            ;; the region; else use the entry title.
            (let* ((initial-text
                    (elfeed-score-maint--initial-text entry))
                   (match-text
                    (if called-interactively
                        (read-string "Match text: " initial-text)
                      initial-text))
                   (match-type
                    (if use-defaults
                        elfeed-score-maint-default-match-type
                      (intern
                       (completing-read
                        "Match type: "
                        '(("s" s) ("S" S) ("r" r) ("R" R) ("w" w) ("W" W)) nil t "s"))))
                   (scope-to-feed
                    (if use-defaults
                        (eq elfeed-score-maint-default-scope-to-feed 'yes)
                      (y-or-n-p "Scope this rule to this entry's feed? ")))
                   (scope-to-tags
                    (if use-defaults
                        (eq elfeed-score-maint-default-scope-to-tags 'yes)
                      (cl-mapcar
                       #'intern
                       (split-string
                        (read-from-minibuffer
	                       "Scope by tags (clear to not scope): "
	                       (string-join
		                      (cl-mapcar
		                       (lambda (x) (pp-to-string x))
		                       (elfeed-entry-tags entry))
		                      " ")))))))
              (elfeed-score-title-or-content-rule--create
               :text match-text
               :title-value title-value
               :content-value content-value
               :type match-type
               :tags
               (if scope-to-tags
                   (cons t scope-to-tags))
               :feeds
               (if scope-to-feed
                   (cons
                    t
                    (list
                     (list 'u 'S (elfeed-entry-feed-id entry))))))))))
    (elfeed-score-serde-add-rule rule)
    (elfeed-score-scoring-score-search)))

(provide 'elfeed-score-maint)
;;; elfeed-score-maint.el ends here
