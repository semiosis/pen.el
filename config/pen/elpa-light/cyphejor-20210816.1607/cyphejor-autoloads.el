;;; cyphejor-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "cyphejor" "cyphejor.el" (0 0 0 0))
;;; Generated autoloads from cyphejor.el

(defvar cyphejor-mode nil "\
Non-nil if Cyphejor mode is enabled.
See the `cyphejor-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `cyphejor-mode'.")

(custom-autoload 'cyphejor-mode "cyphejor" nil)

(autoload 'cyphejor-mode "cyphejor" "\
Toggle the `cyphejor-mode' minor mode.

With a prefix argument ARG, enable `cyphejor-mode' if ARG is
positive, and disable it otherwise.  If called from Lisp, enable
the mode if ARG is omitted or NIL, and toggle it if ARG is
`toggle'.

This global minor mode shortens names of major modes by using a
set of user-defined rules in `cyphejor-rules'.  See the
description of the variable for more information.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "cyphejor" '("cyphejor-"))

;;;***

;;;### (autoloads nil nil ("cyphejor-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; cyphejor-autoloads.el ends here
