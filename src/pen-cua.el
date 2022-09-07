(require 'cua-base)

(define-key global-map (kbd "<M-f5>") 'cua-paste)

(cua-mode 1)

;; (define-key global-map (kbd "C-y") 'cua-paste)
;; (define-key global-map (kbd "C-y") nil)
;; (define-key pen-map (kbd "C-y") 'cua-paste)

(setq cua-enable-cua-keys nil)

(defun helm-scroll-up ()
  (interactive)
  (dotimes (_n 8)
    (call-interactively 'helm-previous-line)))

(defun helm-scroll-down ()
  (interactive)
  (dotimes (_n 8)
    (call-interactively 'helm-next-line)))

(defun pen-cua-scroll-down ()
  (interactive)
  (cond
   ((minor-mode-p helm--minor-mode)
    (call-interactively 'helm-scroll-up))
   ((major-mode-p 'minibuffer-inactive-mode)
    (cond
     ((minor-mode-p selectrum-mode) (call-interactively 'selectrum-previous-page))
     (t (call-interactively 'ivy-scroll-up))))
   ((major-mode-p 'ranger-mode)
    (call-interactively 'ranger-half-page-up))
   (t (call-interactively 'cua-scroll-down))))

(defun pen-cua-scroll-up ()
  (interactive)
  (cond
   ((minor-mode-p helm--minor-mode)
    (call-interactively 'helm-scroll-down))
   ((major-mode-p 'minibuffer-inactive-mode)
    (cond
     ((minor-mode-p selectrum-mode) (call-interactively 'selectrum-next-page))
     (t (call-interactively 'ivy-scroll-down))))
   ((major-mode-p 'ranger-mode)
    (call-interactively 'ranger-half-page-down))
   ;; (define-key selectrum-minibuffer-map (kbd "<next>") 'selectrum-next-page)
   ;; (define-key selectrum-minibuffer-map (kbd "<prior>") 'selectrum-previous-page)
   (t (call-interactively 'cua-scroll-up))))

(define-key cua-global-keymap (kbd "<prior>") 'pen-cua-scroll-down)
(define-key cua-global-keymap (kbd "<next>") 'pen-cua-scroll-up)

(provide 'pen-cua)
