;;; mini-header-line.el --- a minimal header-line

;; Author: Johannes Goslar
;; Created: 24 Mai 2016
;; Version: 0.1.0
;; Package-Requires: ((emacs "24.4"))
;; Keywords: header-line, mode-line
;; URL: https://github.com/ksjogo/mini-header-line

;; Copyright (C) 2016 Johannes Goslar

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;;; Code:

(require 'face-remap)

(defgroup mini-header-line nil
  "A minimal header line."
  :group 'environment)

(defcustom mini-header-line-error-reports
  '(mini-header-line-error-js2 mini-header-line-error-flycheck)
  "The list of error reporters, shall return (errors warnings)."
  :group 'mini-header-line
  :type '(repeat function))

(defface mini-header-line-active
  '((default :weight bold))
  "Additional properties used for the active mini-header-line ")

(defvar mini-header-line-saved-mode-line nil)

(defvar mini-header-line-last-buffer nil)
(defvar mini-header-line-cookie nil)
(defvar mini-header-line-app-has-focus t)

(defun mini-header-line-check ()
  "Check if focus has changed, and if so, update remapping."
  (let ((current-buffer (and mini-header-line-app-has-focus (current-buffer))))
    (unless (eq mini-header-line-last-buffer current-buffer)
      (when (and mini-header-line-last-buffer mini-header-line-cookie)
        (when (buffer-live-p mini-header-line-last-buffer)
          (with-current-buffer mini-header-line-last-buffer
            (face-remap-remove-relative mini-header-line-cookie))))
      (setq mini-header-line-last-buffer current-buffer)
      (when current-buffer
        (setq mini-header-line-cookie
              (face-remap-add-relative 'header-line :inherit 'mini-header-line-active))))))

(defun mini-header-line-app-focus (state)
  (setq mini-header-line-app-has-focus state)
  (mini-header-line-check))

(defun mini-header-line-app-focus-in ()
  (mini-header-line-app-focus t))

(defun mini-header-line-app-focus-out ()
  (mini-header-line-app-focus nil))

(defadvice select-window (after mini-header-line)
  (mini-header-line-check))

(defun mini-header-line-error-format (errs)
  (let ((errors (car errs))
        (warnings (cadr errs)))
    (if (and errors warnings)
        (concat
         (if (numberp errors)
             (if
                 (> errors 0)
                 (propertize (number-to-string errors) 'face 'error)
               "0")
           errors)
         "/"
         (if (numberp warnings)
             (if (> warnings 0)
                 (propertize (number-to-string warnings) 'face 'font-lock-warning-face)
               "0")
           warnings))
      "")))

(defun mini-header-line-error-js2 ()
  (if (eq major-mode 'js2-mode)
      (list (length (js2-errors)) (length (js2-warnings)))
    '(nil nil)))

(defun mini-header-line-error-flycheck ()
  (if (bound-and-true-p flycheck-mode)
      (pcase flycheck-last-status-change
        (`not-checked '(nil nil))
        (`no-checker '("-" "-"))
        (`running '("*" "*"))
        (`errored '("!" "!"))
        (`interrupted '("-" "-"))
        (`suspicious '("?" "?"))
        (`finished
         (if flycheck-current-errors
             (let ((error-counts (flycheck-count-errors flycheck-current-errors)))
               (list (or (cdr (assq 'error error-counts)) 0) (or (cdr (assq 'warning error-counts)) 0)))
           '(0 0))))
    '(nil nil)))

(defvar mini-header-line-format
  (list
   " "
   ;; buffer
   (propertize "%[%b%]" 'face 'font-lock-keyword-face)
   ;; change
   (propertize "%*" 'face 'font-lock-warning-face)
   " "
   ;; error counts
   '(:eval (apply 'concat (cl-map 'list (lambda (func)
                                          (mini-header-line-error-format (funcall func))) mini-header-line-error-reports)))

   ;; line
   (propertize "%4l" 'face 'font-lock-variable-name-face)
   " "
   ;; relative position, size of file
   `((-3 ,(propertize "%P" 'face 'font-lock-constant-face)))
   "/"
   (propertize "%I" 'face 'font-lock-constant-face)
   " "
   ))

(defcustom mini-header-line-excluded-modes '(ranger-mode)
  "Modes to not set the header-line format in.")

(defun mini-header-line-set-header-line ()
  (unless (member major-mode mini-header-line-excluded-modes)
    (setq header-line-format mini-header-line-format)))

;;;###autoload
(define-minor-mode mini-header-line-mode "" :global t
  (if mini-header-line-mode
      (progn
        (setq mini-header-line-saved-mode-line mode-line-format)
        (setq-default mode-line-format nil)
        (ad-enable-advice 'select-window 'after 'mini-header-line)
        (ad-update 'select-window)
        (add-hook 'find-file-hook 'mini-header-line-set-header-line)
        (add-hook 'window-configuration-change-hook 'mini-header-line-check)
        (add-hook 'focus-in-hook 'mini-header-line-app-focus-in)
        (add-hook 'focus-out-hook 'mini-header-line-app-focus-out))
    (progn
      (setq-default mode-line-format mini-header-line-saved-mode-line)
      (setq mini-header-line-saved-mode-line nil)
      (ad-disable-advice 'select-window 'after 'mini-header-line)
      (ad-update 'select-window)
      (remove-hook 'find-file-hook 'mini-header-line-set-header-line)
      (remove-hook 'window-configuration-change-hook 'mini-header-line-check)
      (remove-hook 'focus-in-hook 'mini-header-line-app-focus-in)
      (remove-hook 'focus-out-hook 'mini-header-line-app-focus-out))))

(provide 'mini-header-line)
;;; mini-header-line.el ends here
