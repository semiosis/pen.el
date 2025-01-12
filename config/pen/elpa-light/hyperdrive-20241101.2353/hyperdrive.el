;;; hyperdrive.el --- P2P filesystem  -*- lexical-binding: t; -*-

;; Copyright (C) 2022, 2023, 2024 USHIN, Inc.

;; Author: Joseph Turner <joseph@ushin.org>
;; Author: Adam Porter <adam@alphapapa.net>
;; Maintainer: Joseph Turner <~ushin/ushin@lists.sr.ht>
;; Created: 2022
;; Package-Version: 20241101.2353
;; Package-Revision: 581752cad8bc
;; Package-Requires: ((emacs "28.1") (map "3.0") (compat "30.0.0.0") (org "9.7.6") (plz "0.9.1") (persist "0.6.1") (taxy-magit-section "0.14") (transient "0.7.7"))
;; Homepage: https://git.sr.ht/~ushin/hyperdrive.el

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU Affero General Public License
;; as published by the Free Software Foundation; either version 3 of
;; the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; Affero General Public License for more details.

;; You should have received a copy of the GNU Affero General Public
;; License along with this program. If not, see
;; <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Hyperdrive is a P2P, real-time, local-first, versioned filesystem
;; designed for easy peer-to-peer file sharing.  hyperdrive.el is an
;; independent project built by https://ushin.org, which provides an
;; Emacs interface for managing hyperdrives.

;;;; Installation:

;; hyperdrive.el can be installed on Emacs version 28.1 or later with

;; M-x package-install hyperdrive

;; hyperdrive.el relies on hyper-gateway-ushin for connecting to the P2P
;; network.  You can download and install the gateway by running

;; M-x hyperdrive-install

;;; Code:

;;;; Requirements

