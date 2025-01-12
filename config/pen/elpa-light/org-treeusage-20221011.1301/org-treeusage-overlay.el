;;; org-treeusage-overlay.el --- Overlay library -*- lexical-binding: t; -*-

;; Copyright (C) 2020 Mehmet Tekman <mtekman89@gmail.com>

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;;; Commentary:

;; See org-treeusage.el

;;; Code:
(require 'dash)
(require 'org-treeusage-cycle) ;; brings nil
(require 'org-treeusage-parse) ;; brings

(defvar org-treeusage-overlay--backupformat "%1$-5s--%3$d"
  "Fallback in case an invalid line format is chosen by the user.")

(defcustom org-treeusage-overlay-usecolorbands t
  "Use the color in the percentage bands given in `org-treeusage-overlay-percentlevels'."
  :type 'boolean
  :group 'org-treeusage)

(defcustom org-treeusage-overlay-percentlevels
  '(((-9 .  1)  . (▏ . magit-blame-dimmed))
    (( 2 . 10)  . (▎ . magit-blame-dimmed))
    ((11 . 20)  . (▋ . ibuffer-locked-buffer))
    ((21 . 30)  . (█ . ibuffer-locked-buffer))
    ((31 . 40)  . (█▋ . magit-reflog-rebase))
    ((41 . 50)  . (██ . magit-reflog-rebase))
    ((51 . 60)  . (██▋ . magit-signature-revoked))
    ((61 . 70)  . (███ . magit-signature-error))
    ((71 . 80)  . (███▋ . magit-signature-drop))
    ((81 . 90)  . (████ . magit-signature-bad))
    ((91 . 110) . (████▋ . magit-signature-bad)))
  "Set the percentage lower and upper bands and the corresponding symbol.
Format is ((lower . upper) . (symbol . face)) and bands are allowed to overlap.
Run `list-faces-display' for a selection of faces."
  :type 'alist
  :group 'org-treeusage)

(defcustom org-treeusage-overlay-header t
  "Header to display bindings information."
  :type 'boolean
  :group 'org-treeusage)

(defvar-local org-treeusage-overlay--previousheader nil)

(defun org-treeusage-overlay--setheader (set)
  "SET or restore the header for the top modeline."
  (if org-treeusage-overlay-header
      (if (not set)
          (setq-local header-line-format org-treeusage-overlay--previousheader)
        (setq-local org-treeusage-overlay--previousheader header-line-format)
        (setq-local header-line-format
                    (substitute-command-keys
                     "Line formats: \
`\\[org-treeusage-cycle-modebackward]' or \
`\\[org-treeusage-cycle-modeforward]' | Diff types: \
`\\[org-treeusage-cycle-cycletype]'")))))


(defun org-treeusage-overlay--getformatline ()
  "Get the line format, or use the backup one."
  (or (alist-get org-treeusage-cycle--currentmode org-treeusage-cycle-formats)
      (progn (message "using backup format.")
             org-treeusage-overlay--backupformat)))

(defun org-treeusage-overlay--clear ()
  "Remove all overlays."
  (let ((ovs (overlays-in (point-min) (point-max))))
    (if (cl-loop for ov in ovs
                 thereis (overlay-get ov :org-treeusage))
        (dolist (ov ovs)
          (when (overlay-get ov :org-treeusage)
            (delete-overlay ov))))))


(defun org-treeusage-overlay--setall (&optional reusemap)
  "Set all overlays.  If REUSEMAP is passed (as is the case) when called from `org-cycle-hook', then use or update the existing hashtable."
  (let* ((usecolor org-treeusage-overlay-usecolorbands)
         (perclevels org-treeusage-overlay-percentlevels)
         (hasher (org-treeusage-parse--gethashmap reusemap))
         (clearovs (member reusemap '(-1 nil)))
         (ndiffs (intern (format ":n%s" org-treeusage-cycle--difftype)))
         (pdiffs (intern (format ":p%s" org-treeusage-cycle--difftype)))
         (lineform (org-treeusage-overlay--getformatline))
         (percbands (if usecolor perclevels
                      (--map (cons (nth 0 it) (nth 1 it)) perclevels))))
    (if clearovs
        ;; -1  # Mode initialise :: clear overlays + delete hashmap
        ;; nil # Lformat changed :: clear overlays + use existing hashmap
        ;; any # Head expa/contr :: leave overlays + update the hashmap
        (org-treeusage-overlay--clear))
    (maphash
     (lambda (head info)
       (if (or clearovs (not (plist-get info :overlay-already)))
           (let ((bounds (plist-get info :bounds)) ;; child
                 (nchars (plist-get info :nchars))
                 (nwords (plist-get info :nwords))
                 (nlines (plist-get info :nlines))
                 (ndiffs (plist-get info ndiffs)) ;; one of the n*'s
                 (pdiffs (plist-get info pdiffs)) ;; can only show 1 perc type
                 (leveln (car head)) (header (cdr head)))
             (if pdiffs ;; i.e a parent exists
                 (let ((facehead (intern (format "org-level-%s" leveln)))
                       (overhead (make-overlay (car bounds) (cdr bounds)))
                       (percsymb (cdr (--first (<= (caar it)
                                                   (truncate pdiffs)
                                                   (cdar it))
                                               percbands))))
                   (if (eq (type-of percsymb) 'cons)
                       (setq facehead (cdr percsymb)
                             percsymb (car percsymb)))
                   ;; Header
                   (overlay-put overhead :org-treeusage t)
                   (overlay-put overhead 'face facehead)
                   (overlay-put overhead 'display
                                (format lineform ;; symbol, percentage, abs
                                        percsymb pdiffs ndiffs
                                        nlines nwords nchars
                                        header)))))))
     hasher)))


(provide 'org-treeusage-overlay)
;;; org-treeusage-overlay.el ends here
