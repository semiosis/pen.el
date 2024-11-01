;;; ob-swift.el --- org-babel functions for swift evaluation

;; Copyright (C) 2015 Feng Zhou

;; Author: Feng Zhou <zf.pascal@gmail.com>
;; URL: http://github.com/zweifisch/ob-swift
;; Package-Version: 20170921.1325
;; Package-Commit: ed478ddbbe41ce5373efde06b4dd0c3663c9055f
;; Keywords: org babel swift
;; Version: 0.0.1
;; Created: 4th Dec 2015
;; Package-Requires: ((org "8"))

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

;;; Commentary:
;;
;; org-babel functions for swift evaluation
;;

;;; Code:
(require 'ob)

(defvar ob-swift-process-output "")

(defvar ob-swift-eoe "ob-swift-eoe")

(defun org-babel-execute:swift (body params)
  (let ((session (cdr (assoc :session params))))
    (if (string= "none" session)
        (ob-swift--eval body)
      (ob-swift--ensure-session session)
      (ob-swift--eval-in-repl session body))))

(defun ob-swift--eval (body)
  (with-temp-buffer
    (insert body)
    (shell-command-on-region (point-min) (point-max) "swift -" nil 't)
    (buffer-string)))

(defun ob-swift--ensure-session (session)
  (let ((name (format "*ob-swift-%s*" session)))
    (unless (and (get-process name)
                 (process-live-p (get-process name)))
      (let ((process (with-current-buffer (get-buffer-create name)
                       (start-process name name "swift"))))
        (set-process-filter process 'ob-swift--process-filter)
        (ob-swift--wait "Welcome to Swift")))))

(defun ob-swift--process-filter (process output)
  (setq ob-swift-process-output (concat ob-swift-process-output output)))

(defun ob-swift--wait (pattern)
  (while (not (string-match-p pattern ob-swift-process-output))
    (sit-for 0.5)))

(defun ob-swift--eval-in-repl (session body)
  (let ((name (format "*ob-swift-%s*" session)))
    (setq ob-swift-process-output "")
    (process-send-string name (format "%s\n\"%s\"\n" body ob-swift-eoe))
    (accept-process-output (get-process name) nil nil 1)
    (ob-swift--wait ob-swift-eoe)
    (replace-regexp-in-string
     (format "^\\$R[0-9]+: String = \"%s\"\n" ob-swift-eoe) ""
     (replace-regexp-in-string
      "^\\([0-9]+\\. \\)+\\([0-9]+> \\)*" ""
      (replace-regexp-in-string
       "^\\([0-9]+> \\)+" ""
       ob-swift-process-output)))))

(provide 'ob-swift)
;;; ob-swift.el ends here
