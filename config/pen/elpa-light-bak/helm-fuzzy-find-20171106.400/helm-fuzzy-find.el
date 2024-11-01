;;; helm-fuzzy-find.el --- Find file using Fuzzy Search  -*- lexical-binding: t; -*-

;; Copyright (C) 2015  Chunyang Xu

;; Author: Chunyang Xu <xuchunyang56@gmail.com>
;; Created: Wed Jun 10 12:56:06 CST 2015
;; Version: 0.2
;; Package-Version: 20171106.400
;; Package-Commit: de2abbf7ca13609587325bacd4a1ed4376b5c927
;; URL: https://github.com/xuchunyang/helm-fuzzy-find
;; Package-Requires: ((emacs "24.1") (helm "1.7.0"))
;; Keywords: helm fuzzy find file

;; This file is not part of Emacs.
;;
;; This file is free software: you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free
;; Software Foundation, either version 3 of the License, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
;; FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
;; more details.
;;
;; You should have received a copy of the GNU General Public License along
;; with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; `helm-fuzzy-find.el' is a Helm extension for the `fuzzy-find' command
;; line program (https://github.com/silentbicycle/ff), you can use it to
;; search files under a directory using Fuzzy Search.
;;
;; When you want to search files only according to their base-names, use the
;; notable `find' program and its helm interface `helm-find' instead, but if
;; you also use their parent directory names, i.e., full absolute path name of
;; a file or directory, `fuzzy-find' is probably better.  You can read
;; `fuzzy-find''s homepage and manual page to learn more about these.
;;
;;
;; Installation
;; ============
;;
;; To install, make sure this file is saved in a directory in your `load-path',
;; and add the line:
;;
;;   (require 'helm-fuzzy-find)
;;
;; to your Emacs initialization file.
;;
;;
;; Usage
;; =====
;;
;; M-x helm-fuzzy-find to launch `helm-fuzzy-find' from the current buffer's
;; directory, if with prefix argument, you can choose a directory to search.
;;
;; Like `helm-find', you can also launch `helm-fuzzy-find' from
;; `helm-find-files' (it usually binds to `C-x C-f' for helm users) by typing
;; `C-c C-/' (you can customize this key by setting `helm-fuzzy-find-keybind').
;;
;; Note
;; ====
;;
;; To use `helm-fuzzy-find', you need to know the format (**NOT** regexp) of the
;; query string of `fuzzy-find', especially the meaning of "/" character and "="
;; character, refer to its manual page for more info.
;;
;; To install `fuzzy-find' on Mac OS X via MacPorts:
;;
;;   $ sudo port install fuzzy-find


;;; Code:

(require 'helm)
(require 'helm-files)
(require 'helm-find)

(defgroup helm-fuzzy-find nil
  "Find file using Fuzzy Search.
helm interface for the `fuzzy-find' command line program."
  :group 'helm
  :link '(emacs-commentary-link :tag "commentary" "helm-fuzzy-find.el")
  :link '(emacs-library-link :tag "lisp file" "helm-fuzzy-find.el")
  :link '(url-link :tag "web page" "https://github.com/xuchunyang/helm-fuzzy-find"))

(defcustom helm-fuzzy-find-program "ff"
  "Program name of the `fuzzy-find' command line program."
  :group 'helm-fuzzy-find
  :type 'string)

;; helm-find-files integration.
(defcustom helm-fuzzy-find-keybind (kbd "C-c C-/")
  "Keybinding under which `helm-find-files-map' is assigned.

Use this key to launch `helm-fuzzy-find' from `helm-find-files'.

To change this do something like:
    (setq helm-fuzzy-find-keybind (kbd \"C-c /\"))
BEFORE activating the function `helm-fuzzy-find' and BEFORE `require'ing the
`helm-fuzzy-find' feature."
  :group 'helm-fuzzy-find
  :type 'string)

(defun helm-fuzzy-find-shell-command-fn ()
  "Asynchronously fetch candidates for `helm-fuzzy-find'. "
  (let* (process-connection-type
         non-essential
         (cmd (concat helm-fuzzy-find-program " " (shell-quote-argument helm-pattern)))
         (proc (start-file-process-shell-command "ff" helm-buffer cmd)))
    (helm-log "Fuzzy Find command:\n%s" cmd)
    (prog1 proc
      (set-process-sentinel
       proc
       (lambda (process event)
         (helm-process-deferred-sentinel-hook
          process event (helm-default-directory))
         (if (string= event "finished\n")
             (with-helm-window
               (setq mode-line-format
                     '(" " mode-line-buffer-identification " "
                       (:eval (format "L%s" (helm-candidate-number-at-point))) " "
                       (:eval (propertize
                               (format "[Fuzzy Find process finished - (%s results)]"
                                       (max (1- (count-lines
                                                 (point-min) (point-max)))
                                            0))
                               'face 'helm-locate-finish))))
               (force-mode-line-update))
           (helm-log "Error: Fuzzy Find %s"
                     (replace-regexp-in-string "\n" "" event))))))))

(defvar helm-source-fuzzy-find
  (helm-build-async-source "Fuzzy Find"
    :header-name (lambda (name)
                   (concat name " in [" (helm-default-directory) "]"))
    :candidates-process #'helm-fuzzy-find-shell-command-fn
    :filtered-candidate-transformer 'helm-findutils-transformer
    :action-transformer 'helm-transform-file-load-el
    :action (helm-actions-from-type-file)
    :candidate-number-limit 9999
    :requires-pattern 2))

(defun helm-fuzzy-find-1 (dir)
  (let ((default-directory (file-name-as-directory dir)))
    (helm :sources 'helm-source-fuzzy-find
          :buffer "*helm fuzzy find*"
          :ff-transformer-show-only-basename nil
          :case-fold-search helm-file-name-case-fold-search)))

(defun helm-ff-fuzzy-find-sh-command (_candidate)
  "Run `helm-fuzzy-find' from `helm-find-files'."
  (helm-fuzzy-find-1 helm-ff-default-directory))

(defun helm-ff-run-fuzzy-find-sh-command ()
  "Run find shell command action with key from `helm-find-files'."
  (interactive)
  (with-helm-alive-p
    (helm-quit-and-execute-action 'helm-ff-fuzzy-find-sh-command)))

(define-key helm-find-files-map helm-fuzzy-find-keybind
  #'helm-ff-run-fuzzy-find-sh-command)

(defmethod helm-setup-user-source ((source helm-source-ffiles))
  (helm-source-add-action-to-source-if
   (format "Find file with fuzzy-find `%s'" (key-description helm-fuzzy-find-keybind))
   #'helm-ff-fuzzy-find-sh-command
   source (lambda (_candidate) t)))

;;;###autoload
(defun helm-fuzzy-find (arg)
  "Preconfigured `helm' for the fuzzy-find (\"ff\") shell command.
With ARG, read a directory first for searching."
  (interactive "P")
  (let ((directory
         (if arg
             (file-name-as-directory
              (read-directory-name "Default Directory: "))
           default-directory)))
    (helm-fuzzy-find-1 directory)))

(provide 'helm-fuzzy-find)
;;; helm-fuzzy-find.el ends here
