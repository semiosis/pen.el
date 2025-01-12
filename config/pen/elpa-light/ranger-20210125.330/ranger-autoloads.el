;;; ranger-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "ranger" "ranger.el" (0 0 0 0))
;;; Generated autoloads from ranger.el

(defvar ranger-key [16] "\
Key in `dired-mode' used to toggle `ranger-mode'.")

(custom-autoload 'ranger-key "ranger" t)

(defvar ranger-override-dired nil "\
When non-nil, load `deer' whenever dired is loaded.")

(custom-autoload 'ranger-override-dired "ranger" t)

(when ranger-key (add-hook 'dired-mode-hook (defun ranger-set-dired-key nil (define-key dired-mode-map ranger-key 'deer-from-dired))))

(autoload 'deer "ranger" "\
Launch dired in a minimal ranger window.

\(fn &optional PATH)" t nil)

(defvar ranger-override-dired-mode nil "\
Non-nil if Ranger-Override-Dired mode is enabled.
See the `ranger-override-dired-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `ranger-override-dired-mode'.")

(custom-autoload 'ranger-override-dired-mode "ranger" nil)

(autoload 'ranger-override-dired-mode "ranger" "\
Toggle ranger to override dired using `ranger-override-dired-fn'.

If called interactively, toggle `Ranger-Override-Dired mode'.  If
the prefix argument is positive, enable the mode, and if it is
zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(autoload 'ranger "ranger" "\
Launch dired in ranger-mode.

\(fn &optional PATH)" t nil)

(when ranger-override-dired (ranger-override-dired-mode t))

(autoload 'ranger-override-dired-fn "ranger" "\
Open dired as deer unless already in ranger-mode" nil nil)

(autoload 'ranger-mode "ranger" "\
Major mode emulating the ranger file manager in `dired'.

\\{ranger-mode-map}

\(fn)" t nil)

(register-definition-prefixes "ranger" '("deer-" "r--" "ranger-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; ranger-autoloads.el ends here
