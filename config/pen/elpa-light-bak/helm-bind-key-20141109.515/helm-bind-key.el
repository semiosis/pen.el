;;; helm-bind-key.el --- helm-source for for bind-key.

;; Copyright (C) 2014 Yuhei Maeda <yuhei.maeda_at_gmail.com>
;; Author: Yuhei Maeda <yuhei.maeda_at_gmail.com>
;; Maintainer: myuhe
;; Version: 0.1
;; Package-Commit: 9da6ad8b7530e72fb4ac67be8c6a482898dddc25
;; Package-Version: 20141109.515
;; Package-X-Original-version: 0.1
;; Package-Requires: ((bind-key "1.0") (helm "1.6.4"))
;; Created: 2014-10-08 
;; Keywords: convenience, emulation

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;; 
;; It is necessary to Some Helm and bind-key.el Configurations.
;;

;;; Installation:
;;
;; Put the helm-bin-key.el to your
;; load-path.
;; Add to .emacs:
;; (require 'helm-bind-key)
;;

;;; Changelog:
;;  2014/10/08  Initial release
             

;;; Command:
;;  `helm-bind-key'


;;; Code:
(require 'bind-key)
(require 'helm)

(defun hbk-create-sources ()
  "[internal] create an helm source for bind-key."
  (let (heads 
        cur-title 
        cur-records
        last-binding)
    (dolist (binding
             (setq personal-keybindings
                   (sort personal-keybindings
                         (lambda (l r)
                           (car (compare-keybindings l r))))))
      (cond
       ((equal last-binding nil) nil)
       ((equal (cdar binding) nil) nil)
       ((eq (cdar last-binding) (cdar binding))
        (push (cons (format "%-10s\t%s" (caar binding) (cadr binding)) (cadr binding)) cur-records))
       (t
        (setq cur-title (symbol-name(cdar last-binding)))
        (push
         `((name . ,cur-title)
           (candidates ,@cur-records)
           (type . command))
         heads)
        (setq cur-title nil cur-records nil)
        (push (format "%-10s\t%s" (caar binding) (cadr binding)) cur-records)))
      (setq last-binding binding))
    (reverse heads)))

;;;###autoload
(defun helm-bind-key ()
  "Helm command for bind-key."
  (interactive)
  (helm (hbk-create-sources)))

(provide 'helm-bind-key)

;;; helm-bind-key.el ends here
