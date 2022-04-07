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

(defun backward-kill-word-or-region (&optional arg)
  "Calls `kill-region' when a region is active and
`backward-kill-word' otherwise. ARG is passed to
`backward-kill-word' if no region is active."
  (interactive "p")
  (if (region-active-p)
      (call-interactively #'kill-region)
    (backward-kill-word arg)))

(defun pen-c-w-cut ()
  "Cuts the word before cursor if a region is not selected, and performs regular C-w instead if there is a region"
  (interactive)
  (call-interactively 'backward-kill-word-or-region)
  (xc (yanked) t))

(defun cua-copy-region-around-advice (proc &rest args)
  (let ((res (apply proc args)))
    (xc (yanked) t)
    res))
(advice-add 'cua-copy-region :around #'cua-copy-region-around-advice)
;; (advice-remove 'cua-copy-region #'cua-copy-region-around-advice)

;; This wasn't great. But I need it to expand macros
(defun pen-m-w-copy ()
  "Forward word if a region is not selected."
  (interactive)
  (if (or (region-active-p) (lispy-left-p))
      (let ((pen nil))
        ;; This may expand macros
        (execute-kbd-macro (kbd "M-w")))
    t
    ;; (call-interactively 'pen-complete-words)
    )
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
