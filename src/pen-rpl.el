(require 'rpl-mode)

(add-hook 'rpl-mode-hook 'subword-mode)

;; sp +/"^### Bindings (statements)" "$MYGIT/rosie-pattern-language/rosie/doc/rpl.md"


(defun rpl-imenu-configure ()
  (interactive)
  (defset rpl-imenu-generic-expression
          ;; '("statement / pat. expr. binding" "^\\([0-9a-z_]+ = .*\\)$" 1)
          '("" "^\\([0-9a-z_]+ = .*\\)$" 1))

  (add-to-list
   'imenu-generic-expression
   rpl-imenu-generic-expression))

(add-hook 'rpl-mode-hook 'rpl-imenu-configure)

(provide 'pen-rpl)

