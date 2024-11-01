;;; git-gutter+-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "git-gutter+" "git-gutter+.el" (0 0 0 0))
;;; Generated autoloads from git-gutter+.el

(autoload 'git-gutter+-mode "git-gutter+" "\
Git-Gutter mode

If called interactively, toggle `Git-Gutter+ mode'.  If the
prefix argument is positive, enable the mode, and if it is zero
or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(defvar global-git-gutter+-mode nil "\
Non-nil if Global Git-Gutter+ mode is enabled.
See the `global-git-gutter+-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `global-git-gutter+-mode'.")

(custom-autoload 'global-git-gutter+-mode "git-gutter+" nil)

(autoload 'global-git-gutter+-mode "git-gutter+" "\
Toggle Global Git-Gutter+ mode on or off.

If called interactively, toggle `Global Git-Gutter+ mode'.  If
the prefix argument is positive, enable the mode, and if it is
zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\\{global-git-gutter+-mode-map}

\(fn &optional ARG)" t nil)

(autoload 'git-gutter+-commit "git-gutter+" "\
Commit staged changes. If nothing is staged, ask to stage the current buffer." t nil)

(register-definition-prefixes "git-gutter+" '("git-gutter+-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; git-gutter+-autoloads.el ends here
