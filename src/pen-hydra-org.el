(require 'org)

(defun insert-or-unindent (arg)
  (interactive "P")
  (if (pen-selected-p)
      (progn
        (if (not arg) (setq arg 4))
        (pen-region-pipe (concat "pen-indent -" (str arg))))
    (call-interactively 'self-insert-command)))

(defset org-hydra-snippet-names
  '(src example comment vimrc latex awk snippet equation equationpng jq
        haskell org kotlin es apache emacs-lisp bash yaml dot digraph
        digraph-lr digraph-ascii digraph-ascii-lr algorithm program R
        ruby diff grep javascript json ipython3 C c++ cpp sh shx sh-xv spv
        pen-sps nw sph ghci ghcih-stdout ghcih rh ghciol nohup clojure
        fish
        python text tcl perl perl go nix prolog problog scheme racket
        conf hy html makefile markdown dockerfile script graphql
        purescript common-lisp ql-mode-base guile lean es elasticsearch
        mermaid plantuml plantuml-svg xsh powershell toml bnf quote
        lfescript rpl rosie conf-space tmux z-repl rust terraform
        gitlab-ci))

;; _c_enter
;; Keep the first empty line. It's nice.
;; TODO Generate this hydra from a slit and add a fuzzy search option
(defhydra hydra-org-template (:color blue :hint nil)
  ;;   "

  ;;  _._edit        _<_unindent
  ;;  _z>_search     _/_sps
  ;;  _,_snippet
  ;; "
  ("s" (hot-expand "<s" "src") "")
  ("_" (hot-expand "<e" "example") "EXAMPLE")

  (";" (hot-expand "<C" "comment") "COMMENT")
  ;; ("q" (hot-expand "<q") "QUOTE")
  ;; ("v" (hot-expand "<v") "VERSE")
  ("v" (hot-expand "<s" "vimrc") "vimrc")
  ("n" (hot-expand "<not") "NOTES")
  ;; ("c" (hot-expand "<c"))
  ("l" (hot-expand "<s" "latex") "EXPORT latex")
  ("a" (hot-expand "<s" "awk"))
  ("-" (hot-expand "<s" "bb"))
  ("\"" (hot-expand "<s" "rust"))
  ("C" (hot-expand "<s" "gitlab-ci") "gitlab-ci")
  ("," (hot-expand "<s" "snippet") "snippet")
  ;; ("L" (hot-expand "<L"))
  ("i" (hot-expand "<i"))
  ("=" (hot-expand "<s" "equation") "latex")
  ("6" (hot-expand "<s" "equationpng") "latex")
  ("Q" (hot-expand "<s" "jq") "jq")
  ("E" (hot-expand "<s" "french") "french")
  ("F" (hot-expand "<s" "english") "english")
  ("k" (hot-expand "<s" "ghci-stdout") "haskell")
  ("O" (hot-expand "<s" "org") "org")
  ;; ("K" (hot-expand "<s" "kotlin") "kotlin")
  ;; ("K" (hot-expand "<s" "runhaskell") "haskell")
  ("K" (hot-expand "<s" "script") "haskell")
  ("'" (hot-expand "<s" "es") "elasticsearch")
  ("!" (hot-expand "<s" "apache") "apache")
  ("e" (hot-expand "<s" "emacs-lisp") "emacs-lisp")
  ("b" (hot-expand "<s" "bash") "bash")
  ("B" (hot-expand "<s" "bnf") "bnf")
  ("Y" (hot-expand "<s" "yaml") "yaml")
  ("}" (hot-expand "<s" "lean") "lean")
  ("1" (hot-expand "<s" "dot") "dot / graphviz")
  ("2" (hot-expand "<s" "digraph") "digraph")
  ("3" (hot-expand "<s" "qdot") "qdot")
  ("4" (hot-expand "<s" "qdot2dot") "qdot")
  ("A" (hot-expand "<s" "algorithm") "algorithm")
  ("&" (hot-expand "<s" "mermaid") "mermaid")
  ("%" (hot-expand "<s" "mermaid-show") "mermaid")
  ;;("&" (hot-expand "<s" "program") "program")
  ;; ("R" (hot-expand "<s" "R") "R")
  ("R" (hot-expand "<s" "rosie") "rosie")
  ;; ("U" (hot-expand "<s" "ruby") "ruby")
  ("d" (hot-expand "<s" "diff") "diff")
  ("G" (hot-expand "<s" "grep") "grep")
  ("M-g" (hot-expand "<s" "gherkin") "gherkin / cucumber")
  ;; ("j" (hot-expand "<s" "javascript") "javascript")
  ("j" (hot-expand "<s" "json") "json")
  ;; ("P" (hot-expand "<s" "php") "php")
  ("P" (hot-expand "<s" "ipython3") "python")
  ("c" (hot-expand "<s" "C") "c")
  ("o" (hot-expand "<s" "code-snippet") "text")
  ("+" (hot-expand "<s" "c++") "c++")
  ("h" (hot-expand "<s" "sh") "sh")
  ("V" (hot-expand "<s" "spv") "sh")
  ("/" (hot-expand "<s" "sps") "sh")
  ("?" (hot-expand "<s" "sps-inline") "sh")
  ("S" (hot-expand "<s" "sph") "sh")
  ("H" (hot-expand "<s" "ghci") "haskell")
  ("^" (hot-expand "<s" "ghcih-stdout") "haskell ghcih results")
  ("*" (hot-expand "<s" "ghcih") "haskell pen-sps ghcih")
  ("(" (hot-expand "<s" "rh") "haskell")
  ;; ("&" (hot-expand "<s" "ghciol") "haskell")
  ("$" (hot-expand "<s" "nohup") "bash")
  ("Z" (hot-expand "<s" "z-repl") "bash")
  ("X" (hot-expand "<s" "xsh") "xsh")
  ("x" (hot-expand "<s" "xsh") "xsh")
  ;; ("h" (hot-expand "<h" "sh"))
  ("J" (hot-expand "<s" "clojure") "clojure")
  ("y" (hot-expand "<s" "python") "python")
  ("t" (hot-expand "<s" "text") "text")
  ;; ("T" (hot-expand "<s" "tcl") "tcl")
  ("T" (hot-expand "<s" "terraform") "terraform")
  ("#" (hot-expand "<s" "perl" ":results output :exports both :shebang \"#!/usr/bin/env perl\"\n") "perl shebang")
  ("p" (hot-expand "<s" "perl") "perl")
  ("g" (hot-expand "<s" "go") "go")
  ("N" (hot-expand "<s" "nix") "nix")
  ("r" (hot-expand "<s" "racket") "racket")
  ("~" (hot-expand "<s" "racket-sublang") "racket")
  ("L" (hot-expand "<s" "prolog") "prolog")
  ("I" (hot-expand "<s" "common-lisp") "common lisp")
  (":" (hot-expand "<s" "problog") "problog")
  ("f" (hot-expand "<s" "conf") "conf")
  ;; ("H" (hot-expand "<s" "hy") "hy")
  ("M-h" (hot-expand "<s" "html") "html")
  ("m" (hot-expand "<s" "mustache") "mustache")
  ("M" (hot-expand "<s" "makefile") "makefile")
  ("D" (hot-expand "<s" "markdown") "markdown")
  ;; ("u" (hot-expand "<s" "plantuml :file CHANGE.png") "plantuml")
  ("u" (hot-expand "<s" "plantuml") "plantuml")
  ("U" (hot-expand "<s" "plantuml-svg") "plantuml-svg")
  ;; ("I" (hot-expand "<I"))
  ;; ("H" (hot-expand "<H"))
  ;; ("A" (hot-expand "<A"))
  ("<" insert-or-unindent "ins or unindent")
  ("." (progn (find-file "/home/shane/var/smulliga/source/git/config/emacs/config/hydra-org.el")
              (goto-char 0)
              (search-forward "hydra-org-template")) "edit hydra")
  ("q" nil "quit")
  ("z" fz-hot-expand "fz choose snippet")
  (">" fz-hot-expand "fz choose snippet"))

(defun fz-hot-expand ()
  (interactive)
  (let ((s (fz org-hydra-snippet-names
               nil nil "fz-hot-expand: ")))
    (setq s (cond ((string-match-p "javascript" s) "js")
                  (t s)))

    (if s (hot-expand "<s" s))))

(defun hot-expand (str &optional mod header)
  "Expand org template.

STR is a structure template string recognised by org like <s. MOD is a
string with additional parameters to add the begin line of the
structure element. HEADER string includes more parameters that are
prepended to the element after the #+HEADER: tag."
  (let (text)
    (when (region-active-p)
      (setq text (pen-selected-text))
      (pen-delete-selected-text))

    (cond ((string-equal mod "racket-sublang")
           (let ((sublang (fz '(racket
                                rackjure
                                hackett
                                sicp
                                rash))))
             (insert (eval `(pen-bp pen-org-template-gen ,mod ,sublang ,text)))))
          ((string-equal mod "plantuml-svg")
           (insert (eval `(pen-bp pen-org-template-gen ,mod ,(let ((fp (read-string "svg fp: ")))
                                                               (if (string-match "\.svg$" fp)
                                                                   fp
                                                                 (concat fp ".svg")))
                                  ,text))))
          (t
           (insert (eval `(pen-bp pen-org-template-gen ,mod ,text)))))))

(defun org-run-babel-template-hydra ()
  (interactive)
  (if (or (region-active-p)
          (looking-back "^"))
      (hydra-org-template/body)
    (self-insert-command 1)))

(define-key org-mode-map "<" #'org-run-babel-template-hydra)

(defun hydra-org-template-sps-inline ()
  (interactive)
  (if (or (region-active-p)
          (looking-back "^"))
      (hot-expand "<s" "sps-inline")
    (self-insert-command 1)))

(define-key org-mode-map "?" #'hydra-org-template-sps-inline)

(provide 'pen-hydra-org)
