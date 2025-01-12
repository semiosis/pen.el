;;; path-iterator-test.el --- test for path-iterator.el.  -*-lexical-binding:t-*-

;; Copyright (C) 2015, 2019 Free Software Foundation, Inc.

;; This file is part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Code:
(require 'path-iterator)

(defconst path-iter-root-dir
  (concat
   (file-name-directory (or load-file-name (buffer-file-name)))
   "path-iterator-resources/"))

(defmacro path-iter-deftest (name-suffix path-non-recursive path-recursive expected-dirs &optional ignore-function)
  "Define an ert test for path-iterator.
EXPECTED-DIRS is a list of directory file names; it is compared
with `equal' to a list of the results of running the path
iterator built from PATH-NON-RECURSIVE, PATH-RECURSIVE, IGNORE-FUNCTION."
  (declare (indent defun)
           (debug (symbolp "name-suffix")))
  `(ert-deftest ,(intern (concat "path-iter-test-" (symbol-name name-suffix))) ()
     (path-iter-test-run ,path-non-recursive ,path-recursive ,expected-dirs ,ignore-function)
     ))

(defun path-iter-test-run-1 (iter expected-dirs)
  (let (dir computed-dirs)
    (while (setq dir (path-iter-next iter))
      (push dir computed-dirs))
    (should (null (path-iter-next iter)))
    (setq computed-dirs (nreverse computed-dirs))
    (should (equal computed-dirs expected-dirs))
    ))

(defun path-iter-test-run (path-non-recursive path-recursive expected-dirs ignore-function)
  (let ((iter (make-path-iterator
	       :user-path-non-recursive path-non-recursive
	       :user-path-recursive path-recursive
	       :ignore-function ignore-function)))
    (path-iter-test-run-1 iter expected-dirs)
    (path-iter-restart iter)
    (path-iter-test-run-1 iter expected-dirs)
    ))

(path-iter-deftest recursive
  nil ;; non-recursive
  (list path-iter-root-dir)
  (list
   path-iter-root-dir
   (concat path-iter-root-dir "alice-1/")
   (concat path-iter-root-dir "bob-1/")
   (concat path-iter-root-dir "bob-1/bob-2/")
   (concat path-iter-root-dir "bob-1/bob-3/")
   ))

(path-iter-deftest non-recursive
  (list
   (concat path-iter-root-dir "alice-1/")
   (concat path-iter-root-dir "bob-1/bob-2/")
   (concat path-iter-root-dir "bob-1/bob-3/")
   (concat path-iter-root-dir "bob-1/bob-4/") ;; does not exist
   )
  nil ;; recursive
  (list
   (concat path-iter-root-dir "alice-1/")
   (concat path-iter-root-dir "bob-1/bob-2/")
   (concat path-iter-root-dir "bob-1/bob-3/")
   ))

(path-iter-deftest both
  (list
   (concat path-iter-root-dir "alice-1/"))
  (list
   (concat path-iter-root-dir "bob-1/"))
  (list
   (concat path-iter-root-dir "bob-1/")
   (concat path-iter-root-dir "bob-1/bob-2/")
   (concat path-iter-root-dir "bob-1/bob-3/")
   (concat path-iter-root-dir "alice-1/")
   ))

(path-iter-deftest dup
  (list
   (concat path-iter-root-dir "alice-1/")
   (concat path-iter-root-dir "bob-1/")) ;; non-recursive
  (list
   (concat path-iter-root-dir "bob-1/")) ;; recursive
  (list
   (concat path-iter-root-dir "bob-1/")
   (concat path-iter-root-dir "bob-1/bob-2/")
   (concat path-iter-root-dir "bob-1/bob-3/")
   (concat path-iter-root-dir "alice-1/")
   ))

(defvar path-iter-ignore-bob nil
  "Set during test to change visited directories.")

(defun path-iter-ignore-bob (dir)
  (string-equal path-iter-ignore-bob (file-name-nondirectory dir)))

(ert-deftest path-iter-ignores-restart ()
  (let ((iter
	 (make-path-iterator
	  :user-path-non-recursive nil
	  :user-path-recursive (list path-iter-root-dir)
	  :ignore-function #'path-iter-ignore-bob)))

    (setq path-iter-ignore-bob "bob-2")
    (path-iter-test-run-1
     iter
     (list
      path-iter-root-dir
      (concat path-iter-root-dir "alice-1/")
      (concat path-iter-root-dir "bob-1/")
      (concat path-iter-root-dir "bob-1/bob-3/")
      ))

    (setq path-iter-ignore-bob "bob-3")

    (path-iter-restart iter);; not reset; does not recompute path
    (path-iter-test-run-1
     iter
     (list
      path-iter-root-dir
      (concat path-iter-root-dir "alice-1/")
      (concat path-iter-root-dir "bob-1/")
      (concat path-iter-root-dir "bob-1/bob-3/")
      ))

    (path-iter-reset iter);; recomputes path
    (path-iter-test-run-1
     iter
     (list
      path-iter-root-dir
      (concat path-iter-root-dir "alice-1/")
      (concat path-iter-root-dir "bob-1/")
      (concat path-iter-root-dir "bob-1/bob-2/")
      ))
   ))

(ert-deftest path-iter-ignore-2 ()
  (let ((iter
	 (make-path-iterator
	  :user-path-non-recursive nil
	  :user-path-recursive (list path-iter-root-dir)
	  :ignore-function #'path-iter-ignore-bob)))

    (setq path-iter-ignore-bob "bob-1") ;; has child directories
    (path-iter-test-run-1
     iter
     (list
      path-iter-root-dir
      (concat path-iter-root-dir "alice-1/")
      ))
    ))

(ert-deftest path-iter-truename-nil ()
  (let ((default-directory path-iter-root-dir))
    (should
     (equal
      (path-iter--to-truename
       (list
	nil
	(concat path-iter-root-dir "alice-1/")))
      (list
	path-iter-root-dir
	(concat path-iter-root-dir "alice-1/")))

  )))

(ert-deftest path-iter-all-files ()
  (let ((iter
	 (make-path-iterator
	  :user-path-non-recursive nil
	  :user-path-recursive (list path-iter-root-dir))))

    (should
     (equal
      (path-iter-all-files iter)
      (list
       (concat path-iter-root-dir "bob-1/bob-3/foo-file3.text")
       (concat path-iter-root-dir "bob-1/bob-2/foo-file2.text")
       (concat path-iter-root-dir "alice-1/foo-file1.text")
       (concat path-iter-root-dir "alice-1/bar-file1.text")
       (concat path-iter-root-dir "file-0.text")
       )))
    ))

(provide 'path-iterator-test)
;;; path-iterator.el ends here
