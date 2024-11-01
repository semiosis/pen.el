;;; helm-cider-history.el --- Helm interface for cider history
;;
;; Copyright (C) 2015 Andreas Klein
;;
;; Author: Andreas Klein <git@kungi.org>
;; URL: https://github.com/Kungi/helm-cider-history
;; Package-Version: 20150719.2120
;; Package-Commit: c391fcb2e162a02001605a0b9449783575a831fd
;; Created: 19.07.2015
;; Keywords: convenience
;; Version: 0.0.1
;; Package-Requires: ((helm "1.4.0") (cider "0.9.0"))
;;
;; This file is NOT part of GNU Emacs.
;;
;;; License:
;;
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
;;
;;; Commentary:
;;
;; helm-cider-history integraties cider-input-history with helm
;;
;;; Code:

(require 'helm)

;;;###autoload
(defun helm-cider-history ()
  "Show `cider-input-history` in `helm`."
  (interactive)
  (helm :sources (helm-build-sync-source "Helm Cider History"
                   :candidates cider-repl-input-history
                   :action '(("Yank" . (lambda (candidate) (insert candidate))))
                   :persistent-action (lambda (candidate) (ignore))
                   :persistent-help "DoNothing"
                   :multiline t)
        :buffer "*helm cider history*"
        :resume 'noresume))

(provide 'helm-cider-history)

;;; helm-cider-history.el ends here
