(require 'cua-base)

(define-key global-map (kbd "<M-f5>") 'cua-paste)

(cua-mode 1)

;; (define-key global-map (kbd "C-y") 'cua-paste)
;; (define-key global-map (kbd "C-y") nil)
;; (define-key pen-map (kbd "C-y") 'cua-paste)

(setq cua-enable-cua-keys nil)

(defun pen-cua-scroll-down ()
  (interactive)
  (cond
   ((major-mode-p 'minibuffer-inactive-mode)
    (call-interactively 'ivy-scroll-up))
   (t (call-interactively 'cua-scroll-down))))

(defun pen-cua-scroll-up ()
  (interactive)
  (cond
   ((major-mode-p 'minibuffer-inactive-mode)
    (call-interactively 'ivy-scroll-down))
   (t (call-interactively 'cua-scroll-up))))

(define-key cua-global-keymap (kbd "<prior>") 'pen-cua-scroll-down)
(define-key cua-global-keymap (kbd "<next>") 'pen-cua-scroll-up)

(provide 'pen-cua)