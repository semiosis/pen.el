(require 'hippie-exp)
(require 'hippie-exp-ext)

(remove-from-list 'hippie-expand-try-functions-list 'yas-hippie-try-expand)

(setq hippie-expand-try-functions-list '(try-expand-dabbrev try-expand-dabbrev-all-buffers try-expand-dabbrev-from-kill try-complete-file-name-partially try-complete-file-name try-expand-all-abbrevs try-expand-list try-expand-line try-complete-lisp-symbol-partially try-complete-lisp-symbol))

(provide 'pen-hippie-expand)