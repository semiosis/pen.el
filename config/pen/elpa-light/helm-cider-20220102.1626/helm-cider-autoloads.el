;;; helm-cider-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "helm-cider" "helm-cider.el" (0 0 0 0))
;;; Generated autoloads from helm-cider.el

(autoload 'helm-cider-apropos-symbol "helm-cider" "\
Choose Clojure symbols across namespaces.

Each Helm source is a Clojure namespace (ns), and candidates are
symbols in the namespace.

If both NS and SYMBOL are supplied, puts selection line on
first SYMBOL of NS.

If NS is supplied, puts the selection line on the first
candidate of source with name NS.

If SYMBOL is supplied, puts the selection line on the
first candidate matching SYMBOL.

If neither NS nor SYMBOL is supplied, tries to put the
selection line on candidate matching symbol at point.

If DOC is true, include symbol documentation in candidate.

If FULL-DOC is true, include full instead of short documentation.

Set `helm-cider-apropos-follow' to true to turn on function
`helm-follow-mode' for all sources.  This is useful for quickly
browsing documentation.

\(fn &optional NS SYMBOL DOC FULL-DOC)" t nil)

(autoload 'helm-cider-apropos-symbol-doc "helm-cider" "\
Choose Clojure SYMBOLs, with docs, across namespaces.

Optional arguments NS and SYMBOL are as in
`helm-cider-apropos-symbol'.

\(fn &optional NS SYMBOL)" t nil)

(autoload 'helm-cider-apropos-ns "helm-cider" "\
Choose Clojure namespace to call Helm CIDER apropos on.

NS-OR-QUALIFIED-NAME is a Clojure
namespace (e.g. \"clojure.core\") or a qualified symbol
name (e.g. \"clojure.core/reduce\").  If supplied, it is used as
the default selection.

\(fn &optional NS-OR-QUALIFIED-NAME)" t nil)

(autoload 'helm-cider-apropos "helm-cider" "\
Helm interface to CIDER apropos.

If ARG is raw prefix argument \\[universal-argument], include
symbol documentation.

If ARG is raw prefix argument \\[universal-argument]
\\[universal-argument], choose namespace before symbol.

\(fn &optional ARG)" t nil)

(defvar helm-cider-mode nil "\
Non-nil if Helm-Cider mode is enabled.
See the `helm-cider-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `helm-cider-mode'.")

(custom-autoload 'helm-cider-mode "helm-cider" nil)

(autoload 'helm-cider-mode "helm-cider" "\
Use Helm for CIDER.

If called interactively, toggle `Helm-Cider mode'.  If the prefix
argument is positive, enable the mode, and if it is zero or
negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "helm-cider" '("helm-cider-"))

;;;***

;;;### (autoloads nil "helm-cider-cheatsheet" "helm-cider-cheatsheet.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from helm-cider-cheatsheet.el

(autoload 'helm-cider-cheatsheet "helm-cider-cheatsheet" "\
Use Helm to show a Clojure cheatsheet." t nil)

(register-definition-prefixes "helm-cider-cheatsheet" '("helm-cider-cheatsheet--"))

;;;***

;;;### (autoloads nil "helm-cider-repl" "helm-cider-repl.el" (0 0
;;;;;;  0 0))
;;; Generated autoloads from helm-cider-repl.el

(autoload 'helm-cider-repl-history-insert "helm-cider-repl" "\
Insert candidate at the last CIDER REPL prompt.

Existing input at the prompt is cleared.

This function is meant to be one of `helm-cider-repl-history-actions'.

\(fn CANDIDATE)" nil nil)

(autoload 'helm-cider-repl-history-delete "helm-cider-repl" "\
Delete marked candidates from `cider-repl-input-history'.

This function is meant to be one of `helm-cider-repl-history-actions'.

\(fn CANDIDATE)" nil nil)

(autoload 'helm-cider-repl-history "helm-cider-repl" "\
Helm interface to CIDER REPL history." t nil)

(register-definition-prefixes "helm-cider-repl" '("helm-cider-repl-"))

;;;***

;;;### (autoloads nil "helm-cider-spec" "helm-cider-spec.el" (0 0
;;;;;;  0 0))
;;; Generated autoloads from helm-cider-spec.el

(autoload 'helm-cider-spec-symbol "helm-cider-spec" "\
Choose Clojure specs across namespaces.

Each Helm source is a Clojure namespace (ns), and candidates are
spec keywords in the namespace.

If both NS and NAME are supplied, puts selection line on
first NAME of NS.

If NS is supplied, puts the selection line on the first
candidate of source with name NS.

If NAME is supplied, puts the selection line on the
first candidate matching NAME.

Set `helm-cider-spec-follow' to non-nil to turn on function
`helm-follow-mode' for all sources.  This is useful for quickly
viewing specs.

\(fn &optional NS NAME)" t nil)

(autoload 'helm-cider-spec-ns "helm-cider-spec" "\
Choose spec namespace to call `helm-cider-browse-spec' on.

KW-NS-OR-QUALIFIED-NAME is a spec keyword namespace
 (e.g. \":ring.core\") or a qualified keyword
name (e.g. \":ring.core/error\").  If supplied, it is used as the
default selection.

\(fn &optional KW-NS-OR-QUALIFIED-NAME)" t nil)

(autoload 'helm-cider-spec "helm-cider-spec" "\
Helm interface to CIDER specs.

If ARG is raw prefix argument \\[universal-argument]
\\[universal-argument], choose namespace before symbol.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "helm-cider-spec" '("helm-cider-spec-"))

;;;***

;;;### (autoloads nil "helm-cider-util" "helm-cider-util.el" (0 0
;;;;;;  0 0))
;;; Generated autoloads from helm-cider-util.el

(register-definition-prefixes "helm-cider-util" '("helm-cider--" "wrap-helm-cider-action"))

;;;***

;;;### (autoloads nil nil ("helm-cider-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; helm-cider-autoloads.el ends here
