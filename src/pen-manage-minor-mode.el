(require 'manage-minor-mode)

(setq manage-minor-mode-default
      '((aws-instances-mode
         (on tablist-minor-mode)
         (off hide-mode-line-mode)
         (off display-line-numbers-mode)
         (off visual-line-mode))

        (tabulated-list-mode
         (on tablist-minor-mode)
         (off hide-mode-line-mode)
         (off display-line-numbers-mode)
         (off visual-line-mode))

        (Info-mode
         (off highlight-thing-mode))

        (sh-mode
         (off org-link-minor-mode))

        (helpful-mode
         (on org-link-minor-mode))

        (racket-mode
         (off flycheck-mode)
         (off eldoc-mode))

        (js-mode
         (off electric-pair-local-mode))

        (text-mode
         (off writegood-mode))

        (term-mode
         (off pen)
         (off fringe-mode)
         (off semantic-mode)
         (off highlight-thing-mode)
         (off ivy-mode))

        (global
         (off prettify-symbols-mode)
         (on delete-selection-mode)
         (off semantic-mode)
         (off paredit-mode)
         (on right-click-context-mode)
         (off sotlisp-mode)
         (off helm-mode)
         (off linum-mode)
         (off display-line-numbers-mode)
         (off insert-shebang-mode)
         (on eldoc-mode)
         (on tabbar-mode)
         (on solaire-mode)
         (on company-mode)
         (off winum-mode)
         (off guide-key-mode)
         (off evil-escape-mode)
         (off selected-minor-mode)
         (off selected-region-active-mode))

        (minibuffer-inactive-mode
         (off company-mode))

        (java-mode
         (on electric-pair-local-mode))

        (go-mode
         (on tree-sitter-hl-mode))

        (javascript-mode
         (on tree-sitter-hl-mode))

        (js-mode
         (on tree-sitter-hl-mode))

        (python-mode
         (on tree-sitter-hl-mode)
         (off electric-pair-local-mode)
         (off semantic-mode)
         (on eldoc-mode)
         (off flymake-mode))

        (haskell-mode
         (off flymake-mode)
         (off structured-haskell-mode))

        (markdown-mode
         (off visual-line-mode))

        (org-mode
         (off visual-line-mode))

        (help-mode
         (on org-link-minor-mode)
         (off visual-line-mode))

        (term-mode
         (off yas-minor-mode)
         (off org-indent-mode)
         (off persp-mode)
         (off which-key-mode)
         (off company-mode)
         (off gud-minor-mode))

        (magit-log-mode
         (off highlight-thing-mode))

        (eww-mode
         (off visual-line-mode)
         (off pen-keywords-mode)
         (off rainbow-delimiters-mode)
         (off volatile-highlights-mode)
         (off highlight-indent-guides-mode)
         (off global-highlight-indent-guides-mode)

         (emacs-lisp-mode
          (off semantic-mode)))))

(provide 'pen-manage-minor-mode)