;;; denote-refs.el --- Show links and backlinks in Denote notes  -*- lexical-binding: t; -*-

;; Copyright (C) 2022 Akib Azmain Turja.

;; Author: Akib Azmain Turja <akib@disroot.org>
;; Created: 2022-12-18
;; Version: 0.1.2
;; Package-Requires: ((emacs "28.1") (denote "1.1.0"))
;; Keywords: hypermedia, outlines, files
;; URL: https://codeberg.org/akib/emacs-denote-refs

;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Denote-Refs shows the list of linked file and backlinks to current
;; file.  This list is shown just below the front matter of your note.
;; To enable do M-x denote-refs-mode.  You can also enable it in your
;; `denote-directory' with .dir-locals.el.

;;; Code:

(require 'denote)
(require 'subr-x)

(defgroup denote-refs nil
  "Show links and backlinks in Denote notes."
  :group 'denote
  :link '(url-link "https://codeberg.org/akib/emacs-denote-refs")
  :prefix "denote-refs-")

(defcustom denote-refs-update-delay '(0.2 1 60)
  "Idle delay before updating reference lists.

The value is a list of form (FIRST INIT MAINTAIN).  FIRST the delay
before initializing the reference lists just after enabling the mode.
INIT the delay before initializing the reference lists for the first
time, used if the initialization was interrupted.  MAINTAIN the delay
before updating the reference lists to keep the lists to updated."
  :type '(list (number :tag "Delay after mode enabled")
               (number :tag "Delay before initialization")
               (number :tag "Delay after initialized")))

(defcustom denote-refs-sections '(links backlinks)
  "The sections to show.

Available sections are `links' and `backlinks', which shows the list
of linked file and the list of backlinks respectively."
  :type '(repeat (choice (const :tag "Links" links)
                         (const :tag "Backlinks" backlinks))))

