(require 'comint)

(defun pen-comint-bol ()
  (interactive)

  (cond
   ((derived-mode-p 'comint-mode)
    (comint-bol))
   
   ;; ((and (derived-mode-p 'term-mode)
   ;;       (minor-mode-enabled term-char-mode)
   ;;       ;; (term-in-char-mode)
   ;;       ;; (term-in-line-mode)
   ;;       )
   ;;  (let ((pos
   ;;         (save-excursion-and-region-reliably
   ;;          (comint-bol))))
   ;;    (if (< pos (point))
   ;;        (let ((pen-mode nil))
   ;;          (execute-kbd-macro (kbd "C-a"))))))

   ((derived-mode-p 'term-mode)
    (if (term-in-line-mode)
        (let ((comint-use-prompt-regexp t)
              ;; Really need to derive this from scrraping the line
              (comint-prompt-regexp "^.*[#\\$] "))
          ;; (call-interactively 'term-bol)
          (call-interactively 'comint-bol))
      (term-send-raw)))

   ((lispy--major-mode-lisp-p)
    (call-interactively 'lispy-move-beginning-of-line))

   (t
    (call-interactively 'beginning-of-line))))

(defun comint-delchar ()
  (interactive)
  (let ((pos
         (save-excursion-and-region-reliably
          (comint-bol))))
    (if (< pos (point))
        (delete-backward-char 1))))

(defun pen-comint-del ()
  (interactive)

  (cond
   ((derived-mode-p 'comint-mode)
    (comint-delchar))

   ((derived-mode-p 'term-mode)
    ;; (lambda () (interactive) (term-send-raw-string "?"))
    (if (term-in-line-mode)
        (let ((comint-use-prompt-regexp t)
              ;; Really need to derive this from scrraping the line
              (comint-prompt-regexp "^.*[#\\$] "))
          (comint-delchar))
      (term-send-raw)))

   (t
    (delete-backward-char 1)
    ;; (let ((pen-mode nil))
    ;;   (execute-kbd-macro (kbd "C-h")))
    )))

(provide 'pen-comint)
