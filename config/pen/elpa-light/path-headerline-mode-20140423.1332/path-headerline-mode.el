;;; path-headerline-mode.el --- Displaying file path on headerline.
;;
;; Filename: path-headerline-mode.el
;; Description: Displaying file path on headerline.
;; Author: 7696122
;; Maintainer: 7696122
;; Created: Sat Sep  8 11:44:11 2012 (+0900)
;; Version: 0.0.2
;; Last-Updated: Wed Apr 23 22:32:03 2014 (+0900)
;;           By: 7696122
;;     Update #: 47
;; URL: https://github.com/7696122/path-headerline-mode
;; Keywords: headerline
;; Compatibility:
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:
;;
;; `Path headerline mode' is mode for displaying file path on headerline.
;; Modeline is too short to show filepath when split window by vertical.
;; path-headerline-mode show full file path if window width is enough.
;; but if window width is too short to show full file path, show directory path exclude file name.
;;
;;; Installation
;; Make sure "path-headerline-mode.el" is in your load path, then place
;; this code in your .emacs file:
;;
;; (require 'path-headerline-mode)
;; (path-headerline-mode +1)
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Change Log:
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Code:


(defmacro ph--with-face (str &rest properties)
  `(propertize ,str 'face (list ,@properties)))

(defun ph--make-header ()
  ""
  (let* ((ph--full-header (abbreviate-file-name buffer-file-name))
         (ph--header (file-name-directory ph--full-header))
         (ph--drop-str "[...]"))
    (if (> (length ph--full-header)
           (window-body-width))
        (if (> (length ph--header)
               (window-body-width))
            (progn
              (concat (ph--with-face ph--drop-str
                                 :background "blue"
                                 :weight 'bold)
                      (ph--with-face (substring ph--header
                                            (+ (- (length ph--header)
                                                  (window-body-width))
                                               (length ph--drop-str))
                                            (length ph--header))
                                 :weight 'bold)))
          (concat (ph--with-face ph--header
                             :foreground "#8fb28f"
                             :weight 'bold)))
      (concat (ph--with-face ph--header
                         :weight 'bold
                         :foreground "#8fb28f")
              (ph--with-face (file-name-nondirectory buffer-file-name)
                         :weight 'bold)))))

(defun ph--display-header ()
  "Display path on headerline."
  (setq header-line-format
        '("" ;; invocation-name
          (:eval (if (buffer-file-name)
                     (ph--make-header)
                   "%b")))))

(defun path-header-line-on ()
  "Display path on headerline for current buffer."
  (interactive)
  (ph--display-header))

(defun path-header-line-off ()
  "Undisplay path on headerline for current buffer."
  (interactive)
  (setq header-line-format nil))

;;;###autoload
(define-minor-mode path-headerline-mode
  "Displaying file path on headerline."
  :global t
  :group 'path-headerline-mode
  (if path-headerline-mode
      (progn
        (add-hook 'buffer-list-update-hook #'ph--display-header))
    (remove-hook 'buffer-list-update-hook #'ph--display-header)))

(provide 'path-headerline-mode)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; path-headerline-mode.el ends here
