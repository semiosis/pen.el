;;; projectile-speedbar.el --- projectile integration for speedbar

;; Copyright (C) 2014 Anshul Verma

;; Author: Anshul Verma <anshul.verma86@gmail.com>
;; URL: https://github.com/anshulverma/projectile-speedbar
;; Package-Version: 20190807.2010
;; Package-Commit: 93320e467ee78772065e599a5dba94889a77db22
;; Keywords: project, convenience, speedbar, projectile
;; Version: 0.0.1
;; Package-Requires: ((projectile "0.11.0") (sr-speedbar "0"))

;; This file is NOT part of GNU Emacs.

;;; License
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; This package sits on top of speedbar and projectile and provides an
;; easy to use and useful integration between the two.
;;
;; With this package when you switch between projects that work with
;; projectile, speedbar will automatically show the directly listing
;; of that project as well as expand the tree to show the file in the
;; project.
;;
;; Features that are required by this library:
;;
;;  `speedbar' `sr-speedbar' `projectile'
;;
;; To invoke this function manually:
;;
;; `projectile-speedbar-open-current-buffer-in-tree
;;

;;; Installation
;;
;; Copy speedbar-projectile.el to your load-path and add this to ~/.emacs
;;
;;  (require 'projectile-speedbar)
;;

;;; Customize:
;;
;; Sometimes, when I am deep in a project tree, I like to use this shortcut
;; to see full context:
;;
;;  (global-set-key (kbd "M-<f2>") 'projectile-speedbar-open-current-buffer-in-tree)
;;
;; You can also disable the feature completely:
;;
;;  (setq projectile-speedbar-projectile-speedbar-enable nil)

;;; Change log:
;;
;; * 13 June 2014:
;;   * Anshul Verma
;;     * Initial feature with commentary
;;
;; * 13 June 2014
;;   * Anshul Verma
;;     * fix bug "should switch to file buffer after opening a file via projectile-find-file"
;;
;; * 27 June 2014
;;   * Anshul Verma
;;     * add ability to turn projectile speedbar off
;;
;; * 13 January 2015
;;   * Anshul Verma
;;     * fix headers to comply with standards

;;; Acknowledgments
;;
;;    All emacsers ... :)
;;

;;; Bug
;;
;; * Should select the current buffer file in directory listing after project switch
;;

;;; TODO
;;
;; * Find a better way to get project root
;;

;;; Code:

(require 'speedbar)
(require 'sr-speedbar)
(require 'projectile)

(defgroup projectile-speedbar nil
  "Auto refresh speedbar based on projectile."
  :group 'speedbar)

(defcustom projectile-speedbar-enable t
  "Do not auto-refresh speedbar using `projectile-speedbar'.
Set to nil to disable projectile speedbar. Default is t."
  :type 'boolean
  :set (lambda (symbol value)
         (set symbol value))
  :group 'projectile-speedbar)

(defun projectile-speedbar-project-refresh (root-dir)
  "Refresh the context of speedbar based on project root"
  (when (and (not (equal root-dir sr-speedbar-last-refresh-dictionary))
             (not (sr-speedbar-window-p)))
    (setq sr-speedbar-last-refresh-dictionary root-dir))
  (setq default-directory root-dir)
  (speedbar-refresh))

(defun projectile-speedbar-open-current-project-in-speedbar (root-dir)
  "Refresh speedbar to show current project in tree"
  (if (not (sr-speedbar-exist-p))
      (sr-speedbar-toggle))
  (projectile-speedbar-project-refresh root-dir))

(defun projectile-speedbar-expand-line-list (&optional arg)
  (when arg
    (re-search-forward (concat " " (car arg) "$"))
    (speedbar-expand-line (car arg))
    (speedbar-next 1)
    (projectile-speedbar-expand-line-list (cdr arg))))

;;;###autoload
(defun projectile-speedbar-open-current-buffer-in-tree ()
  (interactive)
  (let* ((root-dir (projectile-project-root))
         (original-buffer-file-directory (file-name-directory
                                          (file-truename (buffer-file-name))))
         (relative-buffer-path (car (cdr (split-string original-buffer-file-directory
                                                       (regexp-quote root-dir)))))
         (parents (butlast (split-string relative-buffer-path "/")))
         (original-window (get-buffer-window)))
    (if projectile-speedbar-enable
        (save-excursion
          (projectile-speedbar-open-current-project-in-speedbar root-dir)
          (select-window (get-buffer-window speedbar-buffer))
          (beginning-of-buffer)
          (projectile-speedbar-expand-line-list parents)
          (if (not (eq original-window (get-buffer-window speedbar-buffer)))
              (select-window original-window)
            (other-window 1))))))

;;;###autoload
(defun projectile-speedbar-toggle ()
  (interactive)
  (sr-speedbar-toggle)
  (if (sr-speedbar-exist-p)
      (projectile-speedbar-open-current-buffer-in-tree)))

(add-hook 'projectile-find-dir-hook 'projectile-speedbar-open-current-buffer-in-tree)
(add-hook 'projectile-find-file-hook 'projectile-speedbar-open-current-buffer-in-tree)
(add-hook 'projectile-cache-projects-find-file-hook
          'projectile-speedbar-open-current-buffer-in-tree)
(add-hook 'projectile-cache-files-find-file-hook
          'projectile-speedbar-open-current-buffer-in-tree)

(provide 'projectile-speedbar)

;;; projectile-speedbar.el ends here
