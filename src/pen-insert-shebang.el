(require 'insert-shebang)

; (add-hook 'find-file-hook 'insert-shebang)

;; The package adds the hook when it's required. Therefore, I must
;; remove it.
(remove-hook 'find-file-hook 'insert-shebang)

(provide 'pen-insert-shebang)