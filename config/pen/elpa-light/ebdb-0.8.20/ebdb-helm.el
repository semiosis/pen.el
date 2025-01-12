;;; ebdb-helm.el --- Helm integration for EBDB       -*- lexical-binding: t; -*-

;; Copyright (C) 2018-2023  Free Software Foundation, Inc.

;; Author: Eric Abrahamsen <eric@ericabrahamsen.net>

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

;; Helm integration for EBDB.  Provides the command `helm-ebdb'.

;;; Code:

(require 'ebdb-com)

(declare-function helm-other-buffer "ext:helm"
		  (any-sources any-buffer))

(declare-function helm-marked-candidates "ext:helm")

(defun ebdb-helm-candidates ()
  "Return a list of all records in the database."
  (mapcar (lambda (rec)
	    (let* ((rec-string (ebdb-string rec))
		   (mails (ebdb-record-mail-canon rec))
		   (mail-list (when mails
				(mapconcat #'identity
					   mails
					   " "))))
	      (cons (if mail-list
			(concat rec-string
				" => "
				mail-list)
		      rec-string)
		    rec)))
	  (ebdb-records)))

(defun ebdb-helm-display-records (_candidate)
  "Display marked candidate(s)."
  (ebdb-display-records
   (helm-marked-candidates) nil nil t nil
   (format "*%s*" ebdb-buffer-name)))

(defun ebdb-helm-compose-mail (_candidate)
  "Compose mail to marked candidate(s)."
  (ebdb-mail (helm-marked-candidates) nil current-prefix-arg))

(defun ebdb-helm-cite-records (_candidate)
  "Insert mode-appropriate \"Name <email>\" string candidate(s)."
  (ebdb-cite-records (helm-marked-candidates) current-prefix-arg))

(defvar helm-source-ebdb
  '((name . "EBDB")
    (candidates . ebdb-helm-candidates)
    (action . (("Display" . ebdb-helm-display-records)
	       ("Send mail" . ebdb-helm-compose-mail)
	       ("Insert name and address" . ebdb-helm-cite-records)))))

;;;###autoload
(defun ebdb-helm ()
  "Preconfigured `helm' for EBDB."
  (interactive)
  (helm-other-buffer 'helm-source-ebdb "*helm ebdb*"))

(provide 'helm-ebdb)
;;; helm-ebdb.el ends here
