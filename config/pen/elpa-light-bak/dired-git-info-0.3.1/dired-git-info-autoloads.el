;;; dired-git-info-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "dired-git-info" "dired-git-info.el" (0 0 0
;;;;;;  0))
;;; Generated autoloads from dired-git-info.el

(autoload 'dired-git-info-mode "dired-git-info" "\
Toggle git message info in current dired buffer.

If called interactively, toggle `Dired-Git-Info mode'.  If the
prefix argument is positive, enable the mode, and if it is zero
or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(autoload 'dired-git-info-auto-enable "dired-git-info" "\
Enable `dired-git-info-mode' if current dired buffer is in a git repo.

Add this function to `dired-after-readin-hook' to enable the mode
automatically inside git repos." nil nil)

(register-definition-prefixes "dired-git-info" '("dgi-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; dired-git-info-autoloads.el ends here
