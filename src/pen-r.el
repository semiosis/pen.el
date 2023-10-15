(loop for p in
      '(tree-sitter-ess-r express ess-view-data ess-view ess-smart-underscore
                          ess-smart-equals ess-r-insert-obj ess-R-data-view ess)
      do
      (eval `(use-package ,p :ensure t)))

(provide 'pen-r)