(require 'cl-lib)

(require 'bookmark)
(require 'json)
(require 'rx)

;; NOTE: On older versions of Emacs with older built-in versions of
;; `map', it's not possible to force Emacs to load the newer version
;; of the library when compiling the package; we can only
;; "Package-Requires" it to cause it to be installed.  So in the case
;; that a user encounters an error caused by macro-expanding an older
;; version of the library, the user would need to delete the
;; hyperdrive package, restart Emacs, and reinstall this package to
;; fix it.
(require 'map)

(require 'compat)
(require 'plz)

(require 'hyperdrive-lib)
(require 'hyperdrive-org)
(require 'hyperdrive-download-monitor)

;;;; Links

(defvar browse-url-handlers)
(defvar thing-at-point-uri-schemes)

(defun h/browse-url (url &rest _ignore)
  "Browse hyperdrive URL."
  (h/open-url url))

(require 'browse-url)
(require 'thingatpt)

(cl-pushnew (cons (rx bos "hyper://") #'h/browse-url)
            browse-url-handlers :test #'equal)
(cl-pushnew "hyper://" thing-at-point-uri-schemes :test #'equal)

;;;; Commands

;; TODO[#A]: Command to rename paths.

;;;###autoload
(defun hyperdrive-start ()
  "Start the gateway if not already running.
Calls function set in option `hyperdrive-gateway-start-function',
which see."
  (interactive)
  (let ((gateway-installed-p (h/gateway-installed-p)))
    (cond (h//gateway-stopping-timer
           (h/user-error "Wait for gateway to stop before starting"))
          (h//gateway-starting-timer
           (h/user-error "Gateway already starting"))
          ((and (h//gateway-ready-p) (h/gateway-live-p))
           (h/user-error "Gateway already running"))
          ((h/gateway-live-p)
           (h/user-error "Gateway process currently live"))
          ((h//gateway-ready-p)
           (h/user-error "Gateway already running outside of Emacs"))
          ((and (not gateway-installed-p) (h/gateway-installing-p))
           (h/user-error "Gateway installation in-progress"))
          ((not gateway-installed-p)
           (h/user-error "Gateway not installed; try \\[hyperdrive-install]"))
          (t
           (h/message
            (if (h/gateway-installing-p)
                "Gateway installation in-progress; starting old gateway anyway."
              "Starting gateway."))
           (funcall h/gateway-start-function))))
  (h//gateway-wait-for-ready))

;;;###autoload
(defun hyperdrive-stop ()
  "Stop the gateway if running.
Calls function set in option `hyperdrive-gateway-stop-function',
which see."
  (interactive)
  (cond
   (h//gateway-stopping-timer
    (h/user-error "Gateway already stopping"))
   ((and (not (h//gateway-ready-p)) (not (h/gateway-live-p)))
    (h/user-error "Gateway already stopped"))
   (t
    (funcall h/gateway-stop-function)))
  ;; Cancel starting timer after calling h/gateway-stop-function since
  ;; h/gateway-ready-hook should still run if h/gateway-stop-function fails.
  (when (timerp h//gateway-starting-timer)
    (cancel-timer h//gateway-starting-timer)
    (setf h//gateway-starting-timer nil))
  (h//gateway-wait-for-dead))

(defun h/restart ()
  "Restart the gateway."
  (interactive)
  (h/message "Restarting gateway...")
  ;; NOTE: Demote errors to continue execution in case the gateway is
  ;; stopped/stopping.  Don't pass FORMAT to `with-demoted-errors' since the
  ;; errors `h/stop' may signal are already prefixed with "Hyperdrive".
  (with-demoted-errors "Hyperdrive: %S" (h/stop))
  (with-timeout (10 (h/error "Timed out waiting for gateway to stop"))
    (cl-loop while (h/gateway-live-p)
             do (sleep-for 0.2)))
  (h/start))

;;;###autoload
(defun hyperdrive-gateway-version ()
  "Say version number of gateway and copy it to the `kill-ring'.
Return version if gateway is running; otherwise signal an error."
  (interactive)
  (let ((version (format "%S" (h//gateway-version))))
    (kill-new version)
    (h/message version)))

;;;###autoload
(defun hyperdrive-new (seed)
  "Open new hyperdrive for SEED.

If SEED is not currently used as the petname for another
hyperdrive, the new hyperdrive's petname will be set to SEED."
  (interactive (list (h/read-name :prompt "New hyperdrive seed")))
  (pcase-let* (((cl-struct plz-response (body url))
                (h/api 'post (concat "hyper://localhost/?key="
                                     (url-hexify-string seed))
                  :as 'response))
               (hyperdrive (he/hyperdrive (h/url-entry url))))
    (unless url (h/error "Unable to create new hyperdrive with seed: %S" seed))
    (setf (h/seed hyperdrive) seed)
    (setf (h/writablep hyperdrive) t)
    (setf (map-elt (h/etc hyperdrive) 'safep) t)
    (unwind-protect
        (h/set-petname seed hyperdrive)
      ;; TODO: Hyperdrive disk usage should be set here.
      (h/persist hyperdrive)
      (h/open (h/url-entry url)))))

;;;###autoload
(defun hyperdrive-mark-as-safe (hyperdrive safep)
  "Mark HYPERDRIVE as safe according to SAFEP.
Interactively, prompt for hyperdrive and action."
  (interactive
   (pcase-let* ((hyperdrive (h//context-hyperdrive))
                (mark-safe-p
                 (pcase (read-answer
                         (format "Mark hyperdrive `%s' as: (currently: %s) "
                                 (h//format-hyperdrive hyperdrive)
                                 (h/safe-string hyperdrive))
                         '(("safe" ?S "mark as safe")
                           ("unsafe" ?U "mark as unsafe")
                           ("unknown" ?u "ask again later")
                           ("explain" ?e "show Info manual section explaining safety")
                           ("quit" ?q "quit")))
                   ("safe" t)
                   ("unsafe" nil)
                   ("unknown" 'unknown)
                   ("explain" :explain)
                   (_ :quit))))
     (list hyperdrive mark-safe-p)))
  (pcase safep
    ;; FIXME: If "explain" is selected from within a transient, Emacs signals
    ;; "Error in post-command-hook (transient--post-command): (wrong-type-argument ewoc nil)"
    ;; since the transient refreshes after the current buffer is the Info
    ;; manual, which has no ewoc.  The transient menu should instead close.
    (:explain (info "(hyperdrive) Mark a hyperdrive as safe"))
    (:quit nil)
    (_ (setf (map-elt (h/etc hyperdrive) 'safep) safep)
       (h/persist hyperdrive)
       (message "Marked hyperdrive `%s' as %s."
                (h//format-hyperdrive hyperdrive)
                (h/safe-string hyperdrive)))))

(defun h/forget-file (entry)
  "Delete local copy of the file or directory contents of ENTRY.
Only delete the blob(s) for the file or directory at ENTRY's
version; other versions of the file or directory are not cleared.
If ENTRY is a directory, recursively delete blobs for all files
within the directory.  Hyperdrive directory contents are not
modified; file blobs may be recoverable from other peers.

Interactively, forget current file ENTRY or ENTRY at point in a
directory.  Otherwise, or with universal prefix argument
\\[universal-argument], prompt for ENTRY."
  ;; TODO: Consider supporting an :all-versions key for clearing the cache for
  ;; all versions of the file/directory.
  (interactive (list (h//context-entry :force-prompt current-prefix-arg)))
  (when (yes-or-no-p
         (format-message
          "Clear local copy of entry (data may not be recoverable—see manual):`%s'? "
          (h//format-entry entry)))
    (he/api 'post entry
      :headers '(("Cache-Control" . "no-store"))
      :else (lambda (err)
              (h/error "Unable to clear cache for `%s': %S" (he/url entry) err))
      ;; Make async; `he//api-then' will call `he//invalidate'.
      :then #'ignore)))

;;;###autoload
(defun hyperdrive-purge (hyperdrive)
  "Purge all data corresponding to HYPERDRIVE."
  (interactive (list (h//context-hyperdrive :force-prompt t)))
  (when (yes-or-no-p (format-message "Delete local copy of hyperdrive (data will likely not be recoverable—see manual): `%s'? "
                                     (h//format-hyperdrive hyperdrive)))
    (h/purge-no-prompt hyperdrive
      :then (lambda (_response)
              (h/message "Purged drive: %s" (h//format-hyperdrive hyperdrive)))
      :else (lambda (plz-error)
              (h/error "Unable to purge drive: %s %S" (h//format-hyperdrive hyperdrive) plz-error)))))

;;;###autoload
(defun hyperdrive-set-petname (petname hyperdrive)
  "Set HYPERDRIVE's PETNAME.
Entering an empty or blank string unsets PETNAME.
Returns HYPERDRIVE.

With universal prefix argument \\[universal-argument], always
prompt for a hyperdrive."
  (interactive
   (let* ((hyperdrive (h//context-hyperdrive :force-prompt current-prefix-arg))
          (petname (h/read-name
                    :prompt (format "Petname for `%s' (leave blank to unset)"
                                    (h//format-hyperdrive hyperdrive))
                    :initial-input (h/petname hyperdrive))))
     (list petname hyperdrive)))
  (while-let (((not (equal petname (h/petname hyperdrive))))
              (other-hyperdrive (cl-find petname (hash-table-values h/hyperdrives)
                                         :key #'h/petname :test #'equal)))
    (setf petname (h/read-name
                   :prompt (format "%S already assigned as petname to hyperdrive `%s'.  Enter new petname"
                                   petname (h//format-hyperdrive other-hyperdrive))
                   :initial-input (h/petname hyperdrive))))
  (if (string-blank-p petname)
      (when (yes-or-no-p (format-message "Unset petname for `%s'? "
                                         (h//format-hyperdrive hyperdrive)))
        (setf (h/petname hyperdrive) nil))
    (setf (h/petname hyperdrive) petname))
  (h/persist hyperdrive)
  ;; TODO: Consider refreshing buffer names, directory headers, etc.
  hyperdrive)

;;;###autoload
(cl-defun hyperdrive-set-nickname (nickname hyperdrive &key (then #'ignore))
  "Set HYPERDRIVE's NICKNAME.
Returns HYPERDRIVE.

Asynchronous callback calls THEN with the updated hyperdrive as
its only argument.

With universal prefix argument \\[universal-argument], always
prompt for a hyperdrive."
  (interactive
   (let* ((hyperdrive (h//context-hyperdrive :predicate #'h/writablep
                                             :force-prompt current-prefix-arg))
          (nickname
           ;; NOTE: Fill metadata first in case the JSON file has been updated manually
           (progn
             (h/fill-metadata hyperdrive)
             (h/read-name
              :prompt (format-message "Nickname for `%s'"
                                      (h//format-hyperdrive hyperdrive))
              :initial-input (alist-get 'name (h/metadata hyperdrive))))))
     (list nickname hyperdrive)))
  (unless (equal nickname (alist-get 'name (h/metadata hyperdrive)))
    (if (string-blank-p nickname)
        (progn
          (cl-callf map-delete (h/metadata hyperdrive) 'name)
          (h/put-metadata hyperdrive
            :then (lambda (_response) (funcall then hyperdrive))))
      (setf (alist-get 'name (h/metadata hyperdrive)) nickname)
      (h/put-metadata hyperdrive
        :then (lambda (_response) (funcall then hyperdrive))))
    ;; TODO: Consider refreshing buffer names, directory headers, etc, especially host-meta.json entry buffer.
    )
  hyperdrive)

(defun h/revert-buffer (&optional _ignore-auto noconfirm)
  "Revert `hyperdrive-mode' buffer by reloading hyperdrive contents.
With NOCONFIRM or when current entry is a directory, revert
without confirmation."
  (when (or (h//entry-directory-p h/current-entry)
            noconfirm
            ;; TODO: Add option hyperdrive-revert-without-query ?
            ;; (and (not (buffer-modified-p))
            ;;      (catch 'found
            ;;        (dolist (regexp revert-without-query)
            ;;          (when (string-match regexp file-name)
            ;;            (throw 'found t)))))
            (yes-or-no-p
             (format (if (buffer-modified-p)
                         "Hyperdrive: Discard edits and reread from %s? "
                       "Hyperdrive: Revert buffer from %s? ")
                     (he/url h/current-entry))))
    ;; TODO: Support before-revert-hook, after-revert-hook, revert-buffer-internal-hook
    ;; Setting the modified flag to nil prevents `h/open'
    ;; from erroring if it has been modified.
    (set-buffer-modified-p nil)
    (h/open h/current-entry)
    t))

(defun h/revert-buffer-quick ()
  "Like `revert-buffer-quick', but works with `hyperdrive-mode' files."
  (interactive nil h/mode)
  (h/revert-buffer nil (not (buffer-modified-p))))

;;;; h/mode

(defvar-local h/mode--state nil
  "Previous state of buffer before `hyperdrive-mode' was activated.
Intended to be passed to `buffer-local-restore-state'.")

;;;###autoload
(define-minor-mode hyperdrive-mode
  ;; TODO: Consider moving h/mode definition to
  ;; hyperdrive-lib.el.  (Since it's used in multiple files.)
  "Minor mode for buffers opened from hyperdrives."
  :global nil
  :interactive nil
  :group 'hyperdrive
  :lighter " hyperdrive"
  :keymap '(([remap revert-buffer-quick] . h/revert-buffer-quick)
            ([remap dired-jump] . h/up))
  (if h/mode
      (progn
        (setq-local h/mode--state
                    (buffer-local-set-state
                     revert-buffer-function #'h/revert-buffer
                     bookmark-make-record-function #'h/bookmark-make-record
                     write-contents-functions (cl-adjoin #'h//write-contents write-contents-functions)
                     ;; TODO: Modify buffer-local value of `save-some-buffers-action-alist'
                     ;; to allow diffing modified buffer with hyperdrive file
                     buffer-offer-save t))
        (add-hook 'after-change-major-mode-hook
                  #'h//hack-write-contents-functions nil 'local)
        ;; TODO: Consider checking for existing advice before adding our own.
        (advice-add #'org-insert-link :after #'h/org--insert-link-after-advice))
    (buffer-local-restore-state h/mode--state)
    (remove-hook 'after-change-major-mode-hook
                 #'h//hack-write-contents-functions 'local)
    ;; FIXME: Only remove advice when all h/mode buffers are killed.
    ;; (advice-remove #'org-insert-link #'hyperdrive-org--insert-link)
    ))
;; Making it permanent-local keeps the minor mode active even if the
;; user changes the major mode, so the buffer can still be saved back
;; to the hyperdrive.
(put 'h/mode 'permanent-local t)

(defun h//hack-write-contents-functions ()
  "Hack `write-contents-functions' for `hyperdrive-mode' in current buffer.
Ensures that hyperdrive buffers can still be saved after the
major mode changes (which resets `write-contents-functions' by
calling `kill-all-local-variables')."
  (cl-pushnew #'h//write-contents write-contents-functions))
(put 'h//hack-write-contents-functions 'permanent-local-hook t)

;;;###autoload
(defun hyperdrive-find-file (entry)
  "Find hyperdrive ENTRY.
Interactively, prompt for known hyperdrive and path.
With universal prefix argument \\[universal-argument], prompt for version."
  (interactive
   (list (h/read-entry (h/read-hyperdrive) :read-version current-prefix-arg)))
  (h/open entry))

;;;###autoload
(defun hyperdrive-view-file (entry)
  "View ENTRY in `view-mode', returning to previous buffer when done.
Interactively, prompt for known hyperdrive and path.
With universal prefix argument \\[universal-argument], prompt for version."
  ;; TODO: Stay in `view-mode' after
  ;; `hyperdrive-previous-version'/`hyperdrive-next-version'. This may
  ;; require another minor mode.
  (interactive (list (h/read-entry (h/read-hyperdrive)
                                   :read-version current-prefix-arg)))
  (h/open entry
    ;; `view-buffer' checks the mode-class symbol property of
    ;; `major-mode' and avoids putting directory buffers in `view-mode'.
    :createp nil :then (lambda () (view-buffer (current-buffer)))))

;;;###autoload
(defun hyperdrive-open-url (url)
  "Open hyperdrive URL."
  (interactive (list (h/read-url :prompt "Open hyperdrive URL")))
  (h/open (h/url-entry url)))

;;;###autoload
(cl-defun hyperdrive-delete (entry &key (then #'ignore) (else #'ignore))
  "Delete ENTRY, then call THEN with response.
Call ELSE with `plz-error' struct if request fails.
Interactively, delete current file ENTRY or ENTRY at point in a
directory.  Otherwise, or with universal prefix argument
\\[universal-argument], prompt for ENTRY."
  (declare (indent defun))
  (interactive
   (let* ((entry (h//context-entry
                  :latest-version t :force-prompt current-prefix-arg))
          (description (h//format-entry entry))
          (buffer (current-buffer)))
     (when (and (h//entry-directory-p entry)
                (or (eq entry h/current-entry)
                    (string= "../" (alist-get 'display-name (he/etc entry)))))
       (h/user-error "Won't delete from within"))
     (when (and (yes-or-no-p (format-message "Delete `%s'? " description))
                (or (not (h//entry-directory-p entry))
                    (yes-or-no-p (format-message "Recursively delete `%s'? "
                                                 description))))
       (list entry
             :then (lambda (_)
                     (when (and (buffer-live-p buffer)
                                (eq 'h/dir-mode (buffer-local-value 'major-mode buffer)))
                       (with-current-buffer buffer
                         (revert-buffer)))
                     (h/message "Deleted: `%s' (Deleted files can be accessed from prior versions of the hyperdrive.)" description))
             :else (lambda (plz-error)
                     (h/message "Unable to delete `%s': %S" description plz-error))))))
  (he/api 'delete entry
    :then (lambda (response)
            (pcase-let* (((cl-struct plz-response headers) response)
                         ((map etag) headers)
                         (nonexistent-entry (compat-call copy-tree entry t)))
              (setf (he/version nonexistent-entry) (string-to-number etag))
              ;; Since there's no way for `h//write-contents' to run when
              ;; `buffer-modified-p' returns nil, this is a workaround to ensure that
              ;; `save-buffer' re-saves files after they've been deleted.
              (when-let* ((buffer (h//find-buffer-visiting entry))
                          ((buffer-live-p buffer)))
                (with-current-buffer buffer (set-buffer-modified-p t)))
              (funcall then response)))
    :else else))

;;;###autoload
(defun hyperdrive-download (entry filename)
  "Download ENTRY to FILENAME on disk.
Interactively, download current hyperdrive file or file at point
in a directory.  Otherwise, or with universal prefix argument
\\[universal-argument], prompt for ENTRY."
  (interactive
   (pcase-let* ((entry (h//context-entry :force-prompt current-prefix-arg))
                ((cl-struct hyperdrive-entry name) entry)
                (read-filename (read-file-name "Filename: " (expand-file-name name h/download-directory))))
     (list entry read-filename)))
  (h/download-url (he/url entry) filename))

;;;###autoload
(defun hyperdrive-download-url (url filename)
  "Load contents at URL as a file to store on disk at FILENAME."
  ;; TODO: Implement entry-based version of this function, or change callers to use entries.
  ;; TODO: Handle directory URLs (recursively download contents?)
  ;; TODO: Hook in download monitor optionally.
  (interactive
   (let* ((read-url (h/read-url :prompt "Download hyperdrive URL"))
          (name (he/name (h/url-entry read-url)))
          (read-filename (read-file-name "Filename: " (expand-file-name name h/download-directory))))
     (list read-url read-filename)))
  (when (or (not (file-exists-p filename))
            (yes-or-no-p (format "File %s already exists; overwrite anyway? " (expand-file-name filename))))
    (when (file-exists-p filename)
      ;; plz.el will not overwrite existing files: ensure there's no file there.
      (delete-file filename))
    ;; TODO(plz v0.10.0): In an upcoming version of `plz', nonexistent parent
    ;; directories will be created for us.  At that point, remove this line.
    (make-directory (file-name-parent-directory filename) t)
    (h/api 'get url :as `(file ,filename)
      :then (lambda (_)
              (h/message "Downloaded `%s' to `%s'." url filename)
              ;; TODO: If plz adds support for getting response headers when downloading
              ;; as a file (<https://github.com/alphapapa/plz.el/issues/61>), use it here.
              ;; Head request is necessary in order to update hyperdrive disk-usage.
              (he/api 'head (h/url-entry url)))
      :else (lambda (plz-error)
              (h/message "Unable to download: %s: %S" url plz-error)))))

;;;###autoload
(defun hyperdrive-write-buffer (entry &optional overwritep)
  "Write current buffer to new hyperdrive ENTRY.
If file already exists and OVERWRITEP is nil, prompt the user to
overwrite.

With universal prefix argument \\[universal-argument], overwrite
without prompting.

This function is for interactive use only since it calls
`select-safe-coding-system', which may prompt for input.
For non-interactive use, see `hyperdrive-write'."
  (interactive (list (h/read-entry (h/read-hyperdrive #'h/writablep)
                                   :default-path
                                   (or (and (buffer-file-name)
                                            (file-name-nondirectory
                                             (buffer-file-name)))
                                       (and h/current-entry
                                            (he/path h/current-entry)))
                                   :latest-version t)
                     current-prefix-arg))
  (pcase-let* (((cl-struct hyperdrive-entry name) entry)
               (url (he/url entry))
               (orig-buffer (current-buffer))
               (coding-system
                (with-current-buffer orig-buffer
                  ;; Detect coding in orig buffer so `buffer-file-coding-system'
                  ;; is prioritized.
                  (select-safe-coding-system (point-min) (point-max))))
               (encoded-buffer
                (with-current-buffer
                    (generate-new-buffer
                     (format " *hyperdrive-encoded %s*" orig-buffer) t)
                  (insert-buffer-substring orig-buffer)
                  (encode-coding-region (point-min) (point-max) coding-system)
                  (current-buffer)))
               (buffer-visiting-entry (h//find-buffer-visiting entry)))
    (unless (or overwritep (not (he/at nil entry)))
      (unless (y-or-n-p
	       (format "File %s exists; overwrite?" (h//format-entry entry)))
        (h/user-error "Canceled"))
      (when (buffer-live-p buffer-visiting-entry)
        (unless (y-or-n-p (format "A buffer is visiting %s; proceed?"
                                  (h//format-entry entry)))
          (h/user-error "Aborted"))))
    (h/write entry
      :body encoded-buffer
      :then (lambda (_response)
              (when (buffer-live-p orig-buffer)
                (with-current-buffer orig-buffer
                  (unless h/mode
                    (h//clean-buffer)
                    (h//set-auto-mode)
                    (h/mode))
                  ;; PUT responses only include ETag and Last-Modified
                  ;; headers, so we need to set other entry metadata manually.
                  (setf (he/size entry) (with-current-buffer encoded-buffer
                                          (bufferpos-to-filepos (point-max))))
                  ;; FIXME: Will entry type ever be anything besides text/plain?
                  ;;        /.well-known/host-meta.json ?
                  (setf (he/type entry)
                        (format "text/plain; charset=%s"
                                (coding-system-base coding-system)))
                  (setq-local h/current-entry entry)
                  (setf buffer-file-name nil)
                  (unless (eq orig-buffer buffer-visiting-entry)
                    (when (buffer-live-p buffer-visiting-entry)
                      (kill-buffer buffer-visiting-entry))
                    (rename-buffer (h//generate-new-buffer-name entry)))
                  (set-buffer-modified-p nil)
                  ;; Update the visited file modtime so undo commands
                  ;; correctly set the buffer-modified flag.  We just
                  ;; use `current-time' here since it's good enough
                  ;; and lets us avoid making another request for
                  ;; metadata.
                  (set-visited-file-modtime (current-time))))
              (h/message "Wrote: %S to \"%s\"" name url)
              (when (buffer-live-p encoded-buffer)
                (kill-buffer encoded-buffer)))
      :else (lambda (plz-error)
              (h/message "Unable to write: %S: %S" name plz-error)
              (when (buffer-live-p encoded-buffer)
                (kill-buffer encoded-buffer))))
    (h/message "Saving to \"%s\"..." url)
    ;; TODO: Reload relevant hyperdrive-dir buffers after writing buffer (if ewoc buffers display version, then possibly all ewoc buffers for a given hyperdrive should be reloaded)
    ))

(defun h//write-contents ()
  "Call `hyperdrive-write-buffer' for the current buffer.
To be used in `write-contents-functions'."
  (cl-assert h/mode)
  (h/write-buffer h/current-entry t))

(defun h/copy-url (entry)
  "Save hyperdrive ENTRY's URL to the kill ring.
Interactively, uses `hyperdrive-current-entry', from either a
hyperdrive directory listing or a `hyperdrive-mode' file buffer."
  (interactive (list h/current-entry) h/mode)
  (let ((url (he/url entry)))
    (kill-new url)
    (h/message "%s" url)))

(cl-defun h/up (entry &key (then nil then-set-p))
  "Go up to parent directory of ENTRY.
Interactively, use the `hyperdrive-current-entry'.  If THEN, pass
it to `hyperdrive-open'."
  (interactive (progn
                 (unless (and h/mode h/current-entry)
                   (h/user-error "Not a hyperdrive buffer"))
                 (list h/current-entry))
               h/mode)
  (if-let ((parent (h/parent entry)))
      ;; TODO: Go to entry in parent directory.
      (if then-set-p
          (h/open parent :then then)
        ;; Allow default callback to be used.
        (h/open parent))
    (h/user-error "At root directory")))

(defvar-keymap h/up-map
  :doc "Keymap to repeat `hyperdrive-up'.  Used in `repeat-mode'."
  :repeat t
  "j"   #'h/up
  "C-j" #'h/up)

;;;###autoload
(define-minor-mode hyperdrive-blob-mode
  "Minor mode for visiting previous versions of hyperdrive files."
  :global nil
  :interactive nil
  :group 'hyperdrive
  :lighter " hyperdrive-blob"
  :keymap '(("n" . h/open-next-version)
            ("p" . h/open-previous-version)
            ("q" . kill-current-buffer)))

(defun h/open-previous-version (entry)
  "Open previous version of ENTRY."
  (interactive (list h/current-entry) h/mode)
  (he/fill-version entry)
  (pcase-let (((cl-struct h/entry hyperdrive path version
                          (etc (map previous-version-exists-p
                                    previous-version-number)))
               entry))
    (pcase-exhaustive previous-version-exists-p
      ('t (h/open (he/create :hyperdrive hyperdrive :path path
                             :version previous-version-number)))
      ('nil (h/message "%s nonexistent before version %d.  Try \\[hyperdrive-history]."
                       (h//format-entry
                        entry h/default-entry-format-without-version)
                       version))
      ('unknown (h/message
                 "Temporarily unable to load previous version of %s: \
unknown before version %d. \
Try \\[hyperdrive-history]."
                 (h//format-entry entry h/default-entry-format-without-version)
                 version)))))

(defun h/open-next-version (entry)
  "Open next version of ENTRY.
If entry is already at the latest version, entry was deleted
after its current version range or entry's existence is unknown,
say so.  If entry is already within the latest version range,
switch to the latest version and say so."
  (interactive (list h/current-entry) h/mode)
  (he/fill-version entry)
  (pcase-exhaustive (map-elt (he/etc entry) 'next-version-exists-p)
    ((guard (not (he/version entry)))
     (h/message
      "Already at latest version of %s; \
use \\[revert-buffer-quick] to check for changes."
      (h//format-entry entry h/default-entry-format-without-version)))
    ('t (pcase-exhaustive (map-elt (he/etc entry) 'next-version-number)

          ('nil
           (h/open (he/create :hyperdrive (he/hyperdrive entry)
                              :path (he/path entry) :version nil))
           (h/message
            "Switching to latest version of %s; \
use \\[revert-buffer-quick] to check for changes."
            (h//format-entry entry h/default-entry-format-without-version)))
          ((and (pred numberp) version)
           (h/open (he/create :hyperdrive (he/hyperdrive entry)
                              :path (he/path entry) :version version)))))
    ('nil
     (h/message "%s was deleted at version %d.  Try \\[hyperdrive-history]."
                (h//format-entry entry h/default-entry-format-without-version)
                (map-elt (he/etc entry) 'next-version-number)))
    ('unknown
     (h/message
      "Temporarily unable to load next version of %s: unknown at %d. \
Try \\[hyperdrive-history]."
      (h//format-entry entry h/default-entry-format-without-version)
      (map-elt (he/etc entry) 'next-version-number)))))

(defun h/open-at-version (entry version)
  "Open ENTRY at VERSION.
Nil VERSION means open the entry at its hyperdrive's latest version."
  (interactive
   (let ((entry h/current-entry))
     (list entry (h/read-version
                  :hyperdrive (he/hyperdrive entry)
                  :prompt (format-message
                           "Open `%s' at version (leave blank for latest version)"
                           (h//format-entry
                            entry h/default-entry-format-without-version)))))
   h/mode)
  (if-let ((latest-entry (he/at version entry)))
      (h/open latest-entry)
    (h/message "%s does not exist at version %s. Try \\[hyperdrive-history]"
               (h//format-entry
                entry h/default-entry-format-without-version)
               version)))

;;;; Bookmark support

;; TODO: Display entry description instead of full URL in bookmark list view.
(require 'bookmark)

(defun h/bookmark-make-record ()
  "Return a bookmark record for current hyperdrive buffer.
Works in `hyperdrive-mode' and `hyperdrive-dir-mode' buffers."
  (let ((bookmark (bookmark-make-record-default 'no-file)))
    (setf (alist-get 'handler bookmark) #'h/bookmark-handler)
    (setf (alist-get 'location bookmark) (he/url h/current-entry))
    (cons (format "hyperdrive: %s" (h//format-entry h/current-entry)) bookmark)))

;;;###autoload
(defun hyperdrive-bookmark-handler (bookmark)
  "Handler for Hyperdrive BOOKMARK."
  (h/open (h/url-entry (alist-get 'location (cdr bookmark)))
    :then (lambda ()
            (bookmark-default-handler
             ;; We add the buffer property, because we don't want to
             ;; store that in the bookmark record, because the buffer
             ;; name could change in the future, and that would make
             ;; the record invalid, which would cause
             ;; `bookmark-default-handler' to signal an error.
             (append bookmark `((buffer . ,(current-buffer)))))
            (pop-to-buffer (current-buffer) '(display-buffer-same-window)))))
(put 'h/bookmark-handler 'bookmark-handler-type "hyperdrive")

(defun h/bookmark-jump (bookmark)
  "Jump to a Hyperdrive BOOKMARK."
  (interactive
   (progn
     (bookmark-maybe-load-default-file)
     (list
      (completing-read "Open Hyperdrive bookmark: " bookmark-alist
                       (pcase-lambda (`(,_name . ,(map handler)))
                         (equal handler #'h/bookmark-handler))
                       t nil 'bookmark-history))))
  (bookmark-jump bookmark))

(defun h/bookmark-list ()
  "List Hyperdrive bookmarks."
  (interactive)
  (bookmark-maybe-load-default-file)
  (let ((bookmark-alist
         (cl-remove-if-not (pcase-lambda (`(,_name . ,(map handler)))
                             (equal handler #'h/bookmark-handler))
                           bookmark-alist)))
    (call-interactively #'bookmark-bmenu-list)))

;;;; Upload files from disk

;;;###autoload
(cl-defun hyperdrive-upload-file
    (filename entry &key queue
              (then (lambda (&rest _ignore)
                      (h/open (h/parent entry))
                      (h/message "Uploaded: \"%s\"." (he/url entry)))))
  "Upload FILENAME to ENTRY.
Interactively, read FILENAME and ENTRY from the user.
After successful upload, call THEN.  When QUEUE, use it."
  (declare (indent defun))
  (interactive (let ((filename (read-file-name "Upload file: " nil nil t)))
                 (list filename
                       (h/read-entry (h/read-hyperdrive #'h/writablep)
                                     :default-path (file-name-nondirectory filename)
                                     :latest-version t))))
  (let ((last-modified (let ((system-time-locale "C"))
                         (format-time-string "%Y-%m-%dT%T.%3NZ"
                                             ;; "%a, %-d %b %Y %T %Z"
                                             (file-attribute-modification-time
                                              (file-attributes filename)) t))))
    (setf (he/size entry) (file-attribute-size (file-attributes filename)))
    (he/api 'put entry :queue queue
      :body `(file ,filename)
      :headers `(("Last-Modified" . ,last-modified))
      :then then)
    ;; TODO: Hyperdrive disk usage should be set here.
    (unless queue
      (h/message "Uploading to \"%s\"..." (he/url entry)))))

(defun h/read-files ()
  "Return list of files read from the user."
  (cl-loop for file = (read-file-name "File (blank to stop): ")
           while (not (string-blank-p file))
           collect file))

(defun h/upload-files (files hyperdrive target-dir)
  "Upload FILES to TARGET-DIR in HYPERDRIVE.

With universal prefix argument \\[universal-argument], always
prompt for a hyperdrive."
  (interactive
   (let* ((files (h/read-files))
          (hyperdrive (h//context-hyperdrive :predicate #'h/writablep
                                             :force-prompt current-prefix-arg))
          ;; TODO: Consider offering target dirs in hyperdrive with completion.
          (target-dir (h/read-path :hyperdrive hyperdrive :prompt "Target directory in `%s'" :default "/")))
     (list files hyperdrive target-dir)))
  (cl-assert (cl-notany #'file-directory-p files))
  (cl-assert (cl-every #'file-readable-p files))
  (setf files (delete-dups files))
  (dolist (file files)
    (unless (= 1 (cl-count (file-name-nondirectory file) files
                           :test #'equal :key #'file-name-nondirectory))
      (h/user-error "Can't upload multiple files with same name: %S" (file-name-nondirectory file))))
  (setf target-dir (h//format-path target-dir :directoryp t))
  (let ((queue (make-plz-queue
                :limit h/queue-limit
                :finally (lambda ()
                           ;; FIXME: Offer more informative message in case of errors?
                           (h/open (he/create :hyperdrive hyperdrive
                                              :path target-dir))
                           (h/message "Uploaded %s files." (length files))))))
    (dolist (file files)
      (let* ((path (file-name-concat target-dir (file-name-nondirectory file)))
             (entry (he/create :hyperdrive hyperdrive :path path)))
        ;; TODO: Handle failures? Retry?
        (h/upload-file file entry :queue queue :then #'ignore)))
    (plz-run queue)))

;;;; Info lookup

(declare-function info-lookup-maybe-add-help "info-look")

(with-eval-after-load 'info-look
  (info-lookup-maybe-add-help
   :mode '(emacs-lisp-mode . "hyperdrive")
   :regexp (rx word-boundary "hyperdrive-" (1+ (not (any "	\n \"'(),[]`‘’"))))
   :doc-spec '((;; INFO-NODE
	        "(hyperdrive)Function Index"
	        ;; TRANS-FUNC
	        nil
	        ;; PREFIX
	        "^ -+ .*: "
	        ;; SUFFIX
	        "\\( \\|$\\)")
	       (;; INFO-NODE
	        "(hyperdrive)Variable Index"
	        ;; TRANS-FUNC
	        nil
	        ;; PREFIX
	        "^ -+ .*: "
	        ;; SUFFIX
	        "\\( \\|$\\)")
               (;; INFO-NODE
	        "(hyperdrive)Keystroke Index"
	        ;; TRANS-FUNC
	        nil
	        ;; PREFIX
	        "^ -+ .*: "
	        ;; SUFFIX
	        "\\( \\|$\\)"))))

;;;; Configure Emacs and EWW for hyper:// URLs.

(require 'url)

;; TODO: EWW buffers end up being marked as modified, and Emacs prompts to save
;; them before exiting.  Emacs should not prompt to save *eww* buffers.
(defun h/url-loader (parsed-url)
  "Retrieve URL synchronously.
PARSED-URL must be a URL-struct like the output of
`url-generic-parse-url'.

The return value of this function is the retrieval buffer."
  (cl-check-type parsed-url url "Need a pre-parsed URL.")
  (pcase-let* ((url (url-recreate-url parsed-url))
               ;; TODO: When `plz.el' adds :as 'response-with-buffer, use that.
               ;; response-buffer will contain the loaded HTML, and will be deleted at the end of `eww-render'.
               ((cl-struct plz-response headers body)
                (he/api 'get (h/url-entry url))))
    (with-current-buffer (generate-new-buffer " *hyperdrive-eww*")
      (widen)
      (goto-char (point-min))
      ;; TODO: When `plz' gains `:as '(response :with buffer)' or whatever, use it instead of this hack.
      ;; HACK: Insert headers because `eww-render' expects them to be in the buffer.
      (map-do (lambda (header value)
                (insert (format "%s: %s\n" header value)))
              headers)
      (insert "\n\n")
      (insert body)
      (while (search-forward (string ?\C-m) nil t)
        ;; Strip CRLF from headers so that `eww-parse-headers' works correctly.
        ;; MAYBE: As an alternative, look at buffer coding systems to
        ;; make `eww-parse-headers' work with CRLFs (since according
        ;; to the HTTP 1 spec, headers are supposed to end with CRLF)
        (replace-match ""))
      (current-buffer))))

(puthash "hyper" '(name "hyper" loader h/url-loader
                        ;; Expand relative paths against host
                        expand-file-name url-default-expander)
         url-scheme-registry)

(require 'eww)
(setf eww-use-browse-url
      (if eww-use-browse-url
          (rx-to-string `(or ,eww-use-browse-url (seq bos "hyper://")))
        (rx bos "hyper://")))

;;;; `kill-buffer-query-functions' integration

(defun h//kill-buffer-possibly-save (buffer)
  "Ask whether to kill modified hyperdrive file BUFFER."
  ;; Mostly copied from `kill-buffer--possibly-save'.
  (cl-assert (and h/mode h/current-entry))
  (let ((response
         (cadr (compat-call
                read-multiple-choice
                (format "Hyperdrive file %s modified; kill anyway?"
                        (h//format-entry h/current-entry))
                '((?y "yes" "kill buffer without saving")
                  (?n "no" "exit without doing anything")
                  (?s "save and then kill" "save the buffer and then kill it"))
                nil nil (and (not use-short-answers)
                             (not (and (fboundp 'use-dialog-box-p)
                                       (with-no-warnings
                                         (use-dialog-box-p)))))))))
    (if (equal response "no")
        nil
      (unless (equal response "yes")
        (with-current-buffer buffer
          (save-buffer)))
      t)))

(defun h/kill-buffer-query-function ()
  "Ask before killing an unsaved hyperdrive file buffer."
  (if (and h/mode
           h/current-entry
           (not (derived-mode-p 'eww-mode))
           (not (h//entry-directory-p h/current-entry))
           (buffer-modified-p))
      (h//kill-buffer-possibly-save (current-buffer))
    t))

(cl-pushnew #'h/kill-buffer-query-function kill-buffer-query-functions)

;;;;; `easy-menu' integration

(defvar h/menu-bar-menu
  '(("Gateway"
     ["Start Gateway" h/start
      :help "Start the gateway"
      :visible (not (or (h/gateway-live-p) (h//gateway-ready-p)))]
     ["Restart Gateway" h/restart
      :help "Restart the gateway"
      :visible (or (h/gateway-live-p) (h//gateway-ready-p))]
     ["Stop Gateway" h/stop
      :help "Stop the gateway"
      :active (or (h/gateway-live-p) (h//gateway-ready-p))]
     ["Gateway Version" h/gateway-version
      :help "Say gateway version"
      :active (h//gateway-ready-p)]
     ["Install Gateway" h/install
      :label
      (if (h/gateway-needs-upgrade-p) "Upgrade Gateway" "Install Gateway")
      :visible (and (not (h/gateway-installing-p))
                    (or (not (h/gateway-installed-p))
                        (h/gateway-needs-upgrade-p)))
      :help "Download and install gateway"]
     ["Cancel Install" h/cancel-install
      :visible (hyperdrive-gateway-installing-p)
      :help "Cancel running download/installation"])
    "---"
    ["Open URL" h/open-url
     :help "Load a hyperdrive URL"]
    ["New Drive" h/new
     :help "Create a new hyperdrive"]
    ("Drives"
     :active (< 0 (hash-table-count h/hyperdrives))
     :label (if (zerop (hash-table-count h/hyperdrives))
                "Drives (empty)"
              "Drives")
     :filter
     (lambda (_)
       (cl-labels
           ((list-drives (drives)
              (cl-loop
               for drive in drives
               for entry = (he/create :hyperdrive drive)
               collect
               (list
                (h//format drive)
                (vector "Describe"
                        `(lambda ()
                           (interactive)
                           (let ((h/current-entry ,entry))
                             (call-interactively #'h/describe-hyperdrive)))
                        :help "Display information about hyperdrive")
                (vector "Find File"
                        `(lambda ()
                           (interactive)
                           (h/open (h/read-entry
                                    ,drive :read-version current-prefix-arg)))
                        :help "Find a file in hyperdrive")
                (vector "View File"
                        `(lambda ()
                           (interactive)
                           (h/view-file
                            (h/read-entry ,drive
                                          :read-version current-prefix-arg)))
                        :help "View a file in hyperdrive")
                "---"
                (vector
                 "Upload File"
                 `(lambda ()
                    (interactive)
                    (let* ((filename (read-file-name "Upload file: "))
                           (entry
                            (h/read-entry
                             ,drive
                             :default-path (file-name-nondirectory filename)
                             :latest-version t)))
                      (h/upload-file filename entry)))
                 :active `(h/writablep ,drive)
                 :help "Upload a file to hyperdrive")
                (vector "Upload Files"
                        `(lambda ()
                           (interactive)
                           (let* ((files (h/read-files))
                                  (target-dir
                                   (h/read-path
                                    :hyperdrive ,drive
                                    :prompt "Target directory in `%s'"
                                    :default "/")))
                             (h/upload-files files ,drive target-dir)))
                        :active `(h/writablep ,drive)
                        :help "Upload files to hyperdrive")
                (vector "Mirror" #'h/mirror
                        ;; TODO: `h/mirror''s interactive form will also prompt
                        ;; for a drive.  After changing `h/mirror' to use
                        ;; Transient.el, we should pass in the default drive
                        ;; argument.
                        :active `(h/writablep ,drive)
                        :help "Mirror a directory to hyperdrive")
                "---"
                (vector "Petname"
                        ;; HACK: We have to unquote the value of the entry
                        ;; because it seems that the filter function is called
                        ;; in an environment that doesn't use
                        ;; lexical-binding...?
                        ;; TODO: Ask about this and/or file a bug report.
                        `(lambda ()
                           (interactive)
                           (let ((h/current-entry ,entry))
                             (call-interactively #'h/set-petname)))
                        :help "Set petname for hyperdrive"
                        :label
                        (format-message "Set Petname: `%s'"
                                        (pcase (h/petname drive)
                                          (`nil "none")
                                          (it it))))
                (vector
                 "Nickname"
                 `(lambda ()
                    (interactive)
                    (let ((h/current-entry ,entry))
                      (call-interactively #'h/set-nickname)))
                 :help "Set nickname for hyperdrive"
                 :active (h/writablep drive)
                 :label
                 (format-message "Set Nickname: `%s'"
                                 (pcase (alist-get 'name (h/metadata drive))
                                   (`nil "none")
                                   (it it))))
                (vector "Mark as Safe"
                        `(lambda ()
                           (interactive)
                           (let ((h/current-entry ,entry))
                             (call-interactively #'h/mark-as-safe)))
                        :help "Mark hyperdrive as safe or not"
                        :label
                        (format-message "Mark as Safe: `%s'"
                                        (h/safe-string drive)))
                "---"
                (vector "Purge"
                        `(lambda ()
                           (interactive)
                           (let ((h/current-entry ,entry))
                             (call-interactively #'h/purge)))
                        :help "Purge all local data about hyperdrive")))))
         (append (list ["Writable" :active nil])
                 (or (list-drives
                      (sort (cl-remove-if-not #'h/writablep
                                              (hash-table-values h/hyperdrives))
                            (lambda (a b)
                              (string< (h//format a)
                                       (h//format b)))))
                     (list ["none" :active nil]))
                 (list "---")
                 (list ["Read-only" :active nil])
                 (or (list-drives
                      (sort (cl-remove-if #'h/writablep
                                          (hash-table-values h/hyperdrives))
                            (lambda (a b)
                              (string< (h//format a)
                                       (h//format b)))))
                     (list ["none" :active nil]))))))
    ("Current"
     :active h/current-entry
     :label (if-let* ((entry h/current-entry))
                (format-message "Current: `%s'"
                                (h//format-entry entry))
              "Current")
     ("Current Drive"
      :active h/current-entry
      :label (if-let* ((entry h/current-entry)
                       (hyperdrive (he/hyperdrive entry)))
                 (format-message "Current Drive `%s'" (h//format hyperdrive))
               "Current Drive")
      ["Find File"
       (lambda ()
         (interactive)
         (h/open (h/read-entry (h//context-hyperdrive)
                               :read-version current-prefix-arg)))
       :help "Find a file in hyperdrive"]
      ["View File"
       (lambda ()
         (interactive)
         (h/view-file (h/read-entry (h//context-hyperdrive)
                                    :read-version current-prefix-arg)))
       :help "View a file in hyperdrive"]
      "---"
      ["Upload File"
       (lambda ()
         (interactive)
         (let* ((filename (read-file-name "Upload file: "))
                (entry (h/read-entry
                        (h//context-hyperdrive)
                        :default-path (file-name-nondirectory filename)
                        :latest-version t)))
           (h/upload-file filename entry)))
       :active (h/writablep (he/hyperdrive h/current-entry))
       :help "Upload a file to hyperdrive"]
      ["Upload Files"
       (lambda ()
         (interactive)
         (let* ((files (h/read-files))
                (drive (he/hyperdrive h/current-entry))
                (target-dir (h/read-path
                             :hyperdrive drive
                             :prompt "Target directory in `%s'"
                             :default "/")))
           (h/upload-files files drive target-dir)))
       :active (h/writablep (he/hyperdrive h/current-entry))
       :help "Upload files to hyperdrive"]
      ["Mirror" h/mirror
       :active (h/writablep (he/hyperdrive h/current-entry))
       :help "Mirror a directory to hyperdrive"]
      "---"
      ["Petname"
       ;; TODO: Remove this and following workarounds for [INSERT-BUG-HERE] when
       ;; fixed.  This workaround prevents keybindings from displaying in the
       ;; menu bar.
       (lambda ()
         (interactive)
         (call-interactively #'h/set-petname))
       :help "Set petname for hyperdrive"
       :label
       (format-message "Set petname: `%s'"
                       (pcase (h/petname (he/hyperdrive h/current-entry))
                         (`nil "none")
                         (it it)))]
      ["Nickname" (lambda ()
                    (interactive)
                    (call-interactively #'h/set-nickname))
       :help "Set nickname for hyperdrive"
       :active (h/writablep (he/hyperdrive h/current-entry))
       :label
       (format-message "Set nickname: `%s'"
                       (pcase (alist-get 'name
                                         (h/metadata
                                          (he/hyperdrive
                                           h/current-entry)))
                         (`nil "none")
                         (it it)))]
      "---"
      ["Describe" (lambda ()
                    (interactive)
                    (call-interactively #'h/describe-hyperdrive))
       :help "Display information about hyperdrive"]
      ["Purge" (lambda ()
                 (interactive)
                 (call-interactively #'h/purge))
       :help "Purge all local data about hyperdrive"])
     ("Current File/Directory"
      :label (format-message "Current %s: `%s'"
                             (if (h//entry-directory-p h/current-entry)
                                 "Directory"
                               "File")
                             (h//format-path (he/path
                                              h/current-entry)))
      ["Refresh" (lambda ()
                   (interactive)
                   (call-interactively #'revert-buffer))
       :help "Revert current hyperdrive file/directory"]
      ["Up to Parent" (lambda ()
                        (interactive)
                        (call-interactively #'h/up))
       :active (h/parent h/current-entry)
       :help "Open parent directory"]
      ("Sort Directory"
       :visible (eq major-mode 'h/dir-mode)
       ["By Name" (lambda ()
                    (interactive)
                    (h/dir-sort
                     (h/dir-toggle-sort-direction
                      'name h/directory-sort)))
        :suffix (pcase-let ((`(,column . ,direction) h/directory-sort))
                  (and (eq 'name column)
                       (format " (%s)" (if (eq 'ascending direction) "v" "^"))))
        :help "Sort directory by name"]
       ["By Size" (lambda ()
                    (interactive)
                    (h/dir-sort
                     (h/dir-toggle-sort-direction
                      'size h/directory-sort)))
        :suffix (pcase-let ((`(,column . ,direction) h/directory-sort))
                  (and (string= 'size column)
                       (format " (%s)" (if (eq 'ascending direction) "v" "^"))))
        :help "Sort directory by size"]
       ["By Last Modified Time" (lambda ()
                                  (interactive)
                                  (h/dir-sort
                                   (h/dir-toggle-sort-direction
                                    'mtime h/directory-sort)))
        :suffix (pcase-let ((`(,column . ,direction) h/directory-sort))
                  (and (string= 'mtime column)
                       (format " (%s)" (if (eq 'ascending direction) "v" "^"))))
        :help "Sort directory by last modified time"])
      ;; TODO: Add command to download whole directories
      ["Download" (lambda ()
                    (interactive)
                    (call-interactively #'h/download))
       :visible (not (eq major-mode 'h/dir-mode))
       :help "Download current file"]
      ["Copy URL" (lambda ()
                    (interactive)
                    (call-interactively #'h/copy-url))
       :help "Copy URL of current file/directory"]
      ["Delete" (lambda ()
                  (interactive)
                  (call-interactively #'h/delete))
       :visible (not (eq major-mode 'h/dir-mode))
       :active (pcase-let (((cl-struct hyperdrive-entry hyperdrive version)
                            h/current-entry))
                 (and (not version) (h/writablep hyperdrive)))
       :help "Delete current file"])
     ("Selected"
      :label (let ((entry-at-point (h/dir--entry-at-point 'no-error)))
               (format-message "Selected %s: `%s'"
                               (if (h//entry-directory-p entry-at-point)
                                   "Directory"
                                 "File")
                               (he/name entry-at-point)))
      :visible (and (eq major-mode 'h/dir-mode)
                    (h/dir--entry-at-point 'no-error))
      ["Open" (lambda ()
                (interactive)
                (call-interactively #'h/dir-find-file))
       :help "Open file/directory at point"]
      ["View" (lambda ()
                (interactive)
                (call-interactively #'h/dir-view-file))
       :active (and-let* ((entry-at-point (h/dir--entry-at-point 'no-error)))
                 (not (h//entry-directory-p entry-at-point)))
       :help "View file at point"]
      ["Download" (lambda ()
                    (interactive)
                    (call-interactively #'h/download))
       :active (and-let* ((entry-at-point (h/dir--entry-at-point 'no-error)))
                 (not (h//entry-directory-p entry-at-point)))
       ;; TODO: Change to "file/directory" when it's possible to download a
       ;; whole directory
       :help "Download file at point"]
      ["Copy URL" (lambda ()
                    (interactive)
                    (call-interactively #'h/dir-copy-url))
       :help "Copy URL of file/directory at point"]
      ["Delete" (lambda ()
                  (interactive)
                  (call-interactively #'h/delete))
       :active
       (let ((selected-entry (h/dir--entry-at-point 'no-error)))
         (and (h/writablep
               (he/hyperdrive h/current-entry))
              (not (eq selected-entry h/current-entry))
              ;; TODO: Add `hyperdrive--parent-entry-p'
              (not (string= ".."  (alist-get 'display-name
                                             (he/etc selected-entry))))))
       :help "Delete file/directory at point"]
      ["Forget file" (lambda ()
                       (interactive)
                       (call-interactively #'h/forget-file))
       :help "Delete local copy of file/directory contents at point"]
      )
     ("Version"
      :label
      (let ((version (he/version h/current-entry))
            (directoryp (hyperdrive--entry-directory-p h/current-entry)))
        (format
         "Version (%s)"
         (cond (directoryp (or version "latest"))
               ((not (map-elt (he/etc h/current-entry) 'existsp)) "nonexistent")
               (version version)
               (t "latest"))))
      ["Previous Version" (lambda ()
                            (interactive)
                            (call-interactively #'h/open-previous-version))
       :active (map-elt (he/etc h/current-entry) 'previous-version-exists-p)
       :label
       (format
        "Previous (%s)"
        (pcase-exhaustive (map-elt (he/etc h/current-entry) 'previous-version-exists-p)
          ('t (map-elt (he/etc h/current-entry) 'previous-version-number))
          ('nil "nonexistent")
          ('unknown "unknown")))
       :help "Open previous version"]
      ["Next Version" (lambda ()
                        (interactive)
                        (call-interactively #'h/open-next-version))
       :active (and (he/version h/current-entry)
                    (map-elt (he/etc h/current-entry) 'next-version-exists-p))
       :label
       (format
        "Next (%s)"
        (pcase-exhaustive (map-elt (he/etc h/current-entry) 'next-version-exists-p)
          ((guard (not (he/version h/current-entry))) "latest")
          ('t (pcase-exhaustive
                  (map-elt (he/etc h/current-entry) 'next-version-number)

                ('nil "latest")
                ((and (pred numberp) version) (format  "%d" version))))
          ('nil "nonexistent")
          ('unknown "unknown")))
       :help "Open next version"]
      ["Open Specific Version" (lambda ()
                                 (interactive)
                                 (call-interactively #'h/open-at-version))
       :help "Open specific version"]
      ["Version History" (lambda ()
                           (interactive)
                           (call-interactively #'h/history))
       :help "Open version history"]))
    "---"
    ("Bookmark"
     ["Bookmark Jump" h/bookmark-jump
      :help "Jump to hyperdrive bookmark"]
     ["Bookmark List" h/bookmark-list
      :help "List hyperdrive bookmarks"]
     ["Bookmark Set" bookmark-set
      :active h/current-entry
      :help "Create a new hyperdrive bookmark"])
    "---"
    ["Customize" h/customize
     :help "Customize hyperdrive options"]
    ["User Manual" h/info-manual
     :help "Open hyperdrive.el info manual"]))

;;;###autoload
(define-minor-mode hyperdrive-menu-bar-mode "Show \"Hyperdrive\" menu bar."
  :global t :group 'hyperdrive
  (if h/menu-bar-mode
      ;; Inspired by https://utcc.utoronto.ca/~cks/space/blog/programming/EmacsEasyMenuAndMenubarOrder
      (define-key-after global-map [menu-bar hyperdrive]
        (easy-menu-binding
         (easy-menu-create-menu "Hyperdrive" h/menu-bar-menu) "Hyperdrive")
        "Tools")
    (define-key global-map [menu-bar hyperdrive] nil)))

;;;;; Miscellaneous commands

;;;###autoload
(defun hyperdrive-customize ()
  "Customize Hyperdrive options."
  (interactive)
  (customize-group 'hyperdrive))

;;;###autoload
(defun hyperdrive-info-manual ()
  "Open Hyperdrive info manual."
  (interactive)
  (info "(hyperdrive) Top"))

;;;;; Markdown link support

(defun h//markdown-follow-link (url)
  "Follow URL.
For use in `markdown-follow-link-functions'."
  (pcase (url-type (url-generic-parse-url url))
    ((and `nil (guard (and h/mode h/current-entry)))
     (h/open (h//markdown-url-entry url))
     t)
    (_ nil)))

(defun h//markdown-url-entry (url)
  "Return hyperdrive entry for URL in `markdown-mode' buffer.
Intended for relative (i.e. non-full) URLs."
  (pcase-let (((cl-struct url filename) (url-generic-parse-url url))
              ((cl-struct hyperdrive-entry hyperdrive path)
               h/current-entry))
    ;; NOTE: Depending on the resolution of
    ;; <https://github.com/jrblevin/markdown-mode/issues/805>, we may
    ;; want to URL-decode paths.  For now, we won't.
    (he/create
     :hyperdrive hyperdrive
     :path (expand-file-name filename (file-name-directory path))
     ;; FIXME: Target.
     ;; :etc `((target . ,FOO))
     )))

;;;###autoload
(with-eval-after-load 'markdown-mode
  (when (boundp 'markdown-follow-link-functions)
    (cl-pushnew #'hyperdrive--markdown-follow-link markdown-follow-link-functions)))

;;;;; `find-file-at-point' (`ffap') support

(eval-when-compile (require 'ffap))

(with-eval-after-load 'ffap
  (setf ffap-url-regexp
        (if ffap-url-regexp
            (rx-to-string `(or (regexp ,ffap-url-regexp) (seq bos "hyper://")))
          (rx bos "hyper://"))))

;;;;; Embark integration

(defvar embark-general-map)
(defvar embark-keymap-alist)

(declare-function h/menu-hyperdrive "hyperdrive-menu" nil t)
(declare-function h/describe-hyperdrive "hyperdrive-describe")

(with-eval-after-load 'embark
  (defvar-keymap h/embark-hyperdrive-map
    :doc "Keymap for Embark actions on hyperdrives."
    :parent embark-general-map
    "h" #'h/menu-hyperdrive
    "p" #'h/set-petname
    "n" #'h/set-nickname
    "d" #'h/describe-hyperdrive)

  (add-to-list 'embark-keymap-alist '(hyperdrive . h/embark-hyperdrive-map)))

;;;;; Installation

(defvar h/gateway-urls-and-hashes
  '((gnu/linux
     ( :url "https://codeberg.org/USHIN/hyper-gateway-ushin/releases/download/v3.14.0/hyper-gateway-ushin-linux"
       :sha256 "3beff6b797f494e17e3d986761ff20ba15493fddba95a56d87a1e96930ab4ac8")
     ( :url "https://git.sr.ht/~ushin/hyper-gateway-ushin/refs/download/v3.14.0/hyper-gateway-ushin-linux-v3.14.0"
       :sha256 "98aa12950e4de59bf900a76f9b6f1d8a62c3d195929ff4b58dd1cf11c59b193b"))
    (darwin
     ( :url "https://codeberg.org/USHIN/hyper-gateway-ushin/releases/download/v3.14.0/hyper-gateway-ushin-macos"
       :sha256 "0fdbe165f6f46263274bb5bd005260474389b2bbce5f9d0ecaed287c592ffec7")
     ( :url "https://git.sr.ht/~ushin/hyper-gateway-ushin/refs/download/v3.14.0/hyper-gateway-ushin-macos-v3.14.0"
       :sha256 "1527c5b06a11a3fd1e89c70b0413fdb0a2d904ab71a2bb4ce125208a05de0017"))
    (windows-nt
     ( :url "https://codeberg.org/USHIN/hyper-gateway-ushin/releases/download/v3.14.0/hyper-gateway-ushin-windows.exe"
       :sha256 "6e6fa89b62f1d39056213b09f68fe7a4fb950ad1af53a7cbafa54cfc7fa5d953")
     ( :url "https://git.sr.ht/~ushin/hyper-gateway-ushin/refs/download/v3.14.0/hyper-gateway-ushin-windows-v3.14.0.exe"
       :sha256 "acaef5bb571b1a77e8cc648a06b1719cdc490c498f779c07bee60992a6926ef0")))
  "Alist mapping `system-type' to URLs where the gateway can be downloaded.")

;;;###autoload
(defun hyperdrive-install (&optional forcep)
  "Download and install the gateway.
If FORCEP, don't prompt for confirmation before downloading."
  (interactive (list current-prefix-arg))
  (when (h/gateway-installing-p)
    (h/user-error "Installation of gateway already in progress"))
  (unless forcep
    (when (h/gateway-installed-p)
      (unless (yes-or-no-p "Download and reinstall/upgrade the gateway? ")
        (h/user-error "Not downloading; aborted"))))
  (let ((urls-and-hashes (alist-get system-type h/gateway-urls-and-hashes))
        (destination (expand-file-name h/gateway-program h/gateway-directory))
        monitor-buffer size)
    (cl-labels
        ((try ()
           (unless urls-and-hashes
             (setf h/install-process nil)
             (h/menu-refresh)
             (h/error "Downloading failed; no more mirrors available"))
           (pcase-let (((map :url :sha256) (pop urls-and-hashes)))
             (when (or size (ensure-size url))
               (if (or forcep (yes-or-no-p
                               (format "Download and install gateway (%s)? "
                                       (file-size-human-readable size))))
                   (progn
                     (setf forcep t) ;; Don't prompt again.
                     (download url sha256))
                 (h/message "Installation canceled.")))))
         (ensure-size (url)
           (let ((host (url-host (url-generic-parse-url url))))
             (h/message "Checking server %S..." host)
             (condition-case _
                 (pcase-let (((cl-struct plz-response
                                         (headers (map content-length)))
                              (plz 'head url :as 'response :connect-timeout 5)))
                   (setf size (cl-parse-integer content-length)))
               ;; Likely missing `curl' executable: Signal error.
               (file-missing (h/error "Please install `curl' program"))
               ;; Any other error: Try next URL.
               (t (h/message "%S unresponsive.  Trying next server..." host)
                  (try)
                  nil))))
         (download (url sha256)
           (let* ((temp-file (make-temp-name
                              (expand-file-name "hyperdrive-gateway-"
                                                temporary-file-directory)))
                  (preamble (format "Downloading gateway from:\n\nURL: %s\nTo: %s\n"
                                    url destination))
                  (postamble
                   (concat
                    (buttonize "Cancel installation"
                               (lambda (_) (hyperdrive-cancel-install)))
                    ;; Prevent button from going to end of the visual line.
                    " ")))
             (setf monitor-buffer (h//download-monitor
                                   :preamble preamble
                                   :postamble postamble
                                   :buffer-name "*hyperdrive-install*"
                                   :path temp-file
                                   :total-size size)
                   h/install-process
                   (plz 'get url :as `(file ,temp-file) :timeout nil
                     :then (lambda (filename)
                             (check filename sha256 url))
                     :else (lambda (plz-error)
                             (pcase (plz-error-curl-error plz-error)
                               (`(2 . ,_)
                                ;; "Failed to initialize", likely due to
                                ;; `interrupt-process' in `h/cancel-install'.
                                (h/message "Canceled install"))
                               (_   ; Otherwise, display error and try next URL.
                                (h/message "Trying next source because downloading from URL %S failed: %S"
                                           url plz-error)
                                (try)))
                             (when (file-exists-p temp-file)
                               (delete-file temp-file))
                             (h//download-monitor-close monitor-buffer))))
             (pop-to-buffer monitor-buffer)
             (h/message "Downloading %s from %S to %S"
                        (file-size-human-readable size) url destination)))
         (check (file-name sha256 url)
           (if (with-temp-buffer
                 (insert-file-contents-literally file-name)
                 (equal sha256 (secure-hash 'sha256 (current-buffer))))
               ;; Hash matches: finish installation.
               (then file-name)
             ;; Hash doesn't match: delete file and try next source.
             (delete-file file-name)
             (h/message "Trying next source because hash comparison failed from URL: %s"
                        url)
             (try)))
         (then (file-name)
           (when (file-exists-p destination)
             (move-file-to-trash destination))
           (unless (file-directory-p h/gateway-directory)
             (mkdir h/gateway-directory t))
           (rename-file file-name destination)
           (chmod destination #o755)
           (setf h/install-process nil)
           (h/menu-refresh)
           (insert-restart-button monitor-buffer)
           (h/message "Gateway installed.  Try \\[%s]"
                      (if (h//gateway-ready-p)
                          "hyperdrive-restart"
                        "hyperdrive-start")))
         (insert-restart-button (buffer)
           (with-current-buffer buffer
             (with-silent-modifications
               (when (timerp (map-elt h/download-monitor-etc :timer))
                 (cancel-timer (map-elt h/download-monitor-etc :timer)))
               (erase-buffer)
               (insert "Gateway installed!\n\n"
                       (if (h//gateway-ready-p)
                           (buttonize "Restart the gateway"
                                      (lambda (_) (h/restart)))
                         (buttonize "Start the gateway"
                                    (lambda (_) (h/start))))
                       "\n\n"
                       (buttonize "View hyperdrive user info manual"
                                  (lambda (_) (info "Hyperdrive")))
                       ;; Prevent button from going to end of the visual line.
                       " ")))))
      (try))))

(defun h/cancel-install ()
  "Stop downloading/installing the gateway."
  (interactive)
  (unless (h/gateway-installing-p)
    (h/user-error "No installation in progress"))
  (h/message "Cancelling install")
  (interrupt-process h/install-process)
  (setf h/install-process nil))

;; (defun h//gateway-appears-valid-p ()
;;   "Return non-nil if a local installation of the gateway appears valid.
;; That is, if an executable file exists at the expected location
;; with an expected hash."
;;   (when-let ((file-name (h//gateway-path)))
;;     (let* ((file-hash (with-temp-buffer
;;                          (insert-file-contents-literally file-name)
;;                          (secure-hash 'sha256 (current-buffer))))
;;            (urls-and-hashes (alist-get system-type h/gateway-urls-and-hashes)))
;;       (cl-loop for pair in urls-and-hashes
;;                for expected-hash = (plist-get pair :sha256)
;;                thereis (equal expected-hash file-hash)))))

;;;; Footer

(provide 'hyperdrive)

;; Local Variables:
;; read-symbol-shorthands: (
;;   ("he//" . "hyperdrive-entry--")
;;   ("he/"  . "hyperdrive-entry-")
;;   ("h//"  . "hyperdrive--")
;;   ("h/"   . "hyperdrive-"))
;; End:
;;; hyperdrive.el ends here
