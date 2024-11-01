;;; imenu-extra-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "imenu-extra" "imenu-extra.el" (0 0 0 0))
;;; Generated autoloads from imenu-extra.el

(autoload 'imenu-extra-add-new-items "imenu-extra" "\
Merge ORIGINAL-ITEMS and extra imenu items from PATTERNS.
PATTERNS should be an alist of the same form as `imenu-generic-expression'.

\(fn ORIGINAL-ITEMS PATTERNS)" nil nil)

(autoload 'imenu-extra-auto-setup "imenu-extra" "\
Add extra imenu items extracted from PATTERNS.
PATTERNS should be an alist of the same form as `imenu-generic-expression'.

\(fn PATTERNS)" nil nil)

(register-definition-prefixes "imenu-extra" '("imenu-extra-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; imenu-extra-autoloads.el ends here
