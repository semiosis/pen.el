;;; license-snippets.el --- LICENSE templates for yasnippet -*- lexical-binding: t -*-

;; Author: Seong Yong-ju <sei40kr@gmail.com>
;; Version: 1.0.0
;; URL: https://github.com/sei40kr/license-snippets
;; Package-Requires: ((emacs "26") (yasnippet "0.8.0"))
;; Keywords: tools

;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; LICENSE templates for yasnippet

;;; Code:

(require 'yasnippet)

(defconst license-snippets-dir
  (let* ((basedir (file-name-directory
                   (cond (load-in-progress load-file-name)
                         ((and (boundp 'byte-compile-current-file) byte-compile-current-file)
                          byte-compile-current-file)
                         (:else (buffer-file-name))))))
    (expand-file-name "snippets" basedir)))

;;;###autoload
(defun license-snippets-init ()
  "Load the `license-snippets' snippets directory."
  (add-to-list 'yas-snippet-dirs 'license-snippets-dir t)
  (yas-load-directory license-snippets-dir t))

(provide 'license-snippets)

;;; license-snippets.el ends here
