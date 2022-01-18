(require 'cyphejor)
(require 'diminish)

;; diminish works fine
;; rich-minority is better "in theory" but i couldn't get it to work


;; I'd like to diminish the minor mode lines manually.
;; So I can be reminded only of modes that I don't already know about

;; Look at the variable 'minor-mode-alist' to determine the minor mode lighters

(diminish 'my-mode)
(diminish 'my/lisp-mode)
(diminish 'highlight-indent-guides-mode)
(diminish 'highlight-thing-mode)
(diminish 'lispy-mode)
(diminish 'emoji-cheat-sheet-plus-display-mode)
(diminish 'holy-mode)
(diminish 'repl-toggle-mode)
(diminish 'sotlisp-mode)
(diminish 'company-mode)
(diminish 'yas-minor-mode)
(diminish 'selected-minor-mode)
(diminish 'ggtags-mode)
(diminish 'pcre-mode)
(diminish 'evil-org-mode)
(diminish 'which-key-mode)
(diminish 'eldoc-overlay-mode)
(diminish 'paredit-mode)
(diminish 'org-link-minor-mode)
;; (diminish 'flycheck)


;; How do I list all the modes in the mode line?




;;(require 'rich-minority)
;;(rich-minority-mode 1)
;;
;;;; (add-to-list " Fill" 'rm-whitelist)
;;(add-to-list 'rm-whitelist " Fill")

;; (setq rm-blacklist
;;       (format "^ \\(%s\\)$"
;;               (mapconcat #'identity
;;                          '("Fly.*" "Projectile.*" "PgLn")
;;                          "\\|")))


(setq
 cyphejor-rules
 '(:upcase
   ("bookmark"    "→")
   ("buffer"      "β")
   ("diff"        "Δ")
   ("dired"       "δ")
   ("emacs"       "ε")
   ("inferior"    "i" :prefix)
   ("interaction" "i" :prefix)
   ("interactive" "i" :prefix)
   ("lisp"        "λ" :postfix)
   ("menu"        "▤" :postfix)
   ("mode"        "")
   ("package"     "↓")
   ("python"      "π")
   ("shell"       "sh" :postfix)
   ("text"        "ξ")
   ("wdired"      "↯δ")))

(cyphejor-mode 1)

(provide 'hide-minor-modes)