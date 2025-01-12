;;; universal-sidecar-sections.el --- Simple sections for universal-sidecar -*- lexical-binding: t -*-

;; Copyright (C) 2023 Samuel W. Flint <me@samuelwflint.com>

;; Author: Samuel W. Flint <me@samuelwflint.com>
;; SPDX-License-Identifier: GPL-3.0-or-later
;; URL: https://git.sr.ht/~swflint/emacs-universal-sidecar
;; Version: 0.0.1

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; This is a collection of miscellaneous sections for `universal-sidecar'.

;;; Code:

(require 'universal-sidecar)


;;; Basic "tail of buffer" section

(defun universal-sidecar-sections-resolve-buffer (buffer)
  "Resolve BUFFER to an actual buffer object.

If BUFFER is a buffer, return, if it's a string, use
`get-buffer', if a symbol, get its value, and if a function, call
it."
  (cond
   ((bufferp buffer) buffer)
   ((stringp buffer) (get-buffer buffer))
   ((symbolp buffer) (symbol-value buffer))
   ((functionp buffer) (funcall buffer))))

(defun universal-sidecar-sections-buffer-tail (buffer n)
  "Get the last N lines from BUFFER, return nil if BUFFER is empty."
  (unless (= 0 (buffer-size buffer))
    (with-current-buffer buffer
      (goto-char (point-max))
      (forward-line (- n))
      (beginning-of-line)
      (string-trim (buffer-substring (point) (point-max))))))

(universal-sidecar-define-section universal-sidecar-tail-buffer-section (shown-buffer n-lines title) ()
  "Show N-LINES of SHOWN-BUFFER in a sidecar with TITLE.

Note: SHOWN-BUFFER may be a buffer, string, or function."
  (when (and (stringp title)
             (integerp n-lines))
    (when-let* ((shown-buffer (universal-sidecar-sections-resolve-buffer shown-buffer))
                (contents (universal-sidecar-sections-buffer-tail shown-buffer n-lines)))
      (universal-sidecar-insert-section tail-buffer-section title
        (with-current-buffer sidecar
          (insert contents))))))

;;; TODO: Implement some (more) generic sidecars

(provide 'universal-sidecar-sections)

;;; universal-sidecar-sections.el ends here
