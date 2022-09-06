(advice-add 'eldoc-print-current-symbol-info :around #'ignore-errors-around-advice)

(provide 'pen-eldoc)
