;;; magit-patch-changelog-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "magit-patch-changelog" "magit-patch-changelog.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from magit-patch-changelog.el

(autoload 'magit-patch-changelog-create "magit-patch-changelog" "\
Compress commits from current branch to master.

ARGS are `transient-args' from `magit-patch-create'.
Limit patch to FILES, if non-nil.

\(fn ARGS FILES)" t nil)

(register-definition-prefixes "magit-patch-changelog" '("magit-patch-changelog-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; magit-patch-changelog-autoloads.el ends here
