;;; helm-go-package-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "helm-go-package" "helm-go-package.el" (0 0
;;;;;;  0 0))
;;; Generated autoloads from helm-go-package.el

(autoload 'helm-go-package "helm-go-package" "\
Helm for Go programming language's package.

\"Go local packages\"
These actions are available.
* Add a new import
* Add a new import as
* Show documentation
* Display GoDoc
* Visit package's directory

This persistent action is available.
* Show documentation

\"search Go packages on Godoc\"
These actions are available.
* Download and install
* Display GoDoc" t nil)

(register-definition-prefixes "helm-go-package" '("helm-go-package-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; helm-go-package-autoloads.el ends here
