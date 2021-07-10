(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
;; Enable ssl
(setq gnutls-algorithm-priority "NORMAL:-VERS-TLS1.3")
(package-initialize)

(package-refresh-contents)

;; Install dependencies
(package-install 'org-brain)
(package-install 'dash)
(package-install 'projectile)
(package-install 'iedit)
(package-install 'ht)
(package-install 'helm)
(package-install 'memoize)
(package-install 'ivy)
(package-install 'pp)
(package-install 's)
(package-install 'f)
;; builtin
;; (package-install 'cl-macs)
(package-install 'company)
(package-install 'selected)
(package-install 'yasnippet)
(package-install 'pcsv)
(package-install 'sx)

(let ((pendir (concat (getenv "EMACSD") "/pen.el")))
  (add-to-list 'load-path (concat pendir "/src"))
  (add-to-list 'load-path (concat pendir "/src/in-development"))
  (load (concat pendir "/src/pen.el"))
  (load (concat pendir "/src/pen-example-config.el")))
