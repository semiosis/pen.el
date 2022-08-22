;; https://roswell.github.io/Initial-Recommended-Setup.html

;; ros install slime
(load (expand-file-name "/root/repos/roswell/lisp/helper.el"))
(setq inferior-lisp-program "ros -Q run")

(provide 'pen-common-lisp)