(require 'hideshow)
;; Hideshow hides comments and code blocks

(comment
 (add-to-list 'hs-special-modes-alist '(eshell-mode "{" "}" "/[*/]" nil nil)))

(provide 'pen-hideshow)
