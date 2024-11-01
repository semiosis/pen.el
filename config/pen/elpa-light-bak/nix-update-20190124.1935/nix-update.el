;;; nix-update.el --- Update "fetch" blocks in .nix expressions

;; Copyright (C) 2018 John Wiegley

;; Author: John Wiegley <johnw@newartisans.com>
;; Maintainer: John Wiegley <johnw@newartisans.com>
;; Created: 1 Feb 2018
;; Version: 1.0
;; Package-Version: 20190124.1935
;; Package-Commit: fc6c39c2da3fcfa62f4796816c084a6389c8b6e7
;; Package-Requires: ((emacs "25"))
;; Keywords: nix
;; URL: https://github.com/jwiegley/nix-update-el

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; Bind nix-update-fetch to a key (I use `C-. u'), and then you can very
;; easily update the rev/sha of a fetchgit declaration.

;;; Code:

(require 'rx)

(defun nix-update-fetch ()
  "Update the nix fetch expression at point."
  (interactive)
  (save-excursion
    (when (re-search-forward
           (rx (and (submatch
                     (or "compileEmacsWikiFile"
                         (and "fetch"
                              (or "url"
                                  "git"
                                  (and "FromGit" (or "Hub" "Lab"))))))
                    (1+ space)
                    "{"))
           nil t)
      (goto-char (1- (match-end 0)))
      (let ((begin (point))
            (type (match-string 1)))
        (forward-sexp)
        (save-restriction
          (narrow-to-region begin (point))
          (cl-flet ((get-field
                     (field)
                     (goto-char (point-min))
                     (when (re-search-forward
                            (concat field "\\s-+=\\s-+\"?\\(.+?\\)\"?\\s-*;")
                            nil
                            t)
                       (match-string 1)))
                    (set-field
                     (field value)
                     (goto-char (point-min))
                     (if (re-search-forward
                          (concat field "\\s-+=\\s-+\"?\\(.+?\\)\"?\\s-*;")
                          nil t)
                         (replace-match value nil t nil 1)
                       (goto-char (point-max))
                       (search-backward ";")
                       (goto-char (line-beginning-position))
                       (let ((leader "    "))
                         (when (looking-at "^\\(\\s-+\\)")
                           (setq leader (match-string 1)))
                         (goto-char (line-end-position))
                         (insert ?\n leader field " = " value ";")))))
            (let ((data
                   (pcase type
                     (`"fetchFromGitHub"
                      (let ((owner (get-field "owner"))
                            (repo (get-field "repo"))
                            (submodules
                             (let ((subs (get-field "fetchSubmodules")))
                               (and subs (string-equal subs "true")))))
                        (with-temp-buffer
                          (message "Fetching GitHub repository: %s/%s ..."
                                   owner repo)
                          (let ((inhibit-redisplay t))
                            (shell-command
                             (format
                              (concat
                               "nix-prefetch-git --no-deepClone"
                               (if submodules " --fetch-submodules" "")
                               " --quiet git://github.com/%s/%s.git %s")
                              owner repo "refs/heads/master")
                             (current-buffer))
                            (message
                             "Fetching GitHub repository: %s/%s ...done"
                             owner repo))
                          (goto-char (point-min))
                          (json-read-object))))
                     (`"fetchFromGitLab"
                      (let ((owner (get-field "owner"))
                            (repo (get-field "repo")))
                        (with-temp-buffer
                          (message "Fetching GitLab repository: %s/%s ..."
                                   owner repo)
                          (let ((inhibit-redisplay t))
                            (shell-command
                             (format
                              (concat
                               "nix-prefetch-git --no-deepClone"
                               " --quiet https://gitlab.com/%s/%s.git %s")
                              owner repo "refs/heads/master")
                             (current-buffer))
                            (message
                             "Fetching GitLab repository: %s/%s ...done"
                             owner repo))
                          (goto-char (point-min))
                          (json-read-object))))
                     (`"fetchgit"
                      (let ((url (get-field "url")))
                        (with-temp-buffer
                          (message "Fetching Git URL: %s ..." url)
                          (let ((inhibit-redisplay t))
                            (shell-command
                             (format (concat
                                      "nix-prefetch-git --no-deepClone"
                                      " --quiet '%s' %s")
                                     url "refs/heads/master")
                             (current-buffer))
                            (message "Fetching Git URL: %s ...done" url))
                          (goto-char (point-min))
                          (json-read-object))))
                     (`"fetchurl"
                      (let ((url (get-field "url")))
                        (with-temp-buffer
                          (message "Fetching URL %s: ..." url)
                          (let ((inhibit-redisplay t))
                            (shell-command (format "nix-prefetch-url '%s'" url)
                                           (current-buffer))
                            (message "Fetching URL %s: ...done" url))
                          (goto-char (point-min))
                          (while (looking-at "^\\(path is\\|warning\\)")
                            (forward-line))
                          (list
                           (cons 'date
                                 (format-time-string "%Y-%m-%dT%H:%M:%S%z"))
                           (cons 'sha256
                                 (buffer-substring
                                  (line-beginning-position)
                                  (line-end-position)))))))
                     (`"compileEmacsWikiFile"
                      (let ((name (get-field "name")))
                        (with-temp-buffer
                          (message "Fetching EmacsWiki file %s: ..." name)
                          (let ((inhibit-redisplay t))
                            (shell-command
                             (format
                              "nix-prefetch-url 'https://www.emacswiki.org/emacs/download/%s'" name)
                             (current-buffer))
                            (message "Fetching EmacsWiki file %s: ...done" name))
                          (goto-char (point-min))
                          (while (looking-at "^\\(path is\\|warning\\)")
                            (forward-line))
                          (list
                           (cons 'date
                                 (format-time-string "%Y-%m-%dT%H:%M:%S%z"))
                           (cons 'sha256
                                 (buffer-substring
                                  (line-beginning-position)
                                  (line-end-position))))))))))
              (if (assq 'rev data)
                  (set-field "rev" (alist-get 'rev data)))
              (if (assq 'date data)
                  (set-field "# date"
                             (let ((date (alist-get 'date data)))
                               (if (string-match "\\`\"\\(.+\\)\"\\'" date)
                                   (match-string 1 date)
                                 date))))
              (set-field "sha256" (alist-get 'sha256 data)))))))))

(provide 'nix-update)

;;; nix-update.el ends here
