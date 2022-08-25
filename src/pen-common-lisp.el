;; https://roswell.github.io/Initial-Recommended-Setup.html

;; ros install slime
(load (expand-file-name (pen-umn "$HOME/.roswell/helper.el")))
(setq inferior-lisp-program "ros -Q run")

(provide 'pen-common-lisp)
