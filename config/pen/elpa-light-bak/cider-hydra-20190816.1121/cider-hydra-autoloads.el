;;; cider-hydra-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "cider-hydra" "cider-hydra.el" (0 0 0 0))
;;; Generated autoloads from cider-hydra.el

(autoload 'cider-hydra-mode "cider-hydra" "\
Hydras for CIDER.

If called interactively, toggle `Cider-Hydra mode'.  If the
prefix argument is positive, enable the mode, and if it is zero
or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "cider-hydra" '("cider-hydra-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; cider-hydra-autoloads.el ends here
