;;; wgrep-ag-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "wgrep-ag" "wgrep-ag.el" (0 0 0 0))
;;; Generated autoloads from wgrep-ag.el

(autoload 'wgrep-ag-setup "wgrep-ag" nil nil nil)

(add-hook 'ag-mode-hook 'wgrep-ag-setup)

(register-definition-prefixes "wgrep-ag" '("wgrep-ag-"))

;;;***

;;;### (autoloads nil nil ("wgrep-ag-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; wgrep-ag-autoloads.el ends here
