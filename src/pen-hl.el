(require 'hl-line)

;; NEVER unhighlight the current line
(setq hl-line-sticky-flag t)
(setq global-hl-line-sticky-flag t)

(global-hl-line-mode 1)

(provide 'pen-hl)