;;; itail.el --- An interactive tail mode

;; Copyright (C) 2012-2017 @re5et

;; Author: atom smith
;; URL: https://github.com/re5et/itail
;; Created: 26 Dec 2012
;; Version: 0.0.8
;; Keywords: tail

;; This file is NOT part of GNU Emacs.

;; This is free software; you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free
;; Software Foundation; either version 3, or (at your option) any later
;; version.

;; This file is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with Emacs; see the file COPYING, or type `C-h C-c'. If not,
;; write to the Free Software Foundation at this address:

;; Free Software Foundation
;; 51 Franklin Street, Fifth Floor
;; Boston, MA 02110-1301
;; USA

;;; Commentary:

;; An interactive tail mode that allows you to filter the tail with
;; unix pipes and highlight the contents of the tailed file. Works
;; locally or on remote files using tramp.

;;; Usage:

;; (require 'itail)
;; M-x itail RET /file/to/tail

;;; Code:

(eval-when-compile
  (require 'dired nil :noerror)
  (require 'ffap nil :noerror))

(defvar itail-keymap
  (let ((itail-map (make-sparse-keymap)))
    (define-key itail-map (kbd "C-c c") 'itail-clear)
    (define-key itail-map (kbd "C-c f") 'itail-toggle-filter)
    (define-key itail-map (kbd "C-c g") 'itail-add-grep)
    (define-key itail-map (kbd "C-c -") 'itail-remove-last-filter)
    (define-key itail-map (kbd "C-c s") 'itail-show-filters)
    (define-key itail-map (kbd "C-c r") 'itail-remove-all-filters)
    (define-key itail-map (kbd "C-c h") 'itail-highlight)
    (define-key itail-map (kbd "C-c u") 'itail-unhighlight)
    (define-key itail-map (kbd "C-c C-k") 'itail-reload)
    (define-key itail-map (kbd "C-c C-c") 'itail-kill)
    itail-map)
  "The keymap used in `itail-mode' buffers.")

