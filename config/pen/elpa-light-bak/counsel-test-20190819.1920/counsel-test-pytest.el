;;; counsel-test-pytest.el --- counsel-test: Pytest integration -*- lexical-binding: t -*-

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

(defvar counsel-test-pytest-cmd "pytest"
  "Command used to invoke pytest.")

(defvar counsel-test-pytest-env nil
  "Environment to use with invocation of `counsel-test-pytest-cmd'.

This may be handy if you need to modify PYTHONPATH before starting pytest.")

(defun counsel-test-pytest--cut-params (test-str)
  "Remove parameter part(if any) from the pytest test string TEST-STR.

TEST-STR is a string from pytest.  Generally it looks like this:
    path/to/testing_module.py::TestClass::test_name
However, pytest tests can be parameterized, in which case their name is
enhanced with the parameter value, e.g.:
    path/to/testing_module.py::TestClass::test_name[param_value].

Pytest does not support executing tests with concrete parameters, that is why it
is necessary to cut them."
  (substring test-str 0 (s-index-of "[" test-str)))

(defun counsel-test-pytest--discover ()
  "Run pytest to get the available test candidates.

NOTE: currently, pytest does not support executing tests with concrete
parameter values, that is why result contains these test name without the
parameter part."
  (let* ((candidates (counsel-test--call-cmd counsel-test-pytest-cmd
                                             counsel-test-pytest-env
                                             "--disable-pytest-warnings"
                                             "--collect-only" "-q")))
    (seq-uniq (seq-map 'counsel-test-pytest--cut-params
                       ;; FIXME: this is actually a hack, even with quiet option
                       ;; set, pytest still prints status line separated with
                       ;; an empty one. Drop both.
                       (butlast candidates 2)))))

(defun counsel-test-pytest--create-cmd (selections)
  "Create pytest command to run the selected candidates.

SELECTIONS is a list of selected strings from `counsel-test-pytest--discover'"
  (format "%s%s %s" (counsel-test--env-to-str counsel-test-pytest-env)
          counsel-test-pytest-cmd (s-join " " selections)))

;;;###autoload
(defun counsel-test-pytest (arg)
  "Browse and execute pytest tests.

If the value of `counsel-test-dir' is not set (e.g. nil) prompt user for the
pytest directory.

With a prefix argument ARG also force prompt user for this directory."
  (interactive "P")

  (counsel-test 'counsel-test-pytest--discover
                'counsel-test-pytest--create-cmd
                'counsel-test-pytest
                arg))

(provide 'counsel-test-pytest)
;;; counsel-test-pytest.el ends here
