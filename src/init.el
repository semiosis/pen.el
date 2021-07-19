(require 'package)

(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
;; Enable ssl
(setq gnutls-algorithm-priority "NORMAL:-VERS-TLS1.3")
(package-initialize)

;; (package-refresh-contents)

(defvar org-roam-v2-ack t)

;; Require dependencies
(require 'shut-up)
;; For org-roam
(require 'emacsql)
(require 'org-roam)
(require 'org-brain)
(require 'dash)
(require 'popup)
(require 'right-click-context)
(require 'projectile)
(require 'transient)
(require 'iedit)
(require 'ht)
(require 'helm)
(require 'memoize)
(require 'ivy)
(require 'counsel)
(require 'yaml-mode)
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

(let ((openaidir (concat (getenv "EMACSD") "/openai-api.el"))
      (openaihostdir (concat (getenv "EMACSD") "/host/openai-api.el"))
      (pendir (concat (getenv "EMACSD") "/pen.el"))
      (penhostdir (concat (getenv "EMACSD") "/host/pen.el"))
      (contribdir (concat (getenv "EMACSD") "/pen-contrib.el"))
      (contribhostdir (concat (getenv "EMACSD") "/host/pen-contrib.el")))

  (if (f-directory-p openaihostdir)
      (setq openaidir openaihostdir))
  (add-to-list 'load-path openaidir)
  (require 'openai-api)

  (if (f-directory-p penhostdir)
      (setq pendir penhostdir))
  (add-to-list 'load-path (concat pendir "/src"))
  (require 'pen)

  (add-to-list 'load-path (concat pendir "/src/in-development"))
  (add-to-list 'load-path (concat contribdir "/src"))

  (load (concat contribdir "/src/init-setup.el"))
  (load (concat contribdir "/src/pen-contrib.el"))

  (load (concat pendir "/src/pen-example-config.el")))

(pen-acolyte-minor-mode t)