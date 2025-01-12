;;; notmuch-bookmarks.el --- Add bookmark handling for notmuch buffers  -*- lexical-binding: t; -*-

;; Copyright (C) 2019

;; Author:  Jörg Volbers <joerg@joergvolbers.de>
;; version: 0.2
;; Keywords: mail
;; Package-Requires: ((seq "2.20") (emacs "26.1") (notmuch "0.29.3"))
;; URL: https://github.com/publicimageltd/notmuch-bookmarks

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package adds a global minor mode which allows you to bookmark
;; notmuch buffers via the standard Emacs bookmark functionality. A
;; `notmuch buffer' denotes either a notmuch tree view, a notmuch
;; search view or a notmuch show buffer (message view). With this
;; minor mode active, you can add these buffers to the standard
;; bookmark list and visit them, e.g. by using `bookmark-jump'.
;;
;; To activate the minor mode, add something like the following to
;; your init file:
;;
;; (use-package notmuch-bookmarks
;;   :after notmuch
;;   :config
;;   (notmuch-bookmarks-mode))
;;
;; There is experimental support for providing annotations which count
;; the read and unread mails for the bookmarks. Currently, annotations
;; do only work when the package `marginalia' is installed. Turn on
;; this feature with `notmuch-bookmarks-annotation-mode'.

;;; Code:

