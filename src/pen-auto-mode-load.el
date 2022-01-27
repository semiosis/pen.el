(require 'scheme)
(require 'pen-aliases)
(require 'org)
(require 'evil-org)

;; This only checks the first line
(add-to-list 'magic-mode-alist '("^#lang racket" . racket-mode))
(add-to-list 'magic-mode-alist '("^#lang scribble" . scribble-mode))
(add-to-list 'magic-mode-alist '("^#lang " . racket-mode))
(add-to-list 'magic-mode-alist '("^#.*env stack$" . haskell-mode))
(add-to-list 'magic-mode-alist '("^#.*sbcl" . lisp-mode))
(add-to-list 'magic-mode-alist '("^#.*xsh" . sh-mode))
(add-to-list 'magic-mode-alist '("#!/sbin/runscript$" . sh-mode))

;; pyramid scheme -- one day I will have a racket mode
(add-to-list 'auto-mode-alist '("\\.pmd\\'" . racket-mode))
(add-to-list 'auto-mode-alist '("\\(\\.network\\|\\.netdev\\|\\.path\\|\\.socket\\|\\.slice\\|\\.automount\\|\\.mount\\|\\.target\\|\\.timer\\|\\.service\\)\\'" . systemd-mode))

(add-hook 'after-init-hook #'global-flycheck-mode)
(remove-hook 'after-init-hook #'global-flycheck-mode)

(add-to-list 'auto-mode-alist '("\\.plrc\\'" . prolog-mode))
(add-to-list 'auto-mode-alist '("\\.kt\\'" . kotlin-mode))
(add-to-list 'auto-mode-alist '("/\\.[^/]*\\'" . fundamental-mode))
(add-to-list 'auto-mode-alist '("\\.ssh/config" . ssh-config-mode))
(add-to-list 'auto-mode-alist '("/etc/ansible/hosts" . conf-mode))
(add-to-list 'auto-mode-alist '("/[^\\./]*\\'" . fundamental-mode))
(add-to-list 'auto-mode-alist '("\\.json\\'" . json-mode))
(add-to-list 'auto-mode-alist '("\\.jsonl\\'" . jsonl-mode))
(add-to-list 'auto-mode-alist '("\\.python-gitlab.cfg\\'" . conf-mode))
(add-to-list 'auto-mode-alist '("\\(\\.tmpl\\|\\.j2\\)\\'" . jinja2-mode))
(add-to-list 'auto-mode-alist '("\\.tcshrc\\'" . csh-mode))
(add-to-list 'auto-mode-alist '("\\.asciidoc\\'" . adoc-mode))
(add-to-list 'auto-mode-alist '("\\.mac\\'" . asm-mode))
(add-to-list 'auto-mode-alist '("\\.csv\\'" . csv-mode))
(add-to-list 'auto-mode-alist '("\\.js\\'" . js-mode))
(ignore-errors (remove-from-list 'auto-mode-alist '("\\.java\\'" . jdee-mode)))
(add-to-list 'auto-mode-alist '("\\.java\\'" . java-mode))
(add-to-list 'auto-mode-alist '("\\.sln\\'" . sln-mode))
(add-to-list 'auto-mode-alist '("\\.xsh\\'" . sh-mode))
(add-to-list 'auto-mode-alist '("\\.env\\'" . sh-mode))
(add-to-list 'auto-mode-alist '("\\.env\\." . sh-mode))
(ignore-errors (remove-from-list 'auto-mode-alist '("\\.pp$" pollen-mode t)))
(add-to-list 'auto-mode-alist '("\\.pp\\'" . puppet-mode))
(add-to-list 'auto-mode-alist '("/home.*/hosts" . conf-mode))
(add-to-list 'auto-mode-alist '(".*\\.hcl\\'" . hcl-mode))
(add-to-list 'auto-mode-alist '(".*\\.gradle\\'" . groovy-mode))
(add-to-list 'auto-mode-alist '("\\.ghci.*\\'" . ghci-script-mode))
(add-to-list 'auto-mode-alist '("\\(\\.git/config\\|\\.gitconfig\\|gitconfig\\)\\'" . gitconfig-mode))
(add-to-list 'auto-mode-alist '("\\(\\.gitignore\\|\\.npmignore\\|\\.hgignore\\|\\.dockerignore\\)\\'" . gitignore-mode))
(add-to-list 'auto-mode-alist '("\\.gitmodules\\'" . gitconfig-mode))
(add-to-list 'auto-mode-alist '("\\.gitattributes\\'" . gitattributes-mode))
(add-to-list 'auto-mode-alist '(".*xmobarrc" . haskell-mode))
(add-to-list 'auto-mode-alist '("\\.jq\\'" . jq-mode))
(add-to-list 'auto-mode-alist '("\\.cl\\'" . lisp-mode))
(add-to-list 'auto-mode-alist '("\\.asd\\'" . lisp-mode))
(add-to-list 'auto-mode-alist '("\\(\\.babelrc\\)\\'" . json-mode)) ;not sure if should be javascript-mode
(add-to-list 'auto-mode-alist '("\\(\\.eslintrc\\)\\'" . javascript-mode))        ;I think this one is javascript. jq doesn't like it
(add-to-list 'auto-mode-alist '("\\.org\\'" . org-mode))
(add-to-list 'auto-mode-alist '("\\.epub\\'" . nov-mode))
(add-to-list 'auto-mode-alist '("\\.mermaid\\'" . mermaid-mode))
(add-to-list 'auto-mode-alist '("rr_gdbinit\\'" . gdb-script-mode))
(add-to-list 'auto-mode-alist '("\\.adoc\\'" . adoc-mode))
(add-to-list 'auto-mode-alist '("\\(\\.puml\\|\\.iuml\\|\\.uml\\)\\'" . plantuml-mode))
(add-to-list 'auto-mode-alist '("\\.toml\\'" . toml-mode))
(add-to-list 'auto-mode-alist '("\\(\\.sh\\|.zsh\\)\\'" . sh-mode))
(add-to-list 'auto-mode-alist '("\\(conf\\|\\.conf\\)\\'" . conf-mode))
(add-to-list 'auto-mode-alist '("\\(\\.wls\\|\\.nb\\|\\.wl\\)\\'" . wolfram-mode))
(add-to-list 'auto-mode-alist '("\\(\\.pxd\\|\\.pyx\\)\\'" . cython-mode))
(add-to-list 'auto-mode-alist '("\\(\\.scrbl\\)\\'" . scribble-mode))
(add-to-list 'auto-mode-alist '("\\(\\.ghci\\)\\'" . haskell-mode))
(add-to-list 'auto-mode-alist '("\\(\\.sparql\\)\\'" . sparql-mode))
(add-to-list 'auto-mode-alist '("\\(Jenkinsfile\\)\\'" . jenkinsfile-mode))
(add-to-list 'auto-mode-alist '("\\(Procfile\\|procfile\\)\\'" . procfile-mode))
(add-to-list 'auto-mode-alist '("\\(Gemfile\\)\\'" . ruby-mode))
(add-to-list 'auto-mode-alist '("\\(Pipfile\\)\\'" . conf-mode))
(add-to-list 'auto-mode-alist '("\\(crontab\\)\\'" . crontab-mode))
(add-to-list 'auto-mode-alist '("\\(cron.d/\\)" . crontab-mode))
(add-to-list 'auto-mode-alist '("\\(GNUmakefile\\)\\'" . makefile-mode))
(add-to-list 'auto-mode-alist '("\\(Cask\\)\\'" . cask-mode))
(add-to-list 'auto-mode-alist '("\\(Caddyfile\\)\\'" . caddyfile-mode))
(add-to-list 'auto-mode-alist '("\\(Dockerfile\\)\\'" . dockerfile-mode))
(add-to-list 'auto-mode-alist '("\\(Vagrantfile\\)\\'" . ruby-mode))
(add-to-list 'auto-mode-alist '("\\(.docker\\)\\'" . dockerfile-mode))
(add-to-list 'auto-mode-alist '("\\(\\.make\\)\\'" . makefile-mode))
(add-to-list 'auto-mode-alist '("\\(\\.ttl\\)\\'" . ttl-mode))
(add-to-list 'auto-mode-alist '("\\(\\.project\\)\\'" . haskell-cabal-mode))
(add-to-list 'auto-mode-alist '("\\.zsh-theme\\'" . sh-mode))
(add-to-list 'auto-mode-alist '("\\.scm\\'" . scheme-mode))
(add-to-list 'auto-mode-alist '("\\.screenrc\\'" . conf-mode))
(add-to-list 'auto-mode-alist '("\\.editorconfig" . editorconfig-conf-mode))
(add-to-list 'auto-mode-alist '("\\.latexrc\\'" . latex-mode))
(add-to-list 'auto-mode-alist '("\\pylintrc\\'" . conf-mode))
(add-to-list 'auto-mode-alist '("\\yarn\\.lock\\'" . yarn-mode))
(add-to-list 'auto-mode-alist '("\\.rcp\\'" . emacs-lisp-mode))
(add-to-list 'auto-mode-alist '("\\.ini\\'" . conf-mode))
(add-to-list 'auto-mode-alist '("\\.bzl\\'" . bazel-mode))
(add-to-list 'auto-mode-alist '("\\(\\.pl\\|\\.pm\\)\\'" . perl-mode))
(add-to-list 'auto-mode-alist '("\\(\\.pro\\|\\.problog\\)\\'" . prolog-mode))
(add-to-list 'auto-mode-alist '("\\(\\.yas\\|\\.snippet\\)\\'" . snippet-mode))
(add-to-list 'auto-mode-alist '("\\(shellrc\\|\\.shell_aliases\\|profile\\|\\.profile\\|\\.bashrc\\|\\.bash_logout\\|\\.bash_profile\\|\\.zshrc\\|\\.shell_environment\\|\\.shell_functions\\|zshrc\\)\\'" . sh-mode))
(add-to-list 'auto-mode-alist '("\\(\\.aderc\\)\\'" . sh-mode))
(add-to-list 'auto-mode-alist '("\\(\\.Xresources\\|\\.Xdefaults\\)\\'" . conf-xdefaults-mode))
(add-to-list 'auto-mode-alist '("\\.yml\\'" . yaml-mode))
(add-to-list 'auto-mode-alist '("\\.prompt\\'" . prompt-description-mode))
(add-to-list 'auto-mode-alist '("\\.gitlab-ci\\.yml\\'" . gitlab-ci-mode))
(add-to-list 'auto-mode-alist '("\\gitlab-ci\\.yml\\'" . gitlab-ci-mode))
(add-to-list 'auto-mode-alist '(".*\\.yaml\\'" . yaml-mode))
(add-to-list 'auto-mode-alist '(".*\\.clql\\'" . clql-mode))
(add-to-list 'auto-mode-alist '("\\.restc\\'" . restclient-mode))
(add-to-list 'auto-mode-alist '("\\.vbs\\'" . basic-mode))
(add-to-list 'auto-mode-alist '("\\.restclient\\'" . restclient-mode))
(add-to-list 'auto-mode-alist '("\\.annotations\\'" . emacs-lisp-mode))
(require 'auto-minor-mode)
;; evil-org-mode doesn't actually work very well with my M-hjkl evil bindings
(add-to-list 'auto-minor-mode-alist '("\\.org\\'" . evil-org-mode))
(add-to-list 'auto-mode-alist `(,(bs "(.vim|.vimrc|vimrc|pentadactylrc)'" ".()'|") . vimrc-mode))
(add-to-list 'auto-mode-alist '("\\(\\.py\\|.pythonrc\\)\\'" . python-mode))
(add-to-list 'auto-mode-alist '("\\(\\.psh\\)\\'" . powershell-mode))
(add-to-list 'auto-mode-alist '("\\.exs\\'" . elixir-mode))
(add-to-list 'auto-mode-alist '("\\.exs\\'" . alchemist-mode))

;; GitHub Semmle / CodeQL
(add-to-list 'auto-mode-alist '("\\.ql\\'" . ql-mode-base))
(add-to-list 'auto-mode-alist '("\\.dbscheme\\'" . dbscheme-mode))

(add-to-list 'auto-mode-alist '("\\.gnus\\'" . emacs-lisp-mode))

;; Hash table stored in file
(add-to-list 'auto-mode-alist '("\\.elht\\'" . emacs-lisp-mode))

(add-to-list 'auto-mode-alist '("\\.classpath\\'" . xml-mode))
(add-to-list 'auto-mode-alist '("\\.C\\'" . c++-mode))
(add-to-list 'auto-mode-alist '("\\.daml\\'" . xml-mode))
(add-to-list 'auto-mode-alist '("\\.js\\'" . js2-mode))
(add-to-list 'auto-mode-alist '("\\(\\.rkt\\|\\.racketrc\\)\\'" . racket-mode))
(add-to-list 'auto-mode-alist '("\\.scm\\'" . scheme-mode))
(add-to-list 'auto-mode-alist '("\\.guix.*\\'" . scheme-mode))
(add-to-list 'auto-mode-alist '("\\(\\.el\\|emacs\\)\\'" . emacs-lisp-mode))
(add-to-list 'auto-mode-alist '("\\.hy\\'" . hy-mode))
(add-to-list 'auto-mode-alist '("\\.closhrc\\'" . lisp-mode))
(add-to-list 'auto-mode-alist '("\\.fishrc\\'" . fish-mode))
(add-to-list 'auto-mode-alist '("\\.gntrc\\'" . conf-mode))
(add-to-list 'auto-mode-alist '("\\(\\.clisprc\\|\\.clojurerc\\)\\'" . lisp-mode))
(add-to-list 'auto-mode-alist '("\\(CONTRIBUTING\\|\\.md\\|\\.markdown\\|\\.Rmd\\)\\'" . markdown-mode))
(add-to-list 'auto-mode-alist '("\\(\\.clj\\|\\.clojurerc\\|\\.repl\\)\\'" . clojure-mode))
(add-to-list 'auto-minor-mode-alist '("\\.clj\\'" . helm-cider-mode))
(add-to-list 'auto-mode-alist '("\\.lsp\\'" . lisp-mode))
(add-to-list 'auto-mode-alist '("\\.cljs\\'" . clojurescript-mode))
(add-to-list 'auto-mode-alist '("\\.cs\\'" . csharp-mode))
(add-to-list 'auto-mode-alist '("\\.rpl\\'" . rpl-mode))

(remove-from-list 'auto-mode-alist '("\\.clj$" . clj-mode))

;; This is to ensure that it doesnt reload somehow
(add-hook 'clj-mode (pen-lm (remove-from-list 'auto-mode-alist '("\\.clj$" . clj-mode))))

(add-to-list 'auto-mode-alist '("\\(\\.clj\\)\\'" . clojure-mode))
(add-to-list 'auto-mode-alist '("\\(\\.clje\\)\\'" . clojerl-mode))
(add-to-list 'auto-mode-alist '("\\.sol\\'" . solidity-mode))
(add-to-list 'auto-mode-alist '("\\.julia\\'" . julia-mode))
(add-to-list 'auto-mode-alist `(,(bs ".(360|6502|6800|8051|8080|8086|68000|arm|as)'" ".()'|") . asm-mode))

(require 'selected)

(defun disable-visual-line-mode ()
  (visual-line-mode -1))

(add-hook 'dired-mode-hook 'disable-visual-line-mode)

(defun my/emacs-lisp-mode-hook-body ()
  "What happens when emacs lisp mode loads"
  (my/lisp-mode 1)
  (remove-hook 'activate-mark-hook #'selected--on) ;Why wont it just die
  (selected-off))

;; Disable this so C-c C-s works
(add-hook 'magit-popup-mode-hook (lambda () (pen -1)))

(add-hook 'magit-status-mode-hook #'my/magit-status-hook-body)
(add-hook 'emacs-lisp-mode-hook #'my/emacs-lisp-mode-hook-body)
(add-hook 'ielm-mode-hook #'my/emacs-lisp-mode-hook-body)
(add-hook 'hy-mode-hook '(lambda () (my/lisp-mode 1)))
(add-hook 'per-mode-hook '(lambda () (my/lisp-mode 1)))
(add-hook 'clojure-mode-hook '(lambda () (my/lisp-mode 1)))
(add-hook 'lisp-mode-hook '(lambda () (my/lisp-mode 1)))
(add-hook 'lfe-mode-hook '(lambda () (my/lisp-mode 1)))
(add-hook 'cider-repl-mode-hook '(lambda () (my/lisp-mode 1)))
(add-hook 'inferior-hy-mode-hook '(lambda () (my/lisp-mode 1)))
(add-hook 'scheme-mode-hook '(lambda () (my/lisp-mode 1)))

(add-hook 'org-mode-hook '(lambda () (selected-minor-mode 1)))

(add-hook 'occur-hook '(lambda () (toggle-truncate-lines 1)))

(defun enable-chop-lines ()
  (visual-line-mode -1)
  (toggle-truncate-lines 1))

(remove-hook 'org-mode-hook #'enable-chop-lines)

(add-hook 'yas-minor-mode-hook '(lambda () (toggle-truncate-lines 1))) ;This is for snippets

(defmacro enable-major-mode (mode_symbol)
  (quote mode_symbol))

(defun fix-completion ()
  "Sometimes the completion function is not removed after leaving a mode. This is the fix."
  (progn
    (setq completion-at-point-functions
          '())))

(add-hook 'org-mode-hook '(lambda () (fix-completion)))
(add-hook 'javascript-mode-hook '(lambda () (fix-completion)))

(defun my/auto-clojure-minor-modes ()
  (interactive)
  (my/lisp-mode 1)
  (helm-cider-mode 1))

(add-hook 'clojure-mode-hook #'my/auto-clojure-minor-modes)

(add-hook 'helm-cider-mode-hook '(lambda () (my/lisp-mode 1)))
(add-hook 'clojurescript-mode-hook '(lambda () (my/lisp-mode 1)))
(add-hook 'racket-mode-hook '(lambda () (my/lisp-mode 1)))
(add-hook 'racket-repl-mode-hook '(lambda () (my/lisp-mode 1)))

;; This is perfect! -- for all programming language modes
(add-hook 'prog-mode-hook 'highlight-indent-guides-mode)

(progn
  (eval-after-load
      'company
    '(add-to-list 'company-backends 'company-omnisharp))

  (defun pen-csharp-mode-setup ()
    (omnisharp-mode)
    (company-mode)
    (flycheck-mode)

    (setq indent-tabs-mode nil)
    (setq c-syntactic-indentation t)
    (c-set-style "ellemtel")
    (setq c-basic-offset 4)
    (setq truncate-lines t)
    (setq tab-width 4)
    (setq evil-shift-width 4)

    (local-set-key (kbd "C-c r r") 'omnisharp-run-code-action-refactoring)
    (local-set-key (kbd "C-c C-c") 'recompile))

  (add-hook 'csharp-mode-hook 'pen-csharp-mode-setup t))

(defun pen-lisp-mode-autoload ()
  (interactive)
  (highlight-indent-guides-mode)
  (lispy-mode 1))

(add-hook 'my/lisp-mode-hook #'pen-lisp-mode-autoload)
(add-hook 'emacs-lisp-mode-hook 'org-link-minor-mode)
(remove-hook 'clojure-mode-hook 'org-link-minor-mode)

(add-to-list 'auto-minor-mode-alist '("\\(\\.go\\)\\'" . org-link-minor-mode))
(add-to-list 'auto-minor-mode-alist '("\\(\\.txt\\)\\'" . org-link-minor-mode))
(add-to-list 'auto-minor-mode-alist '("\\(\\.rkt\\)\\'" . org-link-minor-mode))
(add-to-list 'auto-minor-mode-alist '("\\(\\.clj\\)\\'" . org-link-minor-mode))

(add-to-list 'auto-mode-alist '("\\(/\\|\\`\\)[Mm]akefile" . makefile-gmake-mode))
(add-to-list 'auto-mode-alist '("Rakefile" . ruby-mode))
(add-to-list 'auto-mode-alist '("Guardfile" . ruby-mode))
(add-to-list 'auto-mode-alist '("\\(\\.irbrc\\|\\.pryrc\\)" . ruby-mode))

(when (> emacs-major-version 24)
  (progn
    (add-to-list 'auto-mode-alist '("\\.js\\'" . javascript-mode))))

(defun haskell-mode-config ()
  "Start modes and options for haskell"
  (interactive)
  (haskell-mode))

(add-to-list 'auto-mode-alist '("\\.hs\\'" . haskell-mode-config))

(add-hook 'haskell-mode-hook 'haskell-doc-mode)
(add-hook 'haskell-mode-hook 'haskell-decl-scan-mode) ;This creates a menu. Access with M-l 

(add-to-list 'auto-mode-alist '("\\.asd\\'" . lisp-mode))

(defun c-mode-customizations () (define-key c-mode-map (kbd "C-M-h") nil))
(add-hook 'c-mode-hook #'c-mode-customizations)

(global-diff-hl-mode 1)                 ; gui version only
(global-git-gutter+-mode 1)

(yas-global-mode 1)

(require 'cff)

(add-to-list 'auto-mode-alist '("\\.jq$" . jq-mode))
(add-to-list 'auto-mode-alist '("\\.g4$" . antlr-mode))
(add-to-list 'auto-mode-alist '("\\.vtt$" . subed-mode))

(provide 'auto-mode-load)