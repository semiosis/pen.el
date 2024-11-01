;;; evil-fringe-mark.el --- Display evil-mode marks in the fringe
;; This file is not part of GNU Emacs.

;; Copyright (C) 2019 Andrew Smith

;; Author: Andrew Smith <andy.bill.smith@gmail.com>
;; URL: https://github.com/Andrew-William-Smith/evil-fringe-mark
;; Version: 1.2.1
;; Package-Requires: ((emacs "24.3") (evil "1.0.0") (fringe-helper "0.1.1") (goto-chg "1.6"))

;; This file is part of evil-fringe-mark.

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
;; This file provides `evil-fringe-mark', which in turn provides the minor
;; modes `evil-fringe-mark-mode' and `global-evil-fringe-mark-mode'.  To
;; enable either mode, run its respective command.  These modes display
;; fringe bitmaps representing all `evil-mode' marks within a buffer; the
;; fringe in which bitmap overlays are placed may be changed by modifying
;; the global variable `evil-fringe-mark-side'.  The mode may be configured
;; to display special marks by setting `evil-fringe-mark-show-special' to a
;; non-nil value, and certain mark characters may be omitted from fringe
;; display by adding them to the list `evil-fringe-mark-ignore-chars'.

;;; Code:
(require 'cl-lib)
(require 'evil)
(require 'fringe-helper)
(require 'evil-fringe-mark-overlays)

(defgroup evil-fringe-mark nil
  "Display evil-mode marks in the fringe."
  :prefix "evil-fringe-mark-"
  :group 'evil)

(make-variable-buffer-local
 (defvar evil-fringe-mark-list '()
   "Plist of fringe overlays for buffer-local marks."))

(make-variable-buffer-local
 (defvar evil-fringe-mark-special-list '()
   "Plist of fringe overlays for buffer-local special marks."))

(defvar evil-fringe-mark-file-list '()
  "Plist of fringe overlays for file marks.")

(make-variable-buffer-local
 (defvar evil-fringe-mark-overwritten-list '()
   "List of lists of fringe characters that have been overwritten.  Each list
behaves as a linked list, with the most recently-placed mark at the head (car)."))

(defvar evil-fringe-mark-special-chars '(?< ?> 128 ?. ?^ ?{ ?} ?\[ ?\] 129)
  "List of characters to consider special marks.")

(defcustom evil-fringe-mark-show-special nil
  "Whether to display special marks (defined in `evil-fringe-mark-special-chars')
in the fringe."
  :type 'boolean)

(defcustom evil-fringe-mark-ignore-chars
  '(?')
  "Mark characters for which to never display fringe bitmaps."
  :type '(repeat integer))

(defcustom evil-fringe-mark-always-overwrite t
  "Whether to always overwrite fringe bitmaps when a new mark is placed on a
line or display the bitmap that is closer to the fringe, regardless of whether
it was placed first."
  :type 'boolean)

(defcustom evil-fringe-mark-side 'left-fringe
  "Fringe in which to place mark overlays for graphical Emacs sessions."
  :type '(choice (const :tag "Left fringe" left-fringe)
                 (const :tag "Right fringe" right-fringe)))

(defcustom evil-fringe-mark-margin 'left-margin
  "Margin in which to place mark overlays for non-graphical Emacs sessions."
  :type '(choice (const :tag "Left margin" left-margin)
                 (const :tag "Right margin" right-margin)))

(defface evil-fringe-mark-local-face
  '((t (:inherit (font-lock-keyword-face))))
  "Face with which to display buffer-local fringe marks.")

(defface evil-fringe-mark-special-face
  '((t (:inherit (fringe))))
  "Face with which to display buffer-local special fringe marks.")

(defface evil-fringe-mark-file-face
  '((t (:inherit (font-lock-type-face))))
  "Face with which to display fringe file marks.")


(defun evil-fringe-mark-char-list (char)
  "Determine the list to which a mark represented by character CHAR should belong."
  (cond
   ((member char evil-fringe-mark-special-chars) 'evil-fringe-mark-special-list)    ; Special mark
   ((>= char ?a) 'evil-fringe-mark-list)    ; Buffer-local mark
   (t 'evil-fringe-mark-file-list)))        ; File mark

(defun evil-fringe-mark-char-face (char)
  "Determine the face with which to display a mark represented by character CHAR."
  (cond
   ((member char evil-fringe-mark-special-chars) 'evil-fringe-mark-special-face)
   ((>= char ?a) 'evil-fringe-mark-local-face)
   (t 'evil-fringe-mark-file-face)))

(defun evil-fringe-mark-on-line (pos)
  "Determine what fringe indicators are on the line containing position POS."
  (let ((mark-on-line nil))
    ; Check buffer-local marks
    (cl-loop for (char overlay) on evil-fringe-mark-list by 'cddr do
             (when (and (overlay-start overlay)
                        (eq (line-number-at-pos (overlay-start overlay))
                        (line-number-at-pos pos)))
               (setq mark-on-line `(,char ,overlay))
               (cl-return)))
    ; Check file marks: Emacs has no way to combine plists
    (unless mark-on-line
      (cl-loop for (char overlay) on evil-fringe-mark-file-list by 'cddr do
               (when (and (overlay-start overlay)
                          (eq (current-buffer) (overlay-buffer overlay))
                          (eq (line-number-at-pos (overlay-start overlay))
                              (line-number-at-pos pos)))
                 (setq mark-on-line `(,char ,overlay))
                 (cl-return))))
    mark-on-line))

(defun evil-fringe-mark-put (char char-list marker &optional no-recurse)
  "Place an indicator for mark CHAR, of type CHAR-LIST, in the fringe at location
MARKER."
  (unless (or (member char evil-fringe-mark-ignore-chars)
              (minibufferp))
    (when evil-fringe-mark-always-overwrite
      (let ((old-mark (evil-fringe-mark-on-line (marker-position marker)))
            (this-stack (car (cl-remove-if-not
                              (lambda (stack) (member char stack))
                              evil-fringe-mark-overwritten-list)))
            (overwrite-overlay (plist-get (symbol-value (evil-fringe-mark-char-list char)) char))
            (overwrite-marker (make-marker))
            (old-stack nil))
        (setq old-stack (car (cl-remove-if-not
                               (lambda (stack) (member (car old-mark) stack))
                               evil-fringe-mark-overwritten-list)))
        ; Delete current element from list
        (cl-delete char (car (member (car (cl-remove-if-not
                                           (lambda (stack) (member char stack))
                                           evil-fringe-mark-overwritten-list))
                                          evil-fringe-mark-overwritten-list)))
        ; Prepend new mark to line overwrite list
        (when (and old-mark (not no-recurse))
          (evil-fringe-mark-delete (car old-mark))
          ; Prevent overwriting same character
          (unless (eq (car old-mark) char)
            (if old-stack
                (push char (car (member old-stack evil-fringe-mark-overwritten-list)))
              (push `(,char ,(car old-mark)) evil-fringe-mark-overwritten-list))))
        ; Draw new head of line overwrite list
        (when this-stack
          (when overwrite-overlay
            (set-marker overwrite-marker (overlay-start overwrite-overlay))
            (pop (car (cl-remove-if-not (lambda (stack) (member char stack))
                                        evil-fringe-mark-overwritten-list)))
            (evil-fringe-mark-put (nth 1 this-stack)
                                  (evil-fringe-mark-char-list (nth 1 this-stack))
                                  overwrite-marker t))
          ; Handle end of list
          (when (eq (length this-stack) 1)
            (setq evil-fringe-mark-overwritten-list
                  (cl-remove-if (lambda (stack) (eq this-stack stack))
                                evil-fringe-mark-overwritten-list))))))
    (let ((old-mark (plist-get (symbol-value char-list) char)))
      (when old-mark (fringe-helper-remove old-mark)))
    (set char-list (plist-put (symbol-value char-list) char
                              ; Place indicators in the fringe if running Emacs graphically
                              (if (display-graphic-p)
                                  (fringe-helper-insert
                                   (cdr (assoc char evil-fringe-mark-bitmaps)) marker
                                   evil-fringe-mark-side
                                   (evil-fringe-mark-char-face char))
                                ; Otherwise place indicators in the margin
                                (let ((margin-ov (make-overlay
                                                  (marker-position marker)
                                                  (marker-position marker))))
                                  (overlay-put margin-ov 'before-string
                                               (propertize "!" 'display `((margin ,evil-fringe-mark-margin)
                                                                          ,(char-to-string char))
                                                           'face (evil-fringe-mark-char-face char)))
                                  margin-ov))))))

(defun evil-fringe-mark-put-special (char marker)
  "Place an indicator for special mark CHAR in the fringe at location MARKER.
Special marks will not override marks placed by the user."
  (unless (evil-fringe-mark-on-line (marker-position marker))
    (evil-fringe-mark-put char 'evil-fringe-mark-special-list marker)))

(defun evil-fringe-mark-delete (char)
  "Delete the indicator for mark CHAR from the fringe."
  (let ((char-list (evil-fringe-mark-char-list char))
        (last-bitmap nil))
    (setq last-bitmap (plist-get (symbol-value char-list) char))
    (when last-bitmap
      (progn
        (fringe-helper-remove last-bitmap)
        (set char-list (evil-plist-delete char (symbol-value char-list)))))))

(defun evil-fringe-mark-refresh-visual ()
  "Redraw all special visual mark indicators in the current buffer."
  ; Only attempt to create marker if evil-visual-end is defined
  (when (and evil-fringe-mark-show-special evil-visual-end)
    (let ((visual-end-pos    (marker-position evil-visual-end))
          (visual-end-marker (make-marker)))
      ; Delete all visual special marks
      (evil-fringe-mark-delete ?<)
      (evil-fringe-mark-delete 128)
      (evil-fringe-mark-delete ?>)
      ; Handle line selection marker positioning
      (when (eq (evil-visual-type) 'line)
        (setq visual-end-pos (1- visual-end-pos)))
      (set-marker visual-end-marker visual-end-pos)
      ; Show special bitmap if start and end of visual selection are on same line
      (if (eq (line-number-at-pos (marker-position evil-visual-beginning))
              (line-number-at-pos visual-end-pos))
          (evil-fringe-mark-put-special 128 evil-visual-beginning)    ; Use a nonce ASCII character
        (evil-fringe-mark-put-special ?< evil-visual-beginning)
        (evil-fringe-mark-put-special ?> visual-end-marker)))))

(defun evil-fringe-mark-refresh-paste ()
  "Redraw all special paste (yank) mark indicators in the current buffer."
  (when evil-fringe-mark-show-special
    (let ((start-marker (make-marker))
          (end-marker   (make-marker)))
      ; Delete existing paste special marks
      (evil-fringe-mark-delete ?\[)
      (evil-fringe-mark-delete 129)
      (evil-fringe-mark-delete ?\])
      ; Get paste start and end, avoiding evil-mode boundary errors
      (save-excursion
        (if (ignore-errors (evil-goto-mark ?\[))
            (set-marker start-marker (point))
          (set-marker start-marker 1))
        (if (ignore-errors (evil-goto-mark ?\]))
            (set-marker end-marker (point))
          (set-marker end-marker (buffer-size))))
      (if (eq (line-number-at-pos (marker-position start-marker))
              (line-number-at-pos (marker-position end-marker)))
          (evil-fringe-mark-put-special 129 start-marker)    ; Another nonce character
        (evil-fringe-mark-put-special ?\[ start-marker)
        (evil-fringe-mark-put-special ?\] end-marker)))))

(defun evil-fringe-mark-refresh-special (&rest args)
  "Redraw the special mark indicators for the last change in the current buffer
and the start and end of the current paragraphs."
  (when evil-fringe-mark-show-special
    ; Paragraph start/end
    (let ((start-marker (make-marker))
          (end-marker   (make-marker)))
      (evil-fringe-mark-delete ?{)
      (evil-fringe-mark-delete ?})
      (save-excursion
        ; Avoid evil-mode boundary errors
        (if (ignore-errors (evil-goto-mark ?{))
            (set-marker start-marker (point))
          (set-marker start-marker 1)))
      (save-excursion
        (if (ignore-errors (evil-goto-mark ?}))
            (set-marker end-marker (point))
          (set-marker end-marker (buffer-size))))
      (evil-fringe-mark-put-special ?{ start-marker)
      (evil-fringe-mark-put-special ?} end-marker))
    ; Last change
    ; NOTE: Disabled due to an incompatibility between Emacs 26.1 and
    ; undo-tree that results in the excessive proliferation of canaries
    ; when trying to get evil-mode mark ?.
    ;
    ; (when (and (not (eq this-command last-command))
    ;            buffer-undo-list
    ;            (not (eq buffer-undo-list t)))
    ;   (let ((change-marker (make-marker)))
    ;     (evil-fringe-mark-delete ?.)
    ;     (save-excursion
    ;       (ignore-errors (evil-goto-mark ?.))
    ;       (set-marker change-marker (point)))
    ;     (evil-fringe-mark-put-special ?. change-marker)))))
    ))

(defun evil-fringe-mark-refresh-buffer ()
  "Redraw all mark indicators in the current buffer."
  (setq evil-fringe-mark-overwritten-list nil)
  ; Local marks
  (cl-loop for (char . marker) in evil-markers-alist do
           (when (and (markerp marker)
                      (>= char ?a))
             (evil-fringe-mark-put char 'evil-fringe-mark-list marker)))
  ; Special marks
  (evil-fringe-mark-refresh-visual)
  (evil-fringe-mark-refresh-paste)
  (evil-fringe-mark-refresh-special)
  ; Global marks
  (cl-loop for (char . marker) in (default-value 'evil-markers-alist) do
           (when (and (markerp marker)
                      (>= char ?A)
                      (eq (current-buffer) (marker-buffer marker)))
             (evil-fringe-mark-put char 'evil-fringe-mark-file-list marker))))

(defun evil-fringe-mark-clear-buffer ()
  "Delete all mark indicators from the current buffer."
  (setq evil-fringe-mark-overwritten-list nil)
  ; Local marks
  (cl-loop for (key _) on evil-fringe-mark-list by 'cddr do
           (evil-fringe-mark-delete key))
  ; Special marks
  (cl-loop for (key _) on evil-fringe-mark-special-list by 'cddr do
           (evil-fringe-mark-delete key))
  ; Global marks
  (cl-loop for (key overlay) on evil-fringe-mark-file-list by 'cddr do
           (when (eq (current-buffer) (overlay-buffer overlay))
             (evil-fringe-mark-delete key))))

(defadvice evil-set-marker (around compile)
  "Advice function for `evil-fringe-mark'."
  (let ((char      (ad-get-arg 0))
        (marker    ad-do-it)
        (char-list (evil-fringe-mark-char-list char))
        (old-mark  nil))
    (when (or evil-fringe-mark-mode global-evil-fringe-mark-mode)
      ; Handle special markers set with `evil-set-marker'
      (if (eq char-list 'evil-fringe-mark-special-list)
          (when evil-fringe-mark-show-special
            (evil-fringe-mark-put-special char marker))
        (evil-fringe-mark-put char char-list marker)))))

(defadvice evil-delete-marks (after compile)
  "Advice function for `evil-fringe-mark'."
  (evil-fringe-mark-clear-buffer)
  (evil-fringe-mark-refresh-buffer))

(defadvice evil-visual-refresh (after compile)
  "Advice function for `evil-fringe-mark'."
  (evil-fringe-mark-refresh-visual))

(defadvice evil-paste-before (after compile)
  "Advice function for `evil-fringe-mark'."
  (evil-fringe-mark-refresh-paste))

(defadvice evil-paste-after (after compile)
  "Advice function for `evil-fringe-mark'."
  (evil-fringe-mark-refresh-paste))

;;;###autoload
(define-minor-mode evil-fringe-mark-mode
  "Display evil-mode marks in the fringe."
  :lighter " EFM"
  (if evil-fringe-mark-mode
      (progn
        (evil-fringe-mark-refresh-buffer)
        (ad-activate 'evil-set-marker)
        (ad-activate 'evil-delete-marks)
        ; Only enable special mark tracking when necessary
        (unless (and (member ?< evil-fringe-mark-ignore-chars)
                     (member ?> evil-fringe-mark-ignore-chars))
          (ad-activate 'evil-visual-refresh))
        (unless (and (member ?\[ evil-fringe-mark-ignore-chars)
                     (member ?\] evil-fringe-mark-ignore-chars))
          (ad-activate 'evil-paste-before)
          (ad-activate 'evil-paste-after))
        (unless (and (member ?. evil-fringe-mark-ignore-chars)
                     (member ?{ evil-fringe-mark-ignore-chars)
                     (member ?} evil-fringe-mark-ignore-chars))
          (add-hook 'post-command-hook 'evil-fringe-mark-refresh-special)))
    (progn
      (evil-fringe-mark-clear-buffer)
      (ad-deactivate 'evil-set-marker)
      (ad-deactivate 'evil-delete-marks)
      (ad-deactivate 'evil-visual-refresh)
      (ad-deactivate 'evil-paste-before)
      (ad-deactivate 'evil-paste-after)
      (remove-hook 'post-command-hook 'evil-fringe-mark-refresh-special))))

;;;###autoload
(define-minor-mode global-evil-fringe-mark-mode
  "Display evil-mode marks in the fringe.  Global version of `evil-fringe-mark-mode'."
  :lighter " gEFM"
  :global t
  :require 'evil-fringe-mark
  (if global-evil-fringe-mark-mode
      (progn
        ; Place all marks
        (save-current-buffer
          (cl-loop for buf in (buffer-list) do
                   (set-buffer buf)
                   (evil-fringe-mark-refresh-buffer)))
        (ad-activate 'evil-set-marker)
        (ad-activate 'evil-delete-marks)
        (unless (and (member ?< evil-fringe-mark-ignore-chars)
                     (member ?> evil-fringe-mark-ignore-chars))
          (ad-activate 'evil-visual-refresh))
        (unless (and (member ?\[ evil-fringe-mark-ignore-chars)
                     (member ?\] evil-fringe-mark-ignore-chars))
          (ad-activate 'evil-paste-before)
          (ad-activate 'evil-paste-after))
        (unless (and (member ?. evil-fringe-mark-ignore-chars)
                     (member ?{ evil-fringe-mark-ignore-chars)
                     (member ?} evil-fringe-mark-ignore-chars))
          (add-hook 'post-command-hook 'evil-fringe-mark-refresh-special)))
    (progn
      ; Remove all buffer-local marks
      (save-current-buffer
        (cl-loop for buf in (buffer-list) do
                 (set-buffer buf)
                 (evil-fringe-mark-clear-buffer)))
      ; Remove all global marks
      (ad-deactivate 'evil-set-marker)
      (ad-deactivate 'evil-delete-marks)
      (ad-deactivate 'evil-visual-refresh)
      (ad-deactivate 'evil-paste-before)
      (ad-deactivate 'evil-paste-after)
      (remove-hook 'post-command-hook 'evil-fringe-mark-refresh-special))))

(provide 'evil-fringe-mark)
;;; evil-fringe-mark.el ends here
