;; A list of strings, each a snapshot of the terminal
(defset pen-terminal-states '())

;; Run the command a couple of times before running the prompt

(defun continuum-add-state (state)
  (interactive (list (buffer-string-visible)))
  (setq pen-terminal-states(cons state pen-terminal-states)))

(defun continuum-get-older ()
  (let ((r (reverse pen-terminal-states)))
    (if (> (length pen-terminal-states) 1)
        (second r))))

(defun continuum-get-old ()
  (let ((r (reverse pen-terminal-states)))
    (if (> (length pen-terminal-states) 1)
        (first r))))

(defun continuum-get-current ()
  (buffer-string-visible))

(defun continuum-push ()
  (interactive)
  (setq pen-terminal-states (cons (continuum-get-current) pen-terminal-states)))

(defun continuum (older-state old-state)
  (interactive (list (continuum-get-older) (continuum-get-old)))

  (pf-guess-your-terminal-s-future/3
   (continuum-get-older)
   (continuum-get-old)
   (continuum-get-current)))

(provide 'pen-continuum)