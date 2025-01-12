;;; matlab-maint.el --- matlab mode maintainer utilities
;;
;; Copyright (C) 2019 Eric Ludlam
;;
;; Author: Eric Ludlam <eludlam@emacsvm>
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see https://www.gnu.org/licenses/.

;;; Commentary:
;;
;; Interface for maintainers of matlab mode.

(require 'matlab)
(require 'matlab-shell)
(require 'matlab-netshell)
(require 'semantic/symref)
(require 'semantic/symref/list)

;;; Code:

;;; Minor Mode Definition
;;
(defvar matlab-maint-mode-map
  (let ((km (make-sparse-keymap)))
    ;; compile debug cycle
    (define-key km [f8] 'matlab-maint-run-tests)
    (define-key km [f9] 'matlab-maint-compile-matlab-emacs)
    (define-key km [f10] 'matlab-maint-reload-mode)
    ;; coding
    (define-key km [f7] 'matlab-maint-symref-this)
    ;; matlab
    (define-key km [f5] 'matlab-maint-show-info)
    km)
  "Keymap used by matlab mode maintainers.")

(easy-menu-define
  matlab-maint-menu matlab-maint-mode-map "MATLAB Maintainer's Minor Mode"
  '("MMaint"
    ["Compile" matlab-maint-compile-matlab-emacs t]
    ["Clean" matlab-maint-compile-clean t]
    ["Run Tests" matlab-maint-run-tests t]
    ["Pick Emacs to run" matlab-maint-pick-emacs t]
    ["Toggle IO Logging" matlab-maint-toggle-io-tracking
     :style toggle :selected matlab-shell-io-testing ]
    ["Display logger frame" matlab-maint-toggle-logger-frame
     :style toggle :selected (and matlab-maint-logger-frame
				  (frame-live-p matlab-maint-logger-frame)) ]
    ))

;;;###autoload
(define-minor-mode matlab-maint-minor-mode
  "Minor mode for matlab-mode maintainrs."
  nil " MMaint" matlab-maint-mode-map
  )

;;;###autoload
(define-global-minor-mode global-matlab-maint-minor-mode
  matlab-maint-minor-mode
  (lambda ()
    "Should we turn on in this buffer? Only if in the project."
    (let ((dir (expand-file-name default-directory))
	  (ml (file-name-directory (expand-file-name (locate-library "matlab")))))
      (when (string= ml (substring dir 0 (min (length dir) (length ml))))
	(matlab-maint-minor-mode 1))))
  )

;;; Testing stuff in M buffers
;;
(defun matlab-maint-show-info ()
  "Show info about line in current matlab buffer."
  (interactive)
  (when (eq major-mode 'matlab-mode)
    (matlab-show-line-info)
    ))

;;; HACKING ELISP
;;

(defun matlab-maint-symref-this ()
  "Open a symref buffer on symbol under cursor."
  (interactive)
  (save-buffer)
  (semantic-fetch-tags)
  (let ((ct (semantic-current-tag)))
    ;; Must have a tag...
    (when (not ct) (error "Place cursor inside tag to be searched for"))
    ;; Gather results and tags
    (message "Gathering References for %s.." (semantic-tag-name ct))
    (let* ((name (semantic-tag-name ct))
           (res (semantic-symref-find-references-by-name name)))
      (semantic-symref-produce-list-on-results res name)
      (semantic-symref-list-expand-all) )))


;;; COMPILE AND TEST
;;
;; Helpful commands for maintainers.
(defcustom matlab-maint-compile-opts '("emacs" "emacs24" "emacs25" "emacs26")
  "Various emacs versions we can use to compile with."
  :group 'matlab-maint
  :type '(repeat (string :tag "Emacs Command: ")))

(defcustom matlab-maint-compile-emacs "emacs"
  "The EMACS to pass into make."
  :group 'matlab-maint
  :type 'string)

(defun matlab-maint-pick-emacs (emacscmd)
  "Select the Emacs to use for compiling."
  (interactive (list (completing-read "Emacs to compile MATLAB: "
				      matlab-maint-compile-opts
				      nil
				      t
				      (car matlab-maint-compile-opts))))
  (setq matlab-maint-compile-emacs emacscmd)
  )

(defun matlab-maint-compile-matlab-emacs ()
  "Run make for the matlab-emacs project."
  (interactive)
  (save-excursion
    (matlab-maint-set-buffer-to "matlab.el")
    (if (string= matlab-maint-compile-emacs "emacs")
	(compile "make")
      (compile (concat "make EMACS=" matlab-maint-compile-emacs))))
  )

(defun matlab-maint-compile-clean ()
  "Run make for the matlab-emacs project."
  (interactive)
  (save-excursion
    (matlab-maint-set-buffer-to "matlab.el")
    (compile "make clean")
    ))

(defun matlab-maint-run-tests (arg)
  "Run the tests for matlab mode.
With universal ARG, ask for the code to be run with output tracking turned on."
  (interactive "P")
  (when (buffer-file-name)
    (save-buffer))
  (save-excursion
    (matlab-maint-set-buffer-to "tests/Makefile")
    (if (or arg matlab-shell-io-testing)
	;; Ask for dbug
	(compile "make TESTDEBUG=1")
      ;; No debugging
      (compile "make")))
  (switch-to-buffer "*compilation*")
  (delete-other-windows)
  (goto-char (point-max)))

(defun matlab-maint-reload-mode ()
  "Reload matlab mode, and refresh displayed ML buffers modes."
  (interactive)
  (load-library "matlab-syntax")
  (load-library "matlab-scan")
  (load-library "matlab")
  (mapc (lambda (b) (with-current-buffer b
		      (when (eq major-mode 'matlab-mode)
			(message "Updating matlab mode in %S" b)
			(matlab-mode))))
	(buffer-list (selected-frame)))
  (message "loading done")
  )
;;; MATLAB SHELL tools
;;

(defun matlab-maint-set-buffer-to (file)
  "Set the current buffer to FILE found in matlab-mode's source.
Return the buffer."
  (let* ((ml (file-name-directory (locate-library "matlab")))
	 (newf (expand-file-name file ml)))
    (set-buffer (find-file-noselect newf))))

(defun matlab-maint-toggle-io-tracking ()
  "Toggle tracking of IO with MATLAB Shell."
  (interactive)
  (setq matlab-shell-io-testing (not matlab-shell-io-testing))
  (message "MATLAB Shell IO logging %s" (if matlab-shell-io-testing
					    "enabled" "disabled")))

(defvar matlab-maint-logger-frame nil
  "Frame displaying log information.")

(defun matlab-maint-toggle-logger-frame ()
  "Display a frame showing various log buffers."
  (interactive)
  (if (and matlab-maint-logger-frame
	   (frame-live-p matlab-maint-logger-frame))
      (progn
	(delete-frame matlab-maint-logger-frame)
	(setq matlab-maint-logger-frame nil))
    ;; Otherwise, create ...
    (setq matlab-maint-logger-frame (make-frame))
    (with-selected-frame matlab-maint-logger-frame
      (delete-other-windows)
      (switch-to-buffer "*Messages*")
      (when (matlab-netshell-client)
	(split-window-horizontally)
	(other-window 1)
	(switch-to-buffer (process-buffer (matlab-netshell-client)))
	))))

(provide 'matlab-maint)

;;; matlab-maint.el ends here
