;;; wiz-shortdoc.el --- Shortdoc for wiz          -*- lexical-binding: t; -*-

;; Copyright (C) 2024 USAMI Kenta

;; Author: USAMI Kenta <tadsan@zonu.me>
;; Created: 01 Jan 2024
;; Keywords: lisp
;; Homepage: https://github.com/zonuexe/emacs-wiz
;; License: GPL-3.0-or-later

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Shortdoc implementation for wiz.

;;; Code:
(eval-when-compile
  (require 'shortdoc))

(define-short-documentation-group wiz
  "Wiz for activate feature"
  (wiz
    :eval (macroexpand
           '(wiz nyan-mode))
    :no-eval (macroexpand
               '(wiz php-mode
                  :load "/path/to/php-autoload.el"))
    :result (prog1 'php-mode (load "/path/to/php-autoload.el"))
    :eval (macroexpand
           '(wiz php-mode
              :load-if-exists "/path/to/php-autoload.el"))
    :eval (macroexpand
           '(wiz js
              :setup-hook (lambda () (setopt js-indent-level 4))))
    :eval (macroexpand
           '(wiz elisp-mode
              :hook-names (emacs-lisp-mode-hook)
              :init (lambda () (emacs-lisp-mode 1))))
    :eval (macroexpand
           '(wiz elisp-mode
              :hook-names (emacs-lisp-mode-hook lisp-interaction-mode-hook)
              :setup-hook
              (defun init-emacs-lisp-mode-setup ()
                (message "Nyan!"))))))

(provide 'wiz-shortdoc)
;;; wiz-shortdoc.el ends here
