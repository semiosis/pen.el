;;; helm-ext.el --- A few extensions to Helm                  -*- lexical-binding: t; -*-

;; Copyright (C) 2017  Junpeng Qiu

;; Author: Junpeng Qiu <qjpchmail@gmail.com>
;; Keywords: extensions
;; Version: 0.1.0
;; Package-Requires: ((emacs "24.4") (helm "2.5.3"))

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

;;; Commentary:

;;                              _____________

;;                                 HELM-EXT

;;                               Junpeng Qiu
;;                              _____________


;; Table of Contents
;; _________________

;; 1 Skipping Dots
;; 2 ZShell Like Path Expansion
;; 3 Auto Path Expansion
;; 4 Use Header Line for Minibuffer Completions
;; 5 Other Tools
;; 6 WARNING


;; Extensions to [helm], which I find useful but are unlikely to be
;; accepted in the upstream.

;; A collection of dirty hacks for helm!


;; [helm] https://github.com/emacs-helm/helm


;; 1 Skipping Dots
;; ===============

;;   When entering an *NON-EMPTY* directory using `helm-find-files', skip
;;   the first two entries, `.' and `..'. But if the directory is *EMPTY*,
;;   the selection remains unchanged (still at the position of `.').

;;   To enable it:
;;   ,----
;;   | (helm-ext-ff-enable-skipping-dots t)
;;   `----

;;   Demo (note that the selection skips the first two entries, `.' and
;;   `..' when the directory is non-empty): [./screencasts/skip-dots.gif]

;;   It is also possible to "hide" the first two entries by recentering the
;;   first line. Use the following code to enable such behavior:
;;   ,----
;;   | (setq helm-ext-ff-skipping-dots-recenter t)
;;   `----

;;   Demo: [./screencasts/skip-dots-recenter.gif]

;;   You can see from the demo that the first two entries are just visually
;;   "hiden". You can still use `C-p' to move the selection to them.


;; 2 ZShell Like Path Expansion
;; ============================

;;   This enables zsh-style path expansion in Helm. For example, type
;;   `/h/q/f/b' and then execute the persistent action, the pattern expands
;;   to `/home/qjp/foo/bar', `/home/qjp/foo1/bar1/' etc. Select the
;;   candidate using the helm interface.

;;   To enable it:
;;   ,----
;;   | (helm-ext-ff-enable-zsh-path-expansion t)
;;   `----

;;   Demo: [./screencasts/zsh-expansion.gif]

;;   Here is an [old blog] of mine dicussing about this feature. Note that
;;   now helm already has the ability to search the directory recursively
;;   using the `locate' command as the backend, which is quite different.
;;   For me, I prefer my own approach since it feels more consistent when I
;;   switch between `zsh' and `helm'.


;; [old blog]
;; http://cute-jumper.github.io/emacs/2015/11/17/let-helm-support-zshlike-path-expansion


;; 3 Auto Path Expansion
;; =====================

;;   This feature is an improved version of the zsh-style path expansion.
;;   The expansion is performed /ON-THE-FLY/ as you're typing the pattern!

;;   To enable it:
;;   ,----
;;   | (helm-ext-ff-enable-auto-path-expansion t)
;;   `----

;;   (If you choose to enable this feature, then you don't need the
;;   previous zsh-path-expansion.)

;;   Demo: [./screencasts/auto-expansion.gif]

;;   To be improved: remove the restriction of only performing prefix
;;   matching in each level, making the matching behave more "fuzzily".


;; 4 Use Header Line for Minibuffer Completions
;; ============================================

;;   After enabling `helm-mode', hitting `TAB' in the minibuffer when using
;;   commands like `eval-expression' (`M-:') can also trigger the helm
;;   interface, but the problem is that the minibuffer is reused to enter
;;   the pattern so that we can't see the previous input in the minibuffer.
;;   So, instead of reusing the minibuffer to enter the pattern, use the
;;   header line to enter the pattern when the completion is triggered from
;;   the minibuffer.

;;   To enable it:
;;   ,----
;;   | (helm-ext-minibuffer-enable-header-line-maybe t)
;;   `----

;;   Demo: [./screencasts/minibuffer-header.gif]


;; 5 Other Tools
;; =============

;;   [ace-jump-helm-line] can be used for quick navigation in the helm
;;   window, which uses [avy] behind the scenes. Helm itself also has a
;;   lightweight alternative called `helm-linum-relative-mode' (type `C-x
;;   number' to select a candidate).


;; [ace-jump-helm-line] https://github.com/cute-jumper/ace-jump-helm-line

;; [avy] https://github.com/abo-abo/avy


;; 6 WARNING
;; =========

;;   *These are dirty hacks and it is highly likely that something may be
;;   BROKEN after the helm updates!*

;;; Code:

(require 'helm-ext-ff)
(require 'helm-ext-minibuffer)

;;;###autoload
(defun helm-ext-ff-enable-zsh-path-expansion (enable)
  (interactive)
  (if enable
      (advice-add 'helm-ff-kill-or-find-buffer-fname
                  :around
                  #'helm-ext-ff--try-expand-fname-first)
    (advice-remove 'helm-ff-kill-or-find-buffer-fname
                   #'helm-ext-ff--try-expand-fname-first)))
;;;###autoload
(defun helm-ext-ff-enable-auto-path-expansion (enable)
  (interactive)
  (if enable
      (advice-add 'helm-find-files-1
                  :around
                  'helm-ext-find-files-1)
    (advice-remove 'helm-find-files-1
                   'helm-ext-find-files-1))
  (dolist (func '(find-files-get-candidates
                  ff--transform-pattern-for-completion
                  ff-filter-candidate-one-by-one))
    (let ((old-func (intern (format "helm-%s" func)))
          (new-func (intern (format "helm-ext-%s" func))))
      (if enable
          (advice-add old-func :override new-func)
        (advice-remove old-func new-func)))))

;;;###autoload
(defun helm-ext-ff-enable-skipping-dots (enable)
  (interactive)
  (if enable
      (advice-add 'helm-ff-move-to-first-real-candidate
                  :around
                  'helm-ext-ff-skip-dots)
    (advice-remove 'helm-ff-move-to-first-real-candidate
                   'helm-ext-ff-skip-dots)))

;;;###autoload
(defun helm-ext-ff-enable-split-actions (enable)
  (interactive)
  (require 'helm-types)
  (if enable
      (progn
        (add-to-list 'helm-find-files-actions
                     helm-ext-ff--horizontal-split-action t)
        (add-to-list 'helm-find-files-actions
                     helm-ext-ff--vertical-split-action t)
        (add-to-list 'helm-type-buffer-actions
                     helm-ext-ff--buffer-horizontal-split-action t)
        (add-to-list 'helm-type-buffer-actions
                     helm-ext-ff--buffer-vertical-split-action t)
        (dolist (keymap helm-ext-ff-split-actions-keymaps)
          (define-key keymap
            (kbd helm-ext-ff-horizontal-split-key) #'helm-ext-ff-buffer-execute-horizontal-split)
          (define-key keymap
            (kbd helm-ext-ff-vertical-split-key) #'helm-ext-ff-buffer-execute-vertical-split)))
    (setq helm-find-files-actions
          (delete helm-ext-ff--horizontal-split-action
                  helm-find-files-actions))
    (setq helm-find-files-actions
          (delete helm-ext-ff--vertical-split-action
                  helm-find-files-actions))
    (setq helm-type-buffer-actions
          (delete helm-ext-ff--buffer-horizontal-split-action
                  helm-type-buffer-actions))
    (setq helm-type-buffer-actions
          (delete helm-ext-ff--buffer-vertical-split-action
                  helm-type-buffer-actions))
    (dolist (keymap helm-ext-ff-split-actions-keymaps)
      (define-key keymap
        (kbd helm-ext-ff-horizontal-split-key) nil)
      (define-key keymap
        (kbd helm-ext-ff-vertical-split-key) nil))))

;;;###autoload
(defun helm-ext-minibuffer-enable-header-line-maybe (enable)
  (if enable
      (add-hook 'helm-minibuffer-set-up-hook 'helm-ext--use-header-line-maybe)
    (remove-hook 'helm-minibuffer-set-up-hook 'helm-ext--use-header-line-maybe)))

(provide 'helm-ext)
;;; helm-ext.el ends here
