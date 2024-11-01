;;; test-ob-rust.el --- tests for ob-rust.el

;; This file is not part of GNU Emacs.

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

;;; Code:
(require 'ert)
(require 'org)
(require 'org-id)
(require 'ob-rust)

(defconst ob-rust-test-dir
  (expand-file-name (file-name-directory (or load-file-name buffer-file-name))))

(defconst org-id-locations-file
  (expand-file-name ".test-org-id-locations" ob-rust-test-dir))

(defun ob-rust-test-update-id-locations ()
  (let ((files (directory-files
                ob-rust-test-dir 'full
                "^\\([^.]\\|\\.\\([^.]\\|\\..\\)\\).*\\.org$")))
    (org-id-update-id-locations files)))

(defmacro org-test-at-id (id &rest body)
  "Run body after placing the point in the headline identified by ID."
  (declare (indent 1))
  `(let* ((id-location (org-id-find ,id))
	  (id-file (car id-location))
	  (visited-p (get-file-buffer id-file))
	  to-be-removed)
     (unwind-protect
	 (save-window-excursion
	   (save-match-data
	     (org-id-goto ,id)
	     (setq to-be-removed (current-buffer))
	     (condition-case nil
		 (progn
		   (org-show-subtree)
		   (org-show-block-all))
	       (error nil))
	     (save-restriction ,@body)))
       (unless (or visited-p (not to-be-removed))
	 (kill-buffer to-be-removed)))))
(def-edebug-spec org-test-at-id (form body))

(ert-deftest ob-rust/assert ()
  (should t))

(ert-deftest ob-rust/basic ()
  "Test the usage of string variables."
  (let (org-confirm-babel-evaluate)
    (ob-rust-test-update-id-locations)
    (org-test-at-id "5947c402da07c7aca0000001"
      (org-babel-next-src-block)
      (should (string-equal "hello,ob-rust" (org-babel-execute-src-block))))))

(ert-deftest ob-rust/wrap-main ()
  "Test wrapping Rust code block in main function."
  (let (org-confirm-babel-evaluate)
    (ob-rust-test-update-id-locations)
    (org-test-at-id "5947c402da07c7aca0000002"
      (org-babel-next-src-block)
      (should (string-equal "hello,ob-rust" (org-babel-execute-src-block))))))

(provide 'ob-rust-test)
