(defun pen-turn-on-selected-minor-mode ()
  (interactive)

  (selected-minor-mode -1)
  (selected-region-active-mode -1)
  (selected-minor-mode 1))

(define-globalized-minor-mode
  global-selected-minor-mode selected-minor-mode pen-turn-on-selected-minor-mode)
(global-selected-minor-mode t)

(provide 'pen-selected)