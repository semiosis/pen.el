;;; elfeed-score-log.el --- Logging facility for `elfeed-score'  -*- lexical-binding: t; -*-

;; Copyright (C) 2021-2023 Michael Herstine <sp1ff@pobox.com>

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

;; `elfeed-score' logs its actions; this package governs that
;; functionality.

;;; Code:

(require 'cl-lib)

(defface elfeed-score-date-face
  '((t :inherit font-lock-type-face))
  "Face for showing the date in the elfeed score buffer."
  :group 'elfeed-score)

(defface elfeed-score-error-level-face
  '((t :foreground "red"))
  "Face for showing the `error' log level in the elfeed score buffer."
  :group 'elfeed-score)

(defface elfeed-score-warn-level-face
  '((t :foreground "goldenrod"))
  "Face for showing the `warn' log level in the elfeed score buffer."
  :group 'elfeed-score)

(defface elfeed-score-info-level-face
  '((t :foreground "deep sky blue"))
  "Face for showing the `info' log level in the elfeed score buffer."
  :group 'elfeed-score)

(defface elfeed-score-debug-level-face
  '((t :foreground "magenta2"))
  "Face for showing the `debug' log level in the elfeed score buffer."
  :group 'elfeed-score)

(defvar elfeed-score-log-buffer-name "*elfeed-score*"
  "Name of buffer used for logging `elfeed-score' events.")

(defvar elfeed-score-log-level 'warn
  "Level at which `elfeed-score' shall log; may be one of 'debug, 'info, 'warn, or 'error.")

(defvar elfeed-score-log-max-buffer-size 750
  "Maximum length (in lines) of the log buffer.  nil means unlimited.")

(defun elfeed-score-log--level-number (level)
  "Return a numeric value for log level LEVEL."
  (cl-case level
    (debug -10)
    (info 0)
    (warn 10)
    (error 20)
    (otherwise 0)))

(defun elfeed-score-log-buffer ()
  "Return the `elfeed-score' log buffer, creating it if needed."
  (let ((buffer (get-buffer elfeed-score-log-buffer-name)))
    (if buffer
        buffer
      (with-current-buffer (generate-new-buffer elfeed-score-log-buffer-name)
        (special-mode)
        (current-buffer)))))

(defun elfeed-score-log--truncate-log-buffer ()
  "Truncate the log buffer to `elfeed-score-log-max-buffer-size lines."
  (with-current-buffer (elfeed-score-log-buffer)
    (goto-char (point-max))
    (forward-line (- elfeed-score-log-max-buffer-size))
    (beginning-of-line)
    (let ((inhibit-read-only t))
      (delete-region (point-min) (point)))))

(defun elfeed-score-log (level fmt &rest objects)
  "Write a log message FMT at level LEVEL to the `elfeed-score' log buffer."
  (when (>= (elfeed-score-log--level-number level)
            (elfeed-score-log--level-number elfeed-score-log-level))
    (let ((inhibit-read-only t)
          (log-level-face
           (cl-case level
             (debug 'elfeed-score-debug-level-face)
             (info 'elfeed-score-info-level-face)
             (warn 'elfeed-score-warn-level-face)
             (error 'elfeed-score-error-level-face)
             (otherwise 'elfeed-score-debug-level-face))))
      (with-current-buffer (elfeed-score-log-buffer)
        (goto-char (point-max))
        (insert
         (format
          (concat "[" (propertize "%s" 'face 'elfeed-score-date-face) "] "
                  "[" (propertize "%s" 'face log-level-face) "]: "
                  "%s\n")
          (format-time-string "%Y-%m-%d %H:%M:%S")
          level
          (apply #'format fmt objects)))
        (if (and elfeed-score-log-max-buffer-size
                 (> (line-number-at-pos)
                    elfeed-score-log-max-buffer-size))
            (elfeed-score-log--truncate-log-buffer))))))

(provide 'elfeed-score-log)
;;; elfeed-score-log.el ends here
