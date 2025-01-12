;;; elfeed-score.el --- Gnus-style scoring for Elfeed  -*- lexical-binding: t; -*-

;; Copyright (C) 2019-2023 Michael Herstine <sp1ff@pobox.com>

;; Author: Michael Herstine <sp1ff@pobox.com>
;; Version: 1.2.7
;; Package-Requires: ((emacs "26.1") (elfeed "3.3.0"))
;; Keywords: news
;; URL: https://github.com/sp1ff/elfeed-score

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

;; `elfeed-score' is an add-on for `elfeed', an RSS reader for
;; Emacs.  It brings Gnus-style scoring to your RSS feeds.  Elfeed, by
;; default, displays feed entries by date.  This package allows you to
;; setup rules for assigning numeric scores to entries, and sorting
;; entries with higher scores ahead of those with lower, regardless of
;; date.  The idea is to prioritize content important to you.

;; After installing this file, enable scoring by invoking
;; `elfeed-score-enable'.  This will setup the Elfeed new entry hook,
;; the Elfeed sort function, and load the score file (if it exists).
;; Turn off scoring by invoking `elfeed-score-unload'.

;;; Code:

(require 'elfeed-score-log)
(require 'elfeed-score-rules)
(require 'elfeed-score-rule-stats)
(require 'elfeed-score-serde)
(require 'elfeed-score-scoring)
(require 'elfeed-score-maint)

(defconst elfeed-score-version "1.2.7")

(defgroup elfeed-score nil
  "Gnus-style scoring for Elfeed entries."
  :group 'comm)

(defcustom elfeed-score-score-format '("%d " 6 :right)
  "Format for scores when displayed in the Elfeed search buffer.
This is a three-tuple: the `format' format string, target width,
and alignment.  This should be (string integer keyword)
for (format width alignment).  Possible alignments are :left and
:right."
  :group 'elfeed-score
  :type '(list string integer (choice (const :left) (const :right))))

(defun elfeed-score-sort (a b)
  "Return non-nil if A should sort before B.

`elfeed-score' will substitute this for the Elfeed scoring function."

  (let ((a-score (elfeed-score-scoring-get-score-from-entry a))
        (b-score (elfeed-score-scoring-get-score-from-entry b)))
    (if (> a-score b-score)
        t
      (let ((a-date (elfeed-entry-date a))
            (b-date (elfeed-entry-date b)))
        (and (eq a-score b-score) (> a-date b-date))))))

(defun elfeed-score-set-score (score &optional ignore-region)
  "Set the score of one or more Elfeed entries to SCORE.

Their scores will be set to `elfeed-score-scoring-default-score'
by default.

If IGNORE-REGION is nil (as it will be when called
interactively), then all entries in the current region will have
their scores re-set.  If the region is not active, then only the
entry under point will be affected.  If IGNORE-REGION is t, then
only the entry under point will be affected, regardless of the
region's state."

  (interactive "P")

  (let ((score
         (if score
             (prefix-numeric-value score)
           elfeed-score-scoring-default-score))
        (entries (elfeed-search-selected ignore-region)))
    (dolist (entry entries)
      (elfeed-score-log 'info "entry %s ('%s') was directly set to %d"
                        (elfeed-entry-id entry ) (elfeed-entry-title entry) score)
      ;; Set the score, marking it as "sticky"...
      (elfeed-score-scoring-set-score-on-entry entry score t)
      ;; & update the entry.
      (elfeed-search-update-entry entry))))

(defun elfeed-score-get-score ()
  "Return the score of the entry under point.

If called interactively, print a message."

  (interactive)

  (let* ((entry (elfeed-search-selected t))
         (score (elfeed-score-scoring-get-score-from-entry entry)))
    (if (called-interactively-p 'any)
        (message "%s has a score of %d." (elfeed-entry-title entry) score))
    score))

(defun elfeed-score-format-score (score)
  "Format SCORE for printing in `elfeed-search-mode'.

The customization `elfeed-score-score-format' sets the
formatting.  This implementation is based on that of
`elfeed-search-format-date'."
  (cl-destructuring-bind (format target alignment) elfeed-score-score-format
    (let* ((string (format format score))
           (width (string-width string)))
      (cond
       ((> width target)
        (if (eq alignment :left)
            (substring string 0 target)
          (substring string (- width target) width)))
       ((< width target)
        (let ((pad (make-string (- target width) ?\s)))
          (if (eq alignment :left)
              (concat string pad)
            (concat pad string))))
       (string)))))

(defun elfeed-score-explain (&optional ignore-region)
  "Explain why some entries were scored the way they were.

Explain the scores for all the selected entries, unless
IGNORE-REGION is non-nil, in which case only the entry under
point will be explained.  If the region is not active, only the
entry under point will be explained."
  (interactive)
  (let ((entries (elfeed-search-selected ignore-region)))
    (with-help-window elfeed-score-scoring-explanation-buffer-name
      (with-current-buffer elfeed-score-scoring-explanation-buffer-name
        (dolist (entry entries)
          (elfeed-score-scoring-explain-entry entry (current-buffer)))))
    (elfeed-search-update t)))

(defun elfeed-score-load-score-file (score-file)
  "Load SCORE-FILE into the current scoring rules."

  (interactive
   (list
    (read-file-name "score file: " nil elfeed-score-serde-score-file t
                    elfeed-score-serde-score-file)))
  (elfeed-score-serde-load-score-file score-file))

(defun elfeed-score-score (&optional ignore-region)
  "Score some entries.

Score all selected entries, unless IGNORE-REGION is non-nil, in
which case only the entry under point will be scored.  If the
region is not active, only the entry under point will be scored."

  (interactive "P")

  ;; Inhibit automatic flushing of rule stats to file...
  (let ((entries (elfeed-search-selected ignore-region))
        (elfeed-score-rule-stats-dirty-threshold nil))
    (dolist (entry entries)
      (elfeed-score-scoring-score-entry entry))
    (elfeed-search-update t))
  ;; *Now* flush stats.
  (if elfeed-score-rule-stats-file
      (elfeed-score-rule-stats-write elfeed-score-rule-stats-file)))

(defun elfeed-score-score-search ()
  "Score the current set of search results."
  (interactive)
  (elfeed-score-scoring-score-search))

(defvar elfeed-score-map
  (let ((map (make-sparse-keymap)))
    (prog1 map
      (suppress-keymap map)
      (define-key map "e" #'elfeed-score-set-score)
      (define-key map "g" #'elfeed-score-get-score)
      (define-key map "l" #'elfeed-score-load-score-file)
      (define-key map "s" #'elfeed-score-score)
      (define-key map "v" #'elfeed-score-score-search)
      (define-key map "w" #'elfeed-score-serde-write-score-file)
      (define-key map "x" #'elfeed-score-explain)
      (define-key map "aT" #'elfeed-score-maint-add-title-rule)
      (define-key map "ac" #'elfeed-score-maint-add-content-rule)
      (define-key map "af" #'elfeed-score-maint-add-feed-rule)
      (define-key map "aa" #'elfeed-score-maint-add-authors-rule)
      (define-key map "at" #'elfeed-score-maint-add-tag-rule)
      (define-key map "al" #'elfeed-score-maint-add-link-rule)
      (define-key map "ao" #'elfeed-score-maint-add-title-or-content-rule)))
  "Keymap for `elfeed-score' commands.")

(defvar elfeed-score--old-sort-function nil
  "Original value of `elfeed-search-sort-function'.")

(defvar elfeed-score--old-print-entry-function nil
  "Original value of `elfed-search-print-entry-function'.")

(defun elfeed-score-print-entry (entry)
  "Print ENTRY to the Elfeed search buffer.
This implementation is derived from `elfeed-search-print-entry--default'."
  (let* ((date (elfeed-search-format-date (elfeed-entry-date entry)))
         (title (or (elfeed-meta entry :title) (elfeed-entry-title entry) ""))
         (title-faces (elfeed-search--faces (elfeed-entry-tags entry)))
         (feed (elfeed-entry-feed entry))
         (feed-title
          (when feed
            (or (elfeed-meta feed :title) (elfeed-feed-title feed))))
         (tags (mapcar #'symbol-name (elfeed-entry-tags entry)))
         (tags-str (mapconcat
                    (lambda (s) (propertize s 'face 'elfeed-search-tag-face))
                    tags ","))
         (title-width (- (window-width) 10 elfeed-search-trailing-width))
         (title-column (elfeed-format-column
                        title (elfeed-clamp
                               elfeed-search-title-min-width
                               title-width
                               elfeed-search-title-max-width)
                        :left))
	       (score
          (elfeed-score-format-score
           (elfeed-score-scoring-get-score-from-entry entry))))
    (insert score)
    (insert (propertize date 'face 'elfeed-search-date-face) " ")
    (insert (propertize title-column 'face title-faces 'kbd-help title) " ")
    (when feed-title
      (insert (propertize feed-title 'face 'elfeed-search-feed-face) " "))
    (when tags
      (insert "(" tags-str ")"))))

;;;###autoload
(defun elfeed-score-enable (&optional arg depth)
  "Enable `elfeed-score'.  With prefix ARG do not install a custom sort function.

Add the score function at DEPTH (default 0)."

  (interactive "P")

  ;; Begin scoring on every new entry...
  (add-hook 'elfeed-new-entry-hook #'elfeed-score-scoring-score-entry (or depth 0))
  ;; sort based on score...
  (unless arg
    (setq elfeed-score--old-sort-function        elfeed-search-sort-function
          elfeed-search-sort-function            #'elfeed-score-sort
          elfeed-score--old-print-entry-function elfeed-search-print-entry-function))
  ;; load the default score file (if it's defined & exists)...
  (if (and elfeed-score-serde-score-file
           (file-exists-p elfeed-score-serde-score-file))
      (elfeed-score-load-score-file elfeed-score-serde-score-file))
  ;; load the stats file (again if it's defined & exists)...
  (if (and elfeed-score-rule-stats-file
           (file-exists-p elfeed-score-rule-stats-file))
      (elfeed-score-rule-stats-read elfeed-score-rule-stats-file))
  (elfeed-score-serde-cleanup-stats)
  ;; & finally, arrange to write stats after every `elfeed' update.
  (add-hook 'elfeed-update-hooks #'elfeed-score-rule-stats-update-hook))

(defun elfeed-score-unload ()
  "Unload `elfeed-score'."

  (interactive)

  ;; No need to write the score file at this point; what's on-disk is
  ;; the SoT, anyway.
  (elfeed-score-serde-cleanup-stats)
  (if elfeed-score-rule-stats-file
	    (elfeed-score-rule-stats-write elfeed-score-rule-stats-file))
  (if elfeed-score--old-sort-function
      (setq elfeed-search-sort-function elfeed-score--old-sort-function))
  (if elfeed-score--old-print-entry-function
      (setq elfeed-search-print-entry-function elfeed-score--old-print-entry-function))
  (remove-hook 'elfeed-new-entry-hook #'elfeed-score-scoring-score-entry)
  (remove-hook 'elfeed-update-hooks #'elfeed-score-rule-stats-update-hook))

(provide 'elfeed-score)

;;; elfeed-score.el ends here
