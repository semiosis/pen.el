;;; monroe-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "monroe" "monroe.el" (0 0 0 0))
;;; Generated autoloads from monroe.el

(autoload 'monroe-interaction-mode "monroe" "\
Minor mode for Monroe interaction from a Clojure buffer.

If called interactively, toggle `Monroe-Interaction mode'.  If
the prefix argument is positive, enable the mode, and if it is
zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

The following keys are available in `monroe-interaction-mode`:

  \\{monroe-interaction-mode}

\(fn &optional ARG)" t nil)

(autoload 'monroe "monroe" "\
Load monroe by setting up appropriate mode, asking user for
connection endpoint.

\(fn HOST-AND-PORT)" t nil)

(register-definition-prefixes "monroe" '("clojure-enable-monroe" "monroe-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; monroe-autoloads.el ends here
