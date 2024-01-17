(advice-add 'vc-refresh-state :around #'ignore-errors-around-advice)

(provide 'pen-vc)
