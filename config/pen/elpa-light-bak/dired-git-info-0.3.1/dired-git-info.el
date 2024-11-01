;;; dired-git-info.el --- Show git info in dired -*- lexical-binding: t; -*-

;; Copyright (C) 2018-2019  Free Software Foundation, Inc.

;; Author: Clemens Radermacher <clemera@posteo.net>
;; URL: https://github.com/clemera/dired-git-info
;; Version: 0.3.1
;; Package-Requires: ((emacs "25"))
;; Keywords: dired, files

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
;;
;; Minor mode which shows last commit message and date (info shown is
;; configurable) for git project files in dired.
;;

;;; Code:

(require 'dired)

(defgroup dired-git-info nil
  "Show git info in dired."
  :group 'files
  :prefix "dgi-")

(defface dgi-commit-message-face
  '((t (:inherit font-lock-comment-face)))
  "Face for commit message overlays.")

(defcustom dgi-auto-hide-details-p t
  "If details should get hidden automatically.

Uses function `dired-hide-details-mode' to hide details when showing git
info."
  :type 'boolean)

(defcustom dgi-commit-message-format "%s\t%cr"
  "Format of the commit messages.

Entries separated by tabs are aligned. Some common placeholders
are (see git-log PRETTY FORMATS for all):

           · %H: commit hash

           · %h: abbreviated commit hash

           · %P: parent hashes

           · %p: abbreviated parent hashes

           · %an: author name

           · %ae: author email

           · %cd: committer date

           · %cr: committer date, relative

           · %cn: committer name

           · %ce: committer email

           · %s: subject

           · %f: sanitized subject line, suitable for a filename"
  :type 'string)

(defvar-local dgi--commit-ovs nil
  "Overlays which show the commit messages.")

(defvar dgi--restore-no-details nil
  "If no details view has to be restored.")

(defun dgi--command-to-string (program &rest args)
  "Execute PROGRAM with arguments ARGS and return output string.

If program returns non zero exit code return nil."
  (let* ((ecode nil)
         (output (with-output-to-string
                    (with-current-buffer standard-output
                      (setq ecode (apply #'process-file program nil t nil args))))))
    (when (eq ecode 0)
      output)))


(defun dgi--get-commit-info (&optional file gitf)
  "Get commit message info.

FILE default to current dired file. GITF determines the commit
info format and defaults to `dgi-commit-message-format'."
  (let* ((tfile (or file (dired-get-file-for-visit)))
         (file (or (file-remote-p tfile 'localname) tfile)))
    (when file
      (let ((msg (dgi--command-to-string
                  "git" "log" "-1"
                  (concat "--pretty="
                          (or gitf dgi-commit-message-format))
                  file)))
        (when (and msg (not (string= "" msg)))
          (substring msg
                     ;; skip newline
                     0 -1))))))


(defmacro dgi--save-marked (&rest body)
  "Execute BODY and restore marked files afterwards."
  `(let ((marked (save-excursion
                   (goto-char (point-min))
                   (dired-get-marked-files)))
         (inhibit-message t))
     (save-excursion
       (unwind-protect
           (progn ,@body)
         (dired-unmark-all-marks)
           (dolist (file marked)
             (dired-goto-file file)
             (dired-mark 1))))))


(defun dgi--cleanup ()
  "Remove commit overlays."
  (when dgi--restore-no-details
    (setq dgi--restore-no-details nil)
    (dired-hide-details-mode -1))
  (dolist (ov dgi--commit-ovs)
    (delete-overlay ov))
  (setq dgi--commit-ovs nil))


(defun dgi--get-dired-files-length (files)
  "Get list of lengths of all FILES as displayed by dired."
  (let ((dnames ()))
    (dolist (file files (nreverse dnames))
      (push (dgi--get-dired-file-length file)
            dnames))))


(defun dgi--get-dired-file-length (file)
  "Get lengths of FILE as displayed by dired."
  (save-excursion
    (dired-goto-file file)
    (let ((opos (point)))
      (while (and (not (eolp))
                  (or (not dired-hide-details-mode)
                      (not (get-text-property (point) 'invisible))))
        (forward-char 1))
      (length (buffer-substring opos (point))))))


(defun dgi--get-commit-messages (files)
  "Get formatted commit messages for FILES."
  (let ((messages ()))
    (dolist (file files)
      (push (dgi--get-commit-info file)
            messages))
    (with-temp-buffer
      (dolist (message (nreverse messages))
        (insert (or message "") "\n"))
      (let ((indent-tabs-mode nil))
        (align-regexp (point-min)
                      (point-max)
                      "\\(\\s-*\\)\t" nil nil t))
      (goto-char (point-min))
      (while (search-forward "\t" nil t)
        (replace-match " "))
      (split-string (buffer-string) "\n"))))


(defun dgi--format-line-overlay (msg)
  "Format message MSG for current dired line."
  (let* ((le (line-end-position))
         (aw (- (window-width)
                (1+ (save-excursion
                      (goto-char le)
                      (current-column))))))
    (if (not (> aw 0))
        "\n"
      (concat (dgi--clamp-string msg aw)
              "\n"))))

(defun dgi--clamp-string (str max)
  "Return STRING truncated to MAX length if needed."
  (propertize
   (if (> (length str) max)
       (concat (substring str 0
                          (- max (+ (length str) 3)))
               "...")
     str)
   'face 'dgi-commit-message-face))


;;;###autoload
(define-minor-mode dired-git-info-mode
  "Toggle git message info in current dired buffer."
  :lighter " dgi"
  (if (not dired-git-info-mode)
      (dgi--cleanup)
    (unless (derived-mode-p 'dired-mode)
      (user-error "Not in a dired buffer"))
    (unless (locate-dominating-file "." ".git")
      (user-error "Not inside a git repository"))
    (when dgi-auto-hide-details-p
      (unless dired-hide-details-mode
        (setq dgi--restore-no-details t)
        (dired-hide-details-mode 1)))
    (let* ((files (dgi--save-marked
                   (dired-unmark-all-marks)
                   (dired-toggle-marks)
                   (dired-get-marked-files)))
           (minspc  (1+ (apply #'max  (dgi--get-dired-files-length files))))
           (messages (dgi--get-commit-messages files)))
      (save-excursion
        (dolist (file files)
          (let ((msg (pop messages)))
            (when msg
              (dired-goto-file file)
              (let ((spc (make-string
                          (- minspc (dgi--get-dired-file-length file))
                          ?\s)))
                (goto-char (line-end-position))
                (let ((ov (make-overlay (point) (1+ (point))))
                      (ovs (dgi--format-line-overlay (concat spc msg))))
                  (push ov dgi--commit-ovs)
                  ;; I don't use after-string because I didn't get it to work
                  ;; in combination with hl-line-mode overlay
                  (overlay-put ov 'display ovs)
                  ;; hl line mode should have priority
                  (overlay-put ov 'priority -60))))))))))

;;;###autoload
(defun dired-git-info-auto-enable ()
  "Enable `dired-git-info-mode' if current dired buffer is in a git repo.

Add this function to `dired-after-readin-hook' to enable the mode
automatically inside git repos."
  (when (locate-dominating-file "." ".git")
    (dired-git-info-mode)))

;;;; ChangeLog:




(provide 'dired-git-info)
;;; dired-git-info.el ends here


