;;; persp-mode-autoloads.el --- automatically extracted autoloads (do not edit)   -*- lexical-binding: t -*-
;; Generated by the `loaddefs-generate' function.

;; This file is part of GNU Emacs.

;;; Code:

(add-to-list 'load-path (or (and load-file-name (directory-file-name (file-name-directory load-file-name))) (car load-path)))



;;; Generated autoloads from persp-mode.el

(autoload 'persp-def-auto-persp "persp-mode" "\


(fn NAME &rest KEYARGS &key BUFFER-NAME FILE-NAME MODE MODE-NAME MINOR-MODE MINOR-MODE-NAME PREDICATE HOOKS DYN-ENV GET-NAME GET-BUFFER GET-PERSP SWITCH PARAMETERS NOAUTO WEAK USER-DATA ON-MATCH AFTER-MATCH DONT-PICK-UP-BUFFERS DELETE)")
(define-obsolete-function-alias 'def-auto-persp 'persp-def-auto-persp "persp-mode 2.9.6")
(autoload 'persp-def-buffer-save/load "persp-mode" "\


(fn &rest KEYARGS &key BUFFER-NAME FILE-NAME MODE MODE-NAME MINOR-MODE MINOR-MODE-NAME PREDICATE TAG-SYMBOL SAVE-VARS SAVE-FUNCTION LOAD-FUNCTION AFTER-LOAD-FUNCTION MODE-RESTORE-FUNCTION APPEND)")
(define-obsolete-function-alias 'def-persp-buffer-save/load 'persp-def-buffer-save/load "persp-mode 2.9.6")
(defvar persp-mode nil "\
Non-nil if Persp mode is enabled.
See the `persp-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `persp-mode'.")
(custom-autoload 'persp-mode "persp-mode" nil)
(autoload 'persp-mode "persp-mode" "\
Toggle the persp-mode.

When active, keeps track of multiple 'perspectives',
named collections of buffers and window configurations.
Here is a keymap of this minor mode:
\\{persp-mode-map}

This is a global minor mode.  If called interactively, toggle the
`Persp mode' mode.  If the prefix argument is positive, enable
the mode, and if it is zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

To check whether the minor mode is enabled in the current buffer,
evaluate `(default-value \\='persp-mode)'.

The mode's hook is called both when the mode is enabled and when
it is disabled.

(fn &optional ARG)" t)
(register-definition-prefixes "persp-mode" '("*persp-" "clear-window-persp" "def-" "get-" "ido-toggle-persp-filter" "persp" "safe-persp-" "set-" "window-persp-set-p" "with-persp-ido-hooks"))

;;; End of scraped data

(provide 'persp-mode-autoloads)

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; no-native-compile: t
;; coding: utf-8-emacs-unix
;; End:

;;; persp-mode-autoloads.el ends here
