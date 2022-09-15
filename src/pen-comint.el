(require 'comint)

(defun pen-comint-bol ()
  (interactive)

  (cond
   ((and (derived-mode-p 'term-mode)
         (minor-mode-enabled term-char-mode))
    (let ((pos
           (save-excursion-and-region-reliably
            (comint-bol))))
      (if (< pos (point))
          (let ((pen-mode nil))
            (execute-kbd-macro (kbd "C-a"))))))

   (t
    (beginning-of-line))))

(defun pen-comint-del ()
  (interactive)

  (cond
   ((derived-mode-p 'comint-mode) (let ((pos
                                         (save-excursion-and-region-reliably
                                          (comint-bol))))
                                    (if (< pos (point))
                                        (delete-backward-char 1))))

   ((derived-mode-p 'term-mode)
    ;; (lambda () (interactive) (term-send-raw-string "?"))
    (term-send-raw))

   (t
    (delete-backward-char 1)
    ;; (let ((pen-mode nil))
    ;;   (execute-kbd-macro (kbd "C-h")))
    )))

(provide 'pen-comint)
