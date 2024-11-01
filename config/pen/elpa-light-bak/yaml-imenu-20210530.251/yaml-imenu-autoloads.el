;;; yaml-imenu-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "yaml-imenu" "yaml-imenu.el" (0 0 0 0))
;;; Generated autoloads from yaml-imenu.el

(autoload 'yaml-imenu-create-index "yaml-imenu" "\
Create an imenu index for the current YAML file." nil nil)

(autoload 'yaml-imenu-activate "yaml-imenu" "\
Set the buffer local `imenu-create-index-function' to `yaml-imenu-create-index'." nil nil)

(autoload 'yaml-imenu-enable "yaml-imenu" "\
Globally enable `yaml-imenu-create-index' in yaml-mode by adding `yaml-imenu-activate' to `yaml-mode-hook'." t nil)

(autoload 'yaml-imenu-disable "yaml-imenu" "\
Globally disable `yaml-imenu-create-index' in yaml-mode." t nil)

(register-definition-prefixes "yaml-imenu" '("yaml-imenu-"))

;;;***

;;;### (autoloads nil nil ("yaml-imenu-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; yaml-imenu-autoloads.el ends here
