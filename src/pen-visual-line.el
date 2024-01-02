(require 'visual-fill-column)
;; (require 'visual-line)

(setq visual-line-fringe-indicators '(left-curly-arrow right-curly-arrow))

;; (add-hook 'visual-line-mode-hook #'visual-fill-column-mode)

(setq-default fill-column 80)
;; (setq-default visual-fill-column-center-text t)
(setq-default visual-fill-column-center-text nil)

;; Hide the backslash at the end of the line
;; https://www.emacswiki.org/emacs/LineWrap
;; (set-display-table-slot standard-display-table 'wrap ?\ )

(provide 'pen-visual-line)
