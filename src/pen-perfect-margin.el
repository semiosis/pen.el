;; (require 'perfect-margin)
;; 
;; ;; (perfect-margin-mode 1)
;; ;; (perfect-margin-mode -1)
;; 
;; (setq perfect-margin-visible-width 128)
;; 
;; (dolist (margin '("<left-margin> " "<right-margin> "))
;;   (global-set-key (kbd (concat margin "<mouse-1>")) 'ignore)
;;   (global-set-key (kbd (concat margin "<mouse-3>")) 'ignore)
;;   (dolist (multiple '("" "double-" "triple-"))
;;     (global-set-key (kbd (concat margin "<" multiple "wheel-up>")) 'mwheel-scroll)
;;     (global-set-key (kbd (concat margin "<" multiple "wheel-down>")) 'mwheel-scroll)))

(require 'olivetti)

(provide 'pen-perfect-margin)
