(require 'tab-bar)
(require 'tab-line)

;; Always keep the tab bar hidden, even when the mode is on.
;; This is the way to go to avoid the failed assertion
(setq tab-bar-show nil)
;; Disable the built-in emacs tab-bar-mode and keep using tab-line-mode for the moment
(tab-bar-mode -1)
(tab-bar-mode t)

(tab-line-mode -1)

(provide 'pen-tabs)
