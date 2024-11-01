;;; malinka-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "malinka" "malinka.el" (0 0 0 0))
;;; Generated autoloads from malinka.el

(autoload 'malinka-project-configure "malinka" "\
Configure a project by querying for both NAME and GIVEN-ROOT-DIR.

If multiple projects with the same name in different directories may
exist then it's nice to provide the ROOT-DIR of the project to configure

\(fn NAME GIVEN-ROOT-DIR)" t nil)

(autoload 'malinka-project-select "malinka" "\
Select a project by querying for both NAME and GIVEN-ROOT-DIR.

If multiple projects with the same name in different directories may
exist then it's nice to provide the ROOT-DIR of the project to configure

\(fn NAME GIVEN-ROOT-DIR)" t nil)

(autoload 'malinka-mode "malinka" "\
Enables all malinka functionality for the current buffer

If called interactively, toggle `Malinka mode'.  If the prefix
argument is positive, enable the mode, and if it is zero or
negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "malinka" '("async-shell-command-to-string" "malinka-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; malinka-autoloads.el ends here
