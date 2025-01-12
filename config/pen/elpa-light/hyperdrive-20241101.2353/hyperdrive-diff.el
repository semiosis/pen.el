;;; hyperdrive-diff.el --- Diffing hyperdrive entries -*- lexical-binding: t; -*-

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

;; Code related to diffing hyperdrive entries.

;;; Code:

;;; Requirements

(require 'hyperdrive-lib)
(require 'hyperdrive-vars)

(require 'diff)
(require 'rx)

;;;; Commands

;;;; Internal variables

(defvar-local h/diff-entries nil
  "Entries to be diffed in `hyperdrive-diff' buffer.
A cons cell whose car is OLD-ENTRY and whose cdr is NEW-ENTRY.")
(put 'h/diff-entries 'permanent-local t)

;;;; Functions

(defun h/diff-empty-diff-p (buffer)
  "Return t if `hyperdrive-diff-mode' BUFFER has no differences."
  (with-current-buffer buffer
    (save-excursion
      (without-restriction
        (goto-char (point-max))
        (forward-line -1)
        (looking-at-p (rx line-start "Diff finished (no differences)."))))))

;;;###autoload
(cl-defun hyperdrive-diff-file-entries (old-entry new-entry &key then)
  "Diff OLD-ENTRY and NEW-ENTRY, then call THEN in diff buffer.
Call ELSE if either request fails.
This function is intended to diff files, not directories."
  (declare (indent defun))
  ;; Both entries should exist since we use
  ;; `hyperdrive-entry-description' to generate buffer names
  (cl-check-type old-entry hyperdrive-entry)
  (cl-check-type new-entry hyperdrive-entry)
  (require 'diff)
  (let* (old-response
         new-response
         (queue (make-plz-queue
                 :limit h/queue-limit
                 :finally
                 (lambda ()
                   (let (old-buffer new-buffer diff-buffer)
                     (unwind-protect
                         (progn
                           (unless (or old-response new-response)
                             (h/error "Files non-existent"))
                           (setf old-buffer (generate-new-buffer
                                             (h//format-entry
                                              old-entry h/buffer-name-format))
                                 new-buffer (generate-new-buffer
                                             (h//format-entry
                                              new-entry h/buffer-name-format))
                                 ;; TODO: Improve diff buffer name.
                                 diff-buffer (get-buffer-create "*hyperdrive-diff*"))
                           (when old-response
                             (with-current-buffer old-buffer
                               (insert (plz-response-body old-response))))
                           (when new-response
                             (with-current-buffer new-buffer
                               (insert (plz-response-body new-response))))
                           (condition-case err
                               (progn
                                 (diff-no-select old-buffer
                                                 new-buffer nil t diff-buffer)
                                 (with-current-buffer diff-buffer
                                   (setf h/diff-entries (cons old-entry new-entry))
                                   (h/diff-mode)
                                   (when then
                                     (funcall then))))
                             (error (kill-buffer diff-buffer)
                                    (signal (car err) (cdr err)))))
                       (when (buffer-live-p old-buffer)
                         (kill-buffer old-buffer))
                       (when (buffer-live-p new-buffer)
                         (kill-buffer new-buffer))))))))
    (he/api 'get old-entry :queue queue :else #'ignore
      :then (lambda (response) (setf old-response response)))
    (he/api 'get new-entry :queue queue :else #'ignore
      :then (lambda (response) (setf new-response response)))))

;;;; Mode

(define-derived-mode h/diff-mode diff-mode "hyperdrive-diff"
  "Major mode for `hyperdrive-diff' buffers."
  :group 'hyperdrive
  :interactive nil
  ;; Narrow the buffer to hide the diff command and "diff finished" lines.
  (with-silent-modifications
    (save-excursion
      (goto-char (point-min))
      (delete-line)
      (when (h/diff-empty-diff-p (current-buffer))
        (insert (format "No difference between entries:\n%s\n%s"
                        (h//format-entry (car h/diff-entries))
                        (h//format-entry (cdr h/diff-entries)))))
      (goto-char (point-max))
      (forward-line -1)
      (delete-region (point) (point-max)))))

;;;; Footer

(provide 'hyperdrive-diff)

;; Local Variables:
;; read-symbol-shorthands: (
;;   ("he//" . "hyperdrive-entry--")
;;   ("he/"  . "hyperdrive-entry-")
;;   ("h//"  . "hyperdrive--")
;;   ("h/"   . "hyperdrive-"))
;; End:
;;; hyperdrive-diff.el ends here
