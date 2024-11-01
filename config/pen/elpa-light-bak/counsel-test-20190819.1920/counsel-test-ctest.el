;;; counsel-test-ctest.el --- counsel-test: Integration with ctest -*- lexical-binding: t -*-

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
(require 'counsel-test-core)

(defvar counsel-test-ctest-cmd "ctest"
  "Command used to invoke ctest.")

(defvar counsel-test-ctest-env '("CLICOLOR_FORCE=1" "CTEST_OUTPUT_ON_FAILURE=1")
  "Environment variables for tests.

It is recommended to set this variable via dir-locals.el.")

(defun counsel-test-ctest--discover ()
  "Run ctest to get the available test candidates."
  (let* ((test-re "^Test[[:space:]]*#"))
    (seq-filter (lambda(s)
                  (s-match test-re s))
                (counsel-test--call-cmd counsel-test-ctest-cmd
                                        nil "-N"))))

(defun counsel-test-ctest--num-from-str (s)
  "Extract number from the string representing test.

S is a single string representing test from the output of ctest
-N, e.g Test #2: MyTest"
  (string-to-number (cadr (s-match "#\\([[:digit:]]+\\)" s))))

(defun counsel-test-ctest--nums-from-strs (strs)
  "Extract numbers from strings representing tests.

STRS is a list of test strings from the output of ctest -N"
  (seq-map 'counsel-test-ctest--num-from-str strs))

(defun counsel-test-ctest--create-cmd (selections)
  "Create ctest command to run the selected candidates.

SELECTIONS is a list of selected strings from `counsel-test-ctest--discover'"
  (let* ((environment (counsel-test--env-to-str counsel-test-ctest-env))
         (test-nums (counsel-test-ctest--nums-from-strs selections))
         (test-selection-str (s-join ","
                                     (seq-map (lambda(n)
                                                (format "%d,%d" n n))
                                              test-nums))))
    (format "%s%s -I %s" environment counsel-test-ctest-cmd test-selection-str)))

;;;###autoload
(defun counsel-test-ctest (arg)
  "Browse and execute ctest tests.

If the value of `counsel-test-dir' is not set (e.g. nil) prompt user for the
ctest directory.

With a prefix argument ARG also force prompt user for this directory."
  (interactive "P")

  (unless (executable-find counsel-test-ctest-cmd)
    (error "Command '%s' not found in path" counsel-test-ctest-cmd))

  (counsel-test 'counsel-test-ctest--discover
                'counsel-test-ctest--create-cmd
                'counsel-test-ctest
                arg))

(provide 'counsel-test-ctest)
;;; counsel-test-ctest.el ends here
