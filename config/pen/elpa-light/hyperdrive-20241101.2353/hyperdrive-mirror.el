;;; hyperdrive-mirror.el --- Display information about a hyperdrive  -*- lexical-binding: t; -*-

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
(require 'rx)

(require 'hyperdrive-lib)

(require 'taxy-magit-section)

;;;; Structs

(cl-defstruct hyperdrive-mirror-item
  "Represents a potential mirror operation for a file."
  (file nil :documentation "Local filename.")
  (url nil :documentation "Hyperdrive URL.")
  (status nil :documentation "One of `new', `newer', `older', `same'.
Comparison of the timestamps of the local file and the hyperdrive
file."))

;;;; Variables

;; TODO: Consolidate these two local variables into one?
(defvar-local h/mirror-parent-entry nil
  "Parent entry for `hyperdrive-mirror-mode' buffer.")
(put 'h/mirror-parent-entry 'permanent-local t)

(defvar-local h/mirror-files-and-urls nil
  "List of lists like (FILE URL STATUS) for `hyperdrive-mirror-mode'.
FILE is the local file path of the file to be uploaded.
URL is \"hyper://\" URL where the file would be uploaded.
STATUS is one of:
- \\+`new':   FILE does not exist in hyperdrive at URL
- \\+`newer': FILE has a later modification time than hyperdrive URL
- \\+`older': FILE has an earlier modification time than hyperdrive URL
- \\+`same':  FILE has the same modification time as hyperdrive URL")

(defvar-local h/mirror-query nil
  "List of arguments passed to `hyperdrive-mirror', excluding \\+`no-confirm'.")

(defvar-local h/mirror-visibility-cache nil)

;;;; Keys

;; These are the "keys" used to group items with Taxy.

(eval-and-compile
  (taxy-define-key-definer h/mirror-define-key
    h/mirror-keys "hyperdrive-mirror-key" "Grouping keys."))

(h/mirror-define-key status ()
  (pcase-let (((cl-struct hyperdrive-mirror-item (status item-status)) item))
    (pcase-exhaustive item-status
      (`new "New locally")
      (`newer "Newer locally")
      ('older "Older locally")
      ('same "Same"))))

(defvar h/mirror-default-keys
  '(status)
  "Default keys.")

;;;; Columns

(defgroup hyperdrive-mirror nil
  "Display information about a hyperdrive."
  :group 'hyperdrive)

;; These forms define the columns used to display items with `taxy-magit-section'.

(eval-and-compile
  (taxy-magit-section-define-column-definer "hyperdrive-mirror"))

(h/mirror-define-column "Local File" ()
  (pcase-let (((cl-struct hyperdrive-mirror-item file) item))
    (abbreviate-file-name file)))

(h/mirror-define-column "Hyperdrive File" ()
  (pcase-let* (((cl-struct hyperdrive-mirror-item url) item)
               (entry (h/url-entry url))
               (short-url (h//format-entry-url entry :host-format 'short-key)))
    (propertize url 'display short-url)))

(unless h/mirror-columns
  (setq-default h/mirror-columns (get 'h/mirror-columns 'standard-value)))

;;;; Functions

(declare-function h/upload-file "hyperdrive")
(defun h//mirror (files-and-urls parent-entry)
  "Upload each file to its corresponding URL in FILES-AND-URLs.
FILES-AND-URLS is structured like `hyperdrive-mirror-files-and-urls'.
After uploading files, open PARENT-ENTRY."
  ;; TODO: Sort by size, smallest to largest, before uploading, so that if the
  ;; process is interrupted, the most number of files will have been uploaded,
  ;; and only a few will remain.
  (let* ((count 0)
         (upload-files-and-urls (cl-remove-if-not
                                 (pcase-lambda ((cl-struct hyperdrive-mirror-item status))
                                   (or (eq status 'new) (eq status 'newer)))
                                 files-and-urls))
         (progress-reporter
          (make-progress-reporter
           (format "Uploading %s files: " (length upload-files-and-urls))
           0 (length upload-files-and-urls)))
         (queue (make-plz-queue
                 :limit h/queue-limit
                 :finally (lambda ()
                            (when (buffer-live-p (get-buffer "*hyperdrive-mirror*"))
                              (kill-buffer "*hyperdrive-mirror*"))
                            (h/open parent-entry)
                            (progress-reporter-done progress-reporter)))))
    (if (not upload-files-and-urls)
        (h/message "No new/newer files to upload")
      (pcase-dolist ((cl-struct hyperdrive-mirror-item file url) upload-files-and-urls)
        (h/upload-file file (h/url-entry url)
          :queue queue
          ;; TODO: Error handling (e.g. in case one or more files fails to upload).
          :then (lambda (_)
                  (progress-reporter-update progress-reporter (cl-incf count))))))))

(cl-defun h/mirror--check-items (source files hyperdrive target-dir &key then progress-fun)
  "Call THEN with list of FILES to mirror from SOURCE to TARGET-DIR in HYPERDRIVE.
If PROGRESS-FUN, call it with no arguments after each item has
been checked."
  (let* ((items)
         (metadata-queue (make-plz-queue
                          :limit h/queue-limit
                          :finally (lambda ()
                                     (funcall then items)))))
    (dolist (file files)
      (let ((entry (he/create
                    :hyperdrive hyperdrive
                    :path (expand-file-name (file-relative-name file source) target-dir))))
        (he/api 'head entry :queue metadata-queue
          :then (lambda (_response)
                  (let* ((drive-mtime (floor (float-time (he/mtime entry))))
                         (local-mtime (floor (float-time (file-attribute-modification-time (file-attributes file)))))
                         (status (cond
                                  ((time-less-p drive-mtime local-mtime) 'newer)
                                  ((time-equal-p drive-mtime local-mtime) 'same)
                                  (t 'older)))
                         (url (he/url entry)))
                    (push (make-hyperdrive-mirror-item :file file :url url :status status)
                          items)
                    (when progress-fun
                      (funcall progress-fun))))
          :else (lambda (plz-error)
                  (let ((status-code (plz-response-status (plz-error-response plz-error))))
                    (pcase status-code
                      (404 ;; Entry doesn't exist: Set `status' to `new'".
                       (push (make-hyperdrive-mirror-item
                              :file file :url (he/url entry) :status 'new)
                             items)
                       (when progress-fun
                         (funcall progress-fun)))
                      (_
                       (h/error "Unable to get metadata for URL \"%s\": %S"
                                (he/url entry) plz-error))))))))))

(defun h/mirror-revert-buffer (&optional _ignore-auto _noconfirm)
  "Revert `hyperdrive-mirror-mode' buffer.
Runs `hyperdrive-mirror' again with the same query."
  (apply #'h/mirror h/mirror-query))

;;;; Commands

;;;###autoload
(cl-defun hyperdrive-mirror
    (source hyperdrive target-dir &key (filter #'always) no-confirm)
  "Mirror SOURCE to TARGET-DIR in HYPERDRIVE.

Only mirror paths within SOURCE for which FILTER returns
non-nil.  FILTER may be a function, which receives the expanded
filename path as its argument, or a regular expression, which is
tested against each expanded filename path.  SOURCE is a directory
name.

When TARGET-DIR is nil, SOURCE is mirrored into the
hyperdrive's root directory \"/\".

Opens the \"*hyperdrive-mirror*\" buffer with the list of files to
be uploaded and the URL at which each file will be published.  See
`hyperdrive-mirror-mode'.

When NO-CONFIRM is non-nil, upload without prompting.

Interactively, with one universal prefix argument
\\[universal-argument], prompt for filter, otherwise mirror
all files. With two universal prefix arguments
\\[universal-argument] \\[universal-argument], prompt for
filter and set NO-CONFIRM to t."
  (interactive
   (let ((source (read-directory-name "Mirror directory: " nil nil t))
         (hyperdrive (h//context-hyperdrive :predicate #'h/writablep
                                            :force-prompt t)))
     (list source hyperdrive
           ;; TODO: Get path from any visible hyperdrive-dir buffer and
           ;; auto-fill (or add as "future history") in target-dir prompt.
           (h/read-path :hyperdrive hyperdrive
                        :prompt "Target directory in `%s'"
                        :default "/")
           :filter (if current-prefix-arg
                       (h/mirror-read-filter)
                     #'always)
           :no-confirm (equal '(16) current-prefix-arg))))
  (cl-callf expand-file-name source)
  (setf target-dir (h//format-path target-dir :directoryp t))
  (when (stringp filter)
    (let ((regexp filter))
      (setf filter (lambda (filename)
                     (string-match-p regexp filename)))))
  (let* ((files (cl-remove-if-not filter (directory-files-recursively source ".")))
         (parent-entry (he/create :hyperdrive hyperdrive :path target-dir))
         (buffer (unless no-confirm
                   (get-buffer-create "*hyperdrive-mirror*")))
         (num-filled 0)
         (num-of (length files)))
    (unless files
      (h/user-error "No files selected for mirroring (double-check filter)"))
    (if no-confirm
        (let ((reporter (make-progress-reporter "Checking files" 0 num-of)))
          (h/mirror--check-items source files hyperdrive target-dir
                                 :progress-fun (lambda ()
                                                 (progress-reporter-update reporter (cl-incf num-filled)))
                                 :then (lambda (items)
                                         (progress-reporter-done reporter)
                                         (h//mirror items parent-entry))))
      (with-current-buffer buffer
        (with-silent-modifications
          (cl-labels ((update-progress ()
                        (when (zerop (mod (cl-incf num-filled) 5))
                          (with-current-buffer buffer
                            (with-silent-modifications
                              (erase-buffer)
                              (insert (propertize
                                       (format "Comparing files (%s/%s)..."
                                               num-filled num-of)
                                       'face 'font-lock-comment-face)))))))
            (h/mirror-mode)
            (setq-local h/mirror-query `( ,source ,hyperdrive ,target-dir
                                          :filter ,filter))
            (setq-local h/mirror-parent-entry parent-entry)
            ;; TODO: Add command to clear plz queue.
            (h/mirror--check-items
             source files hyperdrive target-dir
             :progress-fun #'update-progress
             :then (lambda (items)
                     (h/mirror--metadata-finally
                      buffer
                      (sort items
                            (pcase-lambda ((cl-struct hyperdrive-mirror-item (file a-file))
                                           (cl-struct hyperdrive-mirror-item (file b-file)))
                              (string< a-file b-file))))))
            (pop-to-buffer (current-buffer))))))))

(defun h/mirror--metadata-finally (buffer files-and-urls)
  "Insert FILES-AND-URLS into BUFFER.
Callback for queue finalizer in `hyperdrive-mirror'."
  (with-current-buffer buffer
    (with-silent-modifications
      (let ((pos (point))
            (section-ident (and (magit-current-section)
                                (magit-section-ident (magit-current-section))))
            (window-start 0) (window-point 0)
            (uploadable (cl-remove-if-not (lambda (status)
                                            (member status '(new newer)))
                                          files-and-urls
                                          :key #'h/mirror-item-status))
            (non-uploadable (cl-remove-if-not (lambda (status)
                                                (member status '(older same)))
                                              files-and-urls
                                              :key #'h/mirror-item-status)))
        (setq-local h/mirror-files-and-urls files-and-urls)
        (when-let ((window (get-buffer-window (current-buffer))))
          (setf window-point (window-point window))
          (setf window-start (window-start window)))
        (when h/mirror-visibility-cache
          (setf magit-section-visibility-cache h/mirror-visibility-cache))
        (add-hook 'kill-buffer-hook #'h/mirror--cache-visibility nil 'local)
        (delete-all-overlays)
        (erase-buffer)
        (when non-uploadable
          (h/mirror--insert-taxy :name "Ignored" :items non-uploadable))
        (when uploadable
          (h/mirror--insert-taxy :name "To upload" :items uploadable))
        (if-let ((section-ident)
                 (section (magit-get-section section-ident)))
            (goto-char (oref section start))
          (goto-char pos))
        (when-let ((window (get-buffer-window (current-buffer))))
          (set-window-start window window-start)
          (set-window-point window window-point))))
    (set-buffer-modified-p nil)))

(cl-defun h/mirror--insert-taxy
    (&key items name (keys h/mirror-default-keys))
  "Insert and return a `taxy' for `hyperdrive-mirror', optionally having ITEMS.
NAME is the name of the section.  KEYS should be a list of
grouping keys, as in `hyperdrive-mirror-default-keys'."
  (let (format-table column-sizes)
    (cl-labels ((format-item (item)
                  (gethash item format-table))
                (make-fn (&rest args)
                  (apply #'make-taxy-magit-section
                         :make #'make-fn
                         :format-fn #'format-item
                         :level-indent 2
                         :item-indent 0
                         args)))
      (let* ((taxy-magit-section-insert-indent-items nil)
             (taxy
              (thread-last
                (make-fn :name name
                         :take (taxy-make-take-function keys h/mirror-keys))
                (taxy-fill items)
                (taxy-sort* (lambda (a b)
                              (pcase a
                                ("New locally" t)
                                ((and "Newer locally"
                                      (guard (or (equal b "Older locally")
                                                 (equal b "Same"))))
                                 t)
                                ((and "Older locally" (guard (equal b "Same"))) t)
                                (_ nil)))
                  ;; TODO: Instead of comparing taxy-name strings, could we set
                  ;; taxy-key to `new', `newer', `older', or `same' and then
                  ;; compare keys instead?  (When we change to static taxys,
                  ;; sorting them won't be necessary.)
                  #'taxy-name)))
             (format-cons
              (taxy-magit-section-format-items
               h/mirror-columns h/mirror-column-formatters
               taxy))
             (inhibit-read-only t))
        (setf format-table (car format-cons))
        (setf column-sizes (cdr format-cons))
        (setf header-line-format (taxy-magit-section-format-header
                                  column-sizes h/mirror-column-formatters))
        ;; Before this point, no changes have been made to the buffer's contents.
        (save-excursion
          (taxy-magit-section-insert taxy :items 'first :initial-depth 0))
        taxy))))

(defun h/mirror-read-filter ()
  "Read a function for filtering source files for mirroring."
  (let* ((readers
          '(("Mirror all files" . nil)
            ("Regexp string" .
             (lambda () (read-regexp "Regular expression: ")))
            ("Lambda function" .
             (lambda () (read--expression "Lambda: " "(lambda (filename) )")))
            ("Named function"   .
             (lambda () (intern (completing-read "Named function: "
                                                 obarray #'functionp t))))))
         ;; TODO(transient): Implement returning values from prefixes,
         ;; allowing us to use a sub-prefix here instead of completing-read.
         (reader (completing-read "Filter type: " readers nil t))
         (reader (alist-get reader readers nil nil #'equal)))
    (and reader (funcall reader))))

(defun h/mirror-do-upload ()
  "Upload files in current \"*hyperdrive-mirror*\" buffer."
  (interactive nil h/mirror-mode)
  ;; FIXME: Debounce this (e.g. if the user accidentally calls this
  ;; command twice in a mirror buffer, it would start another queue to
  ;; upload the same files, which would unnecessarily increment the
  ;; hyperdrive version by potentially a lot).
  (if (and h/mirror-files-and-urls h/mirror-parent-entry)
      (h//mirror h/mirror-files-and-urls h/mirror-parent-entry)
    (h/user-error "Missing information about files to upload.  \
Are you in a \"*hyperdrive-mirror*\" buffer?")))

(defun h/mirror--cache-visibility ()
  "Save visibility cache.
Sets `hyperdrive-mirror-visibility-cache' to the value of
`magit-section-visibility-cache'.  To be called in
`kill-buffer-hook' in `hyperdrive-mirror' buffers."
  (ignore-errors
    (when magit-section-visibility-cache
      (setf h/mirror-visibility-cache magit-section-visibility-cache))))

;;;; Mode

(defvar-keymap h/mirror-mode-map
  :parent magit-section-mode-map
  :doc "Local keymap for `hyperdrive-mirror-mode' buffers."
  "C-c C-c"   #'h/mirror-do-upload)

(define-derived-mode h/mirror-mode magit-section-mode
  "Hyperdrive-mirror"
  "Major mode for buffers for mirror local directories to a hyperdrive."
  :group 'hyperdrive
  :interactive nil
  (setq-local revert-buffer-function #'h/mirror-revert-buffer))

;;;; Footer

(provide 'hyperdrive-mirror)

;; Local Variables:
;; read-symbol-shorthands: (
;;   ("he//" . "hyperdrive-entry--")
;;   ("he/"  . "hyperdrive-entry-")
;;   ("h//"  . "hyperdrive--")
;;   ("h/"   . "hyperdrive-"))
;; End:
;;; hyperdrive-mirror.el ends here
