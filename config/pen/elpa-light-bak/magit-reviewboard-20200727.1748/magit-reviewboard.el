;;; magit-reviewboard.el --- Show open Reviewboard reviews in Magit  -*- lexical-binding: t; -*-

;; Copyright (C) 2019 Jules Tamagnan

;; Author: Jules Tamagnan <jtamagnan@gmail.com>
;; URL: http://github.com/jtamagnan/magit-reviewboard
;; Package-Version: 20200727.1748
;; Package-Commit: aceedff88921f1dfef8a6b2fb18fe316fb7223a8
;; Version: 1.0
;; Package-Requires: ((emacs "25.2") (magit "2.13.0") (s "1.12.0") (request "0.3.0"))
;; Keywords: magit, vc

;;; Commentary:

;; This package displays open ReviewBoard review-requests in a Magit
;; status buffer.

;;; License:

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

;;; Code:

(require 'browse-url)
(require 'cl-lib)

(require 'magit)
(require 'request)
(require 's)

(cl-defstruct magit-reviewboard-item repository ship-it-count status
              last-updated latest-diff branch description summary
              absolute-url latest-diff-url author)

(defgroup magit-reviewboard nil
  "Show reviewboard review items in source code comments in repos' files."
  :group 'magit)

(magit-define-section-jumper magit-jump-to-reviewboard "Reviews" reviewboard)

(defvar magit-reviewboard-section-map
  (let ((map (make-sparse-keymap)))
    (define-key map "jR" #'magit-reviewboard-jump-to-reviewboard)
    (define-key map "jl" #'magit-reviewboard-list)
    (define-key map (kbd "RET") #'magit-reviewboard-list)
    map)
  "Keymap for `magit-review' top level section.")

(defvar magit-reviewboard-item-section-map
  (let ((map (make-sparse-keymap)))
    (define-key map [remap magit-visit-thing] #'magit-reviewboard-jump-to-item)
    map)
  "Keymap for `magit-review' individual review-request item sections.
See https://magit.vc/manual/magit/Creating-Sections.html for more
details about how section maps work.")

(defvar-local magit-reviewboard-active-scan nil
  "The current scan's process.
Used to avoid running multiple simultaneous scans for a
magit-status buffer.")

(defvar-local magit-reviewboard-updating nil
  "Whether items are being updated now.")

(defvar-local magit-reviewboard-last-update-time nil
  "When the items were last updated.
A time value as returned by `current-time'.")

(defvar-local magit-reviewboard-item-cache nil
  "Items found by most recent scan.")

(defcustom magit-reviewboard-api-max-results 50
  "Number of review requests to fetch from Reviewboard."
  :group 'magit-reviewboard
  :type 'integer)

(defcustom magit-reviewboard-max-items-show 10
  "Automatically collapse the section if there are more than this many items."
  :group 'magit-reviewboard
  :type 'integer)

(defcustom magit-reviewboard-sort-order '(magit-reviewboard--sort-by-last-updated)
  "Order in which to sort items."
  :group 'magit-reviewboard
  :type '(repeat (choice (const :tag "Last updated" magit-reviewboard--sort-by-last-updated)
                         (function :tag "Custom function"))))

(defcustom magit-reviewboard-insert-at 'bottom
  "Insert the reviews section after this section in the Magit status buffer.
Specific sections may be chosen, using the first symbol returned
by evaluating \"(magit-section-ident (magit-current-section))\"
in the status buffer with point on the desired section,
e.g. `recent' for the \"Recent commits\" section.  Note that this
may not work exactly as desired when the built-in scanner is
used."
  :group 'magit-reviewboard
  :type '(choice (const :tag "Top" top)
                 (const :tag "Bottom" bottom)
                 (const :tag "After untracked files" untracked)
                 (const :tag "After unstaged files" unstaged)
                 (symbol :tag "After selected section")))

(defcustom magit-reviewboard-update t
  "When or how often to scan for review-requests.
When set to manual updates, the list can be updated with the
command `magit-reviewboard-update'.  When caching is enabled, scan for
items whenever the Magit status buffer is refreshed and at least
N seconds have passed since the last scan; otherwise, use cached
items."
  :group 'magit-reviewboard
  :type '(choice (const :tag "Automatically, when the Magit status buffer is refreshed" t)
                 (integer :tag "Automatically, but cache items for N seconds")
                 (const :tag "Manually" nil)))

(defcustom magit-reviewboard-base-uri ""
  "The base uri for the ReviewBoard api server."
  :group 'magit-reviewboard
  :type 'string)

(defun magit-reviewboard-uri (endpoint)
  "Create the uri to connect to given the api ENDPOINT."
  (concat magit-reviewboard-base-uri endpoint))

;;;###autoload
(defun magit-reviewboard-list (&optional directory)
  "Show review-request list of the current ReviewBoard repository in a buffer.
With prefix, prompt for repository's DIRECTORY."
  (interactive
   (let ((magit--refresh-cache (list (cons 0 0))))
     (list (and (or current-prefix-arg (not (magit-toplevel)))
                (magit-read-repository)))))
  (condition-case nil
      (let ((magit--refresh-cache (list (cons 0 0))))
        (setq directory (if directory
                            (file-name-as-directory (expand-file-name directory))
                          default-directory))
        (magit-reviewboard-list-internal directory))
    ('magit-outside-git-repo (cl-letf (((symbol-function 'magit-toplevel) (lambda (&rest _) default-directory)))
                               (call-interactively #'magit-reviewboard-list)))))

(put 'magit-reviewboard-list 'interactive-only 'magit-reviewboard-list-internal)

(define-derived-mode magit-reviewboard-list-mode magit-status-mode "Magit"
  "Mode for looking at repository review-request list.

\\<magit-reviewboard-mode-map>\
Type \\[magit-refresh] to refresh the list.
Type \\[magit-section-toggle] to expand or hide the section at point.
Type \\[magit-visit-thing] to visit the item at point.
Type \\[magit-diff-show-or-scroll-up] to peek at the item at point."
  :group 'magit-reviewboard)

;;;###autoload
(defun magit-reviewboard-list-internal (directory)
  "Open buffer showing review-request list of repository at DIRECTORY."
  (magit--tramp-asserts directory)
  (let ((default-directory directory))
    (magit-mode-setup #'magit-reviewboard-list-mode)))

(defun magit-reviewboard-list-refresh-buffer ()
  "Refresh the current `magit-reviewboard-list-mode' buffer."
  (let ((magit-reviewboard-api-max-results 400)
        (magit-reviewboard-max-items-show 400)) ;; We never want the section to be collapsed in this view
    (magit-section-show (magit-insert-section (type magit-root-section)
                          (magit-insert-status-headers)
                          (magit-reviewboard--insert-reviews)))))

(defun magit-reviewboard--delete-section (condition)
  "Delete the section specified by CONDITION from the Magit status buffer.
See `magit-section-match'.  Also delete it from root section's children."
  (save-excursion
    (goto-char (point-min))
    (when-let ((section (cl-loop until (magit-section-match condition)
                                 ;; Use `forward-line' instead of `magit-section-forward' because
                                 ;; sometimes it skips our section.
                                 do (forward-line 1)
                                 when (eobp)
                                 return nil
                                 finally return (magit-current-section))))
      ;; Delete the section from root section's children.  This makes the section-jumper command
      ;; work when a replacement section is inserted after deleting this section.
      (object-remove-from-list magit-root-section 'children section)
      (with-slots (start end) section
        ;; NOTE: We delete 1 past the end because we insert a newline after the section.  I'm not
        ;; sure if this would generalize to all Magit sections.
        (delete-region start (1+ end))))))

(defun magit-reviewboard-jump-to-item ()
  "Show current item in browser."
  (interactive)
  (let* ((item (oref (magit-current-section) value))
         (browse-url-firefox-new-window-is-tab nil))
    (browse-url (magit-reviewboard-item-absolute-url item))))

(defun magit-reviewboard--format-plain (item)
  "Format a review-request ITEM to be displayed in the status buffer."
  (format "%s %20s %15s %s"
          (magit-reviewboard-item-ship-it-count item)
          (propertize (s-truncate 20 (magit-reviewboard-item-author item)) 'face 'magit-log-author)
          (propertize (s-truncate 15 (magit-reviewboard-item-branch item)) 'face 'magit-branch-remote)
          (magit-reviewboard-item-summary item)))

(defun magit-reviewboard-jump-to-reviewboard ()
  "Jump to Reviews section, and update it if empty."
  (interactive)
  (let ((already-in-section-p (magit-section-match [* reviewboard])))
    (magit-jump-to-reviewboard)
    (when (and (or (integerp magit-reviewboard-update)
                   (not magit-reviewboard-update))
               (or already-in-section-p
                   (= 0 (length (oref (magit-current-section) children)))))
      (magit-reviewboard-update))))

(cl-defun magit-reviewboard-scan-reviews (&key magit-status-buffer)
  "Scan for review-requests with magit-reviewboard-scan-reviews and insert the contents into MAGIT-STATUS-BUFFER.
MAGIT-STATUS-BUFFER is what it says.  DIRECTORY is the directory in which to run the scan."
  (when (magit-get-remote)
    (let* ((upstream-url (magit-get nil (format "remote.%s.url" (substring-no-properties (magit-get-remote)))))
           (proc (request
                  (magit-reviewboard-uri "/repositories/")
                  :type "GET"
                  :params '(("max-results" . "200"))
                  :parser 'json-read
                  :headers '(("Content-Type" . "application/json"))))
           (_done (while (not (request-response-done-p proc)) (sleep-for .1)))
           (data (request-response-data proc))
           (repos (assoc-default 'repositories data))
           (repo-id (cl-loop for repo across repos
                             when (cl-search (assoc-default 'path repo) upstream-url)
                             return (assoc-default 'id repo)))
           (magit-status-buffer magit-status-buffer))
      (if repo-id (request
       (magit-reviewboard-uri "/review-requests/")
       :type "GET"
       :parser 'json-read
       :params `(("max-results" . ,(number-to-string magit-reviewboard-api-max-results))
                 ("repository" . ,repo-id))
       :headers '(("Content-Type" . "application/json"))
       :success (cl-function
                 (lambda (&key data &allow-other-keys)
                   (message "Scanning now...")
                   (let ((items
                          (cl-loop for review across (assoc-default 'review_requests data)
                                   collect (make-magit-reviewboard-item
                                            :author (assoc-default 'title (assoc-default 'submitter (assoc-default 'links review)))
                                            :repository (assoc-default 'title (assoc-default 'repository (assoc-default 'links review)))
                                            :ship-it-count (assoc-default 'ship_it_count review)
                                            :status (assoc-default 'status review)
                                            :last-updated (assoc-default 'last_updated review)
                                            :branch (assoc-default 'branch review)
                                            :description  (assoc-default 'description review)
                                            :summary (assoc-default 'summary review)
                                            :absolute-url (assoc-default 'absolute_url review)
                                            :latest-diff-url (assoc-default 'href (assoc-default 'latest_diff (assoc-default 'links review)))))))
                     (message "Done scanning")
                     (message "Inserting now...")
                     (magit-reviewboard--insert-items magit-status-buffer items)
                     (message "Done inserting"))))
       :error
       (cl-function (lambda (&rest args &key error-thrown &allow-other-keys)
                      (message "Got error: %S" error-thrown))))
        (message "No related reviewboard repository: %s not in %s"
                 upstream-url
                 (cl-loop for repo across repos
                          collect (assoc-default 'path repo)))
        proc))))

(defun magit-reviewboard-item-basecommit-id (item)
  "Return the git hash of the ITEM's parent."
  (let* ((href (magit-reviewboard-item-latest-diff-url item))
         (proc (request
                href
                :type "GET"
                :parser 'json-read
                :headers '(("Content-Type" . "application/json"))))
         (_done (while (not (request-response-done-p proc)) (sleep-for .01)))
         (data (request-response-data proc))
         (diff (assq 'diff data))
         (base-commit-id (assoc-default 'base_commit_id diff)))
    base-commit-id))

(defun magit-reviewboard--insert-reviews ()
  "Insert review-request items into current buffer.
This function should be called from inside a ‘magit-status’ buffer."
  (declare (indent defun))
  (when magit-reviewboard-active-scan
    ;; Avoid running multiple scans for a single magit-status buffer.
    (unless (request-response-done-p magit-reviewboard-active-scan)
      (message "Aborting current scan...")
      (request-abort magit-reviewboard-active-scan))
    (setq magit-reviewboard-active-scan nil))
  (pcase magit-reviewboard-update
    ((or 't  ; Automatic
         ;; Manual and updating now
         (and 'nil (guard magit-reviewboard-updating))
         ;; Caching and cache expired
         (and (pred integerp) (guard (or magit-reviewboard-updating  ; Forced update
                                         (>= (float-time
                                              (time-subtract (current-time)
                                                             magit-reviewboard-last-update-time))
                                             magit-reviewboard-update)
                                         (null magit-reviewboard-last-update-time)))))
     ;; Scan and insert.
     ;; HACK: I don't like setting a special var here, because it seems like lexically binding a
     ;; special var should follow down the chain, but it isn't working, so we'll do this.
     (setq magit-reviewboard-updating t)
     (setq magit-reviewboard-active-scan (funcall #'magit-reviewboard-scan-reviews
                                             :magit-status-buffer (current-buffer))))
    (_   ; Caching and cache not expired, or not automatic and not manually updating now
     (magit-reviewboard--insert-items (current-buffer) magit-reviewboard-item-cache))))

(defun magit-reviewboard--sort (items)
  "Return ITEMS sorted according to `magit-reviewboard-sort-order'."
  (dolist (fn (reverse magit-reviewboard-sort-order) items)
    (setq items (sort items fn))))

(defun magit-reviewboard--sort-by-last-updated (a b)
  "Return non-nil if A's last-updated is `string>' B's."
  (string> (magit-reviewboard-item-last-updated a)
           (magit-reviewboard-item-last-updated b)))

(defun magit-reviewboard--skip-section (condition)
  "Move past the section matching CONDITION.
See `magit-section-match'."
  (goto-char (point-min))
  (cl-loop until (magit-section-match condition)
           do (magit-section-forward))
  (cl-loop until (not (magit-section-match condition))
           do (condition-case nil
                  ;; `magit-section-forward' raises an error when there are no more sections.
                  (magit-section-forward)
                (error (progn
                         (goto-char (1- (point-max)))
                         (cl-return))))))

(cl-defun magit-reviewboard--set-visibility (&key section num-items)
  "Set the visibility of SECTION.

If the section's visibility is cached by Magit, the cached
setting is applied.  Otherwise, visibility is set according to
whether NUM-ITEMS is greater than `magit-reviewboard-max-items-show'."
  (declare (indent defun))
  (pcase (magit-section-cached-visibility section)
    ('hide (magit-section-hide section))
    ('show (magit-section-show section))
    (_ (if (> num-items magit-reviewboard-max-items-show)
           (magit-section-hide section)
         (magit-section-show section)))))

(defun magit-reviewboard--add-to-status-buffer-kill-hook ()
  "Add `magit-reviewboard--kill-active-scan' to `kill-buffer-hook' locally."
  (add-hook 'kill-buffer-hook #'magit-reviewboard--kill-active-scan 'append 'local))

(defun magit-reviewboard--kill-active-scan ()
  "Kill `magit-reviewboard-active-scan'.
To be called in status buffers' `kill-buffer-hook'."
  (when (and magit-reviewboard-active-scan
             (not (request-response-done-p magit-reviewboard-active-scan)))
    (message "Aborting current scan...")
    (request-abort magit-reviewboard-active-scan)))

(defun magit-reviewboard--insert-items (magit-status-buffer items)
  "Insert review-request ITEMS into MAGIT-STATUS-BUFFER."
  (declare (indent defun))
  ;; NOTE: This could be factored out into some kind of `magit-insert-section-async' macro if necessary.
  (unless (buffer-live-p magit-status-buffer)
    (message "Callback called for deleted buffer"))
  (let* ((items (magit-reviewboard--sort items))
         (num-items (length items))
         (magit-section-show-child-count t)
         ;; HACK: "For internal use only."  But this makes collapsing the new section work!
         (magit-insert-section--parent magit-root-section)
         (inhibit-read-only t))
    (when (buffer-live-p magit-status-buffer)
      ;; Don't try to select a killed status buffer
      (with-current-buffer magit-status-buffer
        (when magit-reviewboard-updating
          (when (or (null magit-reviewboard-update) ; Manual updates
                    (integerp magit-reviewboard-update)) ; Caching
            (setq magit-reviewboard-item-cache items)
            (setq magit-reviewboard-last-update-time (current-time)))
          ;; HACK: I don't like setting this special var, but it works.  See other comment where
          ;; it's set t.
          (setq magit-reviewboard-updating nil))
        (save-excursion
          ;; Insert items
          (goto-char (point-min))
          ;; Go to insertion position
          (pcase magit-reviewboard-insert-at
            ('top (cl-loop for ((this-section . _) . _) = (magit-section-ident (magit-current-section))
                           until (not (member this-section '(branch tags)))
                           do (magit-section-forward)))
            ('bottom (goto-char (point-max)))
            (_ (magit-reviewboard--skip-section (vector '* magit-reviewboard-insert-at))))
          ;; Insert section
          (let ((reminder (if magit-reviewboard-update
                              "" ; Automatic updates: no reminder
                            ;; Manual updates: remind user
                            " (update manually)")))
            (if (not items)
                (unless magit-reviewboard-update
                  ;; Manual updates: Insert section to remind user
                  (let ((magit-insert-section--parent magit-root-section))
                    (magit-insert-section (reviewboard)
                      (magit-insert-heading (concat (propertize "Reviews" 'face 'magit-section-heading)
                                                    " (0)" reminder)))
                    (insert "\n")))
              (let ((section (magit-reviewboard--insert-group
                               :type 'reviewboard
                               :heading (format "%s (%s)%s"
                                                (propertize "Reviews" 'face 'magit-section-heading)
                                                num-items reminder)
                               :items items)))
                (insert "\n")
                (magit-reviewboard--set-visibility :section section :num-items num-items)))))))))

(cl-defun magit-reviewboard--insert-group (&key heading type items)
  "Insert ITEMS into Magit section and return the section.

DEPTH sets indentation and should be 0 for a top-level group.

HEADING is a string which is the group's heading.  The count of
items in each group is automatically appended.

TYPE is a symbol which is used by Magit internally to identify
sections."
  ;; NOTE: `magit-insert-section' seems to bind `magit-section-visibility-cache' to nil, so setting
  ;; visibility within calls to it probably won't work as intended.
  (declare (indent defun))
  (let* ((section (magit-insert-section ((eval type))
                    (magit-insert-heading heading)
                    (dolist (item items)
                      (let* ((string (magit-reviewboard--format-plain item)))
                        (magit-insert-section (reviewboard-item item)
                          (insert string))
                        (insert "\n"))))))
    (magit-reviewboard--set-visibility :num-items (length items) :section section)
    ;; Don't forget to return the section!
    section))

;;;###autoload
(define-minor-mode magit-reviewboard-mode
  "Show list of reviews in Magit status buffer for tracked reviews in repo."
  :require 'magit-review
  :group 'magit-review
  :global t
  (if magit-reviewboard-mode
      (progn
        (if (lookup-key magit-status-mode-map "jR")
            (message "magit-review: Not overriding bind of \"jR\" in `magit-status-mode-map'.")
          (define-key magit-status-mode-map "jR" #'magit-reviewboard-jump-to-reviewboard))
        (magit-add-section-hook 'magit-status-sections-hook
                                #'magit-reviewboard--insert-reviews
                                'magit-insert-staged-changes
                                'append)
        (add-hook 'magit-status-mode-hook #'magit-reviewboard--add-to-status-buffer-kill-hook 'append))
    ;; Disable mode
    (when (equal (lookup-key magit-status-mode-map "jR") #'magit-jump-to-reviewboard)
      (define-key magit-status-mode-map "jR" nil))
    (remove-hook 'magit-status-sections-hook #'magit-reviewboard--insert-reviews)
    (remove-hook 'magit-status-mode-hook #'magit-reviewboard--add-to-status-buffer-kill-hook)))

(defun magit-reviewboard-update ()
  "Update the review-request list manually.
Only necessary when option `magit-reviewboard-update' is nil."
  (interactive)
  (unless magit-reviewboard-mode
    (user-error "Please activate `magit-reviewboard-mode'"))
  (let ((inhibit-read-only t))
    (magit-reviewboard--delete-section [* reviewboard])
    ;; HACK: See other note on `magit-reviewboard-updating'.
    (setq magit-reviewboard-updating t)
    (magit-reviewboard--insert-reviews)))

(provide 'magit-reviewboard)
;;; magit-reviewboard.el ends here
