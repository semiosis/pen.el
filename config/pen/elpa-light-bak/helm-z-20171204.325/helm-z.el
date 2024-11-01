;;; helm-z.el --- Show z directory list with helm.el support.

;; Copyright (C) 2017 by yynozk
;; Author: yynozk <yynozk@gmail.com>
;; URL: https://github.com/yynozk/helm-z
;; Package-Version: 20171204.325
;; Package-Commit: 37212220bebea8b9c238cb1bbacd8332b7f26c03
;; Version: 0.1
;; Package-Requires: ((helm "1.0"))

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

;; This package provides a helm interface for z.

;;; Code:


(require 'helm)
(require 'dired)


;; Check $Z_DATA
(if (not (equal (shell-command "test -e \"$Z_DATA\"") 0))
    (error "$Z_DATA not found."))


(defun helm-z-cd ()
  "Change directory by shell."
  (call-process-shell-command (format "cd %s" (shell-quote-argument (dired-current-directory)))))
(add-hook 'dired-after-readin-hook 'helm-z-cd)


(defvar helm-z-source
  (helm-build-in-buffer-source "z"
    :init (lambda ()
            (helm-init-candidates-in-buffer 'global
              (shell-command-to-string "sort -r -t '|' -k 3,3 $Z_DATA | sed 's/|.*//'")))
    :action '(("Go" . (lambda (candidate) (dired candidate))))))


;;;###autoload
(defun helm-z ()
  "Show z directory list by helm."
  (interactive)
  (helm :sources '(helm-z-source)
        :buffer "*Helm z source*"))


(provide 'helm-z)
;;; helm-z.el ends here
