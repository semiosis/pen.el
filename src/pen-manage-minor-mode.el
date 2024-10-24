(require 'manage-minor-mode)

;; Disable hl-line-mode for term
(defun not-terminal-around-advice (proc &rest args)
  (if (not (or (major-mode-p 'term-mode)
               (major-mode-p 'vterm-mode)))
      (let ((res (apply proc args)))
        res)))
(advice-add 'global-hl-line-highlight :around #'not-terminal-around-advice)
(advice-add 'display-line-numbers--turn-on :around #'not-terminal-around-advice)



;; Enabling visual-line-mode means it's possible to see the entire line.
;; It's useful for swiper and bible-mode.
;; However, a big problem with Enabling visual-line-mode is that sometimes (with grep, for instance),
;; a really big line results in wrapping that takes up the entire screen.
;; So ideally, there would be a settable limit to the number of visual lines per semantic line.

;; (add-hook 'minibuffer-setup-hook
;;           (lambda ()
;;             (visual-line-mode t)

;;             ;; linum doesn't work good
;;             ;; linum-mode
;;             ))
;; (remove-hook 'minibuffer-setup-hook
;;           (lambda ()
;;             (visual-line-mode t)

;;             ;; linum doesn't work good
;;             ;; linum-mode
;;             ))

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

        (life-mode
         (off hl-line-mode)
         (off hide-mode-line-mode)
         (off display-line-numbers-mode)
         (off visual-line-mode))

        (crossword-mode
         (off hl-line-mode)
         (off hide-mode-line-mode)
         (off display-line-numbers-mode)
         (off visual-line-mode))

        (Info-mode
         (off highlight-thing-mode))

        (sh-mode
         (off org-link-minor-mode))

        ;; (hypertext-mode
        ;;  (on org-link-minor-mode))

        (ascii-adventures-mode
         (off hl-line-mode))

        (prog-mode
         ;; This didn't seem to work.
         ;; Ah, OK, so I have to put it for the specific major-mode, not a parent mode
         ;; (on org-link-minor-mode)
         )
        
        (prolog-mode
         (on org-link-minor-mode))
        (clojure-mode
         (on org-link-minor-mode))
        
        (universal-sidecar-buffer-mode
         (on org-link-minor-mode))

        (helpful-mode
         (on org-link-minor-mode))

        (racket-mode
         (off flycheck-mode)
         (off eldoc-mode))

        ;; (minibuffer-inactive-mode
        ;;  (off pen))

        (js-mode
         (off electric-pair-local-mode))

        (text-mode
         (off writegood-mode))

        

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
         (on org-link-minor-mode)
         (off flymake-mode)
         (off structured-haskell-mode))

        (markdown-mode
         (off visual-line-mode))

        (org-mode
         (on auto-highlight-symbol-mode)
         (off visual-line-mode)
         (on org-verse)
         ;; (on abbrev-mode) This didn't work.
         ;; Instead: (add-hook 'org-mode-hook #'abbrev-mode)􃇃
         )

        (yaml-mode
         (on auto-highlight-symbol-mode))

        (prompt-description-mode
         (on auto-highlight-symbol-mode))

        (help-mode
         ;; org-link-minor-mode in help-mode broke colors in list-colors-display
         ;; it also broke lsp-doctor colors
         ;; (on org-link-minor-mode)
         (off visual-line-mode))

        (term-mode
         (off fringe-mode)
         (off semantic-mode)
         (off highlight-thing-mode)
         (off ivy-mode)
         ;; (off global-hl-line-mode)
         ;; (off hl-line-mode)
         (on yas-minor-mode)
         (off org-indent-mode)
         (off persp-mode)
         (off which-key-mode)
         (on company-mode)
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
