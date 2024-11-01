;;; helm-flx-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "helm-flx" "helm-flx.el" (0 0 0 0))
;;; Generated autoloads from helm-flx.el

(defvar helm-flx-mode nil "\
Non-nil if Helm-Flx mode is enabled.
See the `helm-flx-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `helm-flx-mode'.")

(custom-autoload 'helm-flx-mode "helm-flx" nil)

(autoload 'helm-flx-mode "helm-flx" "\
helm-flx minor mode

If called interactively, toggle `Helm-Flx mode'.  If the prefix
argument is positive, enable the mode, and if it is zero or
negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "helm-flx" '("helm-flx-"))

;;;***

;;;### (autoloads nil nil ("helm-flx-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; helm-flx-autoloads.el ends here
