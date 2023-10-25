(require 'jump-tree)
;; comes from straight
;; (require 'gumshoe)

(global-jump-tree-mode 1)

;; Install and load `quelpa-use-package'.
(package-install 'quelpa-use-package)
(require 'quelpa-use-package)

(package-refresh-contents)
(use-package dogears
  :ensure t

  ;; These bindings are optional, of course:
  :bind (:map global-map
              ("M-g d" . dogears-go)
              ("M-g M-b" . dogears-back)
              ("M-g M-f" . dogears-forward)
              ("M-g M-d" . dogears-list)
              ("M-g M-D" . dogears-sidebar)))

;; minor mode
(dogears-mode 1)

(advice-add 'jump-tree-visualize-jump-next :around #'ignore-errors-around-advice)

(defun pen-holy-jump ()
  (interactive)
  (cond
   ((>= (prefix-numeric-value current-prefix-arg) 4) (call-interactively 'dogears-list))
   ;; (t (call-interactively 'consult-gumshoe))
   ;; (t (call-interactively 'gumshoe-peruse-in-buffer))
   (t (call-interactively 'dogears-back))))
(advice-add 'jump-tree-visualize-jump-prev :around #'ignore-errors-around-advice)

(define-key pen-map (kbd "C-o") #'pen-holy-jump)
(define-key jump-tree-map (kbd "M-.") nil)

(provide 'pen-jump-tree)
