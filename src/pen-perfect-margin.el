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

(defun olivetti-mode-around-advice (proc &rest args)
  (let ((o-enabled olivetti-mode)
        (g-enabled git-gutter+-mode))
    (if (and g-enabled
             (not olivetti-mode))
        (progn
          (git-gutter+-mode -1)
          (message "Disabling git gutter before enabling olivetti")))
    (let ((res (apply proc args)))
      res)))
(advice-add 'olivetti-mode :around #'olivetti-mode-around-advice)

;; (advice-remove 'olivetti #'olivetti-mode-around-advice)

(provide 'pen-perfect-margin)
