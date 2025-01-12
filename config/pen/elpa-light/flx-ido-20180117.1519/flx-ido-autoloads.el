;;; flx-ido-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "flx-ido" "flx-ido.el" (0 0 0 0))
;;; Generated autoloads from flx-ido.el

(defvar flx-ido-mode nil "\
Non-nil if Flx-Ido mode is enabled.
See the `flx-ido-mode' command
for a description of this minor mode.")

(custom-autoload 'flx-ido-mode "flx-ido" nil)

(autoload 'flx-ido-mode "flx-ido" "\
Toggle flx ido mode

If called interactively, toggle `Flx-Ido mode'.  If the prefix
argument is positive, enable the mode, and if it is zero or
negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "flx-ido" '("flx-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; flx-ido-autoloads.el ends here
