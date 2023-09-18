;; TODO Automate
;; - After making changes to your grammar, just run tree-sitter generate again.
;; - Run tests:
;;   tree-sitter parse 'examples/**/*.go' --quiet --stat

(require 'tree-sitter)
(require 'tree-sitter-langs)
(require 'tree-sitter-indent)
(require 'tree-sitter-hl)
(require 'tree-sitter-debug)
(require 'tree-sitter-query)

;; Install .so files from a version bundle.
;; mx:tree-sitter-langs-install-grammars

;; ev:tree-sitter-langs-grammar-dir

;; To get elisp, I need to compile it, I think

(tree-sitter-require 'rust)
(tree-sitter-require 'python)
(tree-sitter-require 'javascript)

;; ;; Elisp is currently not useful for syntax highlighting because everything is currently considered a sexp
;; Besides, it's not working very well right now
;; vim +/"## Limitations" "$MYGIT/Wilfred/tree-sitter-elisp/README.md"
;; (tree-sitter-require 'elisp)

(tree-sitter-require 'go)

(global-tree-sitter-mode)

(provide 'pen-tree-sitter)