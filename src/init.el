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

(require 'cl-macs)

(defun chomp (str)
  "Chomp (remove tailing newline from) STR."
  (replace-regexp-in-string "\n\\'" "" str))

(defun string2list (s)
  "Convert a newline delimited string to list."
  (split-string s "\n"))

(defun pen-q (&rest strings)
  (let ((print-escape-newlines t))
    (mapconcat 'identity (mapcar 'prin1-to-string strings) " ")))

(defun pen-sn-basic (cmd &optional stdin dir)
  (interactive)

  (let ((output))
    (if (not cmd)
        (setq cmd "false"))

    (if (not dir)
        (setq dir default-directory))

    (let ((default-directory dir))
      (if (or
           (and (variable-p 'sh-update)
                (eval 'sh-update))
           (>= (prefix-numeric-value current-prefix-arg) 16))
          (setq cmd (concat "export UPDATE=y; " cmd)))

      (setq tf (make-temp-file "elisp_bash"))
      (setq tf_exit_code (make-temp-file "elisp_bash_exit_code"))

      (setq final_cmd (concat "( cd " (pen-q dir) "; " cmd " ) > " tf))

      (shut-up-c
       (with-temp-buffer
         (insert (or stdin ""))
         (shell-command-on-region (point-min) (point-max) final_cmd)))
      (setq output (slurp-file tf))
      (ignore-errors
        (progn (f-delete tf)
               (f-delete tf_exit_code)))
      output)))

(defun list-directories-recursively (dir)
  (string2list
   (split-string
    (chomp
     (pen-sn-basic
      (concat "find -P " (pen-q dir) " -maxdepth 2 \\( -name 'snippets' -o -name '*-snippets*' \\) -prune -o -type d")
      nil
      "/"))
    "\n")))

(setq load-path (cl-union load-path (list-directories-recursively "~/.emacs.d/elpa/")))

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
(require 'f)
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

(let ((openaidir (f-join user-emacs-directory "openai-api.el"))
      (openaihostdir (f-join user-emacs-directory "host/openai-api.el"))
      (pendir (f-join user-emacs-directory "pen.el"))
      (penhostdir (f-join user-emacs-directory "host/pen.el"))
      (contribdir (f-join user-emacs-directory "pen-contrib.el"))
      (contribhostdir (f-join user-emacs-directory "host/pen-contrib.el")))

  (if (f-directory-p (f-join openaihostdir "src"))
      (setq openaidir openaihostdir))
  (add-to-list 'load-path openaidir)
  (require 'openai-api)

  (if (f-directory-p (f-join penhostdir "src"))
      (setq pendir penhostdir))
  (add-to-list 'load-path (f-join pendir "src"))
  (require 'pen)

  (if (f-directory-p (f-join contribhostdir "src"))
      (setq contribdir contribhostdir))
  (add-to-list 'load-path (f-join contribdir "src"))
  (require 'pen)

  (add-to-list 'load-path (f-join pendir "src/in-development"))
  (add-to-list 'load-path (f-join contribdir "src"))

  (load (f-join contribdir "src/init-setup.el"))
  (load (f-join contribdir "src/pen-contrib.el"))

  (load (f-join pendir "src/pen-example-config.el")))
