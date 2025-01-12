;;; xpm-m2z.el --- (% span 2) => 0             -*- lexical-binding: t -*-

;; Copyright (C) 2014-2021 Free Software Foundation, Inc.

;; Author: Thien-Thi Nguyen <ttn@gnu.org>
;; Maintainer: Thien-Thi Nguyen <ttn@gnu.org>

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

;; Although artist.el is wonderful, it doesn't (yet) do subpixel-centered
;; circles (or ellipses).  Those shapes are always rendered with an odd
;; "span", i.e., (% (- HI LO -1) 2) => 1, since the origin is *on* an
;; integral coordinate (i.e., intersection of row and column).
;;
;; This file provides funcs ‘xpm-m2z-ellipse’ and ‘xpm-m2z-circle’ to
;; locally rectify the current situation ("m2z" means "modulo 2 => 0"),
;; with the hope that eventually a generalization can be worked back
;; into artist.el, perhaps as a subpixel-center minor mode of some sort.

;;; Code:

(require 'artist)
(require 'cl-lib)

;;;###autoload
(defun xpm-m2z-ellipse (cx cy rx ry)
  "Return an ellipse with center (CX,CY) and radii RX and RY.
Both CX and CY must be non-integer, preferably
precisely half-way between integers, e.g., 13/2 => 6.5.
The ellipse is represented as a list of unique XPM coords,
with the \"span\", i.e., (- HI LO -1), of the extreme X and Y
components equal to twice the rounded (to integer) value of
RX and RY, respectively.  For example:

 (xpm-m2z-ellipse 1.5 3.5 5.8 4.2)
 => list of length 20

    min  max  span
 X   -3    6    10
 Y    0    7     8

The span is always an even number.  As a special case, if the
absolute value of RX or RY is less than 1, the value is nil."
  (cl-assert (and (not (integerp cx))
                  (not (integerp cy)))
             nil "Integer component in center coordinate: (%S,%S)"
             cx cy)
  (unless (or (> 1 (abs rx))
              (> 1 (abs ry)))
    (cl-flet*
        ((offset (coord idx)
                 (- (aref coord idx) 0.5))
         (normal (coord)
                 ;; flip axes: artist (ROW,COL) to xpm (X,Y)
                 (cons
                  (offset coord 1)      ; 1: COL -> car: X
                  (offset coord 0)))    ; 0: ROW -> cdr: Y
         (placed (origin scale n)
                 (truncate (+ origin (* scale n))))
         (orient (coords quadrant)
                 (cl-loop
                  with (sx . sy) = quadrant
                  for (x . y) in coords
                  collect (cons (placed cx sx x)
                                (placed cy sy y)))))
      (delete-dups
       (cl-loop
        with coords = (mapcar
                       #'normal
                       (artist-ellipse-generate-quadrant
                        ;; Specify row first; artist.el is like that.
                        ;; (That's why ‘normal’ does what it does...)
                        ry rx))
        for quadrant                    ; these are in order: I-IV
        in '(( 1 .  1)                  ; todo: "manually" remove single
             (-1 .  1)                  ;       (border point) overlaps;
             (-1 . -1)                  ;       avoid ‘delete-dups’
             ( 1 . -1))
        append (orient coords quadrant))))))

;;;###autoload
(defun xpm-m2z-circle (cx cy radius)
  "Like ‘xpm-m2z-ellipse’ with a shared radius RADIUS."
  (xpm-m2z-ellipse cx cy radius radius))

(provide 'xpm-m2z)

;;; xpm-m2z.el ends here
