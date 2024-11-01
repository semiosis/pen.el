;;; helm-ext-minibuffer.el --- Extensions to helm minibuffer completion  -*- lexical-binding: t; -*-

;; Copyright (C) 2017  Junpeng Qiu

;; Author: Junpeng Qiu <qjpchmail@gmail.com>
;; Keywords: extensions

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

;;

;;; Code:

(require 'helm)

(defun helm-ext--use-header-line-maybe ()
  (when (minibufferp (buffer-name helm-current-buffer))
    (with-helm-buffer
      (set (make-local-variable 'helm-echo-input-in-header-line) t))
    (let ((orig-input (with-current-buffer helm-current-buffer
                        (buffer-string)))
          (ov (make-overlay (point-min) (point-max) nil nil t)))
      (overlay-put ov 'window (selected-window))
      (overlay-put ov 'face
                   (let ((bg-color (face-background 'default nil)))
                     `(:background ,bg-color :foreground ,bg-color)))
      (overlay-put ov 'before-string orig-input)
      (setq-local cursor-type nil))))

(provide 'helm-ext-minibuffer)
;;; helm-ext-minibuffer.el ends here
