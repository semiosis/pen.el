(require 'bash-completion)
(bash-completion-setup)

;; TODO Bind this to something in eshell to use it
;; https://github.com/szermatt/emacs-bash-completion#completion-at-point
(defun bash-completion-from-eshell ()
  (interactive)
  (let ((completion-at-point-functions
         '(bash-completion-eshell-capf)))
    (completion-at-point)))

(defun bash-completion-eshell-capf ()
  (bash-completion-dynamic-complete-nocomint
   (save-excursion (eshell-bol) (point))
   (point) t))

(provide 'pen-bash-completion)