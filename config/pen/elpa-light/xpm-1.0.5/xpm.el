;;; xpm.el --- edit XPM images               -*- lexical-binding: t -*-

;; Copyright (C) 2014-2021 Free Software Foundation, Inc.

;; Author: Thien-Thi Nguyen <ttn@gnu.org>
;; Maintainer: Thien-Thi Nguyen <ttn@gnu.org>
;; Version: 1.0.5
;; Package-Requires: ((cl-lib "0.5") (queue "0.2"))
;; Keywords: multimedia, xpm
;; URL: https://www.gnuvola.org/software/xpm/

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

;; This package makes editing XPM images easy (and maybe fun).
;; Editing is done directly on the (textual) image format,
;; for maximal cohesion w/ the Emacs Way.
;;
;; Coordinates have the form (X . Y), with X from 0 to (width-1),
;; and Y from 0 to (height-1), inclusive, in the 4th quadrant;
;; i.e., X grows left to right, Y top to bottom, origin top-left.
;;
;;   (0,0)        … (width-1,0)
;;     ⋮                    ⋮
;;   (0,height-1) … (width-1,height-1)
;;
;; In xpm.el (et al), "px" stands for "pixel", a non-empty string
;; in the external representation of the image.  The px length is
;; the image's "cpp" (characters per pixel).  The "palette" is a
;; set of associations between a px and its "color", which is an
;; alist with symbolic TYPE and and string CVALUE.  TYPE is one of:
;;
;;   c  -- color (most common)
;;   s  -- symbolic
;;   g  -- grayscale
;;   g4 -- four-level grayscale
;;   m  -- monochrome
;;
;; and CVALUE is a string, e.g., "blue" or "#0000FF".  Two images
;; are "congruent" if their width, height and cpp are identical.
;;
;; This package was originally conceived for non-interactive use,
;; so its design is spartan at the core.  However, we plan to add
;; a XPM mode in a future release; monitor the homepage for updates.
;;
;; For now, the features (w/ correspondingly-named files) are:
;; - xpm          -- edit XPM images
;; - xpm-m2z      -- ellipse/circle w/ fractional center
;;
;; Some things are autoloaded.  Which ones?  Use the source, Luke!
;; (Alternatively, just ask on help-gnu-emacs (at gnu dot org).)

;;; Code:

