(require 'comint)

(define-key comint-mode-map (kbd "C-j") 'comint-accumulate)
(define-key comint-mode-map (kbd "C-a") 'comint-bol)
(define-key comint-mode-map (kbd "C-e") 'end-of-line)

(defun pen-comint-del ()
  (interactive)

  (let ((pos
         (save-excursion-and-region-reliably
          (comint-bol))))
    (if (< pos (point))
        (delete-backward-char 1))))

(define-key pen-map (kbd "DEL") 'pen-comint-del)

(provide 'pen-comint)