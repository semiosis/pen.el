;;; git-attr-linguist.el --- Support git attributes from linguist  -*- lexical-binding: t; -*-

;; Copyright (C) 2018  Arne Jørgensen
;; URL: https://github.com/arnested/emacs-git-attr
;; Version: 0.0.3
;; Package-Requires: ((emacs "24.3"))

;; Author: Arne Jørgensen <arne@arnested.dk>
;; Keywords: vc

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

;; This adds some functions for the git attributes linguist-generated
;; and linguist-vendored.

;; It adds a `find-file-hook' and upon visiting a file puts the buffer
;; into `git-attr-linguist-generated-mode' and/or
;; `git-attr-linguist-vendored-mode' minor modes.

;; Both minor modes just puts the buffer into `read-only-mode'.

;;; Code:

(require 'git-attr)

(defun git-attr-linguist-generated-p ()
  "Check if current buffer is a generated file."
  (let ((value (git-attr-get "linguist-generated")))
    (string= value "true")))

(defun git-attr-linguist-vendored-p ()
  "Check if current buffer is a vendored file."
  (let ((value (git-attr-get "linguist-vendored")))
    (string= value "true")))

(define-minor-mode git-attr-linguist-generated-mode
  nil
  :lighter " Generated"
  (if git-attr-linguist-generated-mode
      (read-only-mode 1)
    (read-only-mode 0)))

(define-minor-mode git-attr-linguist-vendored-mode
  nil
  :lighter " Vendored"
  (if git-attr-linguist-vendored-mode
      (read-only-mode 1)
    (read-only-mode 0)))

;;;###autoload
(defun git-attr-linguist ()
  "Make vendored and generated files read only."
  (when (git-attr-linguist-generated-p)
    (git-attr-linguist-generated-mode 1))
  (when (git-attr-linguist-vendored-p)
    (git-attr-linguist-vendored-mode 1)))

;;;###autoload
(add-hook 'find-file-hook 'git-attr-linguist)

(provide 'git-attr-linguist)
;;; git-attr-linguist.el ends here
