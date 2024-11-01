;;; magit-vcsh-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "magit-vcsh" "magit-vcsh.el" (0 0 0 0))
;;; Generated autoloads from magit-vcsh.el

(autoload 'magit-vcsh-status "magit-vcsh" "\
Make vcsh REPO current (cf. `vcsh-link') and run `magit-status' in it.

\(fn REPO)" t nil)

(defvar magit-vcsh-hack-mode nil "\
Non-nil if Magit-Vcsh-Hack mode is enabled.
See the `magit-vcsh-hack-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `magit-vcsh-hack-mode'.")

(custom-autoload 'magit-vcsh-hack-mode "magit-vcsh" nil)

(autoload 'magit-vcsh-hack-mode "magit-vcsh" "\
Advise Magit functions to work with vcsh repositories.
In particular, when this mode is enabled, `magit-status' and
`magit-list-repositories' should work as expected.

If called interactively, toggle `Magit-Vcsh-Hack mode'.  If the
prefix argument is positive, enable the mode, and if it is zero
or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "magit-vcsh" '("magit-vcsh-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; magit-vcsh-autoloads.el ends here