(defvar itail-filters ()
  "List of filters to process the output through. Should be
an sh compatible shell command like 'grep ERROR'")
(make-variable-buffer-local 'itail-filters)

(defvar itail-file nil
  "List of filters to process the output through. Should be
an sh compatible shell command like 'grep ERROR'")
(make-variable-buffer-local 'itail-filters)

(defvar itail-original-mode-line-format mode-line-format)

(defgroup itail nil
  "Interactive tail."
  :group 'itail)

(defcustom itail-lines
  nil
  "Number of line to start output with when opening tail.
If positive or zero, count from the beginning of file.
If negative, count from the end of file."
  :type '(choice (const         :tag "Default"      :value nil)
                 (function-item :tag "Screen Lines" :value (lambda ()
                                                             (- (count-screen-lines (window-start)
                                                                                    (window-end)))))
                 (function      :tag "Dynamic Lines")
                 (integer       :tag "Static Lines"))
  :group 'itail)

(defcustom itail-highlight-list
  '(("Error" . hi-red-b)
    ("GET\\|POST\\|DELETE\\|PUT" . hi-green-b)
    ("[0-9]\\{1,3\\}\\.[0-9]\\{1,3\\}\\.[0-9]\\{1,3\\}\\.[0-9]\\{1,3\\}" . font-lock-string-face))
  "Regexp to highlight in itail-mode"
  :type '(repeat (cons (regexp :tag "Regexp Match")
                       (symbol :tag "Highlight Face")))
  :group 'itail)

(defcustom itail-fancy-mode-line
  nil
  "Non-nil means use the itail fancy mode line."
  :type 'boolean
  :group 'itail)

(defcustom itail-open-fn
  'pop-to-buffer
  "Function to use when opening tail."
  :type 'function
  :group 'itail)

(define-minor-mode itail-mode
  "Tail a local or remote (using tramp) file with
nice bindings for interacting with a tail like
clearing and filtering

\\{itail-keymap}"
  nil
  " itail"
  :keymap itail-keymap)

;;;###autoload
(defun itail (file &optional lines)
  "Tail file FILE in itail mode.  Supports remote tailing through tramp "
  (interactive (list (let* ((file (or (and (eq major-mode 'dired-mode)
                                           (dired-get-filename nil :no-error-if-not-filep))
                                      (when (require 'ffap nil :noerror)
                                        (ffap-file-at-point))))
                            (dir (unless (zerop (length file))
                                   (and (file-directory-p file)
                                        (file-name-as-directory file))))
                            (file (unless (zerop (length file))
                                    (file-relative-name file))))
                       (read-file-name (if (and (null dir) file)
                                           (format "Tail file (%s): " file)
                                         "Tail file: ")
                                       dir
                                       (and (null dir) file)))
                     current-prefix-arg))
  (let* ((file (expand-file-name file))
         (buffer-name (concat "itail: " file))
         (file (file-relative-name file))
         (default-directory (or (and (file-name-absolute-p file)
                                     (or (file-remote-p file)
                                         (and (file-remote-p default-directory)
                                              "~/")))
                                default-directory))
         (file (or (file-remote-p file 'localname) file))
         (lines (or lines (if (functionp itail-lines) (funcall itail-lines) itail-lines))))
    (apply #'make-comint buffer-name "tail" nil "-F" file (when (numberp lines)
                                                            (list "-n" (format "%+d" lines))))
    (funcall itail-open-fn (concat "*" buffer-name "*")))
  (ansi-color-for-comint-mode-on)
  (add-hook 'comint-preoutput-filter-functions 'itail-output-filter)
  (goto-char (point-max))
  (setq buffer-read-only t)
  (setq itail-file file)
  (setq itail-filters ())
  (itail-mode-line)
  (itail-mode))

(defun itail-reload ()
  "Kill the current tail operation, and reload using the same file.
Very useful when the tail has had a great deal of information dumped
to it and emacs can not keep up"
  (interactive)
  (let ((inhibit-read-only t))
    (insert (concat "reloading " (buffer-name (current-buffer)) "\n")))
  (itail-kill-with-process-sentinel 'itail-internal-reload))

(defun itail-internal-reload (&rest ignored)
  (itail itail-file)
  (comint-show-maximum-output))

(defun itail-kill ()
  "Kill the tail process and close the buffer"
  (interactive)
  (when (yes-or-no-p "Really kill itail? ")
    (let ((inhibit-read-only t))
      (insert (concat "killing " (buffer-name (current-buffer)) "\n"))
      (itail-kill-with-process-sentinel 'itail-internal-kill))))

(defun itail-internal-kill (&rest ignored)
  (kill-buffer (current-buffer)))

(defun itail-kill-with-process-sentinel (sentinel)
  (let ((process (get-buffer-process (current-buffer))))
    (if process
        (progn
          (set-process-sentinel process sentinel)
          (comint-quit-subjob))
      (funcall sentinel))))

(defun itail-clear ()
  "Clear out the tail buffer"
  (interactive)
  (let ((inhibit-read-only t))
    (delete-region (point-min) (point-max))))

(defun itail-toggle-filter (filter)
  "Add or remove FILTER to filter pipeline. For example, a filter of
'grep ERROR' will only show lines that contain the string ERROR.
Filters the result of the tail is piped to each filter in sequence."
  (interactive (list (read-string "toggle filter: ")))
  (if (member filter itail-filters)
      (itail-remove-filter filter)
    (itail-add-filter filter)))

(defun itail-add-grep (grep-args)
  "Convenience method to add a grep filter.  A filter will be added
in the format: 'grep GREP-ARGS'."
  (interactive (list (read-string "add grep: ")))
  (itail-add-filter (concat "grep " grep-args)))

(defun itail-add-filter (filter)
  "Add specified FILTER to the filter pipeline."
  (interactive (list (read-string "add filter: ")))
  (add-to-list 'itail-filters filter)
  (message (concat "added filter: " filter))
  (itail-mode-line))

(defun itail-remove-filter (filter)
  "Remove specified FILTER from the filter pipeline if it exists."
  (interactive (list (read-string "remove filter: ")))
  (setq itail-filters (delete filter itail-filters))
  (message (concat "removed filter: " filter))
  (itail-mode-line))

(defun itail-remove-last-filter ()
  "Pop the last filter off of the end of the filter pipeline."
  (interactive)
  (itail-remove-filter (car itail-filters)))

(defun itail-show-filters ()
  "Show the current filter pipeline"
  (interactive)
  (if itail-filters
      (message
       (concat
        "current filters: "
        (itail-filter-pipeline)))
    (message "There are currently no filters.")))

(defun itail-highlight ()
  "Turn on itail highlighting. Relys on itail-highlight-list
for specification on what matches to highlight what color."
  (interactive)
  (dolist (pair itail-highlight-list)
    (highlight-phrase (car pair) (cdr pair))))

(defun itail-unhighlight ()
  "Turns off itail highlighting."
  (interactive)
  (dolist (pair itail-highlight-list)
    (unhighlight-regexp (car pair))))

(defun itail-remove-all-filters ()
  "Remove all filters from the filter pipeline."
  (interactive)
  (setq itail-filters ())
  (itail-mode-line)
  (message "all filters removed."))

(defun itail-filter-pipeline ()
  "Internal use, returns a generated filter pipeline"
  (if itail-filters
      (mapconcat 'identity (reverse itail-filters) " | ")))

(defun itail-output-filter (output)
  "Comint output filter for itail-mode. Filters
output through the filter pipeline."
  (if itail-filters
      (let ((shell-file-name "/bin/sh"))
        (shell-command-to-string
         (format "echo %s | %s"
                 (shell-quote-argument output)
                 (itail-filter-pipeline))))
    output))

(defun itail-mode-line ()
  "Mode line to show the tail command in use including the filters."
  (if itail-fancy-mode-line
      (setq
       mode-line-format
       `(" tail -F "
         ,itail-file
         ,(if (itail-filter-pipeline)
              (concat " | " (itail-filter-pipeline)))))))

(provide 'itail)
;;; itail.el ends here
