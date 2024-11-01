;;; ob-restclient.el --- org-babel functions for restclient-mode

;; Copyright (C) Alf Lervåg

;; Author: Alf Lervåg
;; Keywords: literate programming, reproducible research
;; Package-Version: 20210718.2008
;; Package-Commit: bfbc4d8e8a348c140f9328542daf5d979f0993e2
;; Homepage: https://github.com/alf/ob-restclient.el
;; Version: 0.02
;; Package-Requires: ((restclient "0"))

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
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
;; This is a very simple first iteration at integrating restclient.el
;; and org-mode.

;;; Requirements:
;; restclient.el

;;; Code:
(require 'ob)
(require 'ob-ref)
(require 'ob-comint)
(require 'ob-eval)
(require 'restclient)

(defvar org-babel-default-header-args:restclient
  `((:results . "raw"))
  "Default arguments for evaluating a restclient block.")

;;;###autoload
(defun org-babel-execute:restclient (body params)
  "Execute a block of Restclient code with org-babel.
This function is called by `org-babel-execute-src-block'"
  (message "executing Restclient source code block")
  (with-temp-buffer
    (let ((results-buffer (current-buffer))
          (restclient-same-buffer-response t)
          (restclient-same-buffer-response-name (buffer-name))
          (display-buffer-alist
           (cons
            '("\\*temp\\*" display-buffer-no-window (allow-no-window . t))
            display-buffer-alist)))

      (insert (buffer-name))
      (with-temp-buffer
        (dolist (p params)
          (let ((key (car p))
                (value (cdr p)))
            (when (eql key :var)
              (insert (format ":%s = <<\n%s\n#\n" (car value) (cdr value))))))
        (insert body)
	(goto-char (point-min))
	(delete-trailing-whitespace)
	(goto-char (point-min))
        (restclient-http-parse-current-and-do
         'restclient-http-do (org-babel-restclient--raw-payload-p params) t))

      (while restclient-within-call
        (sleep-for 0.05))

      (goto-char (point-min))
      (when (search-forward (buffer-name) nil t)
        (error "Restclient encountered an error"))

      (when (or (org-babel-restclient--return-pure-payload-result-p params)
                (assq :noheaders params))
        (org-babel-restclient--hide-headers))

      (when (not (org-babel-restclient--return-pure-payload-result-p params))
        (org-babel-restclient--wrap-result))
      (buffer-string))))

(defun org-babel-restclient--wrap-result ()
  "Wrap the contents of the buffer in an `org-mode' src block."
  (let ((mode-name (substring (symbol-name major-mode) 0 -5)))
    (insert (format "#+BEGIN_SRC %s\n" mode-name))
    (goto-char (point-max))
    (insert "#+END_SRC\n")))

(defun org-babel-restclient--hide-headers ()
  "Just return the payload."
  (let ((comments-start
         (save-excursion
           (goto-char (point-max))
           (while (comment-only-p (line-beginning-position) (line-end-position))
             (forward-line -1))
           ;; Include the last line as well
           (forward-line)
           (point))))
    (narrow-to-region (point-min) comments-start)))


(defun org-babel-restclient--return-pure-payload-result-p (params)
  "Return `t' if the `:results' key in PARAMS contains `value' or `table'."
  (let ((result-type (cdr (assoc :results params))))
    (when result-type
      (string-match "value\\|table" result-type))))


(defun org-babel-restclient--raw-payload-p (params)
  "Return t if the `:results' key in PARAMS contain `file'."
  (let ((result-type (cdr (assoc :results params))))
    (when result-type
      (string-match "file" result-type))))

(provide 'ob-restclient)
;;; ob-restclient.el ends here
