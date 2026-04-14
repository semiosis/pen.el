;; (require 'window-jump)

(use-package 'window-jump
  :ensure t
  ;; :bind (:map dired-mode-map
  ;;             (")" . dired-git-info-mode))
  )

;; <f1> bindings seem to be related to <help> bindings in emacs somehow
;; but two keys are very much different.

;; I have to find a way to stop <f1> and <help> being so bound.

;; <HELP>
;; [[info:emacs#Glossary][Emacs Info: emacs#Glossary]]
;; <HELP> is the Emacs name for ‘C-h’ or <F1>.  You can type <HELP> at
;; any time to ask what options you have, or to ask what a command
;; does.  *Note Help::.

;; (define-key global-map [help] 'help-command)
;; (define-key global-map [f1] 'help-command)

(load-library "window-jump")
(defun wj-cursor-pos ()
  (let ((pos (pos-visible-in-window-p (window-point) (selected-window) t))
        (box (wj-window-box (selected-window))))
    (when (null pos) ; Work around a bug in pos-visible-in-window-p when running terminal emacs
      (setq pos (wj-vec (wj-edges-left box) (wj-edges-bottom box))))
    ;; Move pos to the center of the cursor instead of the top-left pixel
    (if (display-p)
        (setq pos (wj-vec (+ (/ (float (frame-char-width)) 2) (wj-vx pos))
                          (+ (/ (float (frame-char-height)) 2) (wj-vy pos))))
      (setq pos (wj-vec (+ left-margin-width (wj-vx pos))
                        (wj-vy pos))))
    (wj-vec (+ (wj-edges-left box) (wj-vx pos))
            (+ (wj-edges-top box) (wj-vy pos)))))

(defun pen-tty-cursor-pos ()
  (let ((margin-x (or (car (window-margins (get-buffer-window)))
                      0))
        (wj-pos (wj-cursor-pos)))
    (list (+ (car wj-pos) margin-x)
          (cadr wj-pos))))

;; I had to unbind f1 from help, like this:
(define-key global-map [f1] nil)

(define-key global-map (kbd "<f1> k") 'window-jump-up)
(define-key global-map (kbd "<f1> j") 'window-jump-down)
(define-key global-map (kbd "<f1> h") 'window-jump-left)
(define-key global-map (kbd "<f1> l") 'window-jump-right)
(global-set-key (kbd "<f1> o") #'other-window)

(provide 'pen-window-jump)
