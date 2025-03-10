;;; mu4easy-autoloads.el --- automatically extracted autoloads (do not edit)   -*- lexical-binding: t -*-
;; Generated by the `loaddefs-generate' function.

;; This file is part of GNU Emacs.

;;; Code:

(add-to-list 'load-path (or (and load-file-name (directory-file-name (file-name-directory load-file-name))) (car load-path)))



;;; Generated autoloads from mu4easy.el

(defvar mu4easy-mode nil "\
Non-nil if Mu4easy mode is enabled.
See the `mu4easy-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `mu4easy-mode'.")
(custom-autoload 'mu4easy-mode "mu4easy" nil)
(autoload 'mu4easy-mode "mu4easy" "\
Toggle mu4easy configuration and keymaps.

This is a global minor mode.  If called interactively, toggle the
`Mu4easy mode' mode.  If the prefix argument is positive, enable
the mode,  and if it is zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

To check whether the minor mode is enabled in the current buffer,
evaluate `(default-value \\='mu4easy-mode)'.

The mode's hook is called both when the mode is enabled and when
it is disabled.

(fn &optional ARG)" t)
(register-definition-prefixes "mu4easy" '("mu4easy-"))

;;; End of scraped data

(provide 'mu4easy-autoloads)

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; no-native-compile: t
;; coding: utf-8-emacs-unix
;; End:

;;; mu4easy-autoloads.el ends here
