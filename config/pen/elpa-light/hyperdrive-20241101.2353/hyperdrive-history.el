;;; hyperdrive-history.el --- Hyperdrive version history frontend  -*- lexical-binding: t; -*-

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
(require 'hyperdrive-ewoc)

;;;; Variables

(defvar-local h/history-current-entry nil
  ;; NOTE: We don't reuse `hyperdrive-current-entry' in history buffers because
  ;; functions like `hyperdrive--find-buffer-visiting' expect only one buffer to
  ;; be visiting an entry at a time.
  "Entry for current history buffer.")

;;;; Functions

(cl-defun h/history-url (entry)
  "Return formatted history URL for ENTRY, START, and END."
  (pcase-let* (((cl-struct hyperdrive-entry hyperdrive path) entry)
               ((cl-struct hyperdrive public-key) hyperdrive))
    (format "hyper://%s/$/history%s" public-key path)))

(cl-defun h/history-get (entry)
  "Return list of file history entries for ENTRY.
Updates `hyperdrive-existent-versions' as a side effect."
  (declare (indent defun))
  (pcase-let*
      (((cl-struct hyperdrive-entry hyperdrive path) entry)
       ((cl-struct plz-response body
                   (headers (map x-drive-size x-drive-version)))
        (condition-case err
            ;; TODO: When plz adds :as 'response-with-buffer, use that.
            (h/api 'get (h/history-url entry) :as 'response)
          (err (h/error "Unable to get history for `%s': %S" (he/url entry)
                        err))))
       (history-entries))
    (pcase-dolist ((map exists blockLengthDownloaded version value)
                   (json-parse-string
                    body :object-type 'alist :array-type 'list
                    :false-object nil :null-object nil))
      (let ((history-entry (he/create :hyperdrive hyperdrive
                                      :path path :version version)))
        (setf (he/size history-entry)
              (map-elt (map-elt value 'blob) 'byteLength))
        (setf (map-elt (he/etc history-entry) 'block-length)
              (map-elt (map-elt value 'blob) 'blockLength))
        (setf (map-elt (he/etc history-entry) 'block-length-downloaded)
              blockLengthDownloaded)
        (when-let ((mtime
                    (map-elt (map-elt value 'metadata) 'mtime)))
          (setf (he/mtime history-entry)
                (seconds-to-time (/ mtime 1000.0))))
        (setf (map-elt (he/etc history-entry) 'next-version-number)
              (and-let* ((next-entry (car history-entries)))
                (he/version next-entry)))
        (setf (map-elt (he/etc history-entry) 'existsp)
              (pcase exists
                ("unknown" 'unknown)
                (_ exists)))
        (when (eq t exists)
          (h/update-existent-versions hyperdrive path version))
        (push history-entry history-entries)))
    (when x-drive-size
      (setf (map-elt (h/etc hyperdrive) 'disk-usage)
            (cl-parse-integer x-drive-size)))
    (when x-drive-version
      (setf (h/latest-version hyperdrive)
            (string-to-number x-drive-version)))
    ;; TODO: Update buffers like h/describe-hyperdrive after updating drive.
    (h/persist (he/hyperdrive entry))
    history-entries))

(defun h/history-find-buffer-visiting (entry)
  "Return a buffer showing ENTRY's history, or nil if none exists."
  ;; There should only ever be one buffer showing ENTRY's history, so it's safe
  ;; to return the first value in the list.
  (car (match-buffers
        (lambda (buffer)
          (and-let* ((local-entry (buffer-local-value 'h/history-current-entry buffer)))
            (he/equal-p entry local-entry t))))))

(defun h/history-find-at-point (event)
  "Find entry at EVENT's position."
  (interactive "e")
  (mouse-set-point event)
  (call-interactively #'h/history-find-file-other-window))

(defun h/history-pp (entry)
  "Pretty-print history ENTRY.
ENTRY's ETC must have `existsp' and `next-version-number' keys.
To be used as the pretty-printer for `ewoc-create'."
  (pcase-let*
      (((cl-struct hyperdrive-entry hyperdrive version size mtime etc) entry)
       ((map block-length block-length-downloaded existsp next-version-number)
        etc)
       (range-end (if next-version-number
                      (1- next-version-number)
                    (h/latest-version hyperdrive)))
       (formatted-range (if (eq version range-end)
                            (format "%d" version)
                          (format "%d-%d" version (or range-end ""))))
       (exists-marker (format "%7s" (pcase-exhaustive existsp
                                      ('t "Yes")
                                      ('nil "No")
                                      ('unknown "Unknown"))))
       (size (and size (file-size-human-readable size)))
       (timestamp (if mtime
                      (format-time-string h/timestamp-format mtime)
                    (propertize " " 'display '(space :width h/timestamp-width)))))
    ;; FIXME: Use dynamic width of range column equal to 2N+1, where N
    ;; is the width of the hyperdrive's latest version
    (insert
     (format
      "%7s  %19s  %6s  %s"
      (propertize exists-marker
                  'face (pcase-exhaustive existsp
                          ('t 'h/history-existent)
                          ('nil 'h/history-nonexistent)
                          ('unknown 'h/history-unknown)))
      (propertize formatted-range
                  'face 'h/history-range
                  'mouse-face 'highlight
                  'help-echo (format (pcase-exhaustive existsp
                                       ('t "Open version %s")
                                       ('nil "Nonexistent at version %s")
                                       ('unknown "Load history at version %s"))
                                     version))
      (propertize (or size "")
                  'face (and block-length-downloaded block-length
                             (pcase block-length-downloaded
                               (0 'h/size-not-downloaded)
                               ((pred (= block-length)) 'h/size-fully-downloaded)
                               (_ 'h/size-partially-downloaded)))
                  'help-echo (format "%s of %s blocks downloaded"
                                     block-length-downloaded block-length))
      (propertize (or timestamp "")
                  'face 'h/timestamp)))))

(defun h/history-entry-at-point (&optional no-error)
  "Return entry at point.
With point on header, return an entry whose \\+`version' and
\\+`next-version-number' are nil and whose \\+`existsp' value
matches that of the first entry in the ewoc.  If history ewoc is
empty, or point is below last entry or on column headers, signal
error.  With non-nil NO-ERROR, return nil in that case."
  (let ((current-line (line-number-at-pos))
        (last-entry (ewoc-nth h/ewoc -1)))
    (cond ((= 1 current-line) ; Point on header: return version-less entry
           (let ((copy-entry (compat-call copy-tree h/history-current-entry t)))
             (setf (map-elt (he/etc copy-entry) 'next-version-number) nil)
             (setf (he/version copy-entry) nil)
             (when-let ((first-node (ewoc-nth h/ewoc 0)))
               (setf (map-elt (he/etc copy-entry) 'existsp)
                     (map-elt (he/etc (ewoc-data first-node)) 'existsp)))
             copy-entry))
          ((or (not last-entry)
               (> current-line (line-number-at-pos (ewoc-location last-entry)))
               (= 2 current-line))
           ;; Point is below the last entry or on column headers: signal error.
           (unless no-error
             (h/user-error "No version on this line")))
          (t ; Point on a file entry: return its entry.
           (ewoc-data (ewoc-locate h/ewoc))))))

(defun h/history-revert-buffer (&optional _ignore-auto _noconfirm)
  "Revert `hyperdrive-history-mode' buffer."
  ;; TODO: Preserve point position in buffer.
  (h/history h/history-current-entry))

(defun hyperdrive-history--invalidate-entry (entry)
  "Invalidate ENTRY's ewoc node in history buffers.
Invalidated ewoc node entries will have these slots updated:

- ETC
  + BLOCK-LENGTH-DOWNLOADED

All other slots in each ewoc node entry data will be reused."
  (when-let* ((history-buffer (h/history-find-buffer-visiting entry))
              (history-ewoc (buffer-local-value 'h/ewoc history-buffer))
              (history-node (h/ewoc-find-node history-ewoc entry
                              :predicate #'he/within-version-range-p))
              (history-ewoc-entry (ewoc-data history-node)))
    (setf (map-elt (he/etc history-ewoc-entry) 'block-length-downloaded)
          (map-elt (he/etc entry) 'block-length-downloaded))
    (ewoc-set-data history-node history-ewoc-entry)
    ;; NOTE: Ensure that the buffer's window is selected,
    ;; if it has one.  (Workaround a possible bug in EWOC.)
    (if-let ((buffer-window (get-buffer-window history-buffer)))
        (with-selected-window buffer-window
          (with-silent-modifications (ewoc-invalidate history-ewoc history-node)))
      (with-current-buffer history-buffer
        (with-silent-modifications (ewoc-invalidate history-ewoc history-node))))))

;;;; Mode

(defvar-keymap h/history-mode-map
  :parent  h/ewoc-mode-map
  :doc "Local keymap for `hyperdrive-history-mode' buffers."
  "RET" #'h/history-find-file
  "o"   #'h/history-find-file-other-window
  "v"   #'h/history-view-file
  "="   #'h/history-diff
  "+"   #'h/history-load
  "w"   #'h/history-copy-url
  "d"   #'h/history-download-file
  "F"   #'h/history-forget-file
  "<mouse-2>" #'h/history-find-at-point
  "<follow-link>" 'mouse-face)

(define-derived-mode h/history-mode h/ewoc-mode
  `("Hyperdrive-history"
    ;; TODO: Add more to lighter, e.g. URL.
    )
  "Major mode for Hyperdrive history buffers."
  ;; TODO: Consider keeping the version around so that we can highlight the line
  ;; corresponding to version currently open in another buffer.
  :group 'hyperdrive
  :interactive nil
  (setf h/ewoc (ewoc-create #'h/history-pp))
  (setq-local revert-buffer-function #'h/history-revert-buffer))

;;;; Commands

;;;###autoload
(defun hyperdrive-history (entry)
  "Display version history for current hyperdrive ENTRY.

Interactively, open version history for current file ENTRY or
ENTRY at point in a directory.  Otherwise, or with universal
prefix argument \\[universal-argument], prompt for ENTRY."
  (interactive (list (h//context-entry :force-prompt current-prefix-arg)))
  ;; TODO: Highlight range for ENTRY
  (when (h//entry-directory-p entry)
    (h/user-error "Directory history not implemented"))
  (let* ((main-header (h//format-entry entry
                                       h/default-entry-format-without-version))
         (header
          (format
           "%s\n%7s  %19s  %6s  %s" main-header
           (propertize "Exists" 'face 'h/column-header)
           (propertize "Drive Version Range" 'face 'h/column-header)
           (propertize "Size" 'face 'h/column-header)
           (string-pad (propertize "Last Modified" 'face 'h/column-header)
                       h/timestamp-width nil t)))
         (prev-entry) (prev-point))
    (with-current-buffer
        (get-buffer-create
         (format "*Hyperdrive-history: %s*"
                 (h//format-entry
                  entry h/default-entry-format-without-version)))
      (h/history-mode)
      (setq-local h/history-current-entry entry)
      (setf prev-entry (h/history-entry-at-point 'no-error))
      (setf prev-point (point))
      (with-silent-modifications
        (ewoc-filter h/ewoc #'ignore)
        (erase-buffer))
      ;; TODO: Display files in pop-up window, like magit-diff buffers appear when selected from magit-log
      (display-buffer (current-buffer) h/history-display-buffer-action)
      (dolist (history-entry (h/history-get entry))
        (ewoc-enter-first h/ewoc history-entry))
      (ewoc-set-hf h/ewoc header "")
      (with-silent-modifications (ewoc-refresh h/ewoc))
      (if-let ((prev-entry)
               (node (h/ewoc-find-node h/ewoc prev-entry
                       :predicate #'he/equal-p)))
          (goto-char (ewoc-location node))
        (goto-char prev-point)))))

(defun h/history-load (entry)
  "Load version history for ENTRY, then refresh history buffer."
  (interactive (list h/history-current-entry) h/history-mode)
  ;; HACK: The proper approach might be to use `ewoc-map', but this is simpler:
  (save-excursion
    (goto-char (point-min))
    (while (search-forward "Unknown" nil t)
      (let ((ov (make-overlay (pos-bol) (+ (pos-bol) (length "Loading")))))
        (overlay-put ov 'display "Loading")
        (overlay-put ov 'evaporate t))))
  (h/fully-replicate entry :then #'h/history))

(declare-function h/diff-file-entries "hyperdrive-diff")
(defun h/history-diff (old-entry new-entry)
  "Show diff between OLD-ENTRY and NEW-ENTRY.
Interactively, diff entry at point with previous entry."
  ;; TODO: Set entries based on marked ranges
  (interactive
   (pcase-let*
       (((and new-entry (cl-struct h/entry version (etc (map existsp))))
         (h/history-entry-at-point))
        (next-node (pcase version
                     ((guard (eq 'unknown existsp))
                      (h/user-error "Can't diff with unknown version range.  \
Try `hyperdrive-history-load' (\\[hyperdrive-history-load])"))
                     ('nil ; Point is on the header: get second node.
                      (ewoc-nth h/ewoc 1))
                     (1 ; Point is on last (nonexistent) range: signal error.
                      (h/user-error "At earliest version range"))
                     (_ (ewoc-next h/ewoc (h/ewoc-find-node h/ewoc new-entry
                                            :predicate #'he/equal-p)))))
        ;; `old-entry' might be nil if we're at the last node.
        (old-entry (and next-node (ewoc-data next-node))))
     (when (and old-entry (eq 'unknown (map-elt (he/etc old-entry) 'existsp)))
       (h/user-error "Can't diff with unknown version range.  \
Try `hyperdrive-history-load' (\\[hyperdrive-history-load])"))
     (list old-entry new-entry))
   h/history-mode)
  (h/diff-file-entries old-entry new-entry
    :then (lambda ()
            (pop-to-buffer (current-buffer)))))

(defmacro h/history--when-exists (&rest body)
  "Wrap BODY to check that the entry exists."
  (declare (indent defun))
  `(pcase-exhaustive (map-elt (he/etc entry) 'existsp)
     ('t ,@body)
     ('nil (h/user-error "File does not exist!"))
     ('unknown (h/history-load entry))))

(defun h/history-find-file (entry)
  "Visit hyperdrive ENTRY at point.
When entry does not exist, signal an error.  When entry is not
known to exist, reload history."
  (interactive (list (h/history-entry-at-point)) h/history-mode)
  (h/history--when-exists (h/open entry)))

(defun h/history-find-file-other-window (entry)
  "Visit hyperdrive ENTRY at point in other window.
Then call THEN.  When entry does not exist, signal an error.
When entry is not known to exist, reload history."
  (interactive (list (h/history-entry-at-point)) h/history-mode)
  (h/history--when-exists
    (h/open entry :then (lambda () (pop-to-buffer (current-buffer) t)))))

(declare-function h/view-file "hyperdrive")
(defun h/history-view-file (entry)
  "Open hyperdrive ENTRY at point in `view-mode'.
When entry does not exist, signal an error.  When entry is not
known to exist, reload history."
  (interactive (list (h/history-entry-at-point)) h/history-mode)
  (h/history--when-exists (h/view-file entry)))

(declare-function h/copy-url "hyperdrive")
(defun h/history-copy-url (entry)
  "Copy URL of ENTRY at point into the kill ring.
When entry does not exist, signal an error.  When entry is not
known to exist, reload history."
  (interactive (list (h/history-entry-at-point)) h/history-mode)
  (h/history--when-exists (h/copy-url entry)))

(declare-function h/download "hyperdrive")
(defun h/history-download-file (entry)
  "Download ENTRY at point.
Prompts for download destination path.
When ENTRY does not exist, signal an error.  When ENTRY is not
known to exist, reload history."
  ;; To avoid duplicating the `read-file-name' prompt, the interactive form does
  ;; not include the filename.
  (interactive (list (h/history-entry-at-point)) h/history-mode)
  (h/history--when-exists
    (h/download entry (read-file-name
                       "Filename: " (expand-file-name
                                     (he/name entry) h/download-directory)))))

(declare-function h/forget-file "hyperdrive")
(defun h/history-forget-file (entry)
  "Delete local copy of the file contents of ENTRY at point.
Only delete the blob(s) for the file at ENTRY's version range;
other blobs are not cleared.  Hyperdrive directory contents are
not modified; file blobs may be recoverable from other peers."
  (interactive (list (h/history-entry-at-point)) h/history-mode)
  (h/history--when-exists (h/forget-file entry)))

(provide 'hyperdrive-history)

;; Local Variables:
;; read-symbol-shorthands: (
;;   ("he//" . "hyperdrive-entry--")
;;   ("he/"  . "hyperdrive-entry-")
;;   ("h//"  . "hyperdrive--")
;;   ("h/"   . "hyperdrive-"))
;; End:
;;; hyperdrive-history.el ends here
