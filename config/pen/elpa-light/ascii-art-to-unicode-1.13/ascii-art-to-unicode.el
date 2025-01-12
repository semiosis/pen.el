;;; ascii-art-to-unicode.el --- a small artist adjunct -*- lexical-binding: t -*-

;; Copyright (C) 2014-2020 Free Software Foundation, Inc.

;; Author: Thien-Thi Nguyen <ttn@gnu.org>
;; Maintainer: Thien-Thi Nguyen <ttn@gnu.org>
;; Version: 1.13
;; Keywords: ascii, unicode, box-drawing
;; URL: http://www.gnuvola.org/software/aa2u/

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

;; The command ‘aa2u’ converts simple ASCII art line drawings in
;; the {active,accessible} region of the current buffer to Unicode.
;; Command ‘aa2u-rectangle’ is like ‘aa2u’, but works on rectangles.
;;
;; Example use case:
;; - M-x artist-mode RET
;; - C-c C-a r               ; artist-select-op-rectangle
;; - (draw two rectangles)
;;
;;   +---------------+
;;   |               |
;;   |       +-------+--+
;;   |       |       |  |
;;   |       |       |  |
;;   |       |       |  |
;;   +-------+-------+  |
;;           |          |
;;           |          |
;;           |          |
;;           +----------+
;;
;; - C-c C-c                 ; artist-mode-off (optional)
;; - C-x n n                 ; narrow-to-region
;; - M-x aa2u RET
;;
;;   ┌───────────────┐
;;   │               │
;;   │       ┌───────┼──┐
;;   │       │       │  │
;;   │       │       │  │
;;   │       │       │  │
;;   └───────┼───────┘  │
;;           │          │
;;           │          │
;;           │          │
;;           └──────────┘
;;
;; Much easier on the eyes now!
;;
;; Normally, lines are drawn with the ‘LIGHT’ weight.  If you set var
;; ‘aa2u-uniform-weight’ to symbol ‘HEAVY’, you will see, instead:
;;
;;   ┏━━━━━━━━━━━━━━━┓
;;   ┃               ┃
;;   ┃       ┏━━━━━━━╋━━┓
;;   ┃       ┃       ┃  ┃
;;   ┃       ┃       ┃  ┃
;;   ┃       ┃       ┃  ┃
;;   ┗━━━━━━━╋━━━━━━━┛  ┃
;;           ┃          ┃
;;           ┃          ┃
;;           ┃          ┃
;;           ┗━━━━━━━━━━┛
;;
;; To protect particular ‘|’, ‘-’ or ‘+’ characters from conversion,
;; you can set the property ‘aa2u-text’ on that text with command
;; ‘aa2u-mark-as-text’.  A prefix arg clears the property, instead.
;; (You can use ‘describe-text-properties’ to check.)  For example:
;;
;;      ┌───────────────────┐
;;      │                   │
;;      │ |\/|              │
;;      │ ‘Oo’   --Oop Ack! │
;;      │  ^&-MM.           │
;;      │                   │
;;      └─────────┬─────────┘
;;                │
;;            """""""""
;;
;; Command ‘aa2u-mark-rectangle-as-text’ is similar, for rectangles.
;;
;; Tip: For best results, you should make sure all the tab characaters
;; are converted to spaces.  See: ‘untabify’, ‘indent-tabs-mode’.

;;; Code:

(require 'cl-lib)
(require 'pcase)

(autoload 'apply-on-rectangle "rect")

(defvar aa2u-uniform-weight 'LIGHT
  "A symbol, one of: ‘LIGHT’, ‘HEAVY’, ‘DOUBLE’.
This specifies the weight of all the lines.")

;;;---------------------------------------------------------------------------
;;; support

(defalias 'aa2u--lookup-char
  ;; Keep some slack: don't ‘eval-when-compile’ here.
  (if (hash-table-p (ucs-names))
      ;; Emacs 26 and later
      #'gethash
    ;; prior to Emacs 26
    (lambda (string alist)
      (cdr (assoc-string string alist)))))

(defsubst aa2u--text-p (pos)
  (get-text-property pos 'aa2u-text))

(defun aa2u-ucs-bd-uniform-name (&rest components)
  "Return the name of the UCS box-drawing char w/ COMPONENTS.
The string begins with \"BOX DRAWINGS\"; followed by the weight
as per variable ‘aa2u-uniform-weight’, followed by COMPONENTS,
a list of one or two symbols from the set:

  VERTICAL
  HORIZONTAL
  DOWN
  UP
  RIGHT
  LEFT

If of length two, the first element in COMPONENTS should be
the \"Y-axis\" (VERTICAL, DOWN, UP).  In that case, the returned
string includes \"AND\" between the elements of COMPONENTS.

Lastly, all words are separated by space (U+20)."
  (format "BOX DRAWINGS %s %s"
          aa2u-uniform-weight
          (mapconcat 'symbol-name components
                     " AND ")))

(defun aa2u-1c (stringifier &rest components)
  "Apply STRINGIFIER to COMPONENTS; return the UCS char w/ this name.
The char is a string (of length one), with two properties:

  aa2u-stringifier
  aa2u-components

Their values are STRINGIFIER and COMPONENTS, respectively."
  (let* ((store (ucs-names))
         (key (apply stringifier components))
         (s (string (if (hash-table-p store)
                        ;; modern: hash table
                        (gethash key store)
                      ;; classic: alist
                      (cdr (assoc-string key store))))))
    (propertize s
                'aa2u-stringifier stringifier
                'aa2u-components components)))

(defun aa2u-phase-1 ()
  (cl-flet
      ((gsr (was name)
            (goto-char (point-min))
            (let ((now (aa2u-1c 'aa2u-ucs-bd-uniform-name name)))
              (while (search-forward was nil t)
                (unless (aa2u--text-p (match-beginning 0))
                  (replace-match now t t))))))
    (gsr "|" 'VERTICAL)
    (gsr "-" 'HORIZONTAL)))

(defun aa2u-replacement (pos)
  (let ((cc (- pos (line-beginning-position))))
    (cl-flet*
        ((ok (name pos)
             (when (or
                    ;; Infer LIGHTness between "snug" ‘?+’es.
                    ;;              |
                    ;;  +-----------++--+   +
                    ;;  | somewhere ++--+---+-+----+
                    ;;  +-+---------+ nowhere |+--+
                    ;;    +         +---------++
                    ;;              |      +---|
                    (eq ?+ (char-after pos))
                    ;; Require properly directional neighborliness.
                    (memq (cl-case name
                            ((UP DOWN)    'VERTICAL)
                            ((LEFT RIGHT) 'HORIZONTAL))
                          (get-text-property pos 'aa2u-components)))
               name))
         (v (name dir) (let ((bol (line-beginning-position dir))
                             (eol (line-end-position dir)))
                         (when (< cc (- eol bol))
                           (ok name (+ bol cc)))))
         (h (name dir) (let ((bol (line-beginning-position))
                             (eol (line-end-position))
                             (pos (+ pos dir)))
                         (unless (or (> bol pos)
                                     (<= eol pos))
                           (ok name pos))))
         (two-p (ls) (= 2 (length ls)))
         (just (&rest args) (delq nil args)))
      (apply 'aa2u-1c
             'aa2u-ucs-bd-uniform-name
             (just (pcase (just (v 'UP   0)
                                (v 'DOWN 2))
                     ((pred two-p) 'VERTICAL)
                     (`(,vc)        vc)
                     (_             nil))
                   (pcase (just (h 'LEFT  -1)
                                (h 'RIGHT  1))
                     ((pred two-p) 'HORIZONTAL)
                     (`(,hc)        hc)
                     (_             nil)))))))

(defun aa2u-phase-2 ()
  (goto-char (point-min))
  (let (changes)
    ;; (phase 2.1 -- what WOULD change)
    ;; This is for the benefit of ‘aa2u-replacement ok’, which
    ;; otherwise (monolithic phase 2) would need to convert the
    ;; "properly directional neighborliness" impl from a simple
    ;; ‘memq’ to an ‘intersction’.
    (while (search-forward "+" nil t)
      (let ((p (point)))
        (unless (aa2u--text-p (1- p))
          (push (cons p (or (aa2u-replacement (1- p))
                            "?"))
                changes))))
    ;; (phase 2.2 -- apply changes)
    (dolist (ch changes)
      (goto-char (car ch))
      (delete-char -1)
      (insert (cdr ch)))))

(defun aa2u-phase-3 ()
  (remove-text-properties (point-min) (point-max)
                          (list 'aa2u-stringifier nil
                                'aa2u-components nil)))

;;;---------------------------------------------------------------------------
;;; commands

;;;###autoload
(defun aa2u (beg end &optional interactive)
  "Convert simple ASCII art line drawings to Unicode.
Specifically, perform the following replacements:

  - (hyphen)          BOX DRAWINGS LIGHT HORIZONTAL
  | (vertical bar)    BOX DRAWINGS LIGHT VERTICAL
  + (plus)            (one of)
                      BOX DRAWINGS LIGHT VERTICAL AND HORIZONTAL
                      BOX DRAWINGS LIGHT DOWN AND RIGHT
                      BOX DRAWINGS LIGHT DOWN AND LEFT
                      BOX DRAWINGS LIGHT UP AND RIGHT
                      BOX DRAWINGS LIGHT UP AND LEFT
                      BOX DRAWINGS LIGHT VERTICAL AND RIGHT
                      BOX DRAWINGS LIGHT VERTICAL AND LEFT
                      BOX DRAWINGS LIGHT UP AND HORIZONTAL
                      BOX DRAWINGS LIGHT DOWN AND HORIZONTAL
                      BOX DRAWINGS LIGHT UP
                      BOX DRAWINGS LIGHT DOWN
                      BOX DRAWINGS LIGHT LEFT
                      BOX DRAWINGS LIGHT RIGHT
                      QUESTION MARK

More precisely, hyphen and vertical bar are substituted unconditionally,
first, and plus is substituted with a character depending on its north,
south, east and west neighbors.

NB: Actually, ‘aa2u’ can also use \"HEAVY\" instead of \"LIGHT\",
depending on the value of variable ‘aa2u-uniform-weight’.

This command operates on either the active region,
or the accessible portion otherwise."
  (interactive "r\np")
  ;; This weirdness, along w/ the undocumented "p" in the ‘interactive’
  ;; form, is to allow ‘M-x aa2u’ (interactive invocation) w/ no region
  ;; selected to default to the accessible portion (as documented), which
  ;; was the norm in ascii-art-to-unicode.el prior to 1.5.  A bugfix,
  ;; essentially.  This is ugly, unfortunately -- is there a better way?!
  (when (and interactive (not (region-active-p)))
    (setq beg (point-min)
          end (point-max)))
  (save-excursion
    (save-restriction
      (widen)
      (narrow-to-region beg end)
      (aa2u-phase-1)
      (aa2u-phase-2)
      (aa2u-phase-3))))

;;;###autoload
(defun aa2u-rectangle (start end)
  "Like ‘aa2u’ on the region-rectangle.
When called from a program the rectangle's corners
are START (top left) and END (bottom right)."
  (interactive "r")
  (let* ((was (delete-extract-rectangle start end))
         (now (with-temp-buffer
                (insert-rectangle was)
                (aa2u (point) (mark))
                (extract-rectangle (point-min) (point-max)))))
    (goto-char (min start end))
    (insert-rectangle now)))

;;;###autoload
(defun aa2u-mark-as-text (start end &optional unmark)
  "Set property ‘aa2u-text’ of the text from START to END.
This prevents ‘aa2u’ from misinterpreting \"|\", \"-\" and \"+\"
in that region as lines and intersections to be replaced.
Prefix arg means to remove property ‘aa2u-text’, instead."
  (interactive "r\nP")
  (funcall (if unmark
               'remove-text-properties
             'add-text-properties)
           start end
           '(aa2u-text t)))

;;;###autoload
(defun aa2u-mark-rectangle-as-text (start end &optional unmark)
  "Like ‘aa2u-mark-as-text’ on the region-rectangle.
When called from a program the rectangle's corners
are START (top left) and END (bottom right)."
  (interactive "r\nP")
  (apply-on-rectangle
   (lambda (scol ecol unmark)
     (let ((p (point)))
       (aa2u-mark-as-text (+ p scol) (+ p ecol) unmark)))
   start end
   unmark))

;;;---------------------------------------------------------------------------
;;; that's it

(provide 'ascii-art-to-unicode)

;;; ascii-art-to-unicode.el ends here
