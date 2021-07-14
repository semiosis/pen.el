(require 'package)

(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
;; Enable ssl
(setq gnutls-algorithm-priority "NORMAL:-VERS-TLS1.3")
(package-initialize)

;; (package-refresh-contents)

;; Require dependencies
(require 'shut-up)
(require 'org-brain)
(require 'dash)
(require 'popup)
(require 'right-click-context)
(require 'projectile)
(require 'iedit)
(require 'ht)
(require 'helm)
(require 'memoize)
(require 'ivy)
(require 'pp)
(require 's)
(require 'f)
;; builtin
;; (require 'cl-macs)
(require 'company)
(require 'selected)
(require 'yasnippet)
(require 'pcsv)
(require 'sx)
(require 'pcre2el)

(f-mkdir (concat user-emacs-directory "/ht-cache"))

(let ((pendir (concat (getenv "EMACSD") "/pen.el")))
  (add-to-list 'load-path (concat pendir "/src"))
  (add-to-list 'load-path (concat pendir "/src/in-development"))
  (load (concat pendir "/src/pen.el"))
  (load (concat pendir "/src/pen-example-config.el")))
