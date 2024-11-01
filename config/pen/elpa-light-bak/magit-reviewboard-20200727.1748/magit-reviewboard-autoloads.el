;;; magit-reviewboard-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "magit-reviewboard" "magit-reviewboard.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from magit-reviewboard.el

(autoload 'magit-reviewboard-list "magit-reviewboard" "\
Show review-request list of the current ReviewBoard repository in a buffer.
With prefix, prompt for repository's DIRECTORY.

\(fn &optional DIRECTORY)" t nil)

(autoload 'magit-reviewboard-list-internal "magit-reviewboard" "\
Open buffer showing review-request list of repository at DIRECTORY.

\(fn DIRECTORY)" nil nil)

(defvar magit-reviewboard-mode nil "\
Non-nil if Magit-Reviewboard mode is enabled.
See the `magit-reviewboard-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `magit-reviewboard-mode'.")

(custom-autoload 'magit-reviewboard-mode "magit-reviewboard" nil)

(autoload 'magit-reviewboard-mode "magit-reviewboard" "\
Show list of reviews in Magit status buffer for tracked reviews in repo.

If called interactively, toggle `Magit-Reviewboard mode'.  If the
prefix argument is positive, enable the mode, and if it is zero
or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "magit-reviewboard" '("magit-reviewboard-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; magit-reviewboard-autoloads.el ends here
