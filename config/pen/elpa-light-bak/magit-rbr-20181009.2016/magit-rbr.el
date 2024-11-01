;;; magit-rbr.el --- Support for git rbr in Magit

;; Copyright (C) 2018 Anatoly Fayngelerin

;; Author: Anatoly Fayngelerin <fanatoly+magitrbr@gmail.com>
;; Maintainer: Anatoly Fayngelerin <fanatoly+magitrbr@gmail.com>
;; Keywords: git magit rbr tools
;; Package-Version: 20181009.2016
;; Package-Commit: 029203b3e48537205052a058e964f058cd802c3c
;; Homepage: https://github.com/fanatoly/magit-rbr
;; Package-Requires: ((magit "2.13.0") (emacs "24.3"))
;; This file is not part of GNU Emacs.

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package tweaks magit to recognize `git rbr` rebases and use
;; corresponding commands during the magit rebase sequence. This
;; means that when you abort a rebase during a recursive rebase,
;; magit will abort the rbr rather than a particular phase of
;; rbr. This also adds recursive rebase as an option to the rebase
;; popup.

;;; Code:

(require 'magit)
(require 'magit-sequence)

;;;###autoload
(defun magit-rbr-rebase-recursive (args)
  "Rebase the current branch recursively onto its upstream."
  (interactive (list (magit-rebase-arguments)))
  (message "Rebasing recursively ...")
  (magit-run-git-sequencer "rbr" args)
  (message "Rebasing recursively...done"))

(magit-define-popup-action 'magit-rebase-popup
  ?r "recursively" 'magit-rbr-rebase-recursive ?i t)

(provide 'magit-rbr)

;;; magit-rbr.el ends here
