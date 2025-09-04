;; It might be good practice for making imenu stuff to build a vimhelp mode

(define-derived-mode vimhelp-mode text-mode "vimhelp"
  "Major mode for navigating vim help text.")

(defun vimhelp-imenu-configure ()
  (interactive)
  (defset vimhelp-imenu-generic-expression
          '("Sections" "^\\([0-9]+\..*\\*\\)$" 1))

  (add-to-list
   'imenu-generic-expression
   vimhelp-imenu-generic-expression))

(add-hook 'vimhelp-mode-hook 'vimhelp-imenu-configure)


;; This didn't do it either:
;; (defun disable-org-link-minor-mode (proc &rest args)
;;   (org-link-minor-mode -1))
;; (advice-add 'vimhelp-mode-hook #'disable-org-link-minor-mode)



(provide 'pen-vimhelp)
