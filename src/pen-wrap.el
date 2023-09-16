(require 'adaptive-wrap)
;; (use-package 'adaptive-wrap)

;; e ia adaptive-wrap
;; https://elpa.gnu.org/packages/adaptive-wrap.html

(setq adaptive-wrap-extra-indent 2)

(add-hook 'bible-mode-hook #'adaptive-wrap-prefix-mode)
(add-hook 'bible-search-mode-hook #'adaptive-wrap-prefix-mode)

(provide 'pen-wrap)
