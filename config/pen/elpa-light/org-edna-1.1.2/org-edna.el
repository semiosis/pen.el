;;; org-edna.el --- Extensible Dependencies 'N' Actions -*- lexical-binding: t; -*-

;; Copyright (C) 2017-2020 Free Software Foundation, Inc.

;; Author: Ian Dunn <dunni@gnu.org>
;; Maintainer: Ian Dunn <dunni@gnu.org>
;; Keywords: convenience, text, org
;; URL: https://savannah.nongnu.org/projects/org-edna-el/
;; Package-Requires: ((emacs "25.1") (seq "2.19") (org "9.0.5"))
;; Version: 1.1.2

;; This file is part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free Software
;; Foundation; either version 3, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
;; FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
;; details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Edna provides an extensible means of specifying conditions which must be
;; fulfilled before a task can be completed and actions to take once it is.

;; Org Edna runs when either the BLOCKER or TRIGGER properties are set on a
;; heading, and when it is changing from a TODO state to a DONE state.

;;; History:

;;; Code:

(require 'org)
(eval-when-compile (require 'subr-x))
(require 'seq)

;; Compatibility for Emacs < 26.1
(unless (fboundp 'if-let*)
  (defalias 'if-let* 'if-let))
(unless (fboundp 'when-let*)
  (defalias 'when-let* 'when-let))

(defgroup org-edna nil
  "Extensible Dependencies 'N' Actions"
  :group 'org)

(defcustom org-edna-use-inheritance nil
  "Whether Edna should use inheritance when looking for properties.

This only applies to the BLOCKER and TRIGGER properties, not any
properties used during actions or conditions."
  :type 'boolean)

(defcustom org-edna-prompt-for-archive t
  "Whether Edna should prompt before archiving a target."
  :type 'boolean)

(defcustom org-edna-timestamp-format 'short
  "Default timestamp format for scheduling and deadlines.

This is either `short' for short format (no time spec), or
`long' (includes time spec).

When using the schedule! or deadline! actions with the ++
modifier, the current time will be used as the base time.  This
leaves the potential for having no \"template\" timestamp to use
for the format.  This is in contrast to the + modifier, which
uses the current timestamp's format.

The timestamp is chosen in one of three ways:

1. If the target heading already has a timestamp, that format is
used.

2. If the modifier \"thing\" is minutes or hours, long format
will always be used.

3. If the property EDNA_TS_FORMAT is set on the target heading,
it will be used.  It should be either \"short\" or
\"long\" (without quotes).

4. Fallback to this variable."
  :type '(choice (const :tag "Short Format" short)
                 (const :tag "Long Format" long)))

(defcustom org-edna-from-todo-states 'todo
  "Category of TODO states that allow Edna to run.

This is one of the following options:

If `todo', Edna will run when changing TODO state from an entry
in `org-not-done-keywords'.

If `not-done', Edna will run when changing TODO state from any
entry that's not in `org-done-keywords'.  This includes TODO
state being empty."
  :type '(choice (const :tag "TODO Keywords" todo)
                 (const :tag "Not DONE Keywords" not-done)))

;;; Form Parsing

;; 3 types of "forms" here
;;
;; 1. String form; this is what you see in a BLOCKER or TRIGGER property
;; 2. Edna sexp form; this is the intermediary form, and form used in org-edna-form
;; 3. Lisp form; a form that can be evaluated by Emacs

(defmacro org-edna--syntax-error (msg form error-pos)
  "Signal an Edna syntax error.

MSG will be reported to the user and should describe the error.
FORM is the form that generated the error.
ERROR-POS is the positiong in MSG at which the error occurred."
  `(signal 'invalid-read-syntax (list :msg ,msg :form ,form :error-pos ,error-pos)))

(defun org-edna--print-syntax-error (error-plist)
  "Prints the syntax error from ERROR-PLIST."
  (let* ((msg (plist-get error-plist :msg))
         (form (plist-get error-plist :form))
         (pos (plist-get error-plist :error-pos)))
    (message
     "Org Edna Syntax Error: %s\n%s\n%s"
     msg form (concat (make-string pos ?\ ) "^"))))

(defun org-edna--id-pred-p (arg)
  "Return non-nil if ARG matches id:UUID.

UUID is any UUID recognized by `org-uuidgen-p'."
  (save-match-data
    (when (string-match "^id:\\(.*\\)" (symbol-name arg))
      (org-uuidgen-p (match-string 1 (symbol-name arg))))))

(defun org-edna--transform-arg (arg)
  "Transform argument ARG.

Currently, the following are handled:

- UUIDs (as determined by `org-uuidgen-p') are converted to strings

Everything else is returned as is."
  (pcase arg
    ((and (pred symbolp) ;; Symbol
          ;; Name matches `org-uuidgen-p'
          (let (pred org-uuidgen-p) (symbol-name arg)))
     (symbol-name arg))
    ((and (pred symbolp) ;; Symbol
          ;; Name matches `org-uuidgen-p'
          (pred org-edna--id-pred-p))
     (symbol-name arg))
    (_
     arg)))

(defun org-edna-break-modifier (token)
  "Break TOKEN into a modifier and base token.

A modifier is a single character.

Return (MODIFIER . TOKEN), even if MODIFIER is nil."
  (if token
      (let (modifier)
        (when (string-match "^\\([!]\\)\\(.*\\)" (symbol-name token))
          (setq modifier (intern (match-string 1 (symbol-name token))))
          (setq token    (intern (match-string 2 (symbol-name token)))))
        (cons modifier token))
    ;; Still return something
    '(nil . nil)))

(defun org-edna--function-for-key (key)
  "Determine the Edna function for KEY.

KEY should be a symbol, the keyword for which to find the Edna
function.

If KEY is an invalid Edna keyword, then return nil."
  (cond
   ;; Just return nil if it's not a symbol
   ((or (not key)
        (not (symbolp key)))
    nil)
   ((memq key '(consideration consider))
    ;; Function is ignored here, but `org-edna-describe-keyword' needs this
    ;; function.
    (cons 'consideration 'org-edna-handle-consideration))
   ((string-suffix-p "!" (symbol-name key))
    ;; Action
    (let ((func-sym (intern (format "org-edna-action/%s" key))))
      (when (fboundp func-sym)
        (cons 'action func-sym))))
   ((string-suffix-p "?" (symbol-name key))
    ;; Condition
    (let ((func-sym (intern (format "org-edna-condition/%s" key))))
      (when (fboundp func-sym)
        (cons 'condition func-sym))))
   (t
    ;; Everything else is a finder
    (let ((func-sym (intern (format "org-edna-finder/%s" key))))
      (when (fboundp func-sym)
        (cons 'finder func-sym))))))

(defun org-edna-parse-string-form (form &optional start)
  "Parse Edna string form FORM starting at position START.

Return (SEXP-FORM POS)

SEXP-FORM is the sexp form of FORM starting at START.
POS is the position in FORM where parsing ended."
  (setq start (or start 0))
  (pcase-let* ((`(,token . ,pos) (read-from-string form start))
               (args nil))
    (unless token
      (org-edna--syntax-error "Invalid Token" form start))
    ;; Check for either end of string or an opening parenthesis
    (unless (or (equal pos (length form))
                (equal (string-match-p "\\s-" form pos) pos)
                (equal (string-match-p "(" form pos) pos))
      (org-edna--syntax-error "Invalid character in form" form pos))
    ;; Parse arguments if we have any
    (when (equal (string-match-p "(" form pos) pos)
      (pcase-let* ((`(,new-args . ,new-pos) (read-from-string form pos)))
        (setq pos new-pos
              args (mapcar #'org-edna--transform-arg new-args))))
    ;; Move across any whitespace
    (when (string-match "\\s-+" form pos)
      (setq pos (match-end 0)))
    (list (cons token args) pos)))

(defun org-edna--convert-form (string &optional pos)
  "Convert string form STRING into a flat sexp form.

POS is the position in STRING from which to start conversion.

Returns (FLAT-FORM END-POS) where

FLAT-FORM is the flat sexp form
END-POS is the position in STRING where parsing ended.

Example:

siblings todo!(TODO) => ((siblings) (todo! TODO))"
  (let ((pos (or pos 0))
        final-form)
    (while (< pos (length string))
      (pcase-let* ((`(,form ,new-pos) (org-edna-parse-string-form string pos)))
        (setq final-form (append final-form (list (cons form pos))))
        (setq pos new-pos)))
    (cons final-form pos)))

(defun org-edna--normalize-sexp-form (form action-or-condition &optional from-string)
  "Normalize flat sexp form FORM into a full edna sexp form.

ACTION-OR-CONDITION is either `action' or `condition', indicating
which of the two types is allowed in FORM.

FROM-STRING is used internally, and is non-nil if FORM was
originally a string.

Returns (NORMALIZED-FORM REMAINING-FORM), where REMAINING-FORM is
the remainder of FORM after the current scope was parsed."
  (let* ((remaining-form (copy-sequence form))
         (state 'finder)
         final-form
         need-break)
    (while (and remaining-form (not need-break))
      (pcase-let* ((`(,current-form . ,error-pos) (pop remaining-form)))
        (pcase (car current-form)
          ('if
              ;; Check the car of each r*-form for the expected
              ;; ending.  If it doesn't match, throw an error.
              (let (cond-form then-form else-form have-else)
                (pcase-let* ((`(,temp-form ,r-form)
                              (org-edna--normalize-forms
                               remaining-form
                               ;; Only allow conditions in cond forms
                               'condition
                               '((then))
                               from-string)))
                  (unless r-form
                    (org-edna--syntax-error
                     "Malformed if-construct; expected then terminator"
                     from-string error-pos))
                  ;; Skip the 'then' construct and move forward
                  (setq cond-form temp-form
                        error-pos (cdar r-form)
                        remaining-form (cdr r-form)))

                (pcase-let* ((`(,temp-form ,r-form)
                              (org-edna--normalize-forms remaining-form
                                                         action-or-condition
                                                         '((else) (endif))
                                                         from-string)))
                  (unless r-form
                    (org-edna--syntax-error
                     "Malformed if-construct; expected else or endif terminator"
                     from-string error-pos))
                  (setq have-else (equal (caar r-form) '(else))
                        then-form temp-form
                        error-pos (cdar r-form)
                        remaining-form (cdr r-form)))
                (when have-else
                  (pcase-let* ((`(,temp-form ,r-form)
                                (org-edna--normalize-forms remaining-form
                                                           action-or-condition
                                                           '((endif))
                                                           from-string)))
                    (unless r-form
                      (org-edna--syntax-error "Malformed if-construct; expected endif terminator"
                                              from-string error-pos))
                    (setq else-form temp-form
                          remaining-form (cdr r-form))))
                (push `(if ,cond-form ,then-form ,else-form) final-form)))
          ((or 'then 'else 'endif)
           (setq need-break t)
           ;; Push the object back on remaining-form so the if knows where we are
           (setq remaining-form (cons (cons current-form error-pos) remaining-form)))
          (_
           ;; Determine the type of the form
           ;; If we need to change state, return from this scope
           (pcase-let* ((`(_ . ,key)   (org-edna-break-modifier (car current-form)))
                        (`(,type . ,func) (org-edna--function-for-key key)))
             (unless (and type func)
               (org-edna--syntax-error "Unrecognized Form"
                                       from-string error-pos))
             (pcase type
               ('finder
                (unless (memq state '(finder consideration))
                  ;; We changed back to finders, so we need to start a new scope
                  (setq need-break t)))
               ('action
                (unless (eq action-or-condition 'action)
                  (org-edna--syntax-error "Actions aren't allowed in this context"
                                          from-string error-pos)))
               ('condition
                (unless (eq action-or-condition 'condition)
                  (org-edna--syntax-error "Conditions aren't allowed in this context"
                                          from-string error-pos))))
             ;; Only update state if we're not breaking.  If we are, then the
             ;; new state doesn't matter.
             (unless need-break
               (setq state type))
             (if need-break ;; changing state
                 ;; Keep current-form on remaining-form so we have it for the
                 ;; next scope, since we didn't process it here.
                 (setq remaining-form (cons (cons current-form error-pos) remaining-form))
               (push current-form final-form)))))))
    (when (and (eq state 'finder)
               (eq action-or-condition 'condition))
      ;; Finders have to have something at the end, so we need to add that
      ;; something.  No default actions, so this must be a blocker.
      (push '(!done?) final-form))
    (list (nreverse final-form) remaining-form)))

(defun org-edna--normalize-forms (form-list action-or-condition end-forms &optional from-string)
  "Normalize forms in flat form list FORM-LIST until one of END-FORMS is found.

ACTION-OR-CONDITION is either `action' or `condition', indicating
which of the two types is allowed in FORM.

FROM-STRING is used internally, and is non-nil if FORM was
originally a string.

END-FORMS is a list of forms.  When one of them is found, stop parsing."
  (pcase-let* ((`(,final-form ,rem-form) (org-edna--normalize-sexp-form form-list action-or-condition from-string)))
    (setq final-form (list final-form))
    ;; Use car-safe to catch r-form = nil
    (while (and rem-form (not (member (car (car-safe rem-form)) end-forms)))
      (pcase-let* ((`(,new-form ,r-form)
                    (org-edna--normalize-sexp-form rem-form action-or-condition from-string)))
        (setq final-form (append final-form (list new-form))
              rem-form r-form)))
    (list final-form rem-form)))

(defun org-edna--normalize-all-forms (form-list action-or-condition &optional from-string)
  "Normalize all forms in flat form list FORM-LIST.

ACTION-OR-CONDITION is either `action' or `condition', indicating
which of the two types is allowed in FORM.

FROM-STRING is used internally, and is non-nil if FORM was
originally a string."
  (car-safe (org-edna--normalize-forms form-list action-or-condition nil from-string)))

(defun org-edna-string-form-to-sexp-form (string-form action-or-condition)
  "Parse string form STRING-FORM into an Edna sexp form.

ACTION-OR-CONDITION is either `action' or `condition', indicating
which of the two types is allowed in STRING-FORM."
  (org-edna--normalize-all-forms
   (car (org-edna--convert-form string-form))
   action-or-condition
   string-form))

(defun org-edna--handle-condition (func mod args targets consideration)
  "Handle a condition.

FUNC is the condition function.
MOD is the modifier to pass to FUNC.
ARGS are any arguments to pass to FUNC.
TARGETS is a list of targets on which to operate.
CONSIDERATION is the consideration symbol, if any."
  (when (seq-empty-p targets)
    (message "Warning: Condition specified without targets"))
  ;; Check the condition at each target
  (when-let* ((blocks
               (mapcar
                (lambda (entry-marker)
                  (org-with-point-at entry-marker
                    (apply func mod args)))
                targets)))
    ;; Apply consideration
    (org-edna-handle-consideration consideration blocks)))

(defun org-edna--add-targets (old-targets new-targets)
  "Add targets in NEW-TARGETS to OLD-TARGETS.

Neither argument is modified."
  (seq-uniq (append old-targets new-targets)))

(defun org-edna--handle-action (action targets last-entry args)
  "Process ACTION on TARGETS.

LAST-ENTRY is the source entry.
ARGS is a list of arguments to pass to ACTION."
  (when (seq-empty-p targets)
    (message "Warning: Action specified without targets"))
  (dolist (target targets)
    (org-with-point-at target
      (apply action last-entry args))))

(defun org-edna--expand-single-sexp-form (single-form
                                          target-var
                                          consideration-var
                                          blocking-var)
  "Expand sexp form SINGLE-FORM into a Lisp form.

TARGET-VAR, BLOCKING-VAR, and CONSIDERATION-VAR are symbols that
correspond to internal variables."
  (pcase-let* ((`(,mkey . ,args) single-form)
               (`(,mod . ,key)   (org-edna-break-modifier mkey))
               (`(,type . ,func) (org-edna--function-for-key key)))
    (pcase type
      ('finder
       `(setq ,target-var (org-edna--add-targets ,target-var (org-edna--handle-finder ',func ',args))))
      ('action
       `(org-edna--handle-action ',func ,target-var (point-marker) ',args))
      ('condition
       `(setq ,blocking-var (or ,blocking-var
                                (org-edna--handle-condition ',func ',mod ',args
                                                            ,target-var
                                                            ,consideration-var))))
      ('consideration
       `(setq ,consideration-var ',(nth 0 args))))))

(defun org-edna--expand-sexp-form (form &optional
                                        use-old-scope
                                        old-target-var
                                        old-consideration-var
                                        old-blocking-var)
  "Expand sexp form FORM into a Lisp form.

USE-OLD-SCOPE, OLD-TARGET-VAR, OLD-CONSIDERATION-VAR, and
OLD-BLOCKING-VAR are used internally."
  (when form
    ;; We inherit the original targets, consideration, and blocking-entry when
    ;; we create a new scope in an if-construct.
    (let* ((target-var (if use-old-scope old-target-var (cl-gentemp "targets")))
           (consideration-var (if use-old-scope
                                  old-consideration-var
                                (cl-gentemp "consideration")))
           ;; The only time we want a new blocking-var is when we are in a
           ;; conditional scope.  Otherwise, we want the same blocking-var
           ;; passed through all scopes.  The only time old-blocking-var won't
           ;; be set is if we are starting a new global scope, or we are
           ;; starting a conditional scope.
           (blocking-var (or old-blocking-var
                             (cl-gentemp "blocking-entry")))
           ;; These won't be used if use-old-scope is non-nil
           (tmp-let-binds `((,target-var ,old-target-var)
                            (,consideration-var ,old-consideration-var)))
           ;; Append blocking-var separately to avoid it attempting to let-bind nil.
           (let-binds (if old-blocking-var
                        tmp-let-binds
                        (append tmp-let-binds
                                (list (list blocking-var nil)))))
           (wrapper-form (if use-old-scope
                             '(progn)
                           `(let (,@let-binds)))))
      (pcase form
        (`(if ,cond ,then . ,else)
         ;; Don't pass the old variables into the condition form; it should be
         ;; evaluated on its own to avoid clobbering the old targets.
         `(if (not ,(org-edna--expand-sexp-form cond))
              ,(org-edna--expand-sexp-form
                then
                t
                old-target-var old-consideration-var old-blocking-var)
            ,(when else
               (org-edna--expand-sexp-form
                ;; else is wrapped in a list, so take the first argument
                (car else)
                t
                old-target-var old-consideration-var old-blocking-var))))
        ((pred (lambda (arg) (symbolp (car arg))))
         (org-edna--expand-single-sexp-form
          form old-target-var old-consideration-var old-blocking-var))
        (_
         ;; List of forms
         ;; Only use new variables if we're asked to
         `(,@wrapper-form
           ,@(mapcar
              (lambda (f) (org-edna--expand-sexp-form
                      f nil target-var consideration-var blocking-var))
              form)))))))

(defun org-edna-eval-sexp-form (sexp-form)
  "Evaluate Edna sexp form SEXP-FORM."
  (eval
   (org-edna--expand-sexp-form sexp-form)
   t))

(defun org-edna-process-form (string-form action-or-condition)
  "Process STRING-FORM.

ACTION-OR-CONDITION is either `action' or `condition', indicating
which of the two types is allowed in STRING-FORM."
  (org-edna-eval-sexp-form
   (org-edna-string-form-to-sexp-form string-form action-or-condition)))

;;; Cache

;; Cache works because the returned values of finders are all markers.  Markers
;; will automatically update themselves when a buffer is edited.

;; We use a timeout for cache because it's expected that the Org files
;; themselves will change.  Thus, there's no assured way to determine if we need
;; to update the cache without actually running again.  Therefore, we assume
;; most operations that the user wants to expedite will be performed in bulk.

(cl-defstruct org-edna--finder-input
  func-sym args)

(cl-defstruct org-edna--finder-cache-entry
  input results last-run-time)

(defvar org-edna--finder-cache (make-hash-table :test 'equal))

(defcustom org-edna-finder-use-cache nil
  "Whether to use cache for improved performance with finders.

When cache is used for a finder, each finder call will store its
results for up to `org-edna-finder-cache-timeout' seconds.  The
results and input are both stored, so the same form for a given
finder will yield the results of the previous call.

If enough time has passed since the results in cache for a
specific form were generated, the results will be regenerated and
stored in cache.

Minor changes to an Org file, such as setting properties or
adding unrelated headings, will be taken into account."
  :type 'boolean)

(defcustom org-edna-finder-cache-timeout 300
  "Maximum age to keep entries in cache, in seconds."
  :type 'number)

(defvar org-edna-finder-cache-enabled-finders
  '(org-edna-finder/match
    org-edna-finder/ids
    org-edna-finder/olp
    org-edna-finder/file
    org-edna-finder/org-file)
  "List of finders for which cache is enabled.

Only edit this list if you've added custom finders.  Many
finders, specifically relative finders, rely on the context in
which they're called.  For these finders, cache will not work
properly.

The default state of this list contains the built-in finders for
which context is irrelevant.

Each entry is the function symbol for the finder.")

(defun org-edna--add-to-finder-cache (func-sym args)
  (let* ((results (apply func-sym args))
         (input (make-org-edna--finder-input :func-sym func-sym
                                             :args args))
         (entry (make-org-edna--finder-cache-entry :input input
                                                   :results results
                                                   :last-run-time (current-time))))
    (puthash input entry org-edna--finder-cache)
    ;; Returning the results here passes them to the calling function.  It's the
    ;; only part of the entry we care about here.
    results))

(defun org-edna--finder-cache-timeout (_func-sym)
  ;; In the future, we may want to support configurable timeouts on a per-finder
  ;; basis.
  org-edna-finder-cache-timeout)

(defun org-edna--get-cache-entry (func-sym args)
  "Find a valid entry in the cache.

If none exists, return nil.  An entry is invalid for any of the
following reasons:

- It doesn't exist
- It has timed out
- It contains an invalid marker"
  (let* ((input (make-org-edna--finder-input :func-sym func-sym
                                             :args args))
         (entry (gethash input org-edna--finder-cache)))
    (cond
     ;; If we don't have an entry, rerun and make a new one.
     ((not entry) nil)
     ;; If we do have an entry, but it's timed out, then create a new one.
     ((>= (float-time (time-subtract (current-time)
                                    (org-edna--finder-cache-entry-last-run-time entry)))
         (org-edna--finder-cache-timeout func-sym))
      nil)
     ;; If any element of the results is an invalid marker, then rerun.
     ((seq-find (lambda (x) (not (markerp x))) (org-edna--finder-cache-entry-results entry) nil)
      nil)
     ;; We have an entry created within the allowed interval.
     (t entry))))

(defun org-edna--cache-is-enabled-for-finder (func-sym)
  (memq func-sym org-edna-finder-cache-enabled-finders))

(defun org-edna--handle-finder (func-sym args)
  (if (not (and org-edna-finder-use-cache
                (org-edna--cache-is-enabled-for-finder func-sym)))
      ;; Not using cache, so use the function directly.
      (apply func-sym args)
    (let* ((entry (org-edna--get-cache-entry func-sym args)))
      (if entry
          (org-edna--finder-cache-entry-results entry)
        ;; Adds the entry to the cache, and returns the results.
        (org-edna--add-to-finder-cache func-sym args)))))

(defun org-edna-reset-cache ()
  "Reset the finder cache.

Use this only if there's a problem with the cache.

When an Org mode buffer is reverted, the cache will be made
useless for that buffer.  Therefore, it's a good idea to call
this after reverting Org mode buffers."
  (interactive)
  (setq org-edna--finder-cache (make-hash-table :test 'equal)))


;;; Interactive Functions

(defun org-enda--should-run-in-from-state-p (from)
  (pcase org-edna-from-todo-states
    ('todo
     (member from (cons 'todo org-not-done-keywords)))
    ('not-done
     (not (member from (cons 'done org-done-keywords))))))

(defun org-edna--should-run-p (change-plist)
  "Check if Edna should run.

The state information is held in CHANGE-PLIST.  If the TODO state
is changing from a TODO state to a DONE state, run BODY."
  (let* ((type (plist-get change-plist :type))
         (from (plist-get change-plist :from))
         (to (plist-get change-plist :to)))
    (and
     ;; We are only handling todo-state-change
     (eq type 'todo-state-change)
     ;; And only from a TODO state to a DONE state
     (org-enda--should-run-in-from-state-p from)
     (member to (cons 'done org-done-keywords)))))

(defmacro org-edna-run (&rest body)
  "Run a TODO state change."
  (declare (indent 0))
  `(condition-case-unless-debug err
       ,@body
     (error
      (if (eq (car err) 'invalid-read-syntax)
          (org-edna--print-syntax-error (cdr err))
        (message "Edna Error at heading %s: %s" (org-get-heading t t t) (error-message-string err)))
      (setq org-block-entry-blocking (org-get-heading))
      ;; Block
      nil)))

(defun org-edna-trigger-function (change-plist)
  "Trigger function work-horse.

See `org-edna-run' for CHANGE-PLIST explanation.

This shouldn't be run from outside of `org-trigger-hook'."
  (when (org-edna--should-run-p change-plist)
    (org-edna-run
      (when-let* ((form (org-entry-get (plist-get change-plist :position)
                                       "TRIGGER" org-edna-use-inheritance)))
        (org-edna-process-form form 'action)))))

(defun org-edna-blocker-function (change-plist)
  "Blocker function work-horse.

See `org-edna-run' for CHANGE-PLIST explanation.

This shouldn't be run from outside of `org-blocker-hook'."
  (if (org-edna--should-run-p change-plist)
      (org-edna-run
        (if-let* ((form (org-entry-get (plist-get change-plist :position)
                                       "BLOCKER" org-edna-use-inheritance)))
            ;; Return nil if there is no blocking entry
            (not (setq org-block-entry-blocking (org-edna-process-form form 'condition)))
          t))
    ;; Return t for the blocker to let the calling function know that there
    ;; is no block here.
    t))

;;;###autoload
(defun org-edna--load ()
  "Setup the hooks necessary for Org Edna to run.

This means adding to `org-trigger-hook' and `org-blocker-hook'."
  (add-hook 'org-trigger-hook #'org-edna-trigger-function)
  (add-hook 'org-blocker-hook #'org-edna-blocker-function))

(define-obsolete-function-alias 'org-edna-load #'org-edna-mode "1.1.1")

;;;###autoload
(defun org-edna--unload ()
  "Unload Org Edna.

Remove Edna's workers from `org-trigger-hook' and
`org-blocker-hook'."
  (remove-hook 'org-trigger-hook #'org-edna-trigger-function)
  (remove-hook 'org-blocker-hook #'org-edna-blocker-function))

(define-obsolete-function-alias 'org-edna-unload #'org-edna-mode "1.1.1")

;;;###autoload
(define-minor-mode org-edna-mode
  "Toggle Org Edna mode."
  :init-value nil
  :lighter " edna"
  :group 'org-edna
  :global t
  (if org-edna-mode
      (org-edna--load)
    (org-edna--unload)))


;;; Finders

;; Tag Finder
(defun org-edna-finder/match (match-spec &optional scope skip)
  "Find entries using Org matching.

Edna Syntax: match(\"MATCH-SPEC\" SCOPE SKIP)

MATCH-SPEC may be any valid match string; it is passed straight
into `org-map-entries'.

SCOPE and SKIP are their counterparts in `org-map-entries'.
SCOPE defaults to agenda, and SKIP defaults to nil.  Because of
the different defaults in SCOPE, the symbol `buffer' may also be
used.  This indicates that scope should be the current buffer,
honoring any restriction (the equivalent of the nil SCOPE in
`org-map-entries'.)

* TODO Test
  :PROPERTIES:
  :BLOCKER:  match(\"test&mine\" agenda)
  :END:

\"Test\" will block until all entries tagged \"test\" and
\"mine\" in the agenda files are marked DONE."
  ;; Our default is agenda...
  (setq scope (or scope 'agenda))
  ;; ...but theirs is the buffer
  (when (eq scope 'buffer) (setq scope nil))
  (org-map-entries
   ;; Find all entries in the agenda files that match the given tag.
   (lambda nil (point-marker))
   match-spec scope skip))

;; ID finder
(defun org-edna-finder/ids (&rest ids)
  "Find a list of headings with given IDS.

Edna Syntax: ids(ID1 ID2 ...)

Each ID is a UUID as understood by `org-id-find'.  Alternatively,
ID may also be id:UUID, where UUID is a UUID as understood by
`org-id-find'.

Note that in the edna syntax, the IDs don't need to be quoted."
  (mapcar
   (lambda (id)
     (if (string-prefix-p "id:" id)
         (org-id-find (string-remove-prefix "id:" id) 'marker)
       (org-id-find id 'marker)))
   ids))

(defun org-edna-finder/self ()
  "Finder for the current heading.

Edna Syntax: self"
  (list (point-marker)))

(defun org-edna-first-sibling ()
  "Return a marker to the first child of the current level."
  (org-with-wide-buffer
   (org-up-heading-safe)
   (org-goto-first-child)
   (point-marker)))

(defun org-edna-last-sibling ()
  "Return a marker to the first child of the current level."
  ;; Unfortunately, we have to iterate through every heading on this level to
  ;; find the first one.
  (org-with-wide-buffer
   (while (org-goto-sibling)
     ;; Do nothing, just keep going down
     )
   (point-marker)))

(defun org-edna-goto-sibling (&optional previous wrap)
  "Move to the next sibling on the same level as the current heading.

If PREVIOUS is non-nil, go to the previous sibling.
f WRAP is non-nil, wrap around when the beginning (or end) is
reached."
  (let ((next (save-excursion
                (if previous (org-get-last-sibling) (org-get-next-sibling)))))
    (cond
     ;; We have a sibling, so go to it and return non-nil
     (next (goto-char next))
     ;; We have no sibling, and we're not wrapping, so return nil
     ((not wrap) nil)
     (t
      ;; Go to the first child if going forward, or the last if going backward,
      ;; and return non-nil.
      (goto-char
       (if previous
           (org-edna-last-sibling)
         (org-edna-first-sibling)))
      t))))

(defun org-edna-self-marker ()
  "Return a marker to the current heading."
  (org-with-wide-buffer
   (and (ignore-errors (org-back-to-heading t) (point-marker)))))

(defun org-edna-collect-current-level (start backward wrap include-point)
  "Collect the headings on the current level.

START is a point or marker from which to start collection.

BACKWARD means go backward through the level instead of forward.

If WRAP is non-nil, wrap around when the end of the current level
is reached.

If INCLUDE-POINT is non-nil, include the current point."
  (org-with-wide-buffer
   (let ((markers))
     (goto-char start)
     ;; Handle including point
     (when include-point
       (push (point-marker) markers))
     (while (and (org-edna-goto-sibling backward wrap)
                 (not (equal (point-marker) start)))
       (push (point-marker) markers))
     (nreverse markers))))

(defun org-edna-collect-ancestors (&optional with-self)
  "Collect the ancestors of the current subtree.

If WITH-SELF is non-nil, include the current subtree in the list
of ancestors.

Return a list of markers for the ancestors."
  (let ((markers))
    (when with-self
      (push (point-marker) markers))
    (org-with-wide-buffer
     (while (org-up-heading-safe)
       (push (point-marker) markers)))
    (nreverse markers)))

(defun org-edna-collect-descendants (&optional with-self)
  "Collect the descendants of the current subtree.

If WITH-SELF is non-nil, include the current subtree in the list
of descendants.

Return a list of markers for the descendants."
  (let ((targets
         (org-with-wide-buffer
          (org-map-entries
           (lambda nil (point-marker))
           nil 'tree))))
    ;; Remove the first one (self) if we didn't want self
    (unless with-self
      (pop targets))
    targets))

(defun org-edna-entry-has-tags-p (&rest tags)
  "Return non-nil if the current entry has any tags in TAGS."
  (when-let* ((entry-tags (org-get-tags nil t)))
    (seq-intersection tags entry-tags)))

(defun org-edna--get-timestamp-time (pom &optional inherit)
  "Get the timestamp time as a time tuple, of a format suitable
for calling org-schedule with, or if there is no timestamp,
returns nil."
  (let ((time (org-entry-get pom "TIMESTAMP" inherit)))
    (when time
      (apply #'encode-time (org-parse-time-string time)))))

(defun org-edna-finder/relatives (&rest options)
  "Find some relative of the current heading.

Edna Syntax: relatives(OPTION OPTION...)
Edna Syntax: chain-find(OPTION OPTION...)

Identical to the chain argument in org-depend, relatives selects
its single target using the following method:

1. Creates a list of possible targets
2. Filters the targets from Step 1
3. Sorts the targets from Step 2

One option from each of the following three categories may be
used; if more than one is specified, the last will be used.
Filtering is the exception to this; each filter argument adds to
the current filter.  Apart from that, argument order is
irrelevant.

The chain-find finder is also provided for backwards
compatibility, and for similarity to org-depend.

All arguments are symbols, unless noted otherwise.

*Selection*

- from-top:             Select siblings of the current heading, starting at the top
- from-bottom:          As above, but from the bottom
- from-current:         Selects siblings, starting from the heading (wraps)
- no-wrap:              As above, but without wrapping
- forward-no-wrap:      Find entries on the same level, going forward
- forward-wrap:         As above, but wrap when the end is reached
- backward-no-wrap:     Find entries on the same level, going backward
- backward-wrap:        As above, but wrap when the start is reached
- walk-up:              Walk up the tree, excluding self
- walk-up-with-self:    As above, but including self
- walk-down:            Recursively walk down the tree, excluding self
- walk-down-with-self:  As above, but including self
- step-down:            Collect headings from one level down

*Filtering*

- todo-only:          Select only targets with TODO state set that isn't a DONE state
- todo-and-done-only: Select all targets with a TODO state set
- no-comments:        Skip commented headings
- no-archive:         Skip archived headings
- NUMBER:             Only use that many headings, starting from the first one
                      If passed 0, use all headings
                      If <0, omit that many headings from the end
- \"+tag\":           Only select headings with given tag
- \"-tag\":           Only select headings without tag
- \"REGEX\":          select headings whose titles match REGEX

*Sorting*

- no-sort:         Remove other sorting in affect
- reverse-sort:    Reverse other sorts (stacks with other sort methods)
- random-sort:     Sort in a random order
- priority-up:     Sort by priority, highest first
- priority-down:   Same, but lowest first
- effort-up:       Sort by effort, highest first
- effort-down:     Sort by effort, lowest first
- scheduled-up:    Scheduled time, farthest first
- scheduled-down:  Scheduled time, closest first
- deadline-up:     Deadline time, farthest first
- deadline-down:   Deadline time, closest first
- timestamp-up:    Timestamp time, farthest first
- timestamp-down:  Timestamp time, closest first"
  (let (targets
        sortfun
        reverse-sort
        (idx 0) ;; By default, use all entries
        filterfuns ;; No filtering by default
        ;; From org-depend.el:
        ;; (and (not todo-and-done-only)
        ;;      (member (second item) org-done-keywords))
        )
    (dolist (opt options)
      (pcase opt
        ('from-top
         (setq targets (org-edna-collect-current-level (org-edna-first-sibling) nil nil t)))
        ('from-bottom
         (setq targets (org-edna-collect-current-level (org-edna-last-sibling) t nil t)))
        ((or 'from-current 'forward-wrap)
         (setq targets (org-edna-collect-current-level (org-edna-self-marker) nil t nil)))
        ((or 'no-wrap 'forward-no-wrap)
         (setq targets (org-edna-collect-current-level (org-edna-self-marker) nil nil nil)))
        ('backward-no-wrap
         (setq targets (org-edna-collect-current-level (org-edna-self-marker) t nil nil)))
        ('backward-wrap
         (setq targets (org-edna-collect-current-level (org-edna-self-marker) t t nil)))
        ('walk-up
         (setq targets (org-edna-collect-ancestors nil)))
        ('walk-up-with-self
         (setq targets (org-edna-collect-ancestors t)))
        ('walk-down
         (setq targets (org-edna-collect-descendants nil)))
        ('walk-down-with-self
         (setq targets (org-edna-collect-descendants t)))
        ('step-down
         (setq targets
               (org-with-wide-buffer
                (when (org-goto-first-child)
                  (org-edna-collect-current-level (org-edna-self-marker) nil nil t)))))
        ('todo-only
         ;; Remove any entry without a TODO keyword, or with a DONE keyword
         (cl-pushnew
          (lambda (target)
            (let ((kwd (org-entry-get target "TODO")))
              (or (not kwd)
                  (member kwd org-done-keywords))))
          filterfuns
          :test #'equal))
        ('todo-and-done-only
         ;; Remove any entry without a TODO keyword
         (cl-pushnew
          (lambda (target)
            (not (org-entry-get target "TODO")))
          filterfuns :test #'equal))
        ((pred numberp)
         (setq idx opt))
        ((and (pred stringp)
              (pred (lambda (opt) (string-match-p "^\\+" opt))))
         (cl-pushnew
          (lambda (target)
            ;; This is a function that will return non-nil if the entry should
            ;; be removed, so remove those entries that don't have the tag
            (org-with-point-at target
              (not (org-edna-entry-has-tags-p (string-remove-prefix "+" opt)))))
          filterfuns :test #'equal))
        ((and (pred stringp)
              (pred (lambda (opt) (string-match-p "^\\-" opt))))
         (cl-pushnew
          (lambda (target)
            ;; This is a function that will return non-nil if the entry should
            ;; be removed, so remove those entries that DO have the tag
            (org-with-point-at target
              (org-edna-entry-has-tags-p (string-remove-prefix "-" opt))))
          filterfuns :test #'equal))
        ((pred stringp)
         (cl-pushnew
          (lambda (target)
            ;; Return non-nil if entry doesn't match the regular expression, so
            ;; it will be removed.
            (not (string-match-p opt
                               (org-with-point-at target
                                 (org-get-heading t t t t)))))
          filterfuns :test #'equal))
        ('no-comment
         (cl-pushnew
          (lambda (target)
            (org-with-point-at target
              (org-in-commented-heading-p)))
          filterfuns :test #'equal))
        ('no-archive
         (cl-pushnew
          (lambda (target)
            (org-with-point-at target
              (org-edna-entry-has-tags-p org-archive-tag)))
          filterfuns :test #'equal))
        ('no-sort
         (setq sortfun nil
               reverse-sort nil))
        ('random-sort
         (setq sortfun
               (lambda (_rhs _lhs)
                 (let ((l (random 100))
                       (r (random 100)))
                   (< l r)))))
        ('reverse-sort
         (setq reverse-sort t))
        ('priority-up
         ;; A is highest priority, but assigned the lowest value, so we need to
         ;; reverse the sort here.
         (setq sortfun
               (lambda (lhs rhs)
                 (let ((priority-lhs (org-entry-get lhs "PRIORITY"))
                       (priority-rhs (org-entry-get rhs "PRIORITY")))
                   (string-lessp priority-lhs priority-rhs)))))
        ('priority-down
         (setq sortfun
               (lambda (lhs rhs)
                 (let ((priority-lhs (org-entry-get lhs "PRIORITY"))
                       (priority-rhs (org-entry-get rhs "PRIORITY")))
                   (not (string-lessp priority-lhs priority-rhs))))))
        ('effort-up
         (setq sortfun
               (lambda (lhs rhs)
                 (let ((effort-lhs (org-duration-to-minutes (org-entry-get lhs "EFFORT")))
                       (effort-rhs (org-duration-to-minutes (org-entry-get rhs "EFFORT"))))
                   (not (< effort-lhs effort-rhs))))))
        ('effort-down
         (setq sortfun
               (lambda (lhs rhs)
                 (let ((effort-lhs (org-duration-to-minutes (org-entry-get lhs "EFFORT")))
                       (effort-rhs (org-duration-to-minutes (org-entry-get rhs "EFFORT"))))
                   (< effort-lhs effort-rhs)))))
        ('scheduled-up
         (setq sortfun
               (lambda (lhs rhs)
                 (let ((time-lhs (org-get-scheduled-time lhs))
                       (time-rhs (org-get-scheduled-time rhs)))
                   (not (time-less-p time-lhs time-rhs))))))
        ('scheduled-down
         (setq sortfun
               (lambda (lhs rhs)
                 (let ((time-lhs (org-get-scheduled-time lhs))
                       (time-rhs (org-get-scheduled-time rhs)))
                   (time-less-p time-lhs time-rhs)))))
        ('deadline-up
         (setq sortfun
               (lambda (lhs rhs)
                 (let ((time-lhs (org-get-deadline-time lhs))
                       (time-rhs (org-get-deadline-time rhs)))
                   (not (time-less-p time-lhs time-rhs))))))
        ('deadline-down
         (setq sortfun
               (lambda (lhs rhs)
                 (let ((time-lhs (org-get-deadline-time lhs))
                       (time-rhs (org-get-deadline-time rhs)))
                   (time-less-p time-lhs time-rhs)))))
        ('timestamp-up
         (setq sortfun
               (lambda (lhs rhs)
                 (let ((time-lhs (org-edna--get-timestamp-time lhs))
                       (time-rhs (org-edna--get-timestamp-time rhs)))
                   (not (time-less-p time-lhs time-rhs))))))
        ('timestamp-down
         (setq sortfun
               (lambda (lhs rhs)
                 (let ((time-lhs (org-edna--get-timestamp-time lhs))
                       (time-rhs (org-edna--get-timestamp-time rhs)))
                   (time-less-p time-lhs time-rhs)))))))
    (setq filterfuns (nreverse filterfuns))
    (when (and targets sortfun)
      (setq targets (seq-sort sortfun targets)))
    (dolist (filterfun filterfuns)
      (setq targets (seq-remove filterfun targets)))
    (when reverse-sort
      (setq targets (nreverse targets)))
    (when (and targets (/= idx 0))
      (if (> idx (seq-length targets))
          (message "Edna relatives finder got index %s out of bounds of target size; ignoring" idx)
        (setq targets (seq-subseq targets 0 idx))))
    targets))

(defalias 'org-edna-finder/chain-find #'org-edna-finder/relatives)

(defun org-edna-finder/siblings (&rest options)
  "Finder for all siblings of the source heading.

Edna Syntax: siblings(OPTIONS...)

Siblings are returned in order, starting from the first heading.

See `org-edna-finder/relatives' for the OPTIONS argument."
  (apply #'org-edna-finder/relatives 'from-top options))

(defun org-edna-finder/rest-of-siblings (&rest options)
  "Finder for the siblings after the source heading.

Edna Syntax: rest-of-siblings(OPTIONS...)

Siblings are returned in order, starting from the first heading
after the source heading.

See `org-edna-finder/relatives' for the OPTIONS argument."
  (apply #'org-edna-finder/relatives 'forward-no-wrap options))

(defun org-edna-finder/rest-of-siblings-wrap (&rest options)
  "Finder for all siblings of the source heading.

Edna Syntax: rest-of-siblings-wrap(OPTIONS...)

Siblings are returned in order, starting from the first heading
after the source heading and wrapping when it reaches the end.

See `org-edna-finder/relatives' for the OPTIONS argument."
  (apply #'org-edna-finder/relatives 'forward-wrap options))

(defalias 'org-edna-finder/siblings-wrap #'org-edna-finder/rest-of-siblings-wrap)

(defun org-edna-finder/next-sibling (&rest options)
  "Finder for the next sibling after the source heading.

Edna Syntax: next-sibling(OPTIONS...)

If the source heading is the last of its siblings, no target is
returned.

See `org-edna-finder/relatives' for the OPTIONS argument."
  (apply #'org-edna-finder/relatives 1 'forward-no-wrap options))

(defun org-edna-finder/next-sibling-wrap (&rest options)
  "Finder for the next sibling after the source heading.

Edna Syntax: next-sibling-wrap(OPTIONS...)

If the source heading is the last of its siblings, its first
sibling is returned.

See `org-edna-finder/relatives' for the OPTIONS argument."
  (apply #'org-edna-finder/relatives 1 'forward-wrap options))

(defun org-edna-finder/previous-sibling (&rest options)
  "Finder for the first sibling before the source heading.

Edna Syntax: previous-sibling(OPTIONS...)

If the source heading is the first of its siblings, no target is
returned.

See `org-edna-finder/relatives' for the OPTIONS argument."
  (apply #'org-edna-finder/relatives 1 'backward-no-wrap options))

(defun org-edna-finder/previous-sibling-wrap (&rest options)
  "Finder for the first sibling before the source heading.

Edna Syntax: previous-sibling-wrap(OPTIONS...)

If the source heading is the first of its siblings, no target is
returned.

See `org-edna-finder/relatives' for the OPTIONS argument."
  (apply #'org-edna-finder/relatives 1 'backward-wrap options))

(defun org-edna-finder/first-child (&rest options)
  "Return the first child of the source heading.

Edna Syntax: first-child(OPTIONS...)

If the source heading has no children, no target is returned.

See `org-edna-finder/relatives' for the OPTIONS argument."
  (apply #'org-edna-finder/relatives 1 'step-down options))

(defun org-edna-finder/children (&rest options)
  "Finder for the immediate children of the source heading.

Edna Syntax: children(OPTIONS...)

If the source has no children, no target is returned.

See `org-edna-finder/relatives' for the OPTIONS argument."
  (apply #'org-edna-finder/relatives 'step-down options))

(defun org-edna-finder/parent (&rest options)
  "Finder for the parent of the source heading.

Edna Syntax: parent(OPTIONS...)

If the source heading is a top-level heading, no target is
returned.

See `org-edna-finder/relatives' for the OPTIONS argument."
  (apply #'org-edna-finder/relatives 1 'walk-up options))

(defun org-edna-finder/descendants (&rest options)
  "Finder for all descendants of the source heading.

Edna Syntax: descendants(OPTIONS...)

This is ALL descendants of the source heading, across all
levels.  This also includes the source heading.

See `org-edna-finder/relatives' for the OPTIONS argument."
  (apply #'org-edna-finder/relatives 'walk-down options))

(defun org-edna-finder/ancestors (&rest options)
  "Finder for the ancestors of the source heading.

Edna Syntax: ancestors(OPTIONS...)

Example:

* TODO Heading 1
** TODO Heading 2
*** TODO Heading 3
**** TODO Heading 4
***** TODO Heading 5
      :PROPERTIES:
      :BLOCKER:  ancestors
      :END:

In the above example, Heading 5 will be blocked until Heading 1,
Heading 3, and Heading 4 are marked DONE, while Heading 2 is
ignored.

See `org-edna-finder/relatives' for the OPTIONS argument."
  (apply #'org-edna-finder/relatives 'walk-up options))

(defun org-edna-finder/olp (file olp)
  "Finder for heading by its outline path.

Edna Syntax: olp(\"FILE\" \"OLP\")

Finds the heading given by OLP in FILE.  Both arguments are
strings.  OLP is an outline path.  Example:

* TODO Test
  :PROPERTIES:
  :BLOCKER:  olp(\"test.org\" \"path/to/heading\")
  :END:

Test will block if the heading \"path/to/heading\" in
\"test.org\" is not DONE."
  (let ((marker (org-find-olp (cons file (split-string-and-unquote olp "/")))))
    (when (markerp marker)
      (list marker))))

;; TODO: Clean up the buffer when it's finished

(defun org-edna-finder/file (file)
  "Finder for a file by its name.

Edna Syntax: file(\"FILE\")

FILE is the full path to the desired file.  The returned target
will be the minimum point in the file.

* TODO Test
  :PROPERTIES:
  :BLOCKER:  file(\"~/myfile.org\") headings?
  :END:

Here, \"Test\" will block until myfile.org is clear of headings.

Note that this does not give a valid heading, so any conditions
or actions that require will throw an error.  Consult the
documentation for individual actions or conditions to determine
which ones will and won't work."
  ;; If there isn't a buffer visiting file, then there's no point in having a
  ;; marker to the start of the file, so use `find-file-noselect'.
  (with-current-buffer (find-file-noselect file)
    (list (point-min-marker))))

(defun org-edna-finder/org-file (file)
  "Finder for FILE in `org-directory'.

Edna Syntax: org-file(\"FILE\")

FILE is the relative path of a file in `org-directory'.  Nested
files are allowed, such as \"my-directory/my-file.org\".  The
returned target is the minimum point of FILE.

* TODO Test
  :PROPERTIES:
  :BLOCKER:  org-file(\"test.org\")
  :END:

Note that the file still requires an extension; the \"org\" here
just means to look in `org-directory', not necessarily an
`org-mode' file.

Note that this does not give a valid heading, so any conditions
or actions that require will throw an error.  Consult the
documentation for individual actions or conditions to determine
which ones will and won't work."
  (with-current-buffer (find-file-noselect (expand-file-name file org-directory))
    (list (point-min-marker))))


;;; Actions

;; Set TODO state
(defun org-edna-action/todo! (_last-entry new-state)
  "Action to set a target heading's TODO state to NEW-STATE.

Edna Syntax: todo!(NEW-STATE)
Edna Syntax: todo!(\"NEW-STATE\")

NEW-STATE may either be a symbol or a string.  If it is a symbol,
the symbol name is used for the new state.  Otherwise, it is a
string for the new state, or \"\" to remove the state."
  (org-todo (if (stringp new-state) new-state (symbol-name new-state))))

;; Set planning info

(defun org-edna--mod-timestamp (time-stamp n what)
  "Modify the timestamp TIME-STAMP by N WHATs.

N is an integer.  WHAT can be `day', `month', `year', `minute',
`second'."
  (with-temp-buffer
    (insert time-stamp)
    (goto-char (point-min))
    (org-timestamp-change n what)
    (buffer-string)))

(defun org-edna--property-for-planning-type (type)
  (pcase type
    ('scheduled "SCHEDULED")
    ('deadline "DEADLINE")
    ('timestamp "TIMESTAMP")
    (_ "")))

(defun org-edna--get-planning-info (what)
  "Get the planning info for WHAT.

WHAT is one of `scheduled', `deadline', or `timestamp'."
  (org-entry-get nil (org-edna--property-for-planning-type what)))

;; Silence the byte-compiler
(defvar parse-time-weekdays)
(defvar parse-time-months)

(defun org-edna--read-date-get-relative (s today default)
  "Like `org-read-date-get-relative' but with a few additions.

S is a string with the form [+|-|++|--][N]THING.

THING may be any of the following:

- A weekday (WEEKDAY), in which case the number of days from
  either TODAY or DEFAULT to the next WEEKDAY will be computed.
  If N is given, jump forward that many occurrences of WEEKDAY

- The string \"weekday\" or \"wkdy\", in which jump forward X
  days to land on a weekday.  If a weekend is found instead, move
  in the direction given (+/-) until a weekday is found.

S may also end with [+|-][DAY].  DAY may be either a weekday
string, such as Monday, Tue, or Friday, or the strings
\"weekday\", \"wkdy\", \"weekend\", or \"wknd\".  The former
indicates that the time should land on the given day of the week,
while the latter group indicates that the time should land on
that type, either a weekday or a weekend.  The [+|-] in this
string indicates that the time should be incremented or
decremented to find the target day.

Return shift list (N what def-flag) to get to the desired date
WHAT       is \"M\", \"h\", \"d\", \"w\", \"m\", or \"y\" for minute, hour, day, week, month, year.
N          is the number of WHATs to shift.
DEF-FLAG   is t when a double ++ or -- indicates shift relative to
           the DEFAULT date rather than TODAY.

Examples:

\"+1d +wkdy\" finds the number of days to move ahead in order to
find a weekday.  This is the same as \"+1wkdy\", and returns (N \"d\" nil).

\"+5d -wkdy\" means move forward 5 days, then backward until a
weekday is found.  Returns (N \"d\" nil).

\"+1m +wknd\" means move forward one month, then forward until a
weekend is found.  Returns (N \"d\" nil), since day precision is
required."
  (require 'parse-time)
  (let* ((case-fold-search t) ;; ignore case when matching, so we get any
         ;; capitalization of weekday names
         (weekdays (mapcar #'car parse-time-weekdays))
         ;; type-strings maps the type of thing to the index in decoded time
         ;; (see `decode-time')
         (type-strings '(("M" . 1)
                         ("h" . 2)
                         ("d" . 3)
                         ("w" . 3)
                         ("m" . 4)
                         ("y" . 5)))
         (regexp (rx-to-string
                  `(and string-start
                        ;; Match 1: [+-]
                        (submatch (repeat 0 2 (in ?+ ?-)))
                        ;; Match 2: Digits
                        (submatch (zero-or-more digit))
                        ;; Match 3: type string (weekday, unit)
                        (submatch (or (any ,@(mapcar #'car type-strings))
                                      "weekday" "wkdy"
                                      ,@weekdays)
                                  word-end)
                        ;; Match 4 (optional): Landing specifier
                        (zero-or-one
                         (submatch (and (one-or-more " ")
                                        (submatch (zero-or-one (in ?+ ?-)))
                                        (submatch (or "weekday" "wkdy"
                                                      "weekend" "wknd"
                                                      ,@weekdays)
                                                  word-end))))
                        string-end))))
    (when (string-match regexp s)
      (let* ((dir (if (> (match-end 1) (match-beginning 1))
		      (string-to-char (substring (match-string 1 s) -1))
		    ?+))
	     (rel (and (match-end 1) (= 2 (- (match-end 1) (match-beginning 1)))))
	     (n (if (match-end 2) (string-to-number (match-string 2 s)) 1))
	     (what (if (match-end 3) (match-string 3 s) "d"))
	     (wday1 (cdr (assoc (downcase what) parse-time-weekdays)))
	     (date (if rel default today))
	     (wday (nth 6 (decode-time date)))
             ;; Are we worrying about where we land?
             (have-landing (match-end 4))
             (landing-direction (string-to-char
                                 (if (and have-landing (match-end 5))
                                     (match-string 5 s)
                                   "+")))
             (landing-type (when have-landing (match-string 6 s)))
	     delta ret)
        (setq
         ret
         (pcase what
           ;; Shorthand for +Nd +wkdy or -Nd -wkdy
           ((or "weekday" "wkdy")
            ;; Determine where we land after N days
            (let* ((del (* n (if (= dir ?-) -1 1)))
                   (end-day (mod (+ del wday) 7)))
              (while (member end-day calendar-weekend-days)
                (let ((d (if (= dir ?-) -1 1)))
                  (cl-incf del d)
                  (setq end-day (mod (+ end-day d) 7))))
              (list del "d" rel)))
           ((pred (lambda (arg) (member arg (mapcar #'car type-strings))))
            (list (* n (if (= dir ?-) -1 1)) what rel))
           ((pred (lambda (arg) (member arg weekdays)))
            (setq delta (mod (+ 7 (- wday1 wday)) 7))
	    (when (= delta 0) (setq delta 7))
	    (when (= dir ?-)
	      (setq delta (- delta 7))
	      (when (= delta 0) (setq delta -7)))
	    (when (> n 1) (setq delta (+ delta (* (1- n) (if (= dir ?-) -7 7)))))
	    (list delta "d" rel))))
        (if (or (not have-landing)
                (member what '("M" "h"))) ;; Don't change landing for minutes or hours
            ret ;; Don't worry about landing, just return
          (pcase-let* ((`(,del ,what _) ret)
                       (mod-index (cdr (assoc what type-strings)))
                       ;; Increment the appropriate entry in the original decoded time
                       (raw-landing-time
                        (let ((tmp (copy-sequence (decode-time date))))
                          (cl-incf (seq-elt tmp mod-index)
                                   ;; We increment the days by 7 when we have weeks
                                   (if (string-equal what "w") (* 7 del) del))
                          tmp))
                       (encoded-landing-time (apply #'encode-time raw-landing-time))
                       ;; Get the initial time difference in days, rounding down
                       ;; (it should be something like 3.0, so it won't matter)
                       (time-diff (truncate
                                   (/ (float-time (time-subtract encoded-landing-time
                                                                 date))
                                      86400))) ;; seconds in a day
                       ;; Decoded landing time
                       (landing-time (decode-time encoded-landing-time))
                       ;; Numeric Landing direction
                       (l-dir (if (= landing-direction ?-) -1 1))
                       ;; Current numeric day of the week on which we end
                       (end-day (nth 6 landing-time))
                       ;; Numeric days of the week on which we are allowed to land
                       (allowed-targets
                        (pcase landing-type
                          ((or "weekday" "wkdy")
                           (seq-difference (number-sequence 0 6) calendar-weekend-days))
                          ((or "weekend" "wknd")
                           calendar-weekend-days)
                          ((pred (lambda (arg) (member arg weekdays)))
                           (list (cdr (assoc (downcase landing-type) parse-time-weekdays)))))))
            ;; While we aren't looking at a valid day, move one day in the l-dir
            ;; direction.
            (while (not (member end-day allowed-targets))
              (cl-incf time-diff l-dir)
              (setq end-day (mod (+ end-day l-dir) 7)))
            (list time-diff "d" rel)))))))

(defun org-edna--float-time (arg this-time default)
  "Read a float time string from ARG.

A float time argument string is as follows:

float [+|-|++|--]?N DAYNAME[ MONTH[ DAY]]

N is an integer
DAYNAME is either an integer day of the week, or a weekday string

MONTH may be a month string or an integer.  Use 0 for the
following or previous month.

DAY is an optional integer.  If not given, it will be 1 (for
forward) or the last day of MONTH (backward).

Time is computed relative to either THIS-TIME (+/-) or
DEFAULT (++/--)."
  (require 'parse-time)
  (let* ((case-fold-search t)
         (weekdays (mapcar #'car parse-time-weekdays))
         (month-names (mapcar #'car parse-time-months))
         (regexp (rx-to-string
                  `(and string-start
                        "float "
                        ;; First argument, N
                        (submatch (repeat 0 2 (in ?+ ?-)))
                        (submatch word-start (one-or-more digit) word-end)
                        " "
                        ;; Second argument, weekday digit or string
                        (submatch word-start
                                  (or (in (?0 . ?6)) ;; Weekday digit
                                      ,@weekdays)
                                  word-end)
                        ;; Third argument, month digit or string
                        (zero-or-one
                         " " (submatch word-start
                                       (or (repeat 1 2 digit)
                                           ,@month-names)
                                       word-end)
                         ;; Fourth argument, day in month
                         (zero-or-one
                          " "
                          (submatch word-start
                                    (repeat 1 2 digit)
                                    word-end)))))))
    (when (string-match regexp arg)
      (pcase-let* ((inc (match-string 1 arg))
                   (dir (if (not (string-empty-p inc)) ;; non-empty string
		            (string-to-char (substring inc -1))
		          ?+))
	           (rel (= (length inc) 2))
                   (numeric-dir (if (= dir ?+) 1 -1))
                   (nth (* (string-to-number (match-string 2 arg)) numeric-dir))
                   (dayname (let* ((tmp (match-string 3 arg))
                                   (day (cdr (assoc (downcase tmp) parse-time-weekdays))))
                              (or day (string-to-number tmp))))
                   (month (if-let* ((tmp (match-string 4 arg)))
                              (or (cdr (assoc (downcase tmp) parse-time-months))
                                  (string-to-number tmp))
                            0))
                   (day (if (match-end 5) (string-to-number (match-string 5 arg)) 0))
                   (ts (if rel default this-time))
                   (`(_ _ _ ,dec-day ,dec-month ,dec-year _ _ _) (decode-time ts))
                   ;; If month isn't given, use the 1st of the following (or previous) month
                   ;; If month is given, use the 1st (or day, if given) of that
                   ;; following month
                   (month-given (not (= month 0)))
                   ;; If day isn't provided, pass nil to
                   ;; `calendar-nth-named-absday' so it can handle it.
                   (act-day (if (not (= day 0)) day nil))
                   (`(,act-month ,act-year)
                    (if (not month-given)
                        ;; Month wasn't given, so start at the following or previous month.
                        (list (+ dec-month (if (= dir ?+) 1 -1)) dec-year)
                      ;; Month was given, so adjust the year accordingly
                      (cond
                       ;; If month is after dec-month and we're incrementing,
                       ;; keep year
                       ((and (> month dec-month) (= dir ?+))
                        (list month dec-year))
                       ;; If month is before or the same as dec-month, and we're
                       ;; incrementing, increment year.
                       ((and (<= month dec-month) (= dir ?+))
                        (list month (1+ dec-year)))
                       ;; We're moving backwards, but month is after, so
                       ;; decrement year.
                       ((and (>= month dec-month) (= dir ?-))
                        (list month (1- dec-year)))
                       ;; We're moving backwards, and month is backward, so
                       ;; leave it.
                       ((and (< month dec-month) (= dir ?-))
                        (list month dec-year)))))
                   (abs-days-now (calendar-absolute-from-gregorian `(,dec-month
                                                                     ,dec-day
                                                                     ,dec-year)))
                   (abs-days-then (calendar-nth-named-absday nth dayname
                                                             act-month
                                                             act-year
                                                             act-day)))
        ;; Return the same arguments as `org-edna--read-date-get-relative' above.
        (list (- abs-days-then abs-days-now) "d" rel)))))

(defun org-edna--determine-timestamp-format (thing old-ts)
  ;; Returns the argument to pass to `org-timestamp-format':
  ;; t for long format (with time), nil for short format (no time).
  ;; thing is a symbol: year, month, day, hour, minute
  ;; old-ts is a timestamp string for the current entry
  (let* ((spec-ts-format (org-entry-get nil "EDNA_TS_FORMAT")))
    (cond
     ;; An old timestamp exists, so use that format.
     (old-ts
      ;; Returns t for long, nil for short, as we do.
      (org-timestamp-has-time-p
       (org-timestamp-from-string old-ts)))
     ;; If THING is minutes or hours, then a timestamp is required.
     ((memq thing '(minute hour)) t)
     ;; User specified the EDNA_TS_FORMAT property, so use it.
     (spec-ts-format
      (pcase spec-ts-format
        ("long" t)
        ("short" nil)
        (_ (error "Unknown Edna timestamp format %s; expected \"long\" or \"short\"" spec-ts-format))))
     ;; Fallback to customizable variable.
     (t
      (pcase org-edna-timestamp-format
        (`long t)
        (`short nil)
        (_ (error "Invalid value for org-edna-timestamp-format %s; expected 'long' or 'short'"
                  org-edna-timestamp-format)))))))


(defun org-edna--handle-planning (type last-entry args)
  "Handle planning of type TYPE.

LAST-ENTRY is a marker to the source entry.
ARGS is a list of arguments; currently, only the first is used."
  (let* ((arg (nth 0 args))
         (last-ts (org-with-point-at last-entry (org-edna--get-planning-info type)))
         (this-ts (org-edna--get-planning-info type))
         (this-time (and this-ts (org-time-string-to-time this-ts)))
         (current (org-current-time))
         (type-map '(("y" . year)
                     ("m" . month)
                     ("d" . day)
                     ("h" . hour)
                     ("M" . minute))))
    (cond
     ((member arg '(rm remove "rm" "remove"))
      (org-add-planning-info nil nil type))
     ((member arg '(cp copy "cp" "copy"))
      (unless last-ts
        (error "Tried to copy but last entry doesn't have a timestamp"))
      ;; Copy old time verbatim
      (org-add-planning-info type last-ts))
     ((string-match-p "\\`float " arg)
      (pcase-let* ((`(,n ,what-string ,def) (org-edna--float-time arg this-time current))
                   (what (cdr (assoc-string what-string type-map)))
                   (ts-format (org-edna--determine-timestamp-format what this-ts))
                   (current-ts (format-time-string (org-time-stamp-format ts-format) current))
                   (ts (if def current-ts this-ts)))
        (org--deadline-or-schedule nil type (org-edna--mod-timestamp ts n what))))
     ((string-match-p "\\`[+-]" arg)
      ;; Starts with a + or -, so assume we're incrementing a timestamp
      ;; We support hours and minutes, so this must be supported separately,
      ;; since org-read-date-analyze doesn't
      (pcase-let* ((`(,n ,what-string ,def) (org-edna--read-date-get-relative arg this-time current))
                   (what (cdr (assoc-string what-string type-map)))
                   (ts-format (org-edna--determine-timestamp-format what this-ts))
                   (current-ts (format-time-string (org-time-stamp-format ts-format) current))
                   (ts (if def current-ts this-ts)))
        ;; Ensure that the source timestamp exists
        (unless ts
          (error "Tried to increment a non-existent timestamp"))
        (org--deadline-or-schedule nil type (org-edna--mod-timestamp ts n what))))
     (t
      ;; For everything else, assume `org-read-date-analyze' can handle it

      ;; The third argument to `org-read-date-analyze' specifies the defaults to
      ;; use if that time component isn't specified.  Since there's no way to
      ;; tell if a time was specified, tell `org-read-date-analyze' to use nil
      ;; if no time is found.
      (let* ((case-fold-search t)
             (parsed-time (org-read-date-analyze arg this-time '(nil nil nil nil nil nil)))
             (have-time (nth 2 parsed-time))
             (final-time (apply #'encode-time (mapcar (lambda (e) (or e 0)) parsed-time)))
             (new-ts (format-time-string (if have-time "%F %R" "%F") final-time)))
        (org--deadline-or-schedule nil type new-ts))))))

(defun org-edna-action/scheduled! (last-entry &rest args)
  "Action to set the scheduled time of a target heading based on ARGS.

Edna Syntax: scheduled!(\"DATE[ TIME]\")                                [1]
Edna Syntax: scheduled!(rm|remove)                                      [2]
Edna Syntax: scheduled!(cp|copy)                                        [3]
Edna Syntax: scheduled!(\"[+|-|++|--]NTHING[ [+|-]LANDING]\")           [4]
Edna Syntax: scheduled!(\"float [+|-|++|--]?N DAYNAME [ DAY[ MONTH]]\") [5]

In form 1, schedule the target for the given date and time.  If
DATE is a weekday instead of a date, schedule the target for the
following weekday.  If it is a date, schedule it for that date
exactly.  TIME is a time string, such as HH:MM.  If it isn't
specified, only a date will be applied to the target.  Any string
recognized by `org-read-date' may be used.

Form 2 will remove the scheduled time from the target.

Form 3 will copy the scheduled time from LAST-ENTRY (the current
heading) to the target.

Form 4 increments(+) or decrements(-) the target's scheduled time
by N THINGS relative to either itself (+/-) or the current
time (++/--).  THING is one of y (years), m (months), d (days),
h (hours), or M (minutes), and N is an integer.

Form 4 may also include a \"landing\" specification.  This is
either (a) a day of the week (\"Sun\", \"friday\", etc.), (b)
\"weekday\" or \"wkdy\", or (c) \"weekend\" or \"wknd\".

If (a), then the target date will be adjusted forward (+) or
backward (-) to find the closest target day of the week.
Form (b) will adjust the target time to find a weekday, and (c)
does the same, but for weekends.

Form 5 handles \"float\" time, named for `diary-float'.  This
form will set the target's scheduled time to the date of the Nth
DAYNAME after/before MONTH DAY.  MONTH may be a month string or
an integer.  Use 0 or leave blank for the following or previous
month.  DAY is an optional integer.  If not given, it will be
1 (for forward) or the last day of MONTH (backward).

For information on how the new timestamp format is chosen when
using ++, see `org-edna-timestamp-format'."
  (org-edna--handle-planning 'scheduled last-entry args))

(defun org-edna-action/deadline! (last-entry &rest args)
  "Action to set the deadline time of a target heading based on ARGS.

Edna Syntax: deadline!(\"DATE[ TIME]\")                                [1]
Edna Syntax: deadline!(rm|remove)                                      [2]
Edna Syntax: deadline!(cp|copy)                                        [3]
Edna Syntax: deadline!(\"[+|-|++|--]NTHING[ [+|-]LANDING]\")           [4]
Edna Syntax: deadline!(\"float [+|-|++|--]?N DAYNAME [ DAY[ MONTH]]\") [5]

In form 1, set the deadline the target for the given date and
time.  If DATE is a weekday instead of a date, set the deadline
the target for the following weekday.  If it is a date, set the
deadline it for that date exactly.  TIME is a time string, such
as HH:MM.  If it isn't specified, only a date will be applied to
the target.  Any string recognized by `org-read-date' may be
used.

Form 2 will remove the deadline time from the target.

Form 3 will copy the deadline time from LAST-ENTRY (the current
heading) to the target.

Form 4 increments(+) or decrements(-) the target's deadline time
by N THINGS relative to either itself (+/-) or the current
time (++/--).  THING is one of y (years), m (months), d (days),
h (hours), or M (minutes), and N is an integer.

Form 4 may also include a \"landing\" specification.  This is
either (a) a day of the week (\"Sun\", \"friday\", etc.), (b)
\"weekday\" or \"wkdy\", or (c) \"weekend\" or \"wknd\".

If (a), then the target date will be adjusted forward (+) or
backward (-) to find the closest target day of the week.
Form (b) will adjust the target time to find a weekday, and (c)
does the same, but for weekends.

Form 5 handles \"float\" time, named for `diary-float'.  This
form will set the target's scheduled time to the date of the Nth
DAYNAME after/before MONTH DAY.  MONTH may be a month string or
an integer.  Use 0 or leave blank for the following or previous
month.  DAY is an optional integer.  If not given, it will be
1 (for forward) or the last day of MONTH (backward).

For information on how the new timestamp format is chosen when
using ++, see `org-edna-timestamp-format'."
  (org-edna--handle-planning 'deadline last-entry args))

(defun org-edna-action/tag! (_last-entry tags)
  "Action to set the tags of a target heading to TAGS.

Edna Syntax: tag!(\"TAGS\")

TAGS is a valid tag specification, such as \":aa:bb:cc:\"."
  (org-set-tags tags))

(defun org-edna--string-is-numeric-p (string)
  "Return non-nil if STRING is a valid numeric string.

Examples of valid numeric strings are \"1\", \"-3\", or \"123\"."
  ;; Can't use string-to-number, because it returns 0 if STRING isn't a
  ;; number, which is ambiguous.
  (numberp (car (read-from-string string))))

(defun org-edna--increment-numeric-property (pom property &optional decrement)
  "Return the incremented value of PROPERTY at POM.

If optional argument DECREMENT is non-nil, decrement the property
value instead."
  (let* ((prop-value (org-entry-get pom property)))
    (unless prop-value
      (error "Attempted to increment/decrement unset property %s" property))
    (unless (org-edna--string-is-numeric-p prop-value)
      (error "Property %s doesn't have a numeric value (got %s)" property prop-value))
    (number-to-string (+ (if decrement -1 1) (string-to-number prop-value)))))

(defun org-edna--cycle-property (pom property &optional previous)
  "Cycle the property PROPERTY at POM through its allowed values.

Change PROPERTY to the next allowed value, unless PREVIOUS is
non-nil, in which case, cycle to the previous allowed value."
  (let* ((prop-value (org-entry-get pom property)))
    (unless prop-value
      (error "Attempted to cycle an unset property %s" property))
    (save-excursion
      ;; Jump to the property line, (required for `org-property-next-allowed-value')
      (re-search-forward (org-re-property property nil nil prop-value))
      (org-property-next-allowed-value previous))))

(defun org-edna-action/set-property! (_last-entry property value)
  "Action to set the property PROPERTY of a target heading to VALUE.

Edna Syntax: set-property!(\"PROPERTY\" \"VALUE\")

PROPERTY and VALUE are both strings.  PROPERTY must be a valid
org mode property."
  (pcase value
    ((pred stringp)
     (org-entry-put (point) property value))
    ((or `inc `dec)
     (let* ((new-value (org-edna--increment-numeric-property (point) property
                                                             (eq value 'dec))))
       (org-entry-put (point) property new-value)))
    ((or `next `prev `previous)
     (org-edna--cycle-property (point) property (memq value '(prev previous))))))

(defun org-edna-action/delete-property! (_last-entry property)
  "Action to delete a property from a target heading.

Edna Syntax: delete-property!(\"PROPERTY\")

PROPERTY must be a valid org mode property."
  (org-entry-delete nil property))

(defun org-edna-action/clock-in! (_last-entry)
  "Action to clock into a target heading.

Edna Syntax: clock-in!"
  (org-clock-in))

(defun org-edna-action/clock-out! (_last-entry)
  "Action to clock out from the current clocked heading.

Edna Syntax: clock-out!

Note that this will not necessarily clock out of the target, but
the actual running clock."
  (org-clock-out))

(defun org-edna-action/set-priority! (_last-entry priority-action)
  "Action to set the priority of a target heading.

Edna Syntax: set-priority!(\"PRIORITY-STRING\") [1]
Edna Syntax: set-priority!(up)                  [2]
Edna Syntax: set-priority!(down)                [3]
Edna Syntax: set-priority!(P)                   [4]

Form 1 sets the priority to PRIORITY-STRING, so PRIORITY-STRING
must be a valid priority string, such as \"A\" or \"E\".  It may
also be the string \" \", which removes the priority from the
target.

Form 2 cycles the target's priority up through the list of
allowed priorities.

Form 3 cycles the target's priority down through the list of
allowed priorities.

Form 4: Set the target's priority to the character P."
  (org-priority (if (stringp priority-action)
                    (string-to-char priority-action)
                  priority-action)))

(defun org-edna-set-effort (value increment)
  "Set the effort property of the current entry.
With numerical prefix arg, use the nth allowed value, 0 stands for the
10th allowed value.

When INCREMENT is non-nil, set the property to the next allowed value."
  ;; NOTE: Copied from `org-set-effort', because the signature changed in 9.1.7.
  ;; Since the Org repo doesn't change its version string until after a release,
  ;; there's no way to tell when to use the old or new signature until after
  ;; 9.1.7 is released.  Therefore, we cut out the middle man and slap the
  ;; entire function here.
  (interactive "P")
  (when (equal value 0) (setq value 10))
  (let* ((completion-ignore-case t)
	 (prop org-effort-property)
	 (cur (org-entry-get nil prop))
	 (allowed (org-property-get-allowed-values nil prop 'table))
	 (existing (mapcar #'list (org-property-values prop)))
	 rpl
	 (val (cond
	       ((stringp value) value)
	       ((and allowed (integerp value))
		(or (car (nth (1- value) allowed))
		    (car (org-last allowed))))
	       ((and allowed increment)
		(or (cl-caadr (member (list cur) allowed))
		    (user-error "Allowed effort values are not set")))
	       (allowed
		(message "Select 1-9,0, [RET%s]: %s"
			 (if cur (concat "=" cur) "")
			 (mapconcat #'car allowed " "))
		(setq rpl (read-char-exclusive))
		(if (equal rpl ?\r)
		    cur
		  (setq rpl (- rpl ?0))
		  (when (equal rpl 0) (setq rpl 10))
		  (if (and (> rpl 0) (<= rpl (length allowed)))
		      (car (nth (1- rpl) allowed))
		    (org-completing-read "Effort: " allowed nil))))
	       (t
		(org-completing-read
		 (concat "Effort" (and cur (string-match "\\S-" cur)
				       (concat " [" cur "]"))
			 ": ")
		 existing nil nil "" nil cur)))))
    (unless (equal (org-entry-get nil prop) val)
      (org-entry-put nil prop val))
    (org-refresh-property
     '((effort . identity)
       (effort-minutes . org-duration-to-minutes))
     val)
    (message "%s is now %s" prop val)))

(defun org-edna-action/set-effort! (_last-entry value)
  "Action to set the effort of a target heading.

Edna Syntax: set-effort!(VALUE)     [1]
Edna Syntax: set-effort!(increment) [2]

For form 1, set the effort based on VALUE.  If VALUE is a string,
it's converted to an integer.  Otherwise, the integer is used as
the raw value for the effort.

For form 2, increment the effort to the next allowed value."
  (if (eq value 'increment)
      (org-edna-set-effort nil value)
    (org-edna-set-effort value nil)))

(defun org-edna-action/archive! (_last-entry)
  "Action to archive a target heading.

Edna Syntax: archive!

If `org-edna-prompt-for-archive', prompt before archiving the
entry."
  (if org-edna-prompt-for-archive
      (org-archive-subtree-default-with-confirmation)
    (org-archive-subtree-default)))

(defun org-edna-action/chain! (last-entry property)
  "Action to copy a property to a target heading.

Edna Syntax: chain!(\"PROPERTY\")

Copy PROPERTY from the source heading to the target heading.
Does nothing if the source heading has no property PROPERTY."
  (when-let* ((old-prop (org-entry-get last-entry property)))
    (org-entry-put nil property old-prop)))


;;; Conditions

;; For most conditions, we return true if condition is true and neg is false, or
;; if condition is false and neg is true:

;; | cond | neg | res |
;; |------+-----+-----|
;; | t    | t   | f   |
;; | t    | f   | t   |
;; | f    | t   | t   |
;; | f    | f   | f   |

;; This means that we want to take the exclusive-or of condition and neg.

(defun org-edna-condition/done? (neg)
  "Condition to check if all target headings are in the DONE state.

Edna Syntax: done?

DONE state is determined by the local value of
`org-done-keywords'.

Example:

* TODO Heading
  :PROPERTIES:
  :BLOCKER: match(\"target\") done?
  :END:

Here, \"Heading\" will block if all targets tagged \"target\" are
in a DONE state.

* TODO Heading 2
  :PROPERTIES:
  :BLOCKER: match(\"target\") !done?
  :END:

Here, \"Heading 2\" will block if all targets tagged \"target\"
are not in a DONE state."
  (when-let* ((condition
               (if neg
                   (member (org-entry-get nil "TODO") org-not-done-keywords)
                 (member (org-entry-get nil "TODO") org-done-keywords))))
    (org-get-heading)))

(defun org-edna-condition/todo-state? (neg state)
  "Condition to check if all target headings have the TODO state STATE.

Edna Syntax: todo-state?(\"STATE\")

Block the source heading if all target headings have TODO state
STATE.  STATE must be a valid TODO state string."
  (let ((condition (string-equal (org-entry-get nil "TODO") state)))
    (when (org-xor condition neg)
      (org-get-heading))))

;; Block if there are headings
(defun org-edna-condition/headings? (neg)
  "Condition to check if a target has headings in its file.

Edna Syntax: headings?

Block the source heading if any headings can be found in its
file.  This means that target does not have to be a heading."
  (let ((condition (not (seq-empty-p (org-map-entries (lambda nil t))))))
    (when (org-xor condition neg)
      (buffer-name))))

(defun org-edna-condition/variable-set? (neg var val)
  "Condition to check if a variable is set in a target.

Edna Syntax: variable-set?(VAR VAL)

Evaluate VAR when visiting a target, and compare it with `equal'
against VAL.  Block the source heading if VAR = VAL.

Target does not have to be a heading."
  (let ((condition (equal (symbol-value var) val)))
    (when (org-xor condition neg)
      (format "%s %s= %s" var (if neg "!" "=") val))))

(defun org-edna-condition/has-property? (neg prop val)
  "Condition to check if a target heading has property PROP = VAL.

Edna Syntax: has-property?(\"PROP\" \"VAL\")

Block if the target heading has the property PROP set to VAL,
both of which must be strings."
  (let ((condition (string-equal (org-entry-get nil prop) val)))
    (when (org-xor condition neg)
      (org-get-heading))))

(defun org-edna-condition/re-search? (neg match)
  "Condition to check for a regular expression in a target's file.

Edna Syntax: re-search?(\"MATCH\")

Block if regular expression MATCH can be found in target's file,
starting from target's position."
  (let ((condition (re-search-forward match nil t)))
    (when (org-xor condition neg)
      (format "%s %s in %s" (if neg "Did Not Find" "Found") match (buffer-name)))))

(defun org-edna-condition/has-tags? (neg &rest tags)
  "Check if the target heading has tags.

Edna Syntax: has-tags?(\"tag1\" \"tag2\"...)

Block if the target heading has any of the tags tag1, tag2, etc."
  (let* ((condition (apply #'org-edna-entry-has-tags-p tags)))
    (when (org-xor condition neg)
      (org-get-heading))))

(defun org-edna--heading-matches (match-string)
  "Return non-nil if the current heading matches MATCH-STRING."
  (let* ((matcher (cdr (org-make-tags-matcher match-string)))
         (todo (org-entry-get nil "TODO"))
         (tags (org-get-tags nil t))
         (level (org-reduced-level (org-outline-level))))
    (funcall matcher todo tags level)))

(defun org-edna-condition/matches? (neg match-string)
  "Matches a heading against a match string.

Edna Syntax: matches?(\"MATCH-STRING\")

Blocks if the target heading matches MATCH-STRING.

MATCH-STRING is a valid match string as passed to
`org-map-entries'."
  (let* ((condition (org-edna--heading-matches match-string)))
    (when (org-xor condition neg)
      (org-get-heading))))


;;; Consideration

(defun org-edna-handle-consideration (consideration blocks)
  "Handle consideration CONSIDERATION.

Edna Syntax: consider(any) [1]
Edna Syntax: consider(N)   [2]
Edna Syntax: consider(P)   [3]
Edna Syntax: consider(all) [4]

A blocker can be read as:
\"If ANY heading in TARGETS matches CONDITION, block this heading\"

The consideration is \"ANY\".

Form 1 blocks only if any target matches the condition.  This is
the default.

Form 2 blocks only if at least N targets meet the condition.  N=1
is the same as `any'.

Form 3 blocks only if *at least* fraction P of the targets meet
the condition.  This should be a decimal value between 0 and 1.

Form 4 blocks only if all targets match the condition.

The default consideration is \"any\".

If CONSIDERATION is nil, default to `any'.

The \"consideration\" keyword is also provided.  It functions the
same as \"consider\"."
  ;; BLOCKS is a list of entries that meets the blocking condition; if one isn't
  ;; blocked, its entry will be nil.
  (let* ((consideration (or consideration 'any))
         (first-block (seq-find #'identity blocks))
         (total-blocks (seq-length blocks))
         (fulfilled (seq-count #'not blocks))
         (blocked (- total-blocks fulfilled)))
    (pcase consideration
      ('any
       ;; In order to pass, all of them must be fulfilled, so find the first one
       ;; that isn't.
       first-block)
      ('all
       ;; All of them must be set to block, so if one of them doesn't block, the
       ;; entire entry won't block.
       (if (> fulfilled 0)
           ;; Have one fulfilled
           nil
         ;; None of them are fulfilled
         first-block))
      ((pred integerp)
       ;; A minimum number of them must meet the blocking condition, so check
       ;; how many block.
       (if (>= blocked consideration)
           first-block
         nil))
      ((pred floatp)
       ;; A certain percentage of them must block for the blocker to block.
       (let* ((float-blocked (/ (float blocked) (float total-blocks))))
         (if (>= float-blocked consideration)
             first-block
           nil))))))


;;; Popout editing

(defvar org-edna-edit-original-marker nil)
(defvar org-edna-blocker-section-marker nil)
(defvar org-edna-trigger-section-marker nil)

(defcustom org-edna-edit-buffer-name "*Org Edna Edit Blocker/Trigger*"
  "Name of the popout buffer for editing blockers/triggers."
  :type 'string)

(defun org-edna-in-edit-buffer-p ()
  "Return non-nil if inside the Edna edit buffer."
  (string-equal (buffer-name) org-edna-edit-buffer-name))

(defun org-edna-replace-newlines (string)
  "Replace newlines with spaces in STRING."
  (string-join (split-string string "\n" t) " "))

(defun org-edna-edit-text-between-markers (first-marker second-marker)
  "Collect the text between FIRST-MARKER and SECOND-MARKER."
  (buffer-substring (marker-position first-marker)
                    (marker-position second-marker)))

(defun org-edna-edit-blocker-section-text ()
  "Collect the BLOCKER section text from an edit buffer."
  (when (org-edna-in-edit-buffer-p)
    (let ((original-text (org-edna-edit-text-between-markers
                          org-edna-blocker-section-marker
                          org-edna-trigger-section-marker)))
      ;; Strip the BLOCKER key
      (when (string-match "^BLOCKER\n\\(\\(?:.*\n\\)+\\)" original-text)
        (org-edna-replace-newlines (match-string 1 original-text))))))

(defun org-edna-edit-trigger-section-text ()
  "Collect the TRIGGER section text from an edit buffer."
  (when (org-edna-in-edit-buffer-p)
    (let ((original-text (org-edna-edit-text-between-markers
                          org-edna-trigger-section-marker
                          (point-max-marker))))
      ;; Strip the TRIGGER key
      (when (string-match "^TRIGGER\n\\(\\(?:.*\n\\)+\\)" original-text)
        (org-edna-replace-newlines (match-string 1 original-text))))))

(defvar org-edna-edit-map
  (let ((map (make-sparse-keymap)))
    (org-defkey map "\C-x\C-s"      'org-edna-edit-finish)
    (org-defkey map "\C-c\C-s"      'org-edna-edit-finish)
    (org-defkey map "\C-c\C-c"      'org-edna-edit-finish)
    (org-defkey map "\C-c'"         'org-edna-edit-finish)
    (org-defkey map "\C-c\C-q"      'org-edna-edit-abort)
    (org-defkey map "\C-c\C-k"      'org-edna-edit-abort)
    map))

(defun org-edna-edit ()
  "Edit the blockers and triggers for current heading in a separate buffer."
  (interactive)
  ;; Move to the start of the current heading
  (let* ((heading-point (save-excursion
                          (org-back-to-heading)
                          (point-marker)))
         (blocker (or (org-entry-get heading-point "BLOCKER") ""))
         (trigger (or (org-entry-get heading-point "TRIGGER") ""))
         (wc (current-window-configuration))
         (sel-win (selected-window)))
    (org-switch-to-buffer-other-window org-edna-edit-buffer-name)
    (erase-buffer)
    ;; Keep global-font-lock-mode from turning on font-lock-mode
    ;; FIXME: Why do we have to do that?  Sounds like a workaround for a bug
    ;; elsewhere (is there a bug#nb for it?).
    (let ((font-lock-global-modes '(not fundamental-mode)))
      (fundamental-mode))
    (use-local-map org-edna-edit-map)
    (setq-local font-lock-global-modes (list 'not major-mode))
    (setq-local org-edna-edit-original-marker heading-point)
    (setq-local org-window-configuration wc)
    (setq-local org-selected-window sel-win)
    (setq-local org-finish-function #'org-edna-edit-finish)
    (insert "Edit blockers and triggers in this buffer under their respective sections below.
All lines under a given section will be merged into one when saving back to
the source buffer.  Finish with `C-c C-c' or abort with `C-c C-k'\n\n")
    (setq-local org-edna-blocker-section-marker (point-marker))
    (insert (format "BLOCKER\n%s\n\n" blocker))
    (setq-local org-edna-trigger-section-marker (point-marker))
    (insert (format "TRIGGER\n%s\n\n" trigger))

    ;; Change syntax table to make ! and ? symbol constituents
    (modify-syntax-entry ?! "_")
    (modify-syntax-entry ?? "_")

    ;; Set up completion
    (add-hook 'completion-at-point-functions #'org-edna-completion-at-point nil t)))

(defun org-edna-edit-finish ()
  "Finish an Edna property edit."
  (interactive)
  (let ((blocker (org-edna-edit-blocker-section-text))
        (trigger (org-edna-edit-trigger-section-text))
        (pos-marker org-edna-edit-original-marker)
        (wc org-window-configuration)
        (sel-win org-selected-window))
    (set-window-configuration wc)
    (select-window sel-win)
    (goto-char pos-marker)
    (unless (string-empty-p blocker)
      (org-entry-put nil "BLOCKER" blocker))
    (unless (string-empty-p trigger)
      (org-entry-put nil "TRIGGER" trigger))
    (kill-buffer org-edna-edit-buffer-name)))

(defun org-edna-edit-abort ()
  "Abort an Edna property edit."
  (interactive)
  (let ((pos-marker org-edna-edit-original-marker)
        (wc org-window-configuration)
        (sel-win org-selected-window))
    (set-window-configuration wc)
    (select-window sel-win)
    (goto-char pos-marker)
    (kill-buffer org-edna-edit-buffer-name)))

;;; Completion

(defun org-edna-between-markers-p (point first-marker second-marker)
  "Return non-nil if POINT is between FIRST-MARKER and SECOND-MARKER in the current buffer."
  (and (markerp first-marker)
       (markerp second-marker)
       (eq (marker-buffer first-marker)
           (marker-buffer second-marker))
       (eq (current-buffer) (marker-buffer first-marker))
       (<= (marker-position first-marker) point)
       (>= (marker-position second-marker) point)))

(defun org-edna-edit-in-blocker-section-p ()
  "Return non-nil if `point' is in an edna blocker edit section."
  (org-edna-between-markers-p (point)
                              org-edna-blocker-section-marker
                              org-edna-trigger-section-marker))

(defun org-edna-edit-in-trigger-section-p ()
  "Return non-nil if `point' is in an edna trigger edit section."
  (org-edna-between-markers-p (point)
                              org-edna-trigger-section-marker
                              (point-max-marker)))

(defun org-edna--collect-keywords (keyword-type &optional suffix)
  "Collect known Edna keywords of type KEYWORD-TYPE.

SUFFIX is an additional suffix to use when matching keywords."
  (let* ((suffix (or suffix ""))
         (edna-sym-list)
         (edna-rx (rx-to-string `(and
                                  string-start
                                  "org-edna-"
                                  ,keyword-type
                                  "/"
                                  (submatch (one-or-more ascii))
                                  ,suffix
                                  string-end))))
    (mapatoms
     (lambda (s)
       (when (and (string-match edna-rx (symbol-name s)) (fboundp s))
         (cl-pushnew (concat (match-string-no-properties 1 (symbol-name s)) suffix)
                     edna-sym-list))))
    edna-sym-list))

(defun org-edna--collect-finders ()
  "Return a list of finder keywords."
  (org-edna--collect-keywords "finder"))

(defun org-edna--collect-actions ()
  "Return a list of action keywords."
  (org-edna--collect-keywords "action" "!"))

(defun org-edna--collect-conditions ()
  "Return a list of condition keywords."
  (org-edna--collect-keywords "condition" "?"))

(defun org-edna-completions-for-blocker ()
  "Return a list of all allowed Edna keywords for a blocker."
  `(,@(org-edna--collect-finders)
    ,@(org-edna--collect-conditions)
    "consideration" "consider"))

(defun org-edna-completions-for-trigger ()
  "Return a list of all allowed Edna keywords for a trigger."
  `(,@(org-edna--collect-finders)
    ,@(org-edna--collect-actions)))

(defun org-edna-completion-table-function (string pred action)
  "Completion table function for Edna keywords.

See `minibuffer-completion-table' for description of STRING,
PRED, and ACTION."
  (let ((completions (cond
                      ;; Don't offer completion inside of arguments
                      ((> (syntax-ppss-depth (syntax-ppss)) 0) nil)
                      ((org-edna-edit-in-blocker-section-p)
                       (org-edna-completions-for-blocker))
                      ((org-edna-edit-in-trigger-section-p)
                       (org-edna-completions-for-trigger)))))
    (pcase action
      (`nil
       (try-completion string completions pred))
      (`t
       (all-completions string completions pred))
      (`lambda
        (test-completion string completions pred))
      (`(boundaries . _) nil)
      (`metadata
       `(metadata . ((category . org-edna)
                     (annotation-function . nil)
                     (display-sort-function . identity)
                     (cycle-sort-function . identity)))))))

(defun org-edna-completion-at-point ()
  "Complete the Edna keyword at point."
  (when-let* ((bounds (bounds-of-thing-at-point 'symbol)))
    (list (car bounds) (cdr bounds) #'org-edna-completion-table-function)))

(defun org-edna-describe-keyword (keyword)
  "Describe the Org Edna keyword KEYWORD.

KEYWORD should be a string for a keyword recognized by edna.

Displays help for KEYWORD in the Help buffer."
  (interactive
   (list
    (completing-read
     "Keyword: "
     `(,@(org-edna--collect-finders)
       ,@(org-edna--collect-actions)
       ,@(org-edna--collect-conditions)
       "consideration" "consider")
     nil ;; No filter predicate
     t))) ;; require match
  ;; help-split-fundoc splits the usage info from the rest of the documentation.
  ;; This avoids having another usage line in the keyword documentation that has
  ;; nothing to do with how edna expects the function.
  (pcase-let* ((`(,_type . ,func) (org-edna--function-for-key (intern keyword)))
               (`(,_usage . ,doc) (help-split-fundoc (documentation func t) func)))
    (with-help-window (help-buffer)
      (princ doc))))


;;; Bug Reports

(declare-function lm-report-bug "lisp-mnt" (topic))

(defun org-edna-submit-bug-report (topic)
  "Submit a bug report to the Edna developers.

TOPIC is the topic for the bug report."
  (interactive "sTopic: ")
  (require 'lisp-mnt)
  (let* ((src-file (locate-library "org-edna.el" t))
         (src-buf-live (find-buffer-visiting src-file))
         (src-buf (find-file-noselect src-file)))
    (with-current-buffer src-buf
      (lm-report-bug topic))
    ;; Kill the buffer if it wasn't live
    (unless src-buf-live
      (kill-buffer src-buf))))

(provide 'org-edna)

;;; org-edna.el ends here
