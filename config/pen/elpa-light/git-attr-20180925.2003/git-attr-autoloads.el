;;; git-attr-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "git-attr" "git-attr.el" (0 0 0 0))
;;; Generated autoloads from git-attr.el

(autoload 'git-attr "git-attr" "\
Get git attributes for current buffer file and set in buffer local variable `git-attr'." t nil)

(autoload 'git-attr-get "git-attr" "\
Get the git attribute named ATTR for the file in current buffer.

 * t for git attributes with the value `set'
 * nil for git attributes with the value `unset'
 * 'undecided for git attributes that are `unspecified'
 * and the value if the git attribute is set to a value

\(fn ATTR)" nil nil)

(register-definition-prefixes "git-attr" '("git-attr"))

;;;***

;;;### (autoloads nil "git-attr-linguist" "git-attr-linguist.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from git-attr-linguist.el

(autoload 'git-attr-linguist "git-attr-linguist" "\
Make vendored and generated files read only." nil nil)

(add-hook 'find-file-hook 'git-attr-linguist)

(register-definition-prefixes "git-attr-linguist" '("git-attr-linguist-"))

;;;***

;;;### (autoloads nil nil ("git-attr-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; git-attr-autoloads.el ends here
