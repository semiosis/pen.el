;;; git-commit-insert-issue-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "git-commit-insert-issue" "git-commit-insert-issue.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from git-commit-insert-issue.el

(autoload 'git-commit-insert-issue-ask-issues "git-commit-insert-issue" "\
Ask for the issue to insert." t nil)

(autoload 'git-commit-insert-issue-mode "git-commit-insert-issue" "\
See the issues when typing 'Fixes #' in a commit message.

If called interactively, toggle `Git-Commit-Insert-Issue mode'.
If the prefix argument is positive, enable the mode, and if it is
zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "git-commit-insert-issue" '("+git-commit-insert-issues-gitlab-api-error+" "git-commit-insert-issue-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; git-commit-insert-issue-autoloads.el ends here
