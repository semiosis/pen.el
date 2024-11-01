;;; flycheck-projectile.el --- Project-wide errors -*- lexical-binding: t -*-

;; Copyright (C) 2020  Nikita Bloshchanevich

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

;; Author: Nikita Bloshchanevich <nikblos@outlook.com>
;; URL: https://github.com/nbfalcon/flycheck-projectile
;; Package-Version: 20201031.1952
;; Package-Commit: ce6e9e8793a55dace13d5fa13badab2dca3b5ddb
;; Package-Requires: ((emacs "25.1") (flycheck "31") (projectile "2.2"))
;; Version: 0.2.0

;;; Commentary:

;; Implement per-project errors by leveraging flycheck and projectile.

;;; Code:

(require 'cl-lib)
(require 'flycheck)                     ; `flycheck-error-list-mode-map'

;;; global `declare-function'
(declare-function projectile-project-buffers "projectile" (project))
(declare-function projectile-project-buffer-p "projectile" (buffer project))

;; (flycheck-projectile-buffer-errors :: Buffer -> [flycheck-error])
(defun flycheck-projectile-buffer-errors (buffer)
  "Return BUFFER's flycheck errors."
  (buffer-local-value 'flycheck-current-errors buffer))

(defcustom flycheck-projectile-blacklisted-checkers '()
  "Flycheck backends to be ignored in the project-error list."
  :group 'flycheck-projectile
  :type '(repeat symbol))

;; (flycheck-projectile-gather-errors :: String -> [flycheck-error])
(defun flycheck-projectile-gather-errors (project)
  "Gather PROJECT's flycheck errors into a list.
`projectile' must already be loaded when this function is
called."
  (cl-delete-if
   (lambda (err) (memq (flycheck-error-checker err)
                       flycheck-projectile-blacklisted-checkers))
   (when-let ((buffers (projectile-project-buffers project)))
     (apply #'append (mapcar #'flycheck-projectile-buffer-errors buffers)))))

(defun flycheck-projectile-list-entries-from-errors (errors)
  "Generate the list entries for the project-error list.
ERRORS is a list of flycheck errors, as returned by
`flycheck-projectile-gather-errors', for instance. The return
value is a sorted list of errors usable with
`tabulated-list-mode'."
  (declare-function flycheck-error-list-make-entry "flycheck" (err))
  (mapcar
   #'flycheck-error-list-make-entry
   (sort errors
         (lambda (a b) (or (string< (flycheck-error-filename a)
                                    (flycheck-error-filename b))
                           (< (flycheck-error-line a)
                              (flycheck-error-line b)))))))

(defun flycheck-projectile-error-list-goto-error (&optional list-pos)
  "Go to the error in the current error-list at LIST-POS.
The current error list shall be a tabulated list of flycheck
errors as shown by `flycheck-projectile-list-errors' or
`flycheck-list-errors'. LIST-POS defaults to (`point')."
  (interactive)
  (declare-function flycheck-error-pos "flycheck" (err))
  (when-let ((err (tabulated-list-get-id list-pos))
             (buf (flycheck-error-buffer err))
             (pos (flycheck-error-pos err)))
    (pop-to-buffer buf 'other-window)
    (goto-char pos)))

(defvar flycheck-projectile--project nil
  "Project whose errors are currently shown.")

(defun flycheck-projectile-make-list-entries ()
  "Make the list entries for the global project-error list.
See `flycheck-projectile-list-entries-from-errors' for details."
  (flycheck-projectile-list-entries-from-errors
   (flycheck-projectile-gather-errors flycheck-projectile--project)))

(defcustom flycheck-projectile-error-list-buffer "*Project errors*"
  "Name of the project error buffer.
Created by `flycheck-projectile-list-errors'."
  :group 'flycheck-projectile
  :type 'string)

(defun flycheck-projectile--reload-errors ()
  "Refresh the errors in the project-error list."
  (with-current-buffer flycheck-projectile-error-list-buffer
    (revert-buffer)))

(defun flycheck-projectile--maybe-reload ()
  "Reload the project-error list for its projects' buffers only.
Reload it only if the current buffer is a file in
`flycheck-projectile--project'."
  (when (projectile-project-buffer-p (current-buffer)
                                     flycheck-projectile--project)
    (flycheck-projectile--reload-errors)))

(defun flycheck-projectile--handle-flycheck-off ()
  "Handle `flycheck-mode' being turned off.
Reloads the project-error list, if the current buffer does
not have flycheck-mode enabled."
  (unless flycheck-mode
    (flycheck-projectile--reload-errors)))

(defun flycheck-projectile--remove-buffer-errors ()
  "Reload the error list without the current buffer's errors."
  (let (flycheck-current-errors)
    (flycheck-projectile--reload-errors)))

(define-minor-mode flycheck-projectile--project-buffer-mode
  "Minor mode to help auto-reload the project's error list.
It sets up various hooks for the current buffer so that the error
list gets auto-updated when certain events (like error-check,
killing, ... occur.)."
  :init-value nil
  :lighter nil
  (cond
   (flycheck-projectile--project-buffer-mode
    ;; When flycheck is turned off, all errors must disappear.
    (add-hook 'flycheck-mode-hook #'flycheck-projectile--handle-flycheck-off
              nil t)
    ;; after syntax checking, new errors could have appeared.
    (add-hook 'flycheck-after-syntax-check-hook
              #'flycheck-projectile--reload-errors nil t)
    ;; remove the buffer's errors after it is gone
    (add-hook 'kill-buffer-hook #'flycheck-projectile--remove-buffer-errors
              nil t))
   (t
    (remove-hook 'flycheck-mode-hook
                 #'flycheck-projectile--handle-flycheck-off t)
    (remove-hook 'flycheck-after-syntax-check-hook
                 #'flycheck-projectile--reload-errors t)
    (remove-hook 'kill-buffer-hook #'flycheck-projectile--remove-buffer-errors
                 t))))

(defun flycheck-projectile--handle-flycheck ()
  "`flycheck-mode' hook to turn on `flycheck-projectile--project-buffer-mode'.
If flycheck was enabled and the current buffer is part of
`flycheck-projectile--project', turn on
`flycheck-projectile--project-buffer-mode' and turn it off
otherwise."
  (when (projectile-project-buffer-p (current-buffer)
                                     flycheck-projectile--project)
    (flycheck-projectile--project-buffer-mode (if flycheck-mode 1 -1))))

(defun flycheck-projectile--disable-project-buffer-mode ()
  "Disable `flycheck-projectile--project-buffer-mode' globally."
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (flycheck-projectile--project-buffer-mode -1))))

(defun flycheck-projectile--enable-project-buffer-mode (project)
  "Enable `flycheck-projectile--project-buffer-mode' for PROJECT.
Enable in all of PROJECT's buffers."
  (dolist (buffer (projectile-project-buffers project))
    (with-current-buffer buffer
      ;; Only buffers with flycheck enabled can contribute errors and as such
      ;; only those should be watched.
      (when flycheck-mode
        (flycheck-projectile--project-buffer-mode 1)))))

(defun flycheck-projectile--global-setup ()
  "Set up hooks so that new project buffers are handled correctly."
  (add-hook 'flycheck-mode-hook #'flycheck-projectile--handle-flycheck))

(defun flycheck-projectile--global-teardown ()
  "Remove the hooks set up by `flycheck-projectile--global-setup'."
  (remove-hook 'flycheck-mode-hook #'flycheck-projectile--handle-flycheck)
  (flycheck-projectile--disable-project-buffer-mode)
  ;; tell `flycheck-projectile-list-errors' that cleanup already happened.
  (setq flycheck-projectile--project nil))

(defun flycheck-projectile--quit-kill-window ()
  "Quit and kill the buffer of the current window."
  (interactive)
  (quit-window t))

(defvar flycheck-projectile-error-list-mode-map
  (let ((map (copy-keymap flycheck-error-list-mode-map)))
    (define-key map (kbd "RET") #'flycheck-projectile-error-list-goto-error)
    (define-key map (kbd "q") #'flycheck-projectile--quit-kill-window)
    map))
(define-derived-mode flycheck-projectile-error-list-mode tabulated-list-mode
  "Flycheck project errors"
  "The mode for this plugins' project-error list."
  (setq tabulated-list-format flycheck-error-list-format
        tabulated-list-padding flycheck-error-list-padding
        ;; we must sort manually, because there are two sort keys: first File
        ;; then Line.
        tabulated-list-sort-key nil
        tabulated-list-entries #'flycheck-projectile-make-list-entries)
  (tabulated-list-init-header))

(defun flycheck-projectile--make-error-list (project)
  "Create and return the global error list buffer.
PROJECT specifies the project to watch. Unlike
`flycheck-projectile-list-errors', this function doesn't optimize
the case of the project not changing after calling it twice."
  (unless (get-buffer flycheck-projectile-error-list-buffer)
    (with-current-buffer (get-buffer-create flycheck-projectile-error-list-buffer)
      ;; If the user kills the buffer, leave no hooks behind, because they would
      ;; impair the performance. Pressing `q' kills the buffer.
      (add-hook 'kill-buffer-hook #'flycheck-projectile--global-teardown nil t)
      (flycheck-projectile-error-list-mode)))

  (when flycheck-projectile--project ;; the user didn't press q
    (flycheck-projectile--global-teardown))

  (flycheck-projectile--enable-project-buffer-mode project)
  (with-current-buffer flycheck-projectile-error-list-buffer
    (setq flycheck-projectile--project project)

    ;; even if the user presses C-g here, the kill hook was already set up;
    ;; this way, they can just kill the buffer to restore performance.
    (flycheck-projectile--global-setup)
    (revert-buffer) ;; reload the list

    (current-buffer)))

;;;###autoload
(defun flycheck-projectile-list-errors (&optional dir)
  "Show a list of all the errors in the current project.
Start the project search at DIR. Efficiently handle the case of
the project not changing since the last time this function was
called."
  (interactive)
  (require 'projectile)
  (declare-function projectile-acquire-root "projectile" (&optional dir))
  (let ((project (projectile-acquire-root dir)))
    (display-buffer
     (or (and (string= project flycheck-projectile--project)
              ;; The project didn't change *and* we have the old buffer? Reuse
              ;; it.
              (get-buffer flycheck-projectile-error-list-buffer))
         ;; Either the project changed or the old buffer is dead. Either way,
         ;; make a new list.
         (flycheck-projectile--make-error-list project)))))

(provide 'flycheck-projectile)
;;; flycheck-projectile.el ends here
