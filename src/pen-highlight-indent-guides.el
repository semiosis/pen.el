(require 'highlight-indent-guides)

(setq highlight-indent-guides-method 'column)

(set-face-background 'highlight-indent-guides-even-face nil)
(set-face-background 'highlight-indent-guides-odd-face "#202020")

;; This prevents the highlighting from resetting
(setq highlight-indent-guides-auto-enabled nil)

(provide 'pen-highlight-indent-guides)