(require 'cl-lib)

(autoload 'image-toggle-display "image-mode" t) ; hmm is this TRT?

(defvar xpm-raster-inhibit-continuity-optimization nil
  "Non-nil disables a heuristic in ‘xpm-raster’ filling.
Normally, if you pass a well-formed (closed, no edge crossings)
shape to ‘xpm-raster’, then you can ignore this variable.")

(cl-defstruct (xpm--gg                  ; gathered gleanings
               (:type vector)           ; no ‘:named’ so no predicate
               (:conc-name xpm--)
               (:constructor xpm--make-gg)
               (:copier xpm--copy-gg))
  (w nil :read-only t) (h nil :read-only t) (cpp nil :read-only t)
  pinfo                                 ; (MARKER . HASH-TABLE)
  (origin nil :read-only t)
  (y-mult nil :read-only t)
  flags)

(defvar xpm--gg nil
  "Various bits for xpm.el (et al) internal use.")

;;;###autoload
(defun xpm-grok (&optional simple)
  "Analyze buffer and prepare internal data structures.
When called as a command, display in the echo area a
summary of image dimensions, cpp and palette.
Set buffer-local variable ‘xpm--gg’ and return its value.
Normally, preparation includes making certain parts of the
buffer intangible.  Optional arg SIMPLE non-nil inhibits that."
  (interactive)
  (unless (or
           ;; easy
           (and (boundp 'image-type)
                (eq 'xpm image-type))
           ;; hard
           (save-excursion
             (goto-char (point-min))
             (string= "/* XPM */"
                      (buffer-substring-no-properties
                       (point) (line-end-position)))))
    (error "Buffer not an XPM image"))
  (when (eq 'image-mode major-mode)
    (image-toggle-display))
  (let ((ht (make-hash-table :test 'equal))
        pinfo gg)
    (save-excursion
      (goto-char (point-min))
      (search-forward "{")
      (skip-chars-forward "^\"")
      (cl-destructuring-bind (w h nc cpp &rest rest)
          (read (format "(%s)" (read (current-buffer))))
        (ignore rest)                   ; for now
        (forward-line 1)
        (setq pinfo (point-marker))
        (cl-loop
         repeat nc
         do (let ((p (1+ (point))))
              (puthash (buffer-substring-no-properties
                        p (+ p cpp))
                       ;; Don't bother w/ CVALUE for now.
                       t ht)
              (forward-line 1)))
        (setq pinfo (cons pinfo ht))
        (skip-chars-forward "^\"")
        (forward-char 1)
        (set (make-local-variable 'xpm--gg)
             (setq gg (xpm--make-gg
                       :w w :h h :cpp cpp
                       :pinfo  pinfo
                       :origin (point-marker)
                       :y-mult (+ 4 (* cpp w)))))
        (unless simple
          (let ((mod (buffer-modified-p))
                (inhibit-read-only t))
            (cl-flet
                ((suppress (span &rest more)
                           (let ((p (point)))
                             (add-text-properties
                              (- p span) p (cl-list*
                                            'intangible t
                                            more)))))
              (suppress 1)
              (cl-loop
               repeat h
               do (progn (forward-char (+ 4 (* w cpp)))
                         (suppress 4)))
              (suppress 2 'display "\n")
              (push 'intangible-sides (xpm--flags gg)))
            (set-buffer-modified-p mod)))
        (when (called-interactively-p 'interactive)
          (message "%dx%d, %d cpp, %d colors in palette"
                   w h cpp (hash-table-count ht)))))
    gg))

(defun xpm--gate ()
  (or xpm--gg
      (xpm-grok)
      (error "Sorry, xpm confused")))

(cl-defmacro xpm--w/gg (names from &body body)
  (declare (indent 2))
  `(let* ((gg ,from)
          ,@(mapcar (lambda (name)
                      `(,name (,(intern (format "xpm--%s" name))
                               gg)))
                    `,names))
     ,@body))

;;;###autoload
(defun xpm-generate-buffer (name width height cpp palette)
  "Return a new buffer in XPM image format.
In this buffer, undo is disabled (see ‘buffer-enable-undo’).

NAME is the buffer and XPM name.  For best interoperation
with other programs, NAME should be a valid C identifier.
WIDTH, HEIGHT and CPP are integers that specify the image
width, height and characters/pixel, respectively.

PALETTE is an alist ((PX . COLOR) ...), where PX is either
a character or string of length CPP, and COLOR is a string.
If COLOR includes a space, it is included directly,
otherwise it is automatically prefixed with \"c \".

For example, to produce palette fragment:

 \"X  c blue\",
 \"Y  s border c green\",

you can specify PALETTE as:

 ((?X . \"blue\")
  (?Y . \"s border c green\"))

This example presumes CPP is 1."
  (let ((buf (generate-new-buffer name)))
    (with-current-buffer buf
      (buffer-disable-undo)
      (cl-flet
          ((yep (s &rest args)
                (insert (apply 'format s args) "\n")))
        (yep "/* XPM */")
        (yep "static char * %s[] = {" name)
        (yep "\"%d %d %d %d\"," width height (length palette) cpp)
        (cl-loop
         for (px . color) in palette
         do (yep "\"%s  %s\","
                 (if (characterp px)
                     (string px)
                   px)
                 (if (string-match " " color)
                     color
                   (concat "c " color))))
        (cl-loop
         with s = (format "%S,\n" (make-string (* cpp width) 32))
         repeat height
         do (insert s))
        (delete-char -2)
        (yep "};")
        (xpm-grok t)))
    buf))

(defun xpm-put-points (px x y)
  "Place PX at coordinate(s) (X,Y).

If both X and Y are vectors of length N, then place N points
using the pairwise vector elements.  If one of X or Y is a vector
of length N and the other component is an integer, then pair the
vector elements with the integer component and place N points.

If one of X or Y is a pair (LOW . HIGH), take it to be equivalent
to specfiying a vector [LOW ... HIGH].  For example, (3 . 8) is
equivalent to [3 4 5 6 7 8].  If one component is a pair, the
other must be an integer -- the case where both X and Y are pairs
is not supported.

Silently ignore out-of-range coordinates."
  (xpm--w/gg (w h cpp origin y-mult) (xpm--gate)
    (when (and (stringp px) (= 1 cpp))
      (setq px (aref px 0)))
    (cl-flet*
        ((out (col row)
              (or (> 0 col) (<= w col)
                  (> 0 row) (<= h row)))
         (pos (col row)
              (goto-char (+ origin (* cpp col) (* y-mult row))))
         (jam (col row len)
              (pos col row)
              (insert-char px len)
              (delete-char len))
         (rep (col row len)
              (pos col row)
              (if (= 1 cpp)
                  (insert-char px len)
                (cl-loop
                 repeat len
                 do (insert px)))
              (delete-char (* cpp len)))
         (zow (col row)
              (unless (out col row)
                (rep col row 1))))
      (pcase (cons (type-of x) (type-of y))
        (`(cons . integer)    (let* ((beg (max 0 (car x)))
                                     (end (min (1- w) (cdr x)))
                                     (len (- end beg -1)))
                                (unless (or (> 1 len)
                                            (out beg y))
                                  (if (< 1 cpp)
                                      ;; general
                                      (rep beg y len)
                                    ;; fast(er) path
                                    (when (stringp px)
                                      (setq px (aref px 0)))
                                    (jam beg y len)))))
        (`(integer . cons)    (cl-loop
                               for two from (car y) to (cdr y)
                               do (zow x two)))
        (`(vector . integer)  (cl-loop
                               for one across x
                               do (zow one y)))
        (`(integer . vector)  (cl-loop
                               for two across y
                               do (zow x two)))
        (`(vector . vector)   (cl-loop
                               for one across x
                               for two across y
                               do (zow one two)))
        (`(integer . integer) (zow x y))
        (_ (error "Bad coordinates: X %S, Y %S"
                  x y))))))

(defun xpm-raster (form edge &optional fill)
  "Rasterize FORM with EDGE pixel (character or string).
FORM is a list of coordinates that comprise a closed shape.
Optional arg FILL specifies a fill pixel, or t to fill with EDGE.

If FORM is not closed or has inopportune vertical-facing
concavities, filling might give bad results.  For those cases,
see variable ‘xpm-raster-inhibit-continuity-optimization’."
  (when (eq t fill)
    (setq fill edge))
  (xpm--w/gg (h) (xpm--gate)
    (let* ((v (make-vector h nil))
           (x-min (caar form))          ; (maybe) todo: xpm--bb
           (x-max x-min)
           (y-min (cdar form))
           (y-max y-min)
           (use-in-map (not xpm-raster-inhibit-continuity-optimization))
           ;; These are bool-vectors to keep track of both internal
           ;; (filled and its "next" (double-buffering)) and external
           ;; state, on a line-by-line basis.
           int nin
           ext)
      (cl-loop
       for (x . y) in form
       do (setq x-min (min x-min x)
                x-max (max x-max x)
                y-min (min y-min y)
                y-max (max y-max y))
       unless (or (> 0 y)
                  (<= h y))
       do (push x (aref v y)))
      (cl-flet
          ((span (lo hi)
                 (- hi lo -1))
           (norm (n)
                 (- n x-min))
           (rset (bv start len value)
                 (cl-loop
                  for i from start repeat len
                  do (aset bv i value)))
           (scan (bv start len yes no)
                 (cl-loop
                  for i from start repeat len
                  when (aref bv i)
                  return yes
                  finally return no)))
        (let ((len (span x-min x-max)))
          (setq int (make-bool-vector len nil)
                nin (make-bool-vector len nil)
                ext (make-bool-vector len t)))
        (cl-loop
         with (ls
               in-map-ok
               in-map)
         for y from (1- y-min) to y-max
         when (setq ls (and (< -1 y)
                            (> h y)
                            (sort (aref v y) '>)))
         do (cl-loop
             with acc = (list (car ls))
             for maybe in (cdr ls)
             do (let* ((was (car acc))
                       (already (consp was)))
                  (cond ((/= (1- (if already
                                     (car was)
                                   was))
                             maybe)
                         (push maybe acc))
                        (already
                         (setcar was maybe))
                        (t
                         (setcar acc (cons maybe was)))))
             finally do
             (when fill
               (let ((was (length in-map))
                     (now (length acc)))
                 (unless (setq in-map-ok
                               (and (= was now)
                                    ;; heuristic: Avoid being fooled
                                    ;; by simulataneous crossings.
                                    (cl-evenp was)))
                   (setq in-map (make-bool-vector now nil)))))
             finally do
             (cl-loop
              with (x rangep beg nx end len nb in)
              for gap from 0
              while acc
              do (setq x (pop acc))
              do (xpm-put-points edge x y)
              do (when fill
                   (setq rangep (consp x))
                   (when (zerop gap)
                     (rset ext 0 (norm (if rangep
                                           (car x)
                                         x))
                           t))
                   (if rangep
                       (cl-destructuring-bind (b . e) x
                         (rset ext (norm b) (span b e) nil))
                     (aset ext (norm x) nil))
                   (when acc
                     (setq beg (1+ (if rangep
                                       (cdr x)
                                     x))
                           nx (car acc)
                           end (1- (if (consp nx)
                                       (car nx)
                                     nx))
                           len (span beg end)
                           nb (norm beg)
                           in (cond ((and use-in-map in-map-ok)
                                     (aref in-map gap))
                                    (in (scan int nb len t nil))
                                    (t (scan ext nb len nil t))))
                     (unless in-map-ok
                       (aset in-map gap in))
                     (if (not in)
                         (rset ext nb len t)
                       (rset nin nb len t)
                       (xpm-put-points fill (cons beg end) y))))
              finally do (when fill
                           (cl-rotatef int nin)
                           (fillarray nin nil)))))))))

(defun xpm-as-xpm (&rest props)
  "Return the XPM image (via ‘create-image’) of the buffer.
PROPS are additional image properties to place on
the new XPM.  See info node `(elisp) XPM Images'."
  (apply 'create-image (buffer-substring-no-properties
                        (point-min) (point-max))
         'xpm t props))

(defun xpm-finish (&rest props)
  "Like ‘xpm-as-xpm’, but also kill the buffer afterwards."
  (prog1 (apply 'xpm-as-xpm props)
    (kill-buffer nil)))

(provide 'xpm)

;;; xpm.el ends here
