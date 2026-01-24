(require 'jump-tree)
;; comes from straight
;; (require 'gumshoe)

(global-jump-tree-mode 1)

;; Install and load `quelpa-use-package'.
(package-install 'quelpa-use-package)
(require 'quelpa-use-package)

;; (package-refresh-contents)
(use-package dogears
  :ensure t

  ;; These bindings are optional, of course:
  :bind (:map global-map
              ("M-g d" . dogears-go)
              
              ("M-g M-D" . dogears-sidebar)))

(defun pen-buffer-history ()
  (interactive)

  (if (>= (prefix-numeric-value current-prefix-arg) 4)
      (call-interactively 'dogears-list)
    (try
     (call-interactively 'handle-history)
     (call-interactively 'dogears-list))))

(defun pen-buffer-hist-prev ()
  (interactive)

  (try
   (call-interactively 'handle-prevhist)
   (call-interactively 'dogears-back)))

(defun pen-buffer-hist-next ()
  (interactive)

  (try
   (call-interactively 'handle-nexthist)
   (call-interactively 'dogears-forward)))

;; C-M-b C-M-p
(define-key global-map (kbd "<select> <prior>") 'pen-buffer-hist-prev)
;; C-M-b C-M-n
(define-key global-map (kbd "<select> <next>") 'pen-buffer-hist-next)

(define-key global-map (kbd "M-g M-P") 'pen-buffer-hist-prev)
(define-key global-map (kbd "M-g M-N") 'pen-buffer-hist-next)
(define-key global-map (kbd "M-G M-P") 'pen-buffer-hist-prev)
(define-key global-map (kbd "M-G M-N") 'pen-buffer-hist-next)

(define-key global-map (kbd "M-g M-d") 'pen-buffer-history)

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
