(require 'cua-base)
(require 'lispy)

(defun pen-lispy-paste ()
  (interactive)
  (xc (pen-mnm (xc nil t t)) t t)
  (call-interactively 'lispy-yank))

(defun pen-paste ()
  (interactive)
  (xc (pen-mnm (xc nil t t)) t t)
  (call-interactively 'cua-paste))

(defun pen-c-w-cut ()
  "Cuts the word before cursor if a region is not selected, and performs regular C-w instead if there is a region"
  (interactive)
  (if (not (region-active-p))
      (progn
        (call-interactively 'cua-cut-region)
        (xc (yanked) t))
    (let ((pen nil))
      (execute-kbd-macro (kbd "C-w"))
      (xc (yanked) t))))

;; This wasn't great. But I need it to expand macros
(defun pen-m-w-copy ()
  "Forward word if a region is not selected."
  (interactive)
  (if (not (or (region-active-p) (lispy-left-p)))
      (call-interactively 'pen-complete-words)
    (let ((pen nil))
      (execute-kbd-macro (kbd "M-w"))))
  (deactivate-mark))

(if (inside-docker-p)
    (progn
      (defun cua-paste-around-advice (proc &rest args)
        (xc (pen-mnm (xc nil t)) t)
        (let ((default-directory "/"))
          (let ((res (apply proc args)))
            res)))
      (advice-add 'cua-paste :around #'cua-paste-around-advice)))

;; (define-key pen-map (kbd "M-w") 'xc)
(define-key pen-map (kbd "M-w") 'pen-m-w-copy)
(define-key lispy-mode-map (kbd "C-y") 'pen-lispy-paste)

(provide 'pen-paste)