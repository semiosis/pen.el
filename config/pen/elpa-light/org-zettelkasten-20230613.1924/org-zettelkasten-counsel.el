;;; org-zettelkasten-counsel.el --- Counsel integration for org-zettelkasten  -*- lexical-binding: t; -*-

;; Copyright (C) 2022-2023  Yann Herklotz

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; An extension to org-zettelkasten for counsel.  This is mainly useful
;; for a nicer interface to searching for back-references to the current
;; identifier.

;;; Code:

(require 'org-zettelkasten)

(eval-when-compile
  (declare-function counsel-rg "ext:counsel"))

(defun org-zettelkasten-counsel-search-current-id ()
  "Use `counsel-rg' to search for the current ID in all files."
  (interactive)
  (let ((current-id (org-entry-get nil "CUSTOM_ID")))
    (counsel-rg (concat "#" current-id) org-zettelkasten-directory "-g *.org" "ID: ")))

(provide 'org-zettelkasten-counsel)

;;; org-zettelkasten-counsel.el ends here
