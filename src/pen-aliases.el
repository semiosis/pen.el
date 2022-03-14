(require 'pcase)

(defalias 'pen-empty-string-p 's-blank?)
(defalias 'tv 'pen-tv)
(defalias 'etv 'pen-etv)
(defalias 'f-basename 'f-filename)
(defalias 'region2string 'buffer-substring)
(defalias 'let-values 'pcase-let)

(provide 'pen-aliases)