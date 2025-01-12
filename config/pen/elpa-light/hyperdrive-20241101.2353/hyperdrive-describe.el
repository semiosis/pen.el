;;; hyperdrive-describe.el --- Display information about a hyperdrive  -*- lexical-binding: t; -*-

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

(require 'hyperdrive-lib)

;;;; Variables

(defvar-local h/describe-current-hyperdrive nil
  "Hyperdrive for current `hyperdrive-describe-mode' buffer.")
(put 'h/describe-current-hyperdrive 'permanent-local t)

;;;; Commands

(declare-function org-table-align "org-table")

;;;###autoload
(defun hyperdrive-describe-hyperdrive (hyperdrive)
  "Display various information about HYPERDRIVE.

With universal prefix argument \\[universal-argument], always
prompt for a hyperdrive."
  (interactive (list (h//context-hyperdrive :force-prompt current-prefix-arg)))
  ;; TODO: Do we want to asynchronously fill the hyperdrive's latest version?
  (h/fill hyperdrive)
  (with-current-buffer
      (get-buffer-create (h//format hyperdrive "*Hyperdrive: %k"))
    (with-silent-modifications
      (h/describe-mode)
      (setq-local h/describe-current-hyperdrive hyperdrive)
      (pcase-let*
          (((cl-struct hyperdrive metadata writablep etc) hyperdrive)
           ((map disk-usage) etc))
        (erase-buffer)
        (insert
         (propertize "Hyperdrive: \n" 'face 'bold)
         (h//format hyperdrive "Public key %K:\n" h/raw-formats)
         (h//format hyperdrive "Seed: %S\n" h/raw-formats)
         (h//format hyperdrive "Petname: %P\n" h/raw-formats)
         (h//format hyperdrive "Nickname: %N\n" h/raw-formats)
         (h//format hyperdrive "Domains: %D\n" h/raw-formats)
         (format "Safe: %s\n" (h/safe-string hyperdrive))
         (format "Latest version: %s\n" (h/latest-version hyperdrive))
         (format "Writable: %s\n" (if writablep "yes" "no"))
         (format "Disk usage: %s\n"
                 (propertize (if disk-usage
                                 (file-size-human-readable disk-usage)
                               "Unknown")
                             'face 'hyperdrive-size))
         (format "Metadata: %s\n"
                 (if metadata
                     (with-temp-buffer
                       (require 'org)
                       (org-mode)
                       (insert "\n|-\n| Key | Value |\n|-\n")
                       (cl-loop for (key . value) in metadata
                                do (insert (format "| %s | %s |\n" key value)))
                       (insert "|-\n")
                       (forward-line -1)
                       (org-table-align)
                       (buffer-string))
                   "[none]")))))
    (setf buffer-read-only t)
    (pop-to-buffer (current-buffer))))

;;;; Mode

(defun h/describe-revert-buffer (&optional _ignore-auto _noconfirm)
  "Revert `hyperdrive-describe-mode' buffer.
Gets latest metadata from hyperdrive."
  (h/fill-metadata h/describe-current-hyperdrive)
  (h/describe-hyperdrive h/describe-current-hyperdrive))

(define-derived-mode h/describe-mode special-mode
  `("Hyperdrive-describe"
    ;; TODO: Add more to lighter, e.g. URL.
    )
  "Major mode for buffers for describing hyperdrives."
  :group 'hyperdrive
  :interactive nil
  (setq-local revert-buffer-function #'h/describe-revert-buffer))

;;;; Footer

(provide 'hyperdrive-describe)

;; Local Variables:
;; read-symbol-shorthands: (
;;   ("he//" . "hyperdrive-entry--")
;;   ("he/"  . "hyperdrive-entry-")
;;   ("h//"  . "hyperdrive--")
;;   ("h/"   . "hyperdrive-"))
;; End:
;;; hyperdrive-describe.el ends here
