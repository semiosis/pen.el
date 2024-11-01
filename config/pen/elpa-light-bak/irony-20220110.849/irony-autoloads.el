;;; irony-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "irony" "irony.el" (0 0 0 0))
;;; Generated autoloads from irony.el

(defvar irony-additional-clang-options nil "\
Additional command line options to pass down to libclang.

Please, do NOT use this variable to add header search paths, only
additional warnings or compiler options.

These compiler options will be prepended to the command line, in
order to not override the value coming from a compilation
database.")

(custom-autoload 'irony-additional-clang-options "irony" t)

(autoload 'irony-mode "irony" "\
Minor mode for C, C++ and Objective-C, powered by libclang.

If called interactively, toggle `Irony mode'.  If the prefix
argument is positive, enable the mode, and if it is zero or
negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(autoload 'irony-version "irony" "\
Return the version number of the file irony.el.

If called interactively display the version in the echo area.

\(fn &optional SHOW-VERSION)" t nil)

(autoload 'irony-server-kill "irony" "\
Kill the running irony-server process, if any." t nil)

(autoload 'irony-get-type "irony" "\
Get the type of symbol under cursor." t nil)

(register-definition-prefixes "irony" '("irony-"))

;;;***

;;;### (autoloads nil "irony-cdb" "irony-cdb.el" (0 0 0 0))
;;; Generated autoloads from irony-cdb.el

(autoload 'irony-cdb-autosetup-compile-options "irony-cdb" nil t nil)

(autoload 'irony-cdb-menu "irony-cdb" nil t nil)

(register-definition-prefixes "irony-cdb" '("irony-cdb-"))

;;;***

;;;### (autoloads nil "irony-cdb-clang-complete" "irony-cdb-clang-complete.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from irony-cdb-clang-complete.el

(autoload 'irony-cdb-clang-complete "irony-cdb-clang-complete" "\


\(fn COMMAND &rest ARGS)" nil nil)

(register-definition-prefixes "irony-cdb-clang-complete" '("irony-cdb-clang-complete--"))

;;;***

;;;### (autoloads nil "irony-cdb-json" "irony-cdb-json.el" (0 0 0
;;;;;;  0))
;;; Generated autoloads from irony-cdb-json.el

(autoload 'irony-cdb-json "irony-cdb-json" "\


\(fn COMMAND &rest ARGS)" nil nil)

(autoload 'irony-cdb-json-add-compile-commands-path "irony-cdb-json" "\
Add an out-of-source compilation database.

Files below the PROJECT-ROOT directory will use the JSON
Compilation Database as specified by COMPILE-COMMANDS-PATH.

The JSON Compilation Database are often generated in the build
directory. This functions helps mapping out-of-source build
directories to project directory.

\(fn PROJECT-ROOT COMPILE-COMMANDS-PATH)" t nil)

(autoload 'irony-cdb-json-select "irony-cdb-json" "\
Select CDB to use with a prompt.

It is useful when you have several CDBs with the same project
root.

The completion function used internally is `completing-read' so
it could easily be used with other completion functions by
temporarily using a let-bind on `completing-read-function'. Or
even helm by enabling `helm-mode' before calling the function." t nil)

(autoload 'irony-cdb-json-select-most-recent "irony-cdb-json" "\
Select CDB that is most recently modified." t nil)

(register-definition-prefixes "irony-cdb-json" '("irony-cdb-json--"))

;;;***

;;;### (autoloads nil "irony-cdb-libclang" "irony-cdb-libclang.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from irony-cdb-libclang.el

(autoload 'irony-cdb-libclang "irony-cdb-libclang" "\


\(fn COMMAND &rest ARGS)" nil nil)

(register-definition-prefixes "irony-cdb-libclang" '("irony-cdb-libclang--"))

;;;***

;;;### (autoloads nil "irony-completion" "irony-completion.el" (0
;;;;;;  0 0 0))
;;; Generated autoloads from irony-completion.el

(autoload 'irony-completion-at-point "irony-completion" nil nil nil)

(register-definition-prefixes "irony-completion" '("irony-"))

;;;***

;;;### (autoloads nil "irony-diagnostics" "irony-diagnostics.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from irony-diagnostics.el

(register-definition-prefixes "irony-diagnostics" '("irony-diagnostics-"))

;;;***

;;;### (autoloads nil "irony-iotask" "irony-iotask.el" (0 0 0 0))
;;; Generated autoloads from irony-iotask.el

(register-definition-prefixes "irony-iotask" '("irony-iotask-"))

;;;***

;;;### (autoloads nil "irony-snippet" "irony-snippet.el" (0 0 0 0))
;;; Generated autoloads from irony-snippet.el

(register-definition-prefixes "irony-snippet" '("irony-snippet-"))

;;;***

;;;### (autoloads nil nil ("irony-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; irony-autoloads.el ends here
