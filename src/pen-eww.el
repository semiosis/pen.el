(require 'eww)

(require 'cl-lib)
(require 'eww-lnum)
(require 'f)
(require 'ace-link)
(require 'eww)

(setq max-specpdl-size 10000)
;; This isn't a great solution
;; https://stackoverflow.com/q/11807128
(setq max-lisp-eval-depth 10000)

(setq shr-external-rendering-functions '((pre . eww-tag-pre)))
(setq shr-use-colors nil)

(define-key eww-mode-map (kbd "]") 'eww-next-image)
(define-key eww-mode-map (kbd "[") 'eww-previous-image)
(define-key eww-mode-map (kbd "M-]") nil)
(define-key eww-mode-map (kbd "M-[") nil)
(define-key image-map (kbd "r") nil)

(provide 'pen-eww)
