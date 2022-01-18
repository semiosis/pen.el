(require 'cyphejor)
(require 'diminish)

;; diminish works fine
;; rich-minority is better "in theory" but i couldn't get it to work


;; I'd like to diminish the minor mode lines manually.
;; So I can be reminded only of modes that I don't already know about

;; Look at the variable 'minor-mode-alist' to determine the minor mode lighters

(defun pen-diminish-modes ()
  (interactive)
  (dolist (s '(highlight-indent-guides-mode
               highlight-thing-mode
               lispy-mode
               emoji-cheat-sheet-plus-display-mode
               holy-mode
               repl-toggle-mode
               sotlisp-mode
               company-mode
               yas-minor-mode
               selected-minor-mode
               ggtags-mode
               pcre-mode
               evil-org-mode
               which-key-mode
               eldoc-overlay-mode
               paredit-mode
               org-link-minor-mode
               right-click-context-mode))
    (ignore-errors (diminish s))))

;; This was breaking pen.
;; Perhaps it's because the hook was erroring.
(pen-diminish-modes)
(add-hook 'after-make-frame-functions 'pen-diminish-modes)

(setq which-key-lighter "")
(setq-default which-key-lighter "")

;; ("ilambda"     "γ" :postfix)
;;    ("pen-mydefaults" "🖊" :postfix)
;;    ;; semiosis protocol
;;    ("semiosis"    "࿋" :postfix)

;; cyphejor is for shortening *Major-Mode* names
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

(provide 'pen-hide-minor-modes)