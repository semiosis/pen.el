;;; dired-imenu.el --- imenu binding for dired mode

;; Copyright (C) 2014 Damien Cassou

;; Author: Damien Cassou <damien.cassou@gmail.com>
;; Url: https://github.com/DamienCassou/dired-imenu
;; Package-Version: 20140109.1610
;; Package-Commit: 610e21fe0988c85931d34894d3eee2442c79ab0a
;; GIT: https://github.com/DamienCassou/dired-imenu
;; Version: 0.5
;; Created: 9 Jan 2014
;; Keywords: dired imenu
;;
;; This file is NOT part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or (at
;; your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program ; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.
;;
;;; commentary:
;;
;; After you add the following line to your Emacs init file you can
;; call imenu from a dired buffer and get a list of all files in the
;; current buffer with completion. That's easier to use the isearch if
;; you use something like idomenu.
;;
;; (require 'dired-imenu)
;;
;;; code:
;;


(require 'dired)
(require 'imenu)

(defun dired-imenu-prev-index-position ()
  "Find the previous file in the buffer."
  (dired-previous-line 1))

(defun dired-imenu-extract-index-name ()
  "Return the name of the file at point."
  (dired-get-filename 'verbatim))

(defun dired-setup-imenu ()
  "Configure imenu for the current dired buffer."
  (set (make-local-variable 'imenu-prev-index-position-function)
       'dired-imenu-prev-index-position)
  (set (make-local-variable 'imenu-extract-index-name-function)
       'dired-imenu-extract-index-name))

(add-hook 'dired-mode-hook 'dired-setup-imenu)

(provide 'dired-imenu)
;;; dired-imenu ends here

;;; dired-imenu.el ends here