(defvar denote-refs--links 'not-ready
  "Alist of linked files.

The key is the path relative to user option `denote-directory', and
the key is the absolute path.")

(defvar denote-refs--backlinks 'not-ready
  "Alist of backlinks.

The key is the path relative to user option `denote-directory', and
the key is the absolute path.")

(defvar denote-refs--schedule-idle-update-timer nil
  "Timer to schedule updating references while idle.")

(defvar denote-refs--idle-update-timers nil
  "Timer to update references while idle.")

(defun denote-refs--render (section)
  "Render SECTION."
  (let ((refs (pcase section
                ('links denote-refs--links)
                ('backlinks denote-refs--backlinks))))
    (cond
     ;; There's no comment syntax in `text-mode', so just follow
     ;; `org-mode'.
     ((derived-mode-p 'org-mode 'text-mode)
      ;; Insert references count.
      (insert (if (or (eq refs 'not-ready)
                      (eq refs 'error))
                  (format "# ... %s\n" (if (eq section 'links)
                                           "links"
                                         "backlinks"))
                (format "# %i %s%s\n" (length refs)
                        (if (eq section 'links)
                            "link"
                          "backlink")
                        (pcase (length refs)
                          (0 "")
                          (1 ":")
                          (_ "s:")))))
      ;; Insert reference list.
      (when (listp refs)
        (dolist (ref refs)
          (insert "#   ")
          (insert-button (car ref)
                         'help-echo (cdr ref)
                         'face 'denote-faces-link
                         'action (lambda (_)
                                   (funcall denote-link-button-action
                                            (cdr ref))))
          (insert ?\n))))
     ((derived-mode-p 'markdown-mode)
      ;; Insert references count.
      (insert (if (or (eq refs 'not-ready)
                      (eq refs 'error))
                  (format "<!-- ... %s -->\n" (if (eq section 'links)
                                                  "links"
                                                "backlinks"))
                (format "<!-- %i %s%s\n" (length refs)
                        (if (eq section 'links)
                            "link"
                          "backlink")
                        (pcase (length refs)
                          (0 " -->")
                          (1 ":")
                          (_ "s:")))))
      ;; Insert reference list.
      (when (listp refs)
        (while refs
          (let ((ref (pop refs)))
            (insert "  ")
            (insert-button
             (car ref)
             'help-echo (cdr ref)
             'face 'denote-faces-link
             'action (lambda (_)
                       (funcall denote-link-button-action
                                (cdr ref))))
            (unless refs
              (insert " -->"))
            (insert ?\n))))))))

(defun denote-refs--goto-end-of-front-matter ()
  "Go to the end of front matter of the note."
  ;; All default front matters end with at least an empty line.  But
  ;; advanced users can change that.  So we keep this code in separate
  ;; function for them to advice.
  (goto-char (point-min))
  (search-forward "\n\n"))

(defun denote-refs--remove ()
  "Remove the references shown."
  ;; We ignore errors, because `denote-refs--goto-end-of-front-matter'
  ;; might fail.
  (ignore-errors
    (save-excursion
      (denote-refs--goto-end-of-front-matter)
      (when (get-text-property (point) 'denote-refs--sections)
        (let ((end (or (next-single-property-change
                        (point) 'denote-refs--sections)
                       (point-max))))
          (when (< end (point-max))
            (setq end (1+ end)))
          (let ((inhibit-read-only t))
            (with-silent-modifications
              (delete-region (point) end))))))))

(defun denote-refs--show ()
  "Show references."
  ;; We ignore errors, because `denote-refs--goto-end-of-front-matter'
  ;; might fail.
  (ignore-errors
    (denote-refs--remove)
    (save-excursion
      (denote-refs--goto-end-of-front-matter)
      (let ((begin (point))
            (inhibit-read-only t))
        (with-silent-modifications
          (dolist (section denote-refs-sections)
            (pcase-exhaustive section
              ('links
               (denote-refs--render 'links))
              ('backlinks
               (denote-refs--render 'backlinks))))
          (put-text-property begin (point) 'read-only t)
          (put-text-property begin (point) 'denote-refs--sections t)
          (insert ?\n))))))

(defun denote-refs--make-path-relative (path)
  "Return a cons of relative and absolute version of PATH.

The car is PATH relative to user option `denote-directory'."
  (cons (string-remove-prefix (denote-directory) path) path))

(defun denote-refs--fetch ()
  "Fetch reference information."
  (dolist (section (seq-uniq denote-refs-sections))
    (pcase-exhaustive section
      ('links
       (setq denote-refs--links
             (condition-case-unless-debug nil
                 (and (buffer-file-name)
                      (file-exists-p (buffer-file-name))
                      (mapcar #'denote-refs--make-path-relative
                              (delete-dups
                               (denote-link--expand-identifiers
                                (denote--link-in-context-regexp
                                 (denote-filetype-heuristics
                                  (buffer-file-name)))))))
               (error 'error))))
      ('backlinks
       (setq denote-refs--backlinks
             (condition-case-unless-debug nil
                 (and (buffer-file-name)
                      (file-exists-p (buffer-file-name))
                      (mapcar
                       #'denote-refs--make-path-relative
                       (delete (buffer-file-name)
                               (denote--retrieve-files-in-xrefs
                                (denote-retrieve-filename-identifier
                                 (buffer-file-name))))))
               (error 'error)))))))

(defun denote-refs-update ()
  "Update Denote references shown."
  (interactive)
  (denote-refs--fetch)
  (denote-refs--show))

(defun denote-refs--idle-update (buffer)
  "Update Denote references shown on BUFFER, but don't block."
  (when (buffer-live-p buffer)
    (with-current-buffer buffer
      (while-no-input
        (denote-refs-update))
      (denote-refs--show))))

(defun denote-refs-update-all ()
  "Update Denote references shown on all buffers."
  (interactive)
  (dolist (buffer (buffer-list))
    (when (buffer-local-value 'denote-refs-mode buffer)
      (with-current-buffer buffer
        (denote-refs-update)))))

(defun denote-refs--fix-xref--collect-matches (fn hit &rest args)
  "Advice around `xref--collect-match' to ignore reference lists.

FN is the original definition of `xref--collect-matches', HIT and ARGS
are it's arguments."
  (let* ((file (cadr hit))
         (file (and file (concat xref--hits-remote-id file)))
         (buf (xref--find-file-buffer file)))
    (if (and buf (buffer-local-value 'denote-refs-mode buf))
        (progn
          (with-current-buffer buf
            (denote-refs--remove))
          (unwind-protect
              (apply fn hit args)
            (with-current-buffer buf
              (denote-refs--show))))
      (apply fn hit args))))

(defun denote-refs--schedule-idle-update ()
  "Schedule updating Denote references shown."
  (mapc #'cancel-timer denote-refs--idle-update-timers)
  (setq denote-refs--idle-update-timers nil)
  (and (eq (while-no-input
             (dolist (buffer (buffer-list))
               (when (buffer-local-value 'denote-refs-mode buffer)
                 (with-current-buffer buffer
                   (push
                    (run-with-idle-timer
                     (if (or (eq denote-refs--links 'not-ready)
                             (eq denote-refs--backlinks 'not-ready))
                         (cadr denote-refs-update-delay)
                       (caddr denote-refs-update-delay))
                     nil #'denote-refs--idle-update buffer)
                    denote-refs--idle-update-timers))))
             'finish)
           'finish)
       (not denote-refs--idle-update-timers)
       (progn
         (advice-remove #'xref--collect-matches
                        #'denote-refs--fix-xref--collect-matches)
         (cancel-timer denote-refs--schedule-idle-update-timer))))

(defun denote-refs--before-write-region (_ _)
  "Make sure `write-region' doesn't write the reference lists."
  (let ((buf (get-buffer-create " *denote-refs-tmp-write-region*"))
        (str (buffer-string)))
    (set-buffer buf)
    (let ((inhibit-read-only t))
      (erase-buffer))
    (insert str)
    (denote-refs--remove)))

;;;###autoload
(define-minor-mode denote-refs-mode
  "Toggle showing links and backlinks in Denote notes."
  :lighter " Denote-Refs"
  (let ((locals '(denote-refs--links denote-refs--backlinks)))
    (if denote-refs-mode
        (progn
          (mapc #'make-local-variable locals)
          (denote-refs--show)
          (add-hook 'write-region-annotate-functions
                    #'denote-refs--before-write-region nil t)
          (add-hook 'org-capture-prepare-finalize-hook
                    #'denote-refs--remove nil t)
          ;; This runs just once, so we don't bother to keep track of
          ;; it.  ;)
          (run-with-idle-timer
           (car denote-refs-update-delay) nil
           #'denote-refs--idle-update (current-buffer))
          (advice-add #'xref--collect-matches :around
                      #'denote-refs--fix-xref--collect-matches)
          ;; This timer takes care of reverting the advice and also
          ;; canceling the timer itself.
          (when denote-refs--schedule-idle-update-timer
            (cancel-timer denote-refs--schedule-idle-update-timer))
          (setq denote-refs--schedule-idle-update-timer
                (run-with-idle-timer
                 (min (cadr denote-refs-update-delay)
                      (caddr denote-refs-update-delay))
                 t #'denote-refs--schedule-idle-update)))
      (denote-refs--remove)
      (remove-hook 'before-save-hook #'denote-refs--remove t)
      (remove-hook 'after-save-hook #'denote-refs--show t)
      (remove-hook 'org-capture-prepare-finalize-hook
                   #'denote-refs--remove t)
      (mapc #'kill-local-variable locals))))

(provide 'denote-refs)
;;; denote-refs.el ends here
