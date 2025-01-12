;;; org-wc.el --- Count words in org mode trees.  -*- lexical-binding: t -*-

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;; Author: Simon Guest
;; Created: 2011-04-23

;; Package-Version: 20200731.2244
;; Package-Revision: dbbf794e4ec6

;;; Commentary:

;; Shows word count per heading line, summed over sub-headings.
;; Aims to be fast, so doesn't check carefully what it's counting.  ;-)
;;
;; Implementation based on:
;; - Paul Sexton's word count posted on org-mode mailing list 21/2/11.
;; - clock overlays
;;
;; v2
;; 29/4/11
;; Don't modify buffer, and fixed handling of empty sections.
;;
;; v3
;; 29/4/11
;; Handle narrowing correctly, so partial word count works on narrowed regions.

;;; Code:

(require 'org)
(require 'cl-lib)

(defun org-wc--downcase-list-of-strings-set-default (var val)
  (set-default var (mapcar #'downcase val)))

(defgroup org-wc nil
  "Options for configuring org-mode wordcount"
  :group 'org)

(defcustom org-wc-ignored-tags '("nowc" "noexport" "ARCHIVE")
  "List of tags for which subtrees will be ignored in word counts"
  :type '(repeat string)
  :safe #'org-wc-list-of-strings-p)

(defcustom org-wc-ignore-commented-trees t
  "Ignore trees with COMMENT-prefix if non-nil."
  :type 'boolean
  :safe #'booleanp)

(defcustom org-wc-default-link-count 'description-or-path
  "Default way of counting words in links.
This is applied to any link type not specified in any of
‘org-wc-ignored-link-types’,‘org-wc-one-word-link-types’, or
‘org-wc-only-description-link-types’ "
  :type '(choice
          (const :tag "Count words in description or else path part of links" description-or-path)
          (const :tag "Count words only in description part of links" description)
          (const :tag "Count links as 0 words" ignore)
          (const :tag "Count links as 1 word" oneword)
          (const :tag "Count words only in path part of links" path))
  :safe 'symbolp)

(defcustom org-wc-ignored-link-types nil
  "Link types which won't be counted as a word"
  :type '(repeat string)
  :safe #'org-wc-list-of-strings-p)

(defcustom org-wc-one-word-link-types '("zotero")
  "Link types which will be counted as one word"
  :type '(repeat string)
  :safe #'org-wc-list-of-strings-p)

(defcustom org-wc-description-or-path-link-types '()
  "Link types for which the description or the path should be counted"
  :type '(repeat string)
  :safe #'org-wc-list-of-strings-p)

(defcustom org-wc-only-description-link-types '("note")
  "Link types for which only the description should be counted"
  :type '(repeat string)
  :safe #'org-wc-list-of-strings-p)

(defcustom org-wc-only-path-link-types '()
  "Link types for which only the path should be counted"
  :type '(repeat string)
  :safe #'org-wc-list-of-strings-p)

(defcustom org-wc-blocks-to-count '("quote" "verse")
  "List of blocks which should be included in word count.

Use lower case block names"
  :type '(repeat string)
  :safe #'org-wc-list-of-strings-p
  :set #'org-wc--downcase-list-of-strings-set-default)

(defun org-wc-list-of-strings-p (arg)
  (cl-every #'stringp arg))

;;;###autoload
(defun org-word-count (beg end)
  "Report the number of words in the Org mode buffer or selected region.

Ignores heading lines, blocks, comments, drawers, and links
depending on customizable variables in customization group org-wc.

LaTeX macros are counted as 1 word. "
  (interactive
   (if (use-region-p)
       (list (region-beginning) (region-end))
     (list (point-min) (point-max))))
  (message (format "%d words in %s."
                   (org-word-count-aux beg end)
                   (if (use-region-p) "region" "buffer"))))

(defun org-word-count-aux (beg end)
  "Return the number of words between BEG and END."
  (let ((wc 0)
        subtreecount
        (latex-macro-regexp "\\\\[A-Za-z]+\\(\\[[^]]*\\]\\|\\){\\([^}]*\\)}"))
    (save-excursion
      (goto-char beg)
      ;; Handle the case where we start in a drawer
      (when (org-at-drawer-p)
        (org-end-of-meta-data t))
      (while (< (point) end)
        (cond
         ;; Handle headlines and subtrees
         ((org-at-heading-p)
          (cond
           ;; Ignore commented and org-wc-ignored-tags trees
           ((or (and org-wc-ignore-commented-trees (org-in-commented-heading-p))
                (cl-intersection org-wc-ignored-tags (org-get-tags) :test #'string=))
            (org-end-of-subtree t t))
           ;; Re-use count for subtrees already counted
           ((setq subtreecount (get-text-property (point) :org-wc))
            (cl-incf wc subtreecount)
            (org-end-of-subtree t t))
           ;; Skip counting words in headline
           (t (org-wc--goto-char (point-at-eol) end))))
         ;; Ignore most blocks.
         ((when (save-excursion
                  (beginning-of-line 1)
                  (looking-at org-block-regexp))
            (if (member (downcase (match-string 1)) org-wc-blocks-to-count)
                (progn ;; go inside block and subtract count of end line
                  (org-wc--goto-char (match-beginning 4) end)
                  (cl-decf wc))
              (org-wc--goto-char (match-end 0) end))))
         ;; Ignore comments.
         ((org-at-comment-p)
          (org-wc--goto-char (point-at-eol) end))
         ;; Ignore drawers.
         ((org-at-drawer-p)
          (org-end-of-meta-data t))
         ;; Ignore all other #+ lines
         ((looking-at "#+")
          (org-wc--goto-char (point-at-eol) end))
         ;; Handle links
         ((save-excursion
            (when (< (1+ (point-min)) (point)) (backward-char 2))
            (looking-at org-link-bracket-re))
          (let* ((type (car (save-match-data (split-string (match-string 1) ":"))))
                 (pathstart (+ 1 (length type) (match-beginning 1))))
            (cl-case (cond ((member type org-wc-ignored-link-types) 'ignore)
                           ((member type org-wc-one-word-link-types) 'oneword)
                           ((member type org-wc-only-description-link-types)
                            'description)
                           ((member type org-wc-only-path-link-types) 'path)
                           ((member type org-wc-description-or-path-link-types)
                            'description-or-path)
                           (t org-wc-default-link-count))
              (ignore (org-wc--goto-char (match-end 0) end))
              (oneword (org-wc--goto-char (match-end 0) end)
                       (cl-incf wc))
              (description (if (match-beginning 2)
                               (goto-char (match-beginning 2))
                             (org-wc--goto-char
                              (match-end 0) end)))
              (path (cl-incf wc (count-words-region pathstart
                                                    (match-end 1)))
                    (org-wc--goto-char (match-end 0) end))
              (description-or-path
               (if (match-beginning 2)
                   (goto-char (match-beginning 2))
                 (cl-incf wc (count-words-region pathstart
                                                 (match-end 1)))
                 (org-wc--goto-char (match-end 0) end)))
              (t (user-error "Error in org-wc link configuration")))))
         ;; Count latex macros as 1 word, ignoring their arguments.
         ((save-excursion
            (when (< (point-min) (point)) (backward-char))
            (looking-at latex-macro-regexp))
          (org-wc--goto-char (match-end 0) end)
          (cl-incf wc))
         (t
          (and (re-search-forward "\\w+\\W*" end 'skip)
               (cl-incf wc))))))
    wc))

;;;###autoload
(defun org-wc-count-subtrees ()
  "Count words in each subtree, putting result as the property :org-wc on that heading."
  (interactive)
  (remove-text-properties (point-min) (point-max)
                          '(:org-wc t))
  (save-excursion
    (goto-char (point-max))
    (while (outline-previous-heading)
      (save-restriction
        (org-narrow-to-subtree)
        (let ((wc (org-word-count-aux (point-min) (point-max))))
          (put-text-property (point) (point-at-eol) :org-wc wc)
          (goto-char (point-min)))))))

;;;###autoload
(defun org-wc-display (total-only)
  "Show subtree word counts in the entire buffer.
With prefix argument, only show the total wordcount for the buffer or region
in the echo area.

Use \\[org-wc-remove-overlays] to remove the subtree times.

Ignores: heading lines,
         blocks,
         comments,
         drawers.
LaTeX macros are counted as 1 word."
  (interactive "P")
  (let ((beg (if (region-active-p) (region-beginning) (point-min)))
        (end (if (region-active-p) (region-end) (point-max))))
      (org-wc-remove-overlays)
  (unless total-only
    (let ((bmp (buffer-modified-p))
          wc
          p)
      (org-wc-count-subtrees)
      (save-excursion
        (goto-char (point-min))
        (while (or (and (equal (setq p (point)) (point-min))
                        (get-text-property p :org-wc))
                   (setq p (next-single-property-change
                            (point) :org-wc)))
          (goto-char p)
          (when (setq wc (get-text-property p :org-wc))
            (org-wc-put-overlay wc)))
        ;; Arrange to remove the overlays upon next change.
        (when org-remove-highlights-with-change
          (add-hook 'before-change-functions 'org-wc-remove-overlays
                        nil 'local)))
    (set-buffer-modified-p bmp)))
    (org-word-count beg end)))

(defvar org-wc-overlays nil)
(make-variable-buffer-local 'org-wc-overlays)

(defface org-wc-overlay
  '((t (:weight bold)))
  "Face for displaying org-wc overlays.")

(defun org-wc-put-overlay (wc)
  "Put an overlay on the current line, displaying word count.
If LEVEL is given, prefix word count with a corresponding number of stars.
This creates a new overlay and stores it in `org-wc-overlays', so that it
will be easy to remove."
  (let* ((c 60)
         (off 0)
         ov tx)
    (org-move-to-column c)
    (unless (eolp) (skip-chars-backward "^ \t"))
    (skip-chars-backward " \t")
    (setq ov (make-overlay (1- (point)) (point-at-eol))
          tx (concat (buffer-substring (1- (point)) (point))
                     (make-string (+ off (max 0 (- c (current-column)))) ?.)
                     (org-add-props (format "%s" (number-to-string wc))
                         (list 'face 'org-wc-overlay))
                     ""))
    (if (not (featurep 'xemacs))
        (overlay-put ov 'display tx)
      (overlay-put ov 'invisible t)
      (overlay-put ov 'end-glyph (make-glyph tx)))
    (push ov org-wc-overlays)))

;;;###autoload
(defun org-wc-remove-overlays (&optional _beg _end noremove)
  "Remove the occur highlights from the buffer.
BEG and END are ignored.  If NOREMOVE is nil, remove this function
from the `before-change-functions' in the current buffer."
  (interactive)
  (unless org-inhibit-highlight-removal
    (mapc 'delete-overlay org-wc-overlays)
    (setq org-wc-overlays nil)
    (unless noremove
      (remove-hook 'before-change-functions
                   'org-wc-remove-overlays 'local))))

(defun org-wc--goto-char (char end)
  "Moves point to CHAR and from there passes 0+ non-word characters.
Searchers to end as a maximum.

This ensures that we are in an expected state (at the first word
character after some non-word characters) after moving beyond
headlines, links etc."
  (goto-char char)
  (re-search-forward "\\W*" end 'skip))


(provide 'org-wc)
;;; org-wc.el ends here
