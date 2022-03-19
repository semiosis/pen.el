(require 'paredit)

(define-key paredit-mode-map (kbd "M-(") nil)
(define-key paredit-mode-map (kbd "M-)") nil)
(define-key paredit-mode-map (kbd "M-;") nil)
(define-key paredit-mode-map (kbd "M-s") nil)
(define-key paredit-mode-map (kbd "\"") nil)
(define-key paredit-mode-map (kbd "DEL") nil)
(define-key paredit-mode-map (kbd "M-DEL") nil)
(define-key paredit-mode-map (kbd "\\") nil)
(define-key paredit-mode-map (kbd "M-\"") nil)
;; Because I want counsel-ag to work
(define-key paredit-mode-map (kbd "M-?") nil)

(defun paredit-join-sexps-around-advice (proc &rest args)
  (if mark-active
      (let ((res (apply proc args)))
        res)
    (call-interactively 'evil-join)))
(advice-add 'paredit-join-sexps :around #'paredit-join-sexps-around-advice)

(defun paredit-kill-around-advice (proc &rest args)
  (try
   (let ((res (apply proc args)))
     (xc (yanked) t)
     res)
   (kill-line)))
;; (advice-remove 'paredit-kill #'paredit-kill-around-advice)
(advice-add 'paredit-kill :around #'paredit-kill-around-advice)

(provide 'pen-paredit)