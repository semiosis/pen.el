;;; el-secretario.el --- Unify all your inboxes with the Emacs secretary -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2020 Leo
;;
;; Author: Leo Okawa Ericson <http://github/Zetagon>
;; Maintainer: Leo <github@relevant-information.com>
;; Created: September 20, 2020
;; Modified: October 17, 2020
;; Version: 0.0.1
;; Keywords: convenience
;; Homepage: https://git.sr.ht/~zetagon/el-secretario
;; Package-Requires: ((emacs "27.1")  (org-ql "0.6-pre") (hercules "0.3"))
;;
;; This file is not part of GNU Emacs.
;;
;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file LICENSE.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.
;;
;;; Commentary:
;;
;; The Emacs secretary that helps you through all your inboxes and tasks.  See
;; README.org
;;
;;; Code:
(require 'eieio)
(require 'eieio-base)
(require 'cl-lib)
(require 'org-ql)
(require 'hercules)
(require 'el-secretario-source)

(defvar el-secretario--is-testing nil
  "Determines if code is running in testing mode.

When a user is interacting with el-secretario this should always
be nil.  Set it to t if in testing.")

(defvar el-secretario--current-source-list nil
  "List of sources that have not yet been reviewed by the user.")

(defvar el-secretario--current-source-list-done nil
  "List of sources that have been reviewed by the user.")

(defvar el-secretario--status-buffer-name "*el-secretario-status*"
  "The name of the status buffer.")

(defvar el-secretario--original-buffer nil
  "The buffer the user was in before activating el-secretario.")

(defun el-secretario-activate-keymap ()
  "Activate the keymap of the currently active source."
  (interactive)
  (when el-secretario--current-source-list
    (el-secretario--source-keymap-activate (car el-secretario--current-source-list))))


;;;###autoload
(defun el-secretario-start-session (source-list)
  "Start session specified by SOURCE-LIST.

SOURCE-LIST should be a list of newly instantiated sources, or
SOURCE-LIST is a function that returns a list of newly instantiated sources.

All nil elements are filtered out from SOURCE-LIST."
  (setq el-secretario--original-buffer (current-buffer))
  (setq el-secretario--current-source-list
        (seq-filter (-compose #'not #'null)
                    (--> (if (functionp source-list)
                             (funcall source-list)
                           source-list)
                         (if (listp it)
                             it
                           (list it)))))
  (setq el-secretario--current-source-list-done nil)
  (with-current-buffer (get-buffer-create "*el-secretario-en*")
    (delete-region (point-min) (point-max)))
  (el-secretario--status-buffer-activate)
  (el-secretario-source-init (car el-secretario--current-source-list)))

(defun el-secretario-end-session ()
  "End current session and do cleanup."
  (interactive)
  (switch-to-buffer el-secretario--original-buffer)
  (el-secretario-status-buffer-deactivate))

(defun el-secretario-next-item ()
  "Go to the next item of this session."
  (interactive)
  (when el-secretario--current-source-list
    (el-secretario-source-next-item
     (car el-secretario--current-source-list))))

(defun el-secretario-previous-item ()
  "Go to the previous item of this session."
  (interactive)
  (when el-secretario--current-source-list
    (el-secretario-source-previous-item
     (car el-secretario--current-source-list))))

(defun el-secretario--next-source ()
  "Switch to the next source in this session."
  (if el-secretario--current-source-list
      (progn
        (el-secretario-source-cleanup (car el-secretario--current-source-list))
        (push (pop el-secretario--current-source-list)
              el-secretario--current-source-list-done)
        (if el-secretario--current-source-list
            (el-secretario-source-init (car el-secretario--current-source-list))
          (with-current-buffer (get-buffer-create "*el-secretario-en*")
            (insert "Done!"))
          (switch-to-buffer (get-buffer-create "*el-secretario-en*"))))
    (el-secretario-status-buffer-deactivate)
    (el-secretario-end-session)))

(defun el-secretario--previous-source ()
  "Switch to the previous source in this session."
  (if el-secretario--current-source-list-done
      (progn
        (el-secretario-source-cleanup (car el-secretario--current-source-list))
        (push (pop el-secretario--current-source-list-done)
              el-secretario--current-source-list)
        (if el-secretario--current-source-list
            (el-secretario-source-init (car el-secretario--current-source-list) 'backward)
          (message "ooflakjdlkf")))
    (message "No more previous sources!")))


(defun el-secretario--status-buffer-activate ()
  "Activate the status buffer."
  (el-secretario-status-buffer-deactivate)
  (display-buffer-in-side-window (get-buffer-create el-secretario--status-buffer-name)
                                 '((side . top))))

(defun el-secretario-status-buffer-deactivate ()
  "Deactivate the status buffer."
  (-some-> (get-buffer-window el-secretario--status-buffer-name)
    (delete-window)))

;;; Utility functions


(defvar el-secretario--y-or-no-p-input-list nil
  "The list `el-secretario-y-or-no-p' will take from if in testing mode.")

(defun el-secretario--y-or-n-p (prompt)
  "A version of `y-or-n-p' that is testable.
Pass PROMPT to `y-or-n-p'."
  (if el-secretario--is-testing
      (pop el-secretario--y-or-no-p-input-list)
    (y-or-n-p prompt)))

;; Shuffling a list. Credit: https://kitchingroup.cheme.cmu.edu/blog/2014/09/06/Randomize-a-list-in-Emacs/
(defun el-secretario--swap (LIST x y)
  "Swap item X and Y in LIST."
  (cl-psetf (elt LIST y) (elt LIST x)
            (elt LIST x) (elt LIST y)))

(defun el-secretario--shuffle (LIST)
  "Shuffle the elements in LIST.
shuffling is done in place."
  (cl-loop for i in (reverse (number-sequence 1 (1- (length LIST))))
           do (let ((j (random (+ i 1))))
                (el-secretario--swap LIST i j)))
  LIST)


(define-advice hercules--show (:override (&optional keymap flatten transient &rest _))
  "Summon hercules.el showing KEYMAP.
Push KEYMAP onto `overriding-terminal-local-map' when TRANSIENT
is nil.  Otherwise use `set-transient-map'.  If FLATTEN is t,
show full keymap \(including sub-maps\), and prevent redrawing on
prefix-key press by overriding `which-key--update'."
  (setq hercules--popup-showing-p t
        which-key-persistent-popup t)
  (when keymap
    (let ((which-key-show-prefix hercules-show-prefix))
      (if flatten
          (progn
            (which-key--show-keymap
             (symbol-name keymap) (symbol-value keymap) nil t t)
            (advice-add #'which-key--update :override #'ignore))
        (which-key--show-keymap
         (symbol-name keymap) (symbol-value keymap) nil nil t)))
    (if transient
        (set-transient-map (symbol-value keymap)
                           t (lambda () (hercules--hide keymap transient)))
      (internal-push-keymap (symbol-value keymap)
                            'overriding-terminal-local-map))))

;;; HACK: Patch for hercules' intereraction with minibuffer
;;; Remove when https://github.com/wurosh/hercules/pull/2 is merged

(defvar el-secretario-hercules--show-arguments nil
  "The arguments `hercules--show' was last called with.")
(defvar el-secretario-hercules--temporary-hide-hooks
  '(el-secretario-hercules--hide-before-minibuffer
    ((:function read-string)
     (:function read-from-minibuffer)))
  "Hooks for temporarily hiding hercules.

CAR should be `hercules--hide-before-minibuffer'.  CDR is a list of
hooks (as defined by `el-secretario-hercules--add-hooks') for when to
temporarily hide hercules.  Also see
`el-secretario-hercules--temporary-restore-hooks'.

Call by
`(apply el-secretario-hercules--add-hooks
        el-secretario-hercules--temporary-hide-hooks)'
or
`(apply el-secretario-hercules--remove-hooks
        el-secretario-hercules--temporary-hide-hooks)'.")

(defvar el-secretario-hercules--temporary-restore-hooks
  '(el-secretario-hercules--restore-after-minibuffer
    ((:hook minibuffer-exit-hook)))
  "Hooks for showing hercules after temporarily hiding.

CAR should be `el-secretario-hercules--restore-after-minibuffer'.  CDR is a list
of hooks (as defined by `el-secretario-hercules--add-hooks') for when to show
hercules after temporarily hiding it with
`el-secretario-hercules--temporary-hide-hooks'.

Call by
`(apply el-secretario-hercules--add-hooks
        el-secretario-hercules--temporary-hide-hooks)'
or
`(apply el-secretario-hercules--remove-hooks
        el-secretario-hercules--temporary-hide-hooks)'.")

(define-advice hercules--hide (:before (&rest _))
  (apply #'el-secretario-hercules--remove-hooks el-secretario-hercules--temporary-hide-hooks))
(define-advice hercules--show (:before (&optional keymap flatten transient &rest _))
  (setq el-secretario-hercules--show-arguments (list keymap flatten transient))
  (apply #'el-secretario-hercules--add-hooks el-secretario-hercules--temporary-hide-hooks))

(defun el-secretario-hercules--remove-hooks (fun hooks)
  "Add FUN to HOOKS.

HOOKS is a (TYPE SYM) plist.  If KEY is :hook remove FUN from the hook
SYM.  If KEY is :function remove FUN as :before advice from SYM."
  (dolist (x hooks)
    (if-let ((hook (plist-get x :hook)))
        (remove-hook hook fun))
    (if-let ((sym (plist-get x :function)))
        (advice-remove sym fun))))

(defun el-secretario-hercules--add-hooks (fun hooks)
  "Add FUN to HOOKS.

HOOKS is a (TYPE SYM) plist.  If KEY is :hook add FUN to the hook
SYM.  If KEY is :function add FUN as :before advice to SYM."
  (dolist (x hooks)
    (if-let ((hook (plist-get x :hook)))
        (add-hook hook fun))
    (if-let ((sym (plist-get x :function)))
        (advice-add sym :before fun))))

(defun el-secretario-hercules--hide-before-minibuffer (&rest _)
  "Temporarily hide hercules.el when the minibuffer is shown.

See `el-secretario-hercules--temporary-hide-hooks'"
  (apply #'el-secretario-hercules--remove-hooks el-secretario-hercules--temporary-hide-hooks)
  (apply #'el-secretario-hercules--add-hooks el-secretario-hercules--temporary-restore-hooks)
  (apply #'hercules--hide el-secretario-hercules--show-arguments))
(defun el-secretario-hercules--restore-after-minibuffer ()
  "Show hercules.el after temporarily hiding when the minibuffer is shown.

See `el-secretario-hercules--temporary-restore-hooks'"
  ;; This timer is needed. Otherwise hercules will for some reason hide
  ;; immedeately after being shown.
  (run-with-timer 0.001 nil
                  (lambda ()
                    (apply #'el-secretario-hercules--remove-hooks el-secretario-hercules--temporary-restore-hooks)
                    (apply #'hercules--show el-secretario-hercules--show-arguments))))
;;;
(cl-pushnew '(:function org-capture)
            (car (cdr el-secretario-hercules--temporary-hide-hooks)))
(cl-pushnew '(:hook org-capture-after-finalize-hook)
            (car (cdr el-secretario-hercules--temporary-restore-hooks)))

(provide 'el-secretario)
;;; el-secretario.el ends here
