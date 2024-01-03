(require 'comint)

(defun pen-comint-bol ()
  (interactive)

  ;; Don't use eshell-bol in this function
  ;; or eshell-bol will become recursive
  ;; (defun eshell-bol ()
  ;; (pen-comint-bol))

  (cond
   ((derived-mode-p 'comint-mode)
    (comint-bol))
   
   ((derived-mode-p 'vterm-mode)
    (vterm-send-C-a))
   
   ((derived-mode-p 'eshell-mode)

    (let ((comint-use-prompt-regexp t)
          ;; Really need to derive this from scraping the line
          ;; (comint-prompt-regexp "^.*[»#\\$] ")
          ;; Don't use the backslash as a prompt marker.
          ;; or it will break in this instance:
          ;;  $PEN/documents/notes:master λ# sps o Music\ Data\ Base.xls
          (comint-prompt-regexp "^.*[»#$] "))
      ;; (call-interactively 'term-bol)
      (call-interactively 'comint-bol))
    
    ;; (eshell-bol)
    )
   
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
              (comint-prompt-regexp "^.*[»#\\$] "))
          ;; (call-interactively 'term-bol)
          (call-interactively 'comint-bol))
      (term-send-raw)))

   ((lispy--major-mode-lisp-p)
    (call-interactively 'lispy-move-beginning-of-line))

   (t
    (call-interactively 'beginning-of-line-or-indentation))))

(advice-add 'pen-comint-bol :around #'shut-up-around-advice)

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
   
   ((derived-mode-p 'eshell-mode)
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

(advice-add 'pen-comint-del :around #'shut-up-around-advice)
;; (advice-remove 'pen-comint-del #'shut-up-around-advice)

(define-key comint-mode-map (kbd "M-r") nil)

(provide 'pen-comint)
