;;disable splash screen and startup message
(setq inhibit-startup-message t)
(setq initial-scratch-message nil)

(require 'package)

(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
;; Enable ssl
(setq gnutls-algorithm-priority "NORMAL:-VERS-TLS1.3")
(package-initialize)

;; (package-refresh-contents)

;; I need this very early on
(defun ask-user-about-lock (file opponent)
  (discard-input)
  nil)

(require 'f)

(defvar pen-src-dir (f-join user-emacs-directory "pen.el" "src"))

(defmacro pen-with-user-repos (&rest body)
  ""
  `(let ((openaidir (f-join user-emacs-directory "openai-api.el"))
         (openaihostdir (f-join user-emacs-directory "host/openai-api.el"))
         (pendir (f-join user-emacs-directory "pen.el"))
         (penhostdir (f-join user-emacs-directory "host/pen.el"))
         (contribdir (f-join user-emacs-directory "pen-contrib.el"))
         (contribhostdir (f-join user-emacs-directory "host/pen-contrib.el")))

     ,@body))

(defmacro remove-from-list (list-var elt)
  `(set ,list-var (delete ,elt ,(eval list-var))))

(pen-with-user-repos
 (if (f-directory-p openaihostdir)
     (progn
       (add-to-list 'load-path openaihostdir)
       (remove-from-list 'load-path openaidir))
   (add-to-list 'load-path openaidir))

 (if (f-directory-p (f-join penhostdir "src"))
     (progn
       (add-to-list 'load-path (f-join penhostdir "src"))
       (add-to-list 'load-path (f-join penhostdir "src/in-development"))
       (remove-from-list 'load-path (f-join pendir "src"))
       (remove-from-list 'load-path (f-join pendir "src/in-development"))
       (setq pen-src-dir (f-join penhostdir "src")))
   (progn
     (add-to-list 'load-path (f-join pendir "src"))
     (add-to-list 'load-path (f-join pendir "src/in-development"))))

 (if (f-directory-p (f-join contribhostdir "src"))
     (progn
       (add-to-list 'load-path (f-join contribhostdir "src"))
       (remove-from-list 'load-path (f-join contribdir "src")))
   (add-to-list 'load-path (f-join contribdir "src"))))

(require 'pen-load-package-paths)

(defvar org-roam-v2-ack t)

;; builtin
(require 'pp)
(require 'cua-base)

;; Require dependencies
(require 'use-package)
(require 'shut-up)
;; For org-roam
(require 'emacsql)
(require 'guess-language)
(require 'language-detection)
(require 'org-roam)
(require 'org-brain)
(require 'dash)
(require 'eterm-256color)
;; (require 'flyspell)
(require 'evil)
(require 'popup)
(require 'right-click-context)
(require 'projectile)
(require 'transient)
(require 'el-patch)
(require 'lsp-mode)
(require 'lsp-ui)
(require 'iedit)
(require 'ht)
(require 'sx)
(require 'helm)
(require 'memoize)
(require 'ivy)
(require 'counsel)
(require 'yaml-mode)
(require 'yaml)
(require 'which-key)
(require 'lispy)
;; (require 'handle)
(require 's)
;; builtin
(require 'company)
(require 'selected)
(require 'yasnippet)
(require 'pcsv)
(require 'pcre2el)
(require 'helpful)
(require 'w3m)
(require 'eww-lnum)
(require 'ace-link)
(require 'mwim)
(require 'unicode-fonts)
(require 'uuidgen)
;; (require 'selectrum)
;; (package-install 'spacemacs-theme)
(require 'spacemacs-dark-theme)
(load-theme 'spacemacs-dark t)
(require 'macrostep)
(require 'tree-sitter)
(require 'tree-sitter-langs)
(require 'tree-sitter-indent)
(require 'shackle)
(require 'wgrep)
(require 'recursive-narrow)

(defvar pen-map (make-sparse-keymap)
  "Keymap for `pen.el'.")

(pen-with-user-repos
 ;; (load (f-join pen-src-dir "pen-contrib.el"))
 (load (f-join pen-src-dir "pen-example-config.el")))

(require 'openai-api)
(require 'pen)