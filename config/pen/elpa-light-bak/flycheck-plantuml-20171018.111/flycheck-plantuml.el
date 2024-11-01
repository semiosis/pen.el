;;; flycheck-plantuml.el --- Integrate plantuml with flycheck

;; Copyright (c) 2016 Alex Murray

;; Author: Alex Murray <murray.alex@gmail.com>
;; Maintainer: Alex Murray <murray.alex@gmail.com>
;; URL: https://github.com/alexmurray/flycheck-plantuml
;; Package-Version: 20171018.111
;; Package-Commit: 183be89e1dbba0b38237dd198dff600e0790309d
;; Version: 0.1
;; Package-Requires: ((flycheck "0.24") (emacs "24.4") (plantuml-mode "1.2.2"))

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
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

;; This packages integrates plantuml with flycheck to automatically check the
;; syntax of your plantuml files on the fly

;;;; Setup

;; (with-eval-after-load 'flycheck
;;   (require 'flycheck-plantuml)
;;   (flycheck-plantuml-setup))

;;; Code:
(require 'flycheck)
(require 'plantuml-mode)

(flycheck-define-checker plantuml
  "A checker using plantuml.

See `http://plantuml.com"
  :command ("java" "-Djava.awt.headless=true" "-jar" (eval plantuml-jar-path) "-syntax")
  :standard-input t
  :error-patterns ((error line-start "ERROR" "\n" line "\n" (message) line-end))
  :modes plantuml-mode)

;;;###autoload
(defun flycheck-plantuml-setup ()
  "Setup flycheck-plantuml.

Add `plantuml' to `flycheck-checkers'."
  (interactive)
  (add-to-list 'flycheck-checkers 'plantuml))

(provide 'flycheck-plantuml)

;;; flycheck-plantuml.el ends here
