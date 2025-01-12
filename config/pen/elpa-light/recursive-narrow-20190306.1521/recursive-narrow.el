;;; recursive-narrow.el --- narrow-to-region that operates recursively

;; Copyright (C) 2010 Nathaniel Flath <flat0103@gmail.com>

;; Author: Nathaniel Flath <flat0103@gmail.com>
;; URL: http://github.com/nflath/recursive-narrow
;; Package-Version: 20190306.1521
;; Package-Commit: 5e3e2067d5a148d7e64e64e0355d3b6860e4c259
;; Version: 20140811.1546
;; X-Original-Version: 20140801.1400
;; X-Original-Version: 1.3

;; This file is not part of GNU Emacs.

;;; Commentary:

;; This package defines two functions, recursive-narrow-to-region and
;; recursive-widen that replace the builtin functions narrow-to-region and
;; widen.  These functions operate the same way, except in the case of multiple
;; calls to recursive-narrow-to-region.  In this case, recursive-widen will go
;; to the previous buffer visibility, not make the entire buffer visible.

;;; Installation:

;; To install, put this file somewhere in your load-path and add the following
;; to your .emacs file:
;;
;; (require 'recursive-narrow)
;;

;;; License:

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.
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

;;; Code:

(defgroup recursive-narrow nil
  "This module contains code for recursively narrowing and widening."
  :tag "User interface"
  :group 'recursive-narrow)

(defcustom recursive-narrow-dwim-functions nil
  "Functions to try for narrowing.
These functions do not get any arguments. They should narrow and
return non-nil if applicable."
  :type 'hook
  :group 'recursive-narrow)

(defvar-local recursive-narrow-settings nil "List of buffer visibility settings.")

(defmacro recursive-narrow-save-position (body &optional unchanged)
  "Execute BODY and save the buffer visibility if changed.
Executes UNCHANGED if the buffer visibility has not changed."
  `(let ((previous-settings (cons (point-min) (point-max))))
     ,body
     (if (and (= (point-min) (car previous-settings))
              (= (point-max) (cdr previous-settings)))
         ,unchanged
       ;; We narrowed, so save the information
       (push previous-settings recursive-narrow-settings))))

(defun recursive-narrow-or-widen-dwim ()
  "If the region is active, narrow to that region.
Otherwise, narrow to the current function. If this has no effect,
widen the buffer. You can add more functions to
`recursive-narrow-dwim-functions'."
  (interactive)
  (recursive-narrow-save-position
   (cond ((region-active-p) (narrow-to-region (region-beginning) (region-end)))
         ((run-hook-with-args-until-success 'recursive-narrow-dwim-functions))
         ((derived-mode-p 'prog-mode) (narrow-to-defun))
         ((derived-mode-p 'org-mode) (org-narrow-to-subtree)))
   ;; If we don't narrow
   (progn
     (message "Recursive settings: %d" (length recursive-narrow-settings))
     (recursive-widen))))

(defun recursive-narrow-to-region (start end)
  "Replacement of `narrow-to-region'.
Performs the exact same function but also allows
`recursive-widen' to remove just one call to
`recursive-narrow-to-region'. START and END define the region."
  (interactive "r")
  (recursive-narrow-save-position (narrow-to-region start end)))

(defun recursive-narrow-to-defun (&optional arg)
  "Replacement of `narrow-to-defun'.
Performs the exact same function but also allows
`recursive-widen' to remove just one call to
`recursive-narrow-to-region'. Optional ARG is ignored."
  (interactive)
  (recursive-narrow-save-position
   (narrow-to-defun)))

(defun recursive-widen ()
  "Replacement of widen that will only pop one level of visibility."
  (interactive)
  (let (widen-to)
    (if recursive-narrow-settings
        (progn
          (setq widen-to (pop recursive-narrow-settings))
          (narrow-to-region (car widen-to) (cdr widen-to))
          (recenter))
      (widen))))


(global-set-key (kbd "C-x n w") 'recursive-widen)
(global-set-key (kbd "C-x n n") 'recursive-narrow-or-widen-dwim)

(provide 'recursive-narrow)

;;; recursive-narrow.el ends here
