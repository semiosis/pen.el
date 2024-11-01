;;; counsel-test-core.el --- counsel-test: Core definitions -*- lexical-binding: t -*-

;; Copyright (c) 2019 Konstantin Sorokin (GNU/GPL Licence)

;; Authors: Konstantin Sorokin <sorokin.kc@gmail.com>

;; This file is NOT part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.
;; If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:
(require 's)
(require 'seq)
(require 'subr-x)
(require 'ivy)

(defvar counsel-test-dir nil
  "Directory to run tests in.

It is recommended to set this variable via dir-locals.el.")

(defun counsel-test--process-lines (program &rest args)
  "Modified version of  `process-lines'.

This function is similar to `process-lines' except that it stores
its output in a dedicated buffer based on the program name
*counsel-test-<program-name>-log*.  If the program execution
fails, the command output is saved for inspection.  Otherwise, the
buffer is killed.

PROGRAM is a the name of program to run (passed to `call-process').
ARGS are the arguments for the given program."
  (let ((log-buffer (get-buffer-create
                     (format "*counsel-test-%s-log*" program))))
    (with-current-buffer log-buffer
      (erase-buffer) ;; clear the contents in case it already exists
      (let ((status (apply 'call-process program nil (current-buffer)
                           nil args)))

        (unless (eq status 0)
          (error "%s exited with status %s.  View log in '%s'"
                 program status (buffer-name)))

        (let ((lines (seq-map 's-trim (s-lines (buffer-string)))))
          ;; Remove the discovery log buffer on success
          (kill-buffer)
          lines)))))

(defun counsel-test--call-cmd (program &optional env &rest args)
  "Execute the given PROGRAM in modifed environment.

ENV is a list of extra envirnment variables to include for PROGRAM execution.
ARGS are the arguments for the given program.

Returns a list of strings representing the trimmed command output."
  (let ((process-environment (append env process-environment)))
    (apply 'counsel-test--process-lines program args)))

(defun counsel-test--env-to-str (env)
  "Transform the given list of environment variables ENV to string.

ENV is a list of strings representing environment variables and their values
similar to the `process-environment' variable format.

The return value is a string 'env ENV1=VALUE1 ENV2=VALUE2 ' (note
the extra space at the end).  If the given list ENV is nil, return
an empty string."
  (let ((joined-vars (s-join " " env)))
    (if (string-empty-p joined-vars)
        "" (format "env %s " joined-vars))))

(defun counsel-test--get-dir (&optional force-read-dir)
  "Determine the directory to run the tests in.

OPTIONAL FORCE-READ-DIR whether to force prompt user for the test directory"
  (let ((test-dir (if (or force-read-dir (not counsel-test-dir))
                      (read-directory-name "Select test dir: ")
                    counsel-test-dir)))
    (s-append "/" (s-chop-suffix "/" test-dir))))

(defun counsel-test (discover-f create-cmd-f caller &optional arg)
  "This function is a generic entry-point for external testing frameworks.

One should specify two functions:

DISCOVER-F is a function that extracts a list of tests (possibly by running
external executable) and gives them as a list of candidates for `ivy-read'.

CREATE-CMD-F is a function that accepts the list of strings (selections from
`ivy-read' based on DISCOVER-F) and creates an external command to run tests in
compile.

CALLER is caller argument for `ivy-read'.

OPTIONAL ARG is forwarded to `counsel-test--get-dir' to force directory
read."
  (let* ((default-directory (counsel-test--get-dir arg))
         (multi-action (lambda (x) (compile (funcall create-cmd-f x))))
         (single-action (lambda (x) (funcall multi-action (list x)))))
    (ivy-read "Select tests: " (funcall discover-f)
              :require-match t
              :sort t
              :action single-action
              :multi-action multi-action
              :caller caller)))


(provide 'counsel-test-core)
;;; counsel-test-core.el ends here


