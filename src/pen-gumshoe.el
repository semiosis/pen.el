;; using dogears now, because gumshoe doesnt work with emacs29

;; melpa
(require 'gumshoe)

;; Gumshoe: a spatial Point movement tracker
;; (use-package gumshoe
;;   :straight (gumshoe :type git
;;                      :host github
;;                      :repo "Overdr0ne/gumshoe"
;;                      :branch "master")
;;   :config
;;   ;; The minor mode must be enabled to begin tracking
;;   (global-gumshoe-mode 1))
(advice-add 'gumshoe-log-current-position :around #'ignore-errors-around-advice)

;; Gumshoe requires this:
(defalias 'math-pow 'expt)

(provide 'pen-gumshoe)
