;;; wgrep-pt-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "wgrep-pt" "wgrep-pt.el" (0 0 0 0))
;;; Generated autoloads from wgrep-pt.el

(autoload 'wgrep-pt-setup "wgrep-pt" nil nil nil)

(add-hook 'pt-search-mode-hook 'wgrep-pt-setup)

(register-definition-prefixes "wgrep-pt" '("wgrep-pt-unload-function"))

;;;***

;;;### (autoloads nil nil ("wgrep-pt-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; wgrep-pt-autoloads.el ends here
