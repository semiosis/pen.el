;;; helm-cscope-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "helm-cscope" "helm-cscope.el" (0 0 0 0))
;;; Generated autoloads from helm-cscope.el

(autoload 'helm-cscope-find-this-symbol "helm-cscope" "\
Locate a symbol in source code.

\(fn SYMBOL)" t nil)

(autoload 'helm-cscope-find-this-symbol-no-prompt "helm-cscope" "\
Locate a symbol in source code [no user prompting]." t nil)

(autoload 'helm-cscope-find-global-definition "helm-cscope" "\
Find a symbol's global definition.

\(fn SYMBOL)" t nil)

(autoload 'helm-cscope-find-global-definition-no-prompt "helm-cscope" "\
Find a symbol's global definition [no user prompting]." t nil)

(autoload 'helm-cscope-find-called-function "helm-cscope" "\
Display functions called by a function.

\(fn SYMBOL)" t nil)

(autoload 'helm-cscope-find-called-function-no-prompt "helm-cscope" "\
Display functions called by a function [no user prompting]." t nil)

(autoload 'helm-cscope-find-calling-this-function "helm-cscope" "\
Display functions calling a function.

\(fn SYMBOL)" t nil)

(autoload 'helm-cscope-find-calling-this-function-no-prompt "helm-cscope" "\
Display functions calling a function [no user prompting]." t nil)

(autoload 'helm-cscope-find-this-text-string "helm-cscope" "\
Locate where a text string occurs.

\(fn SYMBOL)" t nil)

(autoload 'helm-cscope-find-this-text-string-no-prompt "helm-cscope" "\
Locate where a text string occurs [no user prompting]." t nil)

(autoload 'helm-cscope-find-egrep-pattern "helm-cscope" "\
Run egrep over the cscope database.

\(fn SYMBOL)" t nil)

(autoload 'helm-cscope-find-this-file "helm-cscope" "\
Locate a file.

\(fn SYMBOL)" t nil)

(autoload 'helm-cscope-find-this-file-no-prompt "helm-cscope" "\
Locate a file [no user prompting]." t nil)

(autoload 'helm-cscope-find-files-including-file "helm-cscope" "\
Locate all files #including a file.

\(fn SYMBOL)" t nil)

(autoload 'helm-cscope-find-assignments-to-this-symbol "helm-cscope" "\
Locate assignments to a symbol in the source code.

\(fn SYMBOL)" t nil)

(autoload 'helm-cscope-find-assignments-to-this-symbol-no-prompt "helm-cscope" "\
Locate assignments to a symbol in the source code[no user prompting]." t nil)

(autoload 'helm-cscope-mode "helm-cscope" "\
Toggle Helm-Cscope mode on or off.

If called interactively, toggle `Helm-Cscope mode'.  If the
prefix argument is positive, enable the mode, and if it is zero
or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\\{helm-cscope-mode-map}

\(fn &optional ARG)" t nil)

(register-definition-prefixes "helm-cscope" '("helm-cscope-"))

;;;***

;;;### (autoloads nil nil ("helm-cscope-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; helm-cscope-autoloads.el ends here
