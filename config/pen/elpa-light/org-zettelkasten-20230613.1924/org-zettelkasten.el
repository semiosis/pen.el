;;; org-zettelkasten.el --- A Zettelkasten mode leveraging Org  -*- lexical-binding: t; -*-

;; Copyright (C) 2021-2023  Yann Herklotz

;; Author: Yann Herklotz <git@yannherklotz.com>
;; Maintainer: Yann Herklotz <git@yannherklotz.com>
;; Keywords: files, hypermedia, Org, notes
;; Homepage: https://sr.ht/~ymherklotz/org-zettelkasten
;; Mailing-List: https://lists.sr.ht/~ymherklotz/org-zettelkasten
;; Package-Requires: ((emacs "25.1") (org "9.3"))

;; Version: 0.8.0

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; These functions allow for the use of the zettelkasten method in org-mode.
;;
;; It uses the CUSTOM_ID property to store a permanent ID to the note,
;; which are organised in the same fashion as the notes by Luhmann.

;;; Code:

(require 'org)
(require 'cl-lib)

(defgroup org-zettelkasten nil
  "Helper to work with zettelkasten notes."
  :group 'applications)

(defcustom org-zettelkasten-directory (expand-file-name "~/org-zettelkasten")
  "Main zettelkasten directory."
  :type 'string
  :group 'org-zettelkasten)

(defcustom org-zettelkasten-prefix [(control ?c) ?y]
  "Prefix key to use for Zettelkasten commands in Zettelkasten minor mode.
The value of this variable is checked as part of loading Zettelkasten mode.
After that, changing the prefix key requires manipulating keymaps."
  :type 'key-sequence
  :group 'org-zettelkasten)

(defcustom org-zettelkasten-mapping-file
  (expand-file-name "org-zettelkasten-index" org-zettelkasten-directory)
  "The file which contains mappings from indices to file-names."
  :type 'string
  :group 'org-zettelkasten)

(defvar org-zettelkasten--mapping :unset
  "Main mapping from indices to filenames in the Zettelkasten directory.")

(defun org-zettelkasten--read-mapping ()
  "Initialize `org-zettelkasten--mapping' using the contents of
`org-zettelkasten-mapping-file'."
  (let ((filename org-zettelkasten-mapping-file))
    (setq org-zettelkasten--mapping
          (when (file-exists-p filename)
            (with-temp-buffer
              (insert-file-contents filename)
              (read (current-buffer)))))
    (unless
        (seq-every-p
         (lambda (elt)
           (and (numberp (car-safe elt)) (stringp (cdr-safe elt))))
         org-zettelkasten--mapping)
      (warn "Contents of %s are in wrong format, resetting" filename)
      (setq org-zettelkasten--mapping :unset))))

(defun org-zettelkasten--ensure-read-mapping ()
  "Initialise `org-zettelkasten--mapping' if it is not yet initialised."
  (when (eq org-zettelkasten--mapping :unset)
    (org-zettelkasten--read-mapping)))

(defun org-zettelkasten--write-mapping ()
  "Save `org-zettelkasten--mapping' in `org-zettelkasten-mapping-file'."
  (let ((filename org-zettelkasten-mapping-file))
    (with-temp-buffer
      (insert ";;; -*- lisp-data -*-\n")
      (let ((print-length nil)
            (print-level nil))
        (pp org-zettelkasten--mapping (current-buffer)))
      (write-region nil nil filename nil 'silent))))

(defun org-zettelkasten--add-topic (index file-name &optional no-write)
  "Add a topic to `org-zettelkasten--mapping' and optionally save it to disk.
INDEX is the new index of the topic, it should not appear in
`org-zettelkasten--mapping' yet.  FILE-NAME is the file name of
the topic to be added.  NO-WRITE is an optional flag to to
control whether the mapping should be saved to the file."
  (org-zettelkasten--ensure-read-mapping)
  (if (and (numberp index) (stringp file-name))
      (add-to-list 'org-zettelkasten--mapping `(,index . ,file-name))
    (warn "Adding topics in wrong format"))
  (unless no-write
    (org-zettelkasten--write-mapping)))

(defun org-zettelkasten--remove-topic (index &optional no-write)
  "Remove a topic from `org-zettelkasten--mapping' given by INDEX.
Optionally, if NO-WRITE is set, write the new mapping to the
file."
  (org-zettelkasten--ensure-read-mapping)
  (setq org-zettelkasten--mapping
        (assq-delete-all index org-zettelkasten--mapping))
  (unless no-write
    (org-zettelkasten--write-mapping)))

(defun org-zettelkasten--abs-file (file)
  "Return FILE name relative to `org-zettelkasten-directory'."
  (expand-file-name file org-zettelkasten-directory))

(defun org-zettelkasten--ident-prefix (ident)
  "Return the prefix identifier for IDENT.

This function assumes that IDs will start with a number."
  (when (string-match "^\\([0-9]*\\)" ident)
    (string-to-number (match-string 1 ident))))

;;;###autoload
(defun org-zettelkasten-goto-id (id)
  "Go to an ID automatically."
  (interactive "sID: #")
  (org-zettelkasten--ensure-read-mapping)
  (let ((file (alist-get (org-zettelkasten--ident-prefix id)
                         org-zettelkasten--mapping)))
    (org-link-open-from-string
     (concat "[[file:" (org-zettelkasten--abs-file file)
             "::#" id "]]"))))

(defun org-zettelkasten--incr-alpha (ident-part)
  "Increments a string of lowercase letters in IDENT-PART."
  (let ((carry 0)
        (new-list nil)
        (rev-list (reverse (string-to-list ident-part))))
    (let ((new-val (dolist (ident-el
                            (cons (+ (car rev-list) 1) (cdr rev-list))
                            (concat new-list))
                     (let ((incr-val (+ ident-el carry)))
                       (if (<= incr-val ?z)
                           (progn
                             (setq new-list (cons incr-val new-list))
                             (setq carry 0))
                         (setq new-list (cons ?a new-list))
                         (setq carry 1))))))
      (if (< 0 carry) (concat "a" new-val) new-val))))

(defun org-zettelkasten--incr-id (ident)
  "A better way to incement numerical IDENT.

This might still result in duplicate IDENTs for an IDENT that
ends with a letter."
  (if (string-match-p "\\(.*[a-z]\\)?\\([0-9]+\\)$" ident)
      (progn
        (string-match "\\(.*[a-z]\\)?\\([0-9]+\\)$" ident)
        (let ((pre (match-string 1 ident))
              (post (match-string 2 ident)))
          (concat pre (number-to-string (+ 1 (string-to-number post))))))
    (string-match "\\(.*[0-9]\\)?\\([a-z]+\\)$" ident)
    (let ((pre (match-string 1 ident))
          (post (match-string 2 ident)))
      (concat pre (org-zettelkasten--incr-alpha post)))))

(defun org-zettelkasten--branch-id (ident)
  "Create a branch ID from IDENT."
  (if (string-match-p ".*[0-9]$" ident)
      (concat ident "a")
    (concat ident "1")))

(defun org-zettelkasten--create (incr newheading)
  "Create a new heading according to INCR and NEWHEADING.

INCR: function to increment the ID by.
NEWHEADING: function used to create the heading and set the current POINT to
            it."
  (let* ((current-id (org-entry-get nil "CUSTOM_ID"))
         (next-id (funcall incr current-id)))
    (funcall newheading)
    (org-set-property "CUSTOM_ID" next-id)
    (org-set-property "EXPORT_DATE"
                      (format-time-string (org-time-stamp-format t t)))))

(defun org-zettelkasten-create-next ()
  "Create a heading at the same level as the current one."
  (interactive)
  (org-zettelkasten--create
   #'org-zettelkasten--incr-id #'org-insert-heading-after-current))

(defun org-zettelkasten-create-branch ()
  "Create a branching heading at a level lower than the current."
  (interactive)
  (org-zettelkasten--create
   #'org-zettelkasten--branch-id
   (lambda ()
     (org-back-to-heading)
     (org-forward-heading-same-level 1 t)
     (org-insert-subheading ""))))

(defun org-zettelkasten-create-dwim ()
  "Create the right type of heading based on current position."
  (interactive)
  (let ((current-point (save-excursion
                         (org-back-to-heading)
                         (point)))
        (next-point (save-excursion
                      (org-forward-heading-same-level 1 t)
                      (point))))
    (if (= current-point next-point)
        (org-zettelkasten-create-next)
      (org-zettelkasten-create-branch))))

(defun org-zettelkasten--update-modified ()
  "Update the modified timestamp, which can be done on save."
  (org-set-property "modified" (format-time-string
                                (org-time-stamp-format t t))))

(defun org-zettelkasten--all-files ()
  "Return all files in the Zettelkasten with full path."
  (org-zettelkasten--ensure-read-mapping)
  (mapcar #'org-zettelkasten--abs-file
          (mapcar #'cdr org-zettelkasten--mapping)))

(defun org-zettelkasten-buffer ()
  "Check if the current buffer belongs to the Zettelkasten."
  (member (buffer-file-name) (org-zettelkasten--all-files)))

(defun org-zettelkasten-setup ()
  "Activate `zettelkasten-mode' with hooks.

This function only activates `zettelkasten-mode' in Org.  It also
adds `org-zettelkasten--update-modified' to buffer local
`before-save-hook'."
  (org-zettelkasten--ensure-read-mapping)
  (add-hook
   'org-mode-hook
   (lambda ()
     (when (org-zettelkasten-buffer)
       (add-hook 'before-save-hook
                 #'org-zettelkasten--update-modified
                 nil 'local)
       (org-zettelkasten-mode)))))

;;;###autoload
(defun org-zettelkasten-search-current-id ()
  "Search for references to ID in `org-zettelkasten-directory'."
  (interactive)
  (let ((current-id (org-entry-get nil "CUSTOM_ID")))
    (lgrep (concat "[:[]." current-id "]") "*.org" org-zettelkasten-directory)))

;;;###autoload
(defun org-zettelkasten-agenda-search-view ()
  "Search for text using Org agenda in Zettelkasten files."
  (interactive)
  (let ((org-agenda-files (org-zettelkasten--all-files)))
    (org-search-view)))

;;;###autoload
(defun org-zettelkasten-new-topic (file-name)
  "Create a new topic in a file named FILE-NAME."
  (interactive "sNew topic filename: ")
  (org-zettelkasten--ensure-read-mapping)
  (let ((new-id
         (if org-zettelkasten--mapping
             (1+ (apply #'max (mapcar (lambda (val) (car val))
                                      org-zettelkasten--mapping)))
           1))
        (norm-file-name
         (if (string-suffix-p ".org" file-name)
             file-name
           (concat file-name ".org"))))
    (org-zettelkasten--add-topic new-id norm-file-name)
    (find-file (org-zettelkasten--abs-file norm-file-name))
    (insert (format "#+title:

* First Note
:PROPERTIES:
:CUSTOM_ID: %da
:EXPORT_DATE: %s
:END:

" new-id (format-time-string (org-time-stamp-format t t))))))

(defvar org-zettelkasten-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "n") #'org-zettelkasten-create-dwim)
    (define-key map (kbd "C-s") #'org-zettelkasten-search-current-id)
    (define-key map (kbd "s") #'org-zettelkasten-agenda-search-view)
    (define-key map (kbd "g") #'org-zettelkasten-goto-id)
    (define-key map (kbd "t") #'org-zettelkasten-new-topic)
    map)
  "Keymap with default bindings.")

(defvar org-zettelkasten-minor-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map org-zettelkasten-prefix org-zettelkasten-mode-map)
    map)
  "Keymap used for binding footnote minor mode.")

;;;###autoload
(define-minor-mode org-zettelkasten-mode
  "Enable the keymaps to be used with zettelkasten."
  :lighter " ZK"
  :keymap org-zettelkasten-minor-mode-map)

(provide 'org-zettelkasten)

(with-eval-after-load 'consult (require 'org-zettelkasten-consult))
(with-eval-after-load 'counsel (require 'org-zettelkasten-counsel))

;;; org-zettelkasten.el ends here
