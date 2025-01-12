;;; hyperdrive.el --- P2P filesystem  -*- lexical-binding: t; -*-

;; Copyright (C) 2023, 2024 USHIN, Inc.

;; Author: Adam Porter <adam@alphapapa.net>
;; Author: Joseph Turner <joseph@ushin.org>

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

;; This file adds a transient.el menu for hyperdrive entries.

;;; Code:

;;;; Requirements

(require 'cl-lib)
(require 'pcase)
(require 'transient)
(require 'compat)

(require 'hyperdrive)
(require 'hyperdrive-vars)
(require 'hyperdrive-lib)
(require 'hyperdrive-mirror)

;;;; Declarations

(declare-function h/dir--entry-at-point "hyperdrive-dir")
(declare-function h/delete "hyperdrive")
(declare-function h/set-nickname "hyperdrive")
(declare-function h/set-petname "hyperdrive")
(declare-function h/describe-hyperdrive "hyperdrive-describe")

;;;; hyperdrive-menu: Transient for entries

;; TODO: Use something like this later.
;; (defmacro hyperdrive-menu-lambda (&rest body)
;;   (declare (indent defun))
;;   `(lambda ()
;;      (when h/current-entry
;;        (pcase-let (((cl-struct hyperdrive-entry hyperdrive)
;;                     h/current-entry))
;;          ,@body))))

;;;###autoload (autoload 'hyperdrive-menu "hyperdrive-menu" nil t)
(transient-define-prefix hyperdrive-menu (entry)
  "Show the hyperdrive transient menu."
  :info-manual "(hyperdrive)"
  :refresh-suffixes t
  [["Hyperdrive"
    :description
    (lambda ()
      (if-let* ((entry (h/menu--scope))
                (hyperdrive (he/hyperdrive entry)))
          (concat (propertize "Hyperdrive: " 'face 'transient-heading)
                  (h//format hyperdrive))
        "Hyperdrive"))
    ("h" "Hyperdrive" h/menu-hyperdrive)
    ("N" "New drive" h/new)
    ("L" "Open link" h/open-url)]
   ["Version"
    :if (lambda ()
          (and (h/menu--scope)
               ;; TODO: Remove this check and add useful history transient UI.
               (not (eq 'h/history-mode major-mode))))
    :description
    (lambda ()
      (let* ((entry (h/menu--scope))
             (version (he/version entry))
             (directoryp (hyperdrive--entry-directory-p entry)))
        (concat
         (propertize "Version: " 'face 'transient-heading)
         (cond (directoryp (propertize (format "%s" (or version "latest"))
                                       'face 'h/history-existent))
               ((not (map-elt (he/etc entry) 'existsp))
                (propertize "nonexistent" 'face 'h/history-unknown))
               (version (propertize (format "%d" version)
                                    'face 'h/history-existent))
               (t (propertize "latest"
                              'face 'h/history-existent))))))
    ("V p" "Previous" h/open-previous-version
     :inapt-if-not (lambda ()
                     (map-elt (he/etc (h/menu--scope)) 'previous-version-exists-p))
     ;; :transient t
     :description
     (lambda ()
       (let ((entry (h/menu--scope)))
         (format
          "Previous %s"
          (pcase-exhaustive (map-elt (he/etc entry) 'previous-version-exists-p)
            ('t (format (propertize "%d" 'face 'h/history-existent)
                        (map-elt (he/etc entry) 'previous-version-number)))
            ;; TODO: Is it possible to show the `h/history-nonexistent' face
            ;; over the `transient-inapt-suffix' face?
            ('nil (propertize "nonexistent" 'face 'h/history-nonexistent))
            ('unknown (propertize "unknown" 'face 'h/history-unknown)))))))
    ("V n" "Next" h/open-next-version
     :inapt-if-not (lambda ()
                     (let ((entry (h/menu--scope)))
                       (and (he/version entry)
                            (map-elt (he/etc entry) 'next-version-exists-p))))
     :description
     (lambda ()
       (let ((entry (h/menu--scope)))
         (format
          "Next %s"
          (pcase-exhaustive (map-elt (he/etc entry) 'next-version-exists-p)
            ((guard (not (he/version entry)))
             (propertize "latest" 'face 'h/history-existent))
            ('t (pcase-exhaustive (map-elt (he/etc entry) 'next-version-number)

                  ('nil
                   (propertize "latest" 'face 'h/history-existent))
                  ((and (pred numberp) version)
                   (format (propertize "%d" 'face 'h/history-existent)
                           version))))
            ;; TODO: Is it possible to show the `h/history-nonexistent' face
            ;; over the `transient-inapt-suffix' face?
            ('nil (propertize "nonexistent" 'face 'h/history-nonexistent))
            ('unknown (propertize "unknown" 'face 'h/history-unknown)))))))
    ("V a" "At..." h/open-at-version)
    ("V h" "History" h/history
     :inapt-if (lambda ()
                 (h//entry-directory-p (h/menu--scope))))]]
  [:if (lambda ()
         (and (h/menu--scope)
              ;; TODO: Remove this check and add useful history transient UI.
              (not (eq 'h/history-mode major-mode))))
       [;; Current
        :description
        (lambda ()
          (let ((entry (h/menu--scope)))
            (concat (propertize "Current: " 'face 'transient-heading)
                    (propertize (h//format-path (he/path entry))
                                'face 'transient-value))))
        ("g" "Refresh" revert-buffer)
        ("^" "Up to parent" h/up
         :inapt-if-not (lambda ()
                         (h/parent (h/menu--scope))))
        ("s" "Sort" h/dir-sort
         :if-mode h/dir-mode
         :transient t)
        ;; TODO: Consider running whatever command imenu has been rebound to in the
        ;; global map, e.g., consult-imenu.
        ("j" "Jump" imenu
         :if-mode h/dir-mode)
        ;; TODO: Combine previous and next commands on the same line?
        ("p" "Previous" h/ewoc-previous
         :if-mode h/dir-mode
         :transient t)
        ("n" "Next" h/ewoc-next
         :if-mode h/dir-mode
         :transient t)
        ("w" "Copy URL" h/copy-url
         :if-not-mode h/dir-mode)
        ("D" "Delete" h/delete
         :if-not-mode h/dir-mode
         :inapt-if (lambda ()
                     (pcase-let (((cl-struct hyperdrive-entry hyperdrive version)
                                  (h/menu--scope)))
                       (or version (not (h/writablep hyperdrive))))))
        ("d" "Download" h/download
         :if-not-mode h/dir-mode)
        ("F" "Forget file" h/forget-file
         :transient t)]
       ;; TODO: Consider adding a defcustom to hide the "Selected" and
       ;; "Current" groups when in a directory buffer.
       [;; Selected
        :if (lambda ()
              (and (h/menu--scope)
                   (eq major-mode 'h/dir-mode)
                   (h/dir--entry-at-point 'no-error)))
        :description
        (lambda ()
          (let ((current-entry (h/menu--scope))
                (selected-entry (h/dir--entry-at-point 'no-error)))
            (concat (propertize "Selected: " 'face 'transient-heading)
                    (propertize
                     (or (and (he/equal-p current-entry selected-entry)
                              "./")
                         (alist-get 'display-name
                                    (he/etc selected-entry))
                         (he/name selected-entry))
                     'face 'transient-value))))
        :pad-keys t
        ("d" "Download" h/download
         :inapt-if (lambda ()
                     (and-let* ((entry-at-point
                                 (h/dir--entry-at-point 'no-error)))
                       (h//entry-directory-p entry-at-point))))
        ("D" "Delete" h/delete
         :inapt-if (lambda ()
                     (let ((current-entry (h/menu--scope))
                           (selected-entry (h/dir--entry-at-point 'no-error)))
                       (or (not (h/writablep
                                 (he/hyperdrive current-entry)))
                           (eq selected-entry current-entry)
                           (string= "../" (alist-get 'display-name
                                                     (he/etc selected-entry)))))))
        ("w" "Copy URL" h/dir-copy-url)
        ;; FIXME: The sequence "? RET" says "Unbound suffix" instead of showing the help for that command.  Might be an issue in Transient.
        ("RET" "Open" h/dir-find-file)
        ("v" "View" h/dir-view-file
         :inapt-if (lambda ()
                     (and-let* ((entry-at-point
                                 (h/dir--entry-at-point 'no-error)))
                       (h//entry-directory-p entry-at-point))))]]
  [["Gateway"
    :description
    (lambda ()
      (concat (propertize "Gateway: " 'face 'transient-heading)
              (propertize
               (cond (h//gateway-starting-timer "starting")
                     (h//gateway-stopping-timer "stopping")
                     ((h//gateway-ready-p) "on")
                     ((and (h/gateway-installed-p) (h/gateway-installing-p))
                      "upgrading")
                     ((h/gateway-installing-p) "installing")
                     ((h/gateway-installed-p) "off")
                     (t "not found"))
               'face 'transient-value)))
    ("G i" "Install" h/install
     :description
     (lambda () (if (h/gateway-needs-upgrade-p) "Upgrade" "Install"))
     :if (lambda ()
           (and (not (h/gateway-installing-p))
                (or (not (h/gateway-installed-p))
                    (h/gateway-needs-upgrade-p)))))
    ("G c" "Cancel install" h/cancel-install
     :transient t
     :if h/gateway-installing-p)
    ("G s" "Start" h/start
     :transient t
     :inapt-if-not (lambda () (h/gateway-installed-p))
     :if-not (lambda () (or (h/gateway-live-p) (h//gateway-ready-p))))
    ("G r" "Restart" h/restart
     :transient t
     :inapt-if-not (lambda () (h/gateway-installed-p))
     :if (lambda () (or (h/gateway-live-p) (h//gateway-ready-p))))
    ("G S" "Stop" h/stop
     :transient t
     :inapt-if-not (lambda () (or (h/gateway-live-p) (h//gateway-ready-p))))
    ("G v" "Version" h/gateway-version
     :transient t
     :inapt-if-not (lambda () (h//gateway-ready-p)))]
   ["Bookmark"
    ("b j" "Jump" h/bookmark-jump)
    ("b l" "List" h/bookmark-list)
    ("b s" "Set" bookmark-set
     :if h/menu--scope)]]
  (interactive (list h/current-entry))
  (transient-setup 'h/menu nil nil :scope entry))

;;;; hyperdrive-menu-hyperdrive: Transient for hyperdrives

(defvar h/mirror-source nil)
(defvar h/mirror-target nil)
(defvar h/mirror-filter nil)
(defvar h/mirror-confirm t)

;;;###autoload (autoload 'hyperdrive-menu-hyperdrive "hyperdrive-menu" nil t)
(transient-define-prefix hyperdrive-menu-hyperdrive (hyperdrive)
  "Show menu for HYPERDRIVE."
  :info-manual "(hyperdrive)"
  :refresh-suffixes t
  ["Hyperdrive"
   ;; TODO(transient): Maybe support shared predicates like
   ;; so, and then ":if entryp" to avoid duplication below.
   ;; :predicates ((entryp ,(lambda () (h/seed (h/menu--scope)))))
   ;; TODO(transient): Support subgroups in a column group,
   ;; making the below "" "Upload" unnecessary.
   ;; TODO: After transient supports subgroup in a column group, use :if writablep
   ;; on whole "Upload" group instead of :inapt-if-not on individual commands
   ;; TODO(transient): Implement :inapt-if* for groups.
   :pad-keys t
   ("d" h/menu-describe-hyperdrive)
   ("w" h/menu-hyperdrive-copy-url)
   (:info (lambda () (h//format (h/menu--scope) "Public key: %K" h/raw-formats)))
   ( :info (lambda () (h//format (h/menu--scope) "Seed: %S" h/raw-formats))
     :if (lambda () (h/seed (h/menu--scope))))
   ("p" h/menu-set-petname  :transient t)
   ("n" h/menu-set-nickname :transient t
    :inapt-if-not (lambda () (h/writablep (h/menu--scope))))
   ("S" h/menu-mark-as-safe :transient t)
   ( :info (lambda () (h//format (h/menu--scope) "Domain: %D" h/raw-formats))
     :if (lambda () (h/domains (h/menu--scope))))
   (:info (lambda () (format "Latest version: %s" (h/latest-version (h/menu--scope)))))
   ( :info (lambda ()
             (format "Disk usage: %s"
                     (propertize (file-size-human-readable
                                  (map-elt (h/etc (h/menu--scope)) 'disk-usage))
                                 'face 'hyperdrive-size)))
     :if (lambda () (map-elt (h/etc (h/menu--scope)) 'disk-usage)))]
  [["Open"
    ("f"   "Find file"    h/menu-open-file)
    ("v"   "View file"    h/menu-view-file)
    "" "Upload"
    ("u f" "File"         h/menu-upload-file
     :inapt-if-not (lambda () (h/writablep (h/menu--scope))))
    ("u F" "Files" h/menu-upload-files
     :inapt-if-not (lambda () (h/writablep (h/menu--scope))))]
   ["Mirror"
    :if (lambda () (h/writablep (h/menu--scope)))
    ("m m" "Mirror using settings below" h/mirror-configured)
    ("m s" "Source"  h/mirror-set-source)
    ("m t" "Target"  h/mirror-set-target)
    ("m f" "Filter"  h/mirror-set-filter)
    ("m c" "Confirm" h/mirror-set-confirm)]]
  (interactive (list (h//context-hyperdrive :force-prompt current-prefix-arg)))
  (transient-setup 'h/menu-hyperdrive nil nil :scope hyperdrive))

(transient-define-suffix h/mirror-configured ()
  (interactive)
  (h/mirror (or h/mirror-source default-directory)
            (h/menu--scope)
            h/mirror-target
            :filter h/mirror-filter
            :no-confirm (not h/mirror-confirm)))

;; TODO(transient): Use a suffix class, so these commands can be invoked
;; directly.  See magit-branch.<branch>.description et al.
(defclass h/mirror-variable (transient-lisp-variable)
  ((format :initform " %k %d: %v")
   (format-value :initarg :format-value :initform nil)
   (value-face :initarg :value-face :initform nil)))

(cl-defmethod transient-format-value ((obj h/mirror-variable))
  "Method for displaying hyperdrive mirror variables for suffix OBJ."
  (if-let ((fn (oref obj format-value)))
      (funcall fn obj)
    (if-let ((value (oref obj value))
             (value (if (stringp value)
                        value
                      (prin1-to-string value))))
        (if-let ((face (oref obj value-face)))
            (propertize value 'face face)
          value)
      (propertize "not set" 'face 'h/dimmed))))

(transient-define-infix h/mirror-set-source ()
  :class 'h/mirror-variable
  :variable 'h/mirror-source
  :value-face 'h/file-name
  :format-value (lambda (obj)
                  (if-let ((value (oref obj value)))
                      (propertize value 'face 'h/file-name)
                    (format (propertize "%s (default)" 'face 'h/dimmed)
                            (propertize default-directory 'face 'h/file-name))))
  :reader (lambda (_prompt _default _history)
            (read-directory-name "Mirror directory: " nil nil t)))

(transient-define-infix h/mirror-set-target ()
  :class 'h/mirror-variable
  :variable 'h/mirror-target
  :value-face 'h/file-name
  :format-value (lambda (obj)
                  (if-let ((value (oref obj value)))
                      (propertize value 'face 'h/file-name)
                    (format (propertize "%s (default)" 'face 'h/dimmed)
                            (propertize "/" 'face 'h/file-name))))
  :reader (lambda (_prompt _default _history)
            (h//format-path
             (h/read-path
              :hyperdrive (h/menu--scope)
              :prompt "Target directory in `%s'"
              :default "/")
             :directoryp t)))

(transient-define-infix h/mirror-set-filter ()
  :class 'h/mirror-variable
  :variable 'h/mirror-filter
  :always-read nil
  :format-value (lambda (obj)
                  (pcase-exhaustive (oref obj value)
                    ('nil (propertize "None (mirror all)" 'face 'h/file-name))
                    ((and (pred stringp) it) (propertize it 'face 'font-lock-regexp-face))
                    ((and (pred symbolp) it) (propertize (symbol-name it) 'face 'font-lock-function-name-face))
                    ;; TODO: Fontify the whole lambda.
                    ((and (pred consp) it) (propertize (prin1-to-string it) 'face 'default))))
  :reader (lambda (_prompt _default _history)
            (h/mirror-read-filter)))

(transient-define-infix h/mirror-set-confirm ()
  :class 'h/mirror-variable
  :variable 'h/mirror-confirm
  :format-value (lambda (obj)
                  ;; TODO dedicated faces
                  (if (oref obj value)
                      (propertize "yes" 'face 'h/file-name)
                    (propertize "no (dangerous)" 'face 'font-lock-warning-face)))
  :reader (lambda (_prompt _default _history)
            (not h/mirror-confirm)))

(transient-define-suffix h/menu-open-file ()
  (interactive)
  (h/open (h/read-entry (h/menu--scope) :read-version current-prefix-arg)))

(transient-define-suffix h/menu-view-file ()
  (interactive)
  (h/view-file (h/read-entry (h/menu--scope) :read-version current-prefix-arg)))

(transient-define-suffix h/menu-upload-file (filename entry)
  (interactive
   (let* ((filename (read-file-name "Upload file: "))
          (entry (h/read-entry (h/menu--scope)
                               :default-path (file-name-nondirectory filename)
                               :latest-version t)))
     (list filename entry)))
  (h/upload-file filename entry))

(transient-define-suffix h/menu-upload-files (files hyperdrive target-dir)
  (interactive
   (let ((drive (h/menu--scope)))
     (list
      (h/read-files)
      drive
      (h/read-path
       :hyperdrive drive
       :prompt "Target directory in `%s'"
       :default "/"))))
  (h/upload-files files hyperdrive target-dir))

(transient-define-suffix h/menu-describe-hyperdrive ()
  :description "Describe"
  (interactive)
  (h/describe-hyperdrive (h/menu--scope)))

(transient-define-suffix h/menu-hyperdrive-copy-url ()
  :description "Copy URL"
  (interactive)
  (h/copy-url (he/create
               :hyperdrive (h/menu--scope))))

(transient-define-suffix h/menu-set-petname (petname hyperdrive)
  :description (lambda ()
                 (format "Petname: %s"
                         (if-let ((petname (h/petname
                                            (h/menu--scope))))
                             (propertize petname 'face 'h/petname)
                           "")))
  (interactive
   (list (h/read-name
          :prompt "New petname"
          :initial-input (h/petname (h/menu--scope)))
         (h/menu--scope)))
  (h/set-petname petname hyperdrive))

(transient-define-suffix h/menu-set-nickname (nickname hyperdrive)
  :description
  (lambda ()
    (format "Nickname: %s"
            ;; TODO: h/metadata accessor (and maybe gv setter).
            (if-let ((nickname (alist-get 'name
                                          (h/metadata
                                           (h/menu--scope)))))
                (propertize nickname 'face 'h/nickname)
              "")))
  (interactive
   (list (h/read-name
          :prompt "New nickname"
          :initial-input (alist-get 'name (h/metadata (h/menu--scope))))
         (h/menu--scope)))
  (h/set-nickname nickname hyperdrive))

(transient-define-suffix h/menu-mark-as-safe ()
  :description
  (lambda () (format "Safe: %s" (h/safe-string (h/menu--scope))))
  (interactive)
  (call-interactively #'h/mark-as-safe))

;;;; Menu Utilities

(defun h/menu--scope ()
  "Return the current entry as understood by `hyperdrive-menu'."
  (oref (transient-prefix-object) scope))

;;;; Footer

(provide 'hyperdrive-menu)

;; Local Variables:
;; read-symbol-shorthands: (
;;   ("he//" . "hyperdrive-entry--")
;;   ("he/"  . "hyperdrive-entry-")
;;   ("h//"  . "hyperdrive--")
;;   ("h/"   . "hyperdrive-"))
;; End:
;;; hyperdrive-menu.el ends here
