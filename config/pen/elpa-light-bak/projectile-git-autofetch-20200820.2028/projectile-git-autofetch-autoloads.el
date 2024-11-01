;;; projectile-git-autofetch-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "projectile-git-autofetch" "projectile-git-autofetch.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from projectile-git-autofetch.el

(defvar projectile-git-autofetch-mode nil "\
Non-nil if Projectile-Git-Autofetch mode is enabled.
See the `projectile-git-autofetch-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `projectile-git-autofetch-mode'.")

(custom-autoload 'projectile-git-autofetch-mode "projectile-git-autofetch" nil)

(autoload 'projectile-git-autofetch-mode "projectile-git-autofetch" "\
Fetch git repositories periodically.

If called interactively, toggle `Projectile-Git-Autofetch mode'.
If the prefix argument is positive, enable the mode, and if it is
zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "projectile-git-autofetch" '("projectile-git-autofetch-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; projectile-git-autofetch-autoloads.el ends here
