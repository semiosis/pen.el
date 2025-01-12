;;; hyperdrive-ewoc.el --- Common EWOC behavior for Hyperdrive  -*- lexical-binding: t; -*-

;; Copyright (C) 2023, 2024  USHIN, Inc.

;; Author: Joseph Turner <joseph@ushin.org>

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU Affero General Public License
;; as published by the Free Software Foundation, either version 3 of
;; the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; Affero General Public License for more details.

;; You should have received a copy of the GNU Affero General Public
;; License along with this program. If not, see
;; <https://www.gnu.org/licenses/>.

;;; Commentary:

;;

;;; Code:

;;;; Requirements

(require 'cl-lib)
(require 'ewoc)

(require 'hyperdrive-lib)

;;;; Variables

(defvar-local h/ewoc nil
  "EWOC for current hyperdrive buffer.")
(put 'h/ewoc 'permanent-local t)

;;;; Functions

(cl-defun h/ewoc-find-node (ewoc data &key (predicate #'eq))
  "Return the last node in EWOC whose DATA matches PREDICATE.
PREDICATE is called with DATA and node's data.  Searches backward from
last node."
  (declare (indent defun))
  ;; Intended to be like `ewoc-collect', but returning as soon as a match is found.
  (cl-loop with node = (ewoc-nth ewoc -1)
           while node
           when (funcall predicate data (ewoc-data node))
           return node
           do (setf node (ewoc-prev ewoc node))))

;;;; Mode

(defvar-keymap h/ewoc-mode-map
  :parent special-mode-map
  :doc "Local keymap for `hyperdrive-ewoc-mode' buffers."
  "n"   #'h/ewoc-next
  "p"   #'h/ewoc-previous)

(define-derived-mode h/ewoc-mode special-mode
  `("Hyperdrive-ewoc"
    ;; TODO: Add more to lighter, e.g. URL.
    )
  "Major mode for Hyperdrive ewoc buffers."
  :interactive nil
  (hl-line-mode))

;;;; Commands

(cl-defun h/ewoc-next (&optional (n 1))
  "Move forward N entries.
When on header line, moves point to first entry, skipping over
column headers."
  (interactive "p" h/ewoc-mode)
  ;; TODO: Try using the intangible text property on headers to
  ;; automatically skip over them without conditional code. Setting
  ;; `cursor-intangible' on the column header causes `hl-line-mode' to
  ;; highlight the wrong line when crossing over the headers.
  (let ((lines-below-header (- (line-number-at-pos) 2)))
    (if (cl-plusp lines-below-header)
        (h/ewoc-move n)
      ;; Point on first line or column header:
      ;; jump to first ewoc entry and then maybe move.
      (goto-char (ewoc-location (ewoc-nth h/ewoc 0)))
      (h/ewoc-move (1- n)))))

(cl-defun h/ewoc-previous (&optional (n 1))
  "Move backward N entries.
When on first entry, moves point to header line, skipping over
column headers."
  (interactive "p" h/ewoc-mode)
  (let ((lines-below-header (- (line-number-at-pos) 2)))
    (if (and (cl-plusp lines-below-header)
             (< n lines-below-header))
        (h/ewoc-move (- n))
      ;; Point on first line or column header or N > LINE
      (goto-char (point-min)))))

(cl-defun h/ewoc-move (&optional (n 1))
  "Move forward N entries."
  (let ((next-fn (pcase n
                   ((pred (< 0)) #'ewoc-next)
                   ((pred (> 0)) #'ewoc-prev)))
        (node (ewoc-locate h/ewoc))
        (i 0)
        (n (abs n))
        target-node)
    (while (and (< i n)
                (setf node (funcall next-fn h/ewoc node)))
      (setf target-node node)
      (cl-incf i))
    (when target-node
      (goto-char (ewoc-location target-node)))))

;;;; Functions

(defun h/ewoc-collect-nodes (ewoc predicate)
  "Collect all nodes in EWOC matching PREDICATE.
PREDICATE is called with the full node."
  ;; Intended to be like `ewoc-collect', but working with the full
  ;; node instead of just the node's data.
  (cl-loop with node = (ewoc-nth ewoc 0)
           while node
           when (funcall predicate node)
           collect node
           do (setf node (ewoc-next ewoc node))))

(provide 'hyperdrive-ewoc)

;; Local Variables:
;; read-symbol-shorthands: (
;;   ("he//" . "hyperdrive-entry--")
;;   ("he/"  . "hyperdrive-entry-")
;;   ("h//"  . "hyperdrive--")
;;   ("h/"   . "hyperdrive-"))
;; End:
;;; hyperdrive-ewoc.el ends here