(require 'notmuch)
(require 'cl-lib)
(require 'seq)
(require 'bookmark)

(declare-function marginalia-annotate-bookmark "marginalia")
(defvar marginalia-annotator-registry)

;;; Variables:

(defvar notmuch-bookmarks-bmenu-original-keymap nil
  "Internal storage for original keymap of `bookmarks-bmenu'.")

;;; Custom Variables:

(defcustom notmuch-bookmarks-prefix "notmuch: "
  "Prefix to add to new notmuch bookmarks, or nil."
  :type 'string
  :group 'notmuch-bookmarks)

(defcustom notmuch-bookmarks-bmenu-filter-key "N"
  "Key in the bookmarks menu which restricts view to notmuch bookmarks.
If this value is nil, do not implement any key."
  :type 'string
  :group 'notmuch-bookmarks)

;; Unified access to the query across all supported notmuch modes:

(cl-defgeneric notmuch-bookmarks-get-buffer-query (&optional buffer)
  "Return the notmuch query of BUFFER.
If BUFFER is nil, use current buffer instead. To make this
generic method work, add a specialiced method for a major mode."
  (user-error "Not defined for this type of buffer: %s" buffer))

(cl-defmethod notmuch-bookmarks-get-buffer-query (&context (major-mode notmuch-tree-mode) &optional buffer)
;; checkdoc-params: (major-mode)
  "Return the query for notmuch tree mode BUFFER.
Specialized method for `notmuch-tree-mode'."
  (with-current-buffer (or buffer (current-buffer))
    (notmuch-tree-get-query)))

(cl-defmethod notmuch-bookmarks-get-buffer-query (&context (major-mode notmuch-search-mode) &optional buffer)
;; checkdoc-params: (major-mode)
  "Return the query for notmuch search mode BUFFER.
Specialized method for `notmuch-search-mode'."
  (with-current-buffer (or buffer (current-buffer))
    (notmuch-search-get-query)))

(cl-defmethod notmuch-bookmarks-get-buffer-query (&context (major-mode notmuch-show-mode) &optional buffer)
;; checkdoc-params: (major-mode)
  "Return the query for notmuch search mode BUFFER.
Specialized method for `notmuch-show-mode'."
  (with-current-buffer (or buffer (current-buffer))
    (notmuch-show-get-query)))

;;; Create and visit the bookmark

;; Bookmarking a query here means to store the query and the buffer's
;; major mode. Supported major modes are hard wired since extending it
;; requires writing a method with a new major mode as specializing
;; context and extending `notmuch-bookmarks--visit', as well as
;; extending `notmuch-bookmarks--install'.

(defun notmuch-bookmarks-supported-major-mode-p (a-major-mode)
  "Check if A-MAJOR-MODE is supported."
  (seq-contains-p
   '(notmuch-show-mode notmuch-tree-mode notmuch-search-mode)
   a-major-mode))

;; currently used by notmuch-alerts.el
(defsubst notmuch-bookmarks-query (bookmark)
  "Return the BOOKMARK's query."
  (alist-get 'filename (bookmark-get-bookmark-record bookmark)))

(defun notmuch-bookmarks-make-record ()
  "Return a bookmark record for the current notmuch buffer."
  (unless (notmuch-bookmarks-supported-major-mode-p major-mode)
    (user-error "Notmuch bookmarks not supported for this buffer"))
  (let* ((query (notmuch-bookmarks-get-buffer-query))
         (name  (concat notmuch-bookmarks-prefix query)))
    `(,name
      (handler    . ,#'notmuch-bookmarks-jump-handler)
      (filename   . ,query)
      (major-mode . ,major-mode))))

(defun notmuch-bookmarks-record-p (bookmark)
  "Test whether BOOKMARK points to a notmuch query."
  (eq 'notmuch-bookmarks-jump-handler (bookmark-prop-get bookmark 'handler)))

(defun notmuch-bookmarks--visit (query the-major-mode)
  "Visit a notmuch buffer of type THE-MAJOR-MODE and open QUERY."
  (cl-case the-major-mode
    (notmuch-tree-mode   (notmuch-tree query))
    (notmuch-show-mode   (notmuch-show query))
    (notmuch-search-mode (notmuch-search query))
    (t (user-error "No notmuch command associated with %s" the-major-mode))))

(defun notmuch-bookmarks--all-buffers ()
  "Return a list of all live buffers supported."
  (seq-filter (lambda (buf)
                (with-current-buffer buf
                  (notmuch-bookmarks-supported-major-mode-p major-mode)))
              (buffer-list)))

(defun notmuch-bookmarks--get-buffer (query the-major-mode)
  "Return the buffer displaying QUERY in THE-MAJOR-MODE."
  (seq-find (lambda (buf)
              (with-current-buffer buf
                (and
                 (eq major-mode the-major-mode)
                 (string= (notmuch-bookmarks-get-buffer-query)
                          query))))
            (notmuch-bookmarks--all-buffers)))

(defun notmuch-bookmarks-get-buffer-bookmark (&optional buffer)
  "Find bookmark pointing to BUFFER or current buffer.
Throw an error if there is none."
  (with-current-buffer (or buffer (current-buffer))
    (if (notmuch-bookmarks-supported-major-mode-p major-mode)
        (let ((query (notmuch-bookmarks-get-buffer-query)))
          (seq-find (lambda (bmk)
                      (and
                       (eq major-mode (bookmark-prop-get bmk 'major-mode))
                       (string= query (bookmark-prop-get bmk 'filename))))
                    (seq-filter #'notmuch-bookmarks-record-p bookmark-alist)))
      (user-error "Current buffer's major mode is not supported by notmuch bookmarks"))))

;;;###autoload
(defun notmuch-bookmarks-jump-handler (bookmark)
  "Open BOOKMARK or switch to its visiting buffer."
  (let* ((.filename    (bookmark-prop-get bookmark 'filename))
         (.major-mode  (bookmark-prop-get bookmark 'major-mode)))
    ;; do some sanity checks:
    ;; (cl-assert always calls the debugger, so we do it manually:)
    (unless (notmuch-bookmarks-supported-major-mode-p .major-mode)
      (user-error "Notmuch bookmarks does not support major mode %s" .major-mode))
    (unless .filename
      (user-error "No query string in bookmark record"))
    (unless (stringp .filename)
      (user-error "Bookmark query has to be a string"))
    ;;
    (let ((buf (notmuch-bookmarks--get-buffer .filename .major-mode)))
      (if (not buf)
          (notmuch-bookmarks--visit .filename .major-mode)
        (switch-to-buffer buf)
        (message "This buffer might not be up to date; you may want to refresh it")))))

;; Integrate in bookmarks package:

(defun notmuch-bookmarks-sync-updates ()
  "Save bookmarks and sync with `bookmark-bmenu'."
  (setq bookmark-alist-modification-count
        (1+ bookmark-alist-modification-count))
  (if (bookmark-time-to-save-p)
      (bookmark-save))
  (bookmark-bmenu-surreptitiously-rebuild-list))

(defun notmuch-bookmarks-bmenu ()
  "Display bookmark menu only with notmuch bookmarks."
  (interactive)
  (if-let* ((notmuch-bookmarks (seq-filter #'notmuch-bookmarks-record-p bookmark-alist)))
      ;; TODO toggle like a filter
      (let ((bookmark-alist notmuch-bookmarks))
        (if (called-interactively-p 'interactive)
            (call-interactively #'bookmark-bmenu-list)
          (bookmark-bmenu-list)))
    (user-error "No notmuch bookmarks registered")))

;; Completion annotation:

;; NOTE Possible speed optimizations:
;; - query read and unread mails in one call using `notmuch count --batch'

(defun notmuch-bookmarks--count (query &optional no-zero)
  "Get the number of mails matching QUERY.
Optionally return a count of 0 as nil if NO-ZERO is non-nil."
  (let ((count (string-to-number (notmuch-command-to-string "count" query))))
    (if (and no-zero (eq count 0)) nil count)))

(defun notmuch-bookmarks--unread-mails-query (bookmark)
  "Return a query for counting unread mails of BOOKMARK."
  (when-let ((query (notmuch-bookmarks-query bookmark)))
    (concat "(" query ") AND tag:unread")))

(defun notmuch-bookmarks--total-mails-query (bookmark)
  "Return a query for counting all mails of BOOKMARK."
  (notmuch-bookmarks-query bookmark))

(defun notmuch-bookmarks--annotation (cand)
  "Return an annotation string for CAND."
  (when-let ((bookmark (assoc cand bookmark-alist)))
    (let* ((unread-query (notmuch-bookmarks--unread-mails-query bookmark))
           (unread-count (when unread-query (notmuch-bookmarks--count unread-query :no-zero)))
           (total-query  (notmuch-bookmarks--total-mails-query bookmark))
           (total-count  (when total-query (notmuch-bookmarks--count total-query))))
      (concat
       (when (and unread-query unread-count)
         (propertize (format "%d unread mails" unread-count)
                     'face 'notmuch-tag-unread))
       (when (and unread-count total-query)
         "; ")
       (when total-query
         (format "%d mails" total-count))
       (when (or unread-count total-query)
         ".")))))

(defun notmuch-bookmarks-get-annotation (bookmark)
  "Return an annotation for BOOKMARK."
  (concat
   (when (featurep 'marginalia)
     (concat (marginalia-annotate-bookmark bookmark) " "))
   (when (notmuch-bookmarks-record-p bookmark)
     (notmuch-bookmarks--annotation bookmark))))


(defun notmuch-bookmarks--register-with-marginalia (&optional unregister)
  "Register annotations with marginalia.
Optionally UNREGISTER them."
  (let ((annotation-assoc '(bookmark notmuch-bookmarks-get-annotation)))
    (if unregister
        (setq marginalia-annotator-registry
              (seq-remove (lambda (l)
                            (when (listp l)
                              (equal l annotation-assoc)))
                          marginalia-annotator-registry))
      (add-to-list 'marginalia-annotator-registry
                   annotation-assoc))))

(defun notmuch-bookmarks--install-annotations (&optional uninstall)
  "Install annotation for notmuch bookmarks.
Optionally UNINSTALL this feature.

Do not call this function directly; use
`notmuch-bookmarks-annotation-mode' instead."
  (with-eval-after-load 'marginalia
    (notmuch-bookmarks--register-with-marginalia uninstall)))

;; Edit current buffer's bookmark

(defun notmuch-bookmarks--reload-current-bookmark ()
  "Reload current buffer's bookmark."
  (if-let ((bmk bookmark-current-bookmark))
      (progn
        (kill-buffer)
        (bookmark-jump bmk)
        (message "Bookmark has been changed"))
    (user-error "Buffer has no current bookmark")))

;;;###autoload
(defun notmuch-bookmarks-edit-name (bookmark-name)
  ;; checkdoc-params: (bookmark-name)
  "Edit current buffer's bookmark name."
  (interactive (list bookmark-current-bookmark))
  (unless bookmark-name
    (user-error "Buffer has no current bookmark"))
  (let ((new-name (read-string "Edit bookmark name: " bookmark-name)))
    (bookmark-set-name bookmark-name new-name)
    (setq-local bookmark-current-bookmark new-name)
    (notmuch-bookmarks--reload-current-bookmark)))

;;;###autoload
(defun notmuch-bookmarks-edit-query (bookmark-name)
  ;; checkdoc-params: (bookmark-name)
  "Edit current buffer's bookmark query."
  (interactive (list bookmark-current-bookmark))
  (unless bookmark-name
    (user-error "Buffer has no current bookmark"))
  (let ((new-query (read-string "Edit notmuch query: " (notmuch-bookmarks-query bookmark-name))))
    (bookmark-prop-set bookmark-name 'filename new-query)
    (notmuch-bookmarks--reload-current-bookmark)))

;; Install or uninstall the bookmark functionality:

(defun notmuch-bookmarks-set-record-fn ()
  "Register current buffer to be bookmarked via `notmuch-bookmark'."
  (setq-local bookmark-make-record-function 'notmuch-bookmarks-make-record))

(defun notmuch-bookmarks--install (&optional uninstall)
  "Install bookmarking for notmuch buffers.
If UNINSTALL is set to a non-nil value, uninstall instead.

Do not call this function directly; use the global minor mode
instead."
  ;; install/uninstall hooks:
  (cl-dolist (mode-name '(notmuch-show-mode notmuch-search-mode notmuch-tree-mode))
    (funcall (if uninstall 'remove-hook 'add-hook)
             (intern (format "%s-hook" mode-name)) #'notmuch-bookmarks-set-record-fn))
  ;; set/remove local bookmark var in existing buffers
  (cl-dolist (buf (notmuch-bookmarks--all-buffers))
    (with-current-buffer buf
      (if uninstall
          (kill-local-variable 'bookmark-make-record-function)
        (notmuch-bookmarks-set-record-fn))))
  ;; add to consult bookmarking for narrowing:
  (let ((consult-narrow-entry
         `(?n "Notmuch" ,#'notmuch-bookmarks-jump-handler)))
    (with-eval-after-load 'consult
      (when (bound-and-true-p consult-bookmark-narrow)
        (setq consult-bookmark-narrow
              (if uninstall
                  (cl-remove consult-narrow-entry consult-bookmark-narrow :test #'equal)
                (cons consult-narrow-entry consult-bookmark-narrow))))))
  ;; edit bmenu keymap:
  (when notmuch-bookmarks-bmenu-filter-key
    (if uninstall
        (when notmuch-bookmarks-bmenu-original-keymap
          (setq bookmark-bmenu-mode-map notmuch-bookmarks-bmenu-original-keymap))
      (setq notmuch-bookmarks-bmenu-original-keymap (copy-keymap bookmark-bmenu-mode-map))
      (define-key bookmark-bmenu-mode-map notmuch-bookmarks-bmenu-filter-key 'notmuch-bookmarks-bmenu))))

;;;###autoload
(define-minor-mode notmuch-bookmarks-mode
  "Add notmuch specific bookmarks to the bookmarking system."
  :group 'notmuch-bookmarks
  :global t
  (notmuch-bookmarks--install (not notmuch-bookmarks-mode)))

;;;###autoload
(define-minor-mode notmuch-bookmarks-annotation-mode
  "Add annotations for notmuch bookmarks."
  :group 'notmuch-bookmarks
  :global t
  (notmuch-bookmarks--install-annotations (not notmuch-bookmarks-annotation-mode)))

(provide 'notmuch-bookmarks)
;;; notmuch-bookmarks.el ends here
