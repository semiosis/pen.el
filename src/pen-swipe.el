(require 'swiper)
(require 'helm-swoop)

(defvar swipecmd 'swiper)

(defun pen-swiper (&optional initial-input)
  "Fixes the initial Lisp nesting exceeds ‘max-lisp-eval-depth’ error after opening a file and running swiper for the first time."
  (interactive)
  (swiper initial-input)
  (swiper initial-input))

(defun pen-swipe ()
  (interactive)
  (let ((s (pen-selected-text t))
        (x visual-line-mode))

    (if mark-active
        (deactivate-mark))

    (setf visual-line-mode -1)
    (consult-line s)
    (setf visual-line-mode x)))

(defun stribb/isearch-region (&optional not-regexp no-recursive-edit)
  "If a region is active, make this the isearch default search pattern."
  (interactive "P\np")
  (when (use-region-p)
    (let ((search (buffer-substring-no-properties
                   (region-beginning)
                   (region-end))))
      (setq deactivate-mark t)
      (isearch-yank-string search))))

(advice-add 'isearch-forward-regexp :after 'stribb/isearch-region)
(advice-add 'isearch-forward :after 'stribb/isearch-region)

(require 'helm-org-rifle)
(defun pen-isearch-forward ()
  (interactive)
  (cond
   ((>= (prefix-numeric-value current-prefix-arg) 8)
    (let ((current-prefix-arg nil))
      (call-interactively 'helm-org-rifle)))
   (t (call-interactively 'isearch-forward-regexp))))

(define-key isearch-mode-map "\C-s" 'isearch-repeat-forward)

(defun swiper-dir (&optional dir)
  (interactive (list (read-string-hist "swiper dir:")))
  (with-current-buffer
    (dired dir)
    (call-interactively 'swiper)))

(define-key pen-map (kbd "M-l C-s") 'pen-swipe)

(provide 'pen-swipe)