(defun term-ranger ()
  (interactive)
  ;; ranger just doesn't look good in term
  ;; (pen-term-nsfa (concat "ranger " (pen-q (current-directory))))
  (pen-nw (concat "ranger " (pen-q (current-directory)))))

(defun spv-ranger ()
  (interactive)
  (shell-command (concat "pen-tm -f -d -te spv -c " (pen-q default-directory) " ranger")))

(defun sps-ranger (dir)
  (interactive (list default-directory))
  (shell-command (concat "pen-tm -f -d -te pen-sps -c " (pen-q dir) " ranger")))
(defalias 'sh/ranger 'sps-ranger)

(provide 'pen-ranger)