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

(defun pen-paredit-kill ()
  (interactive)

  ;; With an argument, should run paredit-kill without adding to the
  ;; kill ring
  (if (>= (prefix-numeric-value current-prefix-arg) 4)
      (let ((kr kill-ring))
        (call-interactively 'paredit-kill)
        (setq kill-ring kr)
        (xc (car kill-ring)))
    (call-interactively 'paredit-kill)))

(define-key paredit-mode-map (kbd "C-k") 'pen-paredit-kill)

(provide 'pen-paredit)
