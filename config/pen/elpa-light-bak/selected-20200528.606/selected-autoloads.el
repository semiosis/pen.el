;;; selected-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "selected" "selected.el" (0 0 0 0))
;;; Generated autoloads from selected.el

(autoload 'selected-minor-mode "selected" "\
If enabled activates the `selected-keymap' when the region is active.

If called interactively, enable Selected minor mode if ARG is
positive, and disable it if ARG is zero or negative.  If called
from Lisp, also enable the mode if ARG is omitted or nil, and
toggle it if ARG is `toggle'; disable the mode otherwise.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(put 'selected-global-mode 'globalized-minor-mode t)

(defvar selected-global-mode nil "\
Non-nil if Selected-Global mode is enabled.
See the `selected-global-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `selected-global-mode'.")

(custom-autoload 'selected-global-mode "selected" nil)

(autoload 'selected-global-mode "selected" "\
Toggle Selected minor mode in all buffers.
With prefix ARG, enable Selected-Global mode if ARG is positive;
otherwise, disable it.  If called from Lisp, enable the mode if
ARG is omitted or nil.

Selected minor mode is enabled in all buffers where
`selected--global-on-p' would do it.
See `selected-minor-mode' for more information on Selected minor mode.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "selected" '("selected-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; selected-autoloads.el ends here
