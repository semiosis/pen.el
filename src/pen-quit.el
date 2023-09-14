(defun quit-app ()
  (interactive)
  (cond
   ((major-mode-p 'crossword-mode) (call-interactively 'crossword-quit))
   (t nil)))

(define-key pen-map (kbd "M-q M-q") 'quit-app)

(provide 'pen-quit)
