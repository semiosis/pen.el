(require 'test-case-mode)

(advice-add 'test-case-mode :around #'ignore-errors-around-advice)

(provide 'pen-test-case-mode)
