;;; load-bash-alias.el --- Convert bash aliases into eshell ones -*- lexical-binding: t; -*-

;; Copyright (C) 2018-2023 Davide Restivo

;; Author: Davide Restivo <davide.restivo@yahoo.it>
;; Maintainer: Davide Restivo <davide.restivo@yahoo.it>
;; Version: 0.0.3
;; URL: https://github.com/daviderestivo/load-bash-alias
;; Package-Requires: ((emacs "24.1") (seq "2.16"))
;; Keywords: emacs bash eshell alias

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.


;;; Commentary:

;; Convert bash aliases into eshell ones

(require 'seq)

;;; Code:

(defgroup load-bash-alias nil
  "Convert bash aliases into eshell ones"
  :group 'eshell)

(defcustom load-bash-alias-bashrc-file "~/.bashrc"
  "Bash aliases file."
  :type 'string)

(defcustom load-bash-alias-additional-aliases-files nil
  "Additional bash aliases files list. For example:
   (\"~/.bashrc_personal\")"
  :type 'list)

(defcustom load-bash-alias-exclude-aliases-regexp "^alias magit\\|^alias oc"
  "Regexp to exclude Bash aliases to be converted into eshell ones."
  :type 'string)

(defun load-bash-alias-read-bash-file (BASHFILE)
  "Read BASHFILE and return a list of lines after merging continuation lines."
  (with-temp-buffer
    (progn
      (insert-file-contents BASHFILE)
      ;; Merge continuation lines into single line. The below regexp
      ;; matches a '\' at the end of a line followed by one or
      ;; multiple TAB or spaces.
      (while (re-search-forward "\\\\[ \t]*\n" nil t)
        (replace-match ""))
      ;; Return a list of lines
      (split-string (buffer-string) "\n" t))))

(defun load-bash-alias-extract-bash-aliases (LIST)
  "Take a LIST of strings and extract Bash aliases from it."
  (seq-filter (lambda (element)
	        (and
	         (string-match-p "alias" element)
	         (not (string-match-p "^#" element))
                 (not (string-match-p load-bash-alias-exclude-aliases-regexp element))))
	      LIST))

(defun load-bash-alias-into-eshell ()
  "Convert bash aliases into eshell ones.

Take the file specified in `load-bash-alias-bashrc-file', trims it to a
list of alias commands, and inserts them as eshell aliases."
  (interactive)
  (dolist (file (append (list load-bash-alias-bashrc-file) load-bash-alias-additional-aliases-files))
    (if (file-exists-p file)
        (progn
          (eshell)
          (dolist
              (element
               (load-bash-alias-extract-bash-aliases (load-bash-alias-read-bash-file file)))
            ;; First collaps multiple whitespaces and tabs into a single
            ;; whitespace then convert a bash alias into an eshell one
            ;; by removing the "=" sign.
            (let* ((trimmed (replace-regexp-in-string "=\\|[ \t]+" " " element))
                   (all-but-last-char (substring trimmed 0 -1))
                   (last-char (substring trimmed -1 nil))
                   (enhanced (concat all-but-last-char " $*" last-char)))
              (goto-char (point-max))
              (insert enhanced)
              (eshell-send-input))))
      (message (concat "The aliases file: " file " does not exists!")))))

;; `load-bash-alias-load-bash-aliases-into-eshell' has been marked as
;; obsolete and might be removed in the near future. Please use
;; `load-bash-alias-into-eshell' instead.
(define-obsolete-function-alias
  'load-bash-alias-load-bash-aliases-into-eshell
  'load-bash-alias-into-eshell "2018-12-19")

(provide 'load-bash-alias)
;;; load-bash-alias.el ends here
