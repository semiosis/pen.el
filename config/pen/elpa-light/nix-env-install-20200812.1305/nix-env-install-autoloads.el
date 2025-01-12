;;; nix-env-install-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "nix-env-install" "nix-env-install.el" (0 0
;;;;;;  0 0))
;;; Generated autoloads from nix-env-install.el

(autoload 'nix-env-install-cachix-use "nix-env-install" "\
Enable binary cache of NAME.

\(fn NAME)" t nil)

(autoload 'nix-env-install-uninstall "nix-env-install" "\
Uninstall PACKAGE installed by nix-env.

\(fn PACKAGE)" t nil)

(autoload 'nix-env-install-npm "nix-env-install" "\
Install PACKAGES from npm using Nix.

\(fn PACKAGES)" t nil)

(register-definition-prefixes "nix-env-install" '("nix-env-install-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; nix-env-install-autoloads.el ends here
