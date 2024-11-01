;;; lsp-java-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "dap-java" "dap-java.el" (0 0 0 0))
;;; Generated autoloads from dap-java.el
(with-eval-after-load 'lsp-java (require 'dap-java))

(register-definition-prefixes "dap-java" '("dap-java-"))

;;;***

;;;### (autoloads nil "lsp-java" "lsp-java.el" (0 0 0 0))
;;; Generated autoloads from lsp-java.el

(autoload 'lsp-java-lens-mode "lsp-java" "\
Toggle run/debug overlays.

If called interactively, toggle `Lsp-Java-Lens mode'.  If the
prefix argument is positive, enable the mode, and if it is zero
or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "lsp-java" '("lsp-java-"))

;;;***

;;;### (autoloads nil "lsp-java-boot" "lsp-java-boot.el" (0 0 0 0))
;;; Generated autoloads from lsp-java-boot.el

(autoload 'lsp-java-boot-lens-mode "lsp-java-boot" "\
Toggle code-lens overlays.

If called interactively, toggle `Lsp-Java-Boot-Lens mode'.  If
the prefix argument is positive, enable the mode, and if it is
zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "lsp-java-boot" '("lsp-java-boot-"))

;;;***

;;;### (autoloads nil "lsp-jt" "lsp-jt.el" (0 0 0 0))
;;; Generated autoloads from lsp-jt.el

(autoload 'lsp-jt-lens-mode "lsp-jt" "\
Toggle code-lens overlays.

If called interactively, toggle `Lsp-Jt-Lens mode'.  If the
prefix argument is positive, enable the mode, and if it is zero
or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(autoload 'lsp-jt-browser "lsp-jt" nil t nil)

(register-definition-prefixes "lsp-jt" '("lsp-jt-"))

;;;***

;;;### (autoloads nil nil ("lsp-java-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; lsp-java-autoloads.el ends here
