;;; helm-cider-repl.el --- Helm interface to CIDER REPL -*- lexical-binding: t; -*-

;; Copyright (C) 2016-2022 Tianxiang Xiong

;; Author: Tianxiang Xiong <tianxiang.xiong@gmail.com>

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

;;; Commentary:

;; Helm interface to CIDER REPL.

;;; Code:

(require 'cider-repl)
(require 'cl-lib)
(require 'subr-x)


;;;; Customize

(defgroup helm-cider-repl nil
  "Helm interface to CIDER REPL."
  :prefix "helm-cider-repl-"
  :group 'helm-cider
  :tag "Helm CIDER REPL")

(defcustom helm-cider-repl-history-max-lines 5
  "Max number of lines displayed per candidate in CIDER REPL history browser.

If not a positive integer, don't truncate candidate, show all."
  :group 'helm-cider-repl
  :type '(choice
          (const :tag "Disabled" nil)
          (integer :tag "Max number of lines")))

(defcustom helm-cider-repl-history-actions
  (helm-make-actions
   "Insert" 'helm-cider-repl-history-insert
   "Delete" 'helm-cider-repl-history-delete)
  "List of actions for Helm CIDER REPL source."
  :group 'helm-cider-repl
  :type '(alist :key-type string :value-type function))

(defcustom helm-cider-repl-follow nil
  "If true, turn on `helm-follow-mode' for CIDER REPL entries."
  :group 'helm-cider-repl
  :type 'boolean)


;;;; CIDER REPL History

(defvar helm-cider-repl-history-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map helm-map)
    (define-key map (kbd "M-D") (lambda ()
                                  (interactive)
                                  (with-helm-alive-p
                                    (helm-exit-and-execute-action 'helm-cider-repl-history-delete))))
    map)
  "Keymap for `helm-cider-repl-history'.")

(defun helm-cider-repl--history-candidates ()
  "Candidates for Helm CIDER REPL history.

Blank and duplicate candidates are excluded."
  (cl-loop
     for c in (helm-fast-remove-dups cider-repl-input-history :test 'equal)
     unless (string-blank-p c)
     collect c))

(defun helm-cider-repl--history-transformer (candidates _source)
  "Display only the `helm-cider-repl-history-max-lines'
lines of candidate."
  (cl-loop
     for c in candidates
     for m = helm-cider-repl-history-max-lines
     when (get-text-property 0 'read-only c)
     do (set-text-properties 0 (length c) '(read-only nil) c)
     for n = (with-temp-buffer (insert c) (count-lines (point-min) (point-max)))
     if (and (integerp m)
             (> n m 0))
     collect (cons (with-temp-buffer
                     (insert c)
                     (goto-char (point-min))
                     (concat
                      (buffer-substring
                       (point-min)
                       (save-excursion
                         (forward-line helm-cider-repl-history-max-lines)
                         (point)))
                      "[...]"))
                   c)
     ;; Need to collect a cons b/c persistent action is executed on
     ;; unpropertied string otherwise
     ;; See: https://github.com/emacs-helm/helm/blob/v2.4.0/helm.el#L4999
     else collect (cons c c)))

(defun helm-cider-repl--history-preview (candidate)
  "Preview the CIDER REPL history candidate in a temp buffer.

Useful when the candidate longer than `helm-cider-repl-history-max-lines' lines."

  (let ((buf (get-buffer-create "*Helm CIDER REPL History Preview*")))
    (cl-flet ((preview (candidate)
                (switch-to-buffer buf)
                (let ((inhibit-read-only t))
                  (erase-buffer)
                  (insert candidate))))
      (if (and (helm-attr 'previewp)
               (string= candidate (helm-attr 'current-candidate)))
          (progn
            (kill-buffer buf)
            (helm-attrset 'previewp nil))
        (preview candidate)
        (helm-attrset 'previewp t)))
    (helm-attrset 'current-candidate candidate)))

(defun helm-cider-repl--history-source ()
  "Source for Helm CIDER REPL history."
  (helm-build-sync-source "CIDER REPL History"
    :action helm-cider-repl-history-actions
    :candidates (helm-cider-repl--history-candidates)
    :filtered-candidate-transformer #'helm-cider-repl--history-transformer
    :follow (when helm-cider-repl-follow 1)
    :keymap helm-cider-repl-history-map
    :multiline t
    :persistent-action #'helm-cider-repl--history-preview
    :persistent-help "Preview entry"))


;;;; API

;;;###autoload
(defun helm-cider-repl-history-insert (candidate)
  "Insert candidate at the last CIDER REPL prompt.

Existing input at the prompt is cleared.

This function is meant to be one of `helm-cider-repl-history-actions'."
  (goto-char (point-max))
  (cider-repl-kill-input)
  (insert candidate))

;;;###autoload
(defun helm-cider-repl-history-delete (_candidate)
  "Delete marked candidates from `cider-repl-input-history'.

This function is meant to be one of `helm-cider-repl-history-actions'."
  (cl-loop
     for cand in (helm-marked-candidates)
     do (setq cider-repl-input-history
              (delete cand cider-repl-input-history))))

;;;###autoload
(defun helm-cider-repl-history ()
  "Helm interface to CIDER REPL history."
  (interactive)
  (if (null cider-repl-input-history)
      (user-error "No CIDER REPL history")
    (helm :buffer "*Helm CIDER REPL History*"
          :sources (helm-cider-repl--history-source))))


(provide 'helm-cider-repl)

;;; helm-cider-repl.el ends here
