;;; universal-sidecar-elfeed-related.el --- Related Papers Sidecar Section for Elfeed -*- lexical-binding: t -*-

;; Copyright (C) 2023 Samuel W. Flint <me@samuelwflint.com>

;; Author: Samuel W. Flint <me@samuelwflint.com>
;; SPDX-License-Identifier: GPL-3.0-or-later
;; URL: https://git.sr.ht/~swflint/emacs-universal-sidecar
;; Version: 1.0.1
;; Package-Requires: ((emacs "25.1") (universal-sidecar "1.0.0") (bibtex-completion "1.0.0") (elfeed "3.4.1"))

;; This file is NOT part of GNU Emacs.

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
;;
;; The usecase that started this project: I wanted to be able to see
;; possibly related papers that I've read when I read through the
;; ArXiv RSS feeds.  I initially wrote a basic command which could be
;; run manually for each Elfeed article, yet this is somewhat painful.
;; Thus came `universal-sidecar', and this particular sidecar section.
;; This extension is fairly simple, and builds on top of the
;; `bibtex-completion' library, so it's necessary to configure it
;; appropriately.  Once `bibtex-completion' is configured and the
;; `elfeed-related-works-section' is added to
;; `universal-sidecar-sections', if an article's authors have other
;; works in your Bibtex databases, they will be shown.  Note, however,
;; that as of now, search is only by author last name.

;;; Code:

(require 'universal-sidecar)
(require 'elfeed-show)
(require 'elfeed-db)
(require 'bibtex-completion)


;;; Customization

(defcustom universal-sidecar-elfeed-related-citation-formatter #'bibtex-completion-apa-format-reference
  "How should a related paper be formatted for display?

By default, the APA formatting from `bibtex-completion' is used.
Any function used for this should take a parsed BibTeX entry, and
return a fully-formatted string (font properties may be set using
`propertize'."
  :type 'function
  :group 'elfeed)


;;; Select formatting candidates

(defun universal-sidecar-elfeed-related--author-regexp (authors-list)
  "Generate a regular expression to match AUTHORS-LIST in bibtex entries."
  (regexp-opt (mapcar (lambda (author)
                        (car (last (split-string (plist-get :name author)))))
                      authors-list)
              'words))

(defun universal-sidecar-elfeed-related-search-candidates (regexp)
  "List entry keys which match REGEXP."
  (mapcar #'cdr (cl-remove-if-not
                 (lambda (entry)
                   (string-match regexp (car entry)))
                 (bibtex-completion-candidates))))


;;; Define the sidecar section

(universal-sidecar-define-section universal-sidecar-elfeed-related-section ()
                                  (:major-modes elfeed-show-mode)
  (when-let ((elfeed-entry (with-current-buffer buffer elfeed-show-entry))
             (title (elfeed-entry-title elfeed-entry))
             (authors-regexp (universal-sidecar-elfeed-related--author-regexp (elfeed-meta elfeed-entry :authors)))
             (candidate-keys (mapcar #'cdr
                                     (mapcar (apply-partially #'assoc "=key=")
                                             (universal-sidecar-elfeed-related-search-candidates authors-regexp)))))
    (universal-sidecar-insert-section elfeed-related-works "Related Articles"
      (dolist (key candidate-keys)
        (insert " - " (funcall universal-sidecar-elfeed-related-citation-formatter
                               (bibtex-completion-get-entry key))
                "\n")))))


(provide 'universal-sidecar-elfeed-related)

;;; universal-sidecar-elfeed-related.el ends here
