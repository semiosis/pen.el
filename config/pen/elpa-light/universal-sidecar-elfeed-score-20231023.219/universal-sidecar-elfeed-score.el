;;; universal-sidecar-elfeed-score.el --- Show Elfeed Score information in sidecar -*- lexical-binding: t -*-

;; Copyright (C) 2023 Samuel W. Flint <me@samuelwflint.com>

;; Author: Samuel W. Flint <me@samuelwflint.com>
;; SPDX-License-Identifier: GPL-3.0-or-later
;; URL: https://git.sr.ht/~swflint/emacs-universal-sidecar
;; Version: 0.5.0
;; Package-Requires: ((emacs "25.1") (universal-sidecar "1.0.0") (elfeed "3.4.1") (elfeed-score "1.2.6"))

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
;; The section `elfeed-score-section' shows the score of the currently
;; shown elfeed entry and why it is scored that way.

;;; Code:

(require 'universal-sidecar)
(require 'elfeed-show)
(require 'elfeed-db)
(require 'elfeed-score-scoring)

(universal-sidecar-define-section universal-sidecar-elfeed-score-section ()
                                  (:major-modes elfeed-show-mode)
  (when-let ((elfeed-entry (with-current-buffer buffer elfeed-show-entry))
             (title (elfeed-entry-title elfeed-entry))
             (score (elfeed-score-scoring-get-score-from-entry elfeed-entry)))
    (universal-sidecar-set-title (propertize title 'font-lock-face 'bold) sidecar)
    (with-current-buffer sidecar
      (universal-sidecar-insert-section score-information (format "Article score: %d" score)
        (elfeed-score-scoring-explain-entry elfeed-entry sidecar)))))

(provide 'universal-sidecar-elfeed-score)

;;; universal-sidecar-elfeed-score.el ends here
