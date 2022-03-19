(require 'jump-tree)
;; comes from straight
(require 'gumshoe)

(global-jump-tree-mode 1)

(advice-add 'jump-tree-visualize-jump-next :around #'ignore-errors-around-advice)

(defun pen-holy-jump ()
  (interactive)
  (cond
   ((>= (prefix-numeric-value current-prefix-arg) 4) (call-interactively 'dogears-list))
   ;; (t (call-interactively 'consult-gumshoe))
   (t (call-interactively 'gumshoe-peruse-in-buffer))))
(advice-add 'jump-tree-visualize-jump-prev :around #'ignore-errors-around-advice)

(define-key pen-map (kbd "C-o") #'pen-holy-jump)
(define-key jump-tree-map (kbd "M-.") nil)

(provide 'pen-jump-tree)
