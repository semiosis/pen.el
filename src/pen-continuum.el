;; A list of strings, each a snapshot of the terminal
(defvar pen-terminal-states '())

;; Run the command a couple of times before running the prompt

(defun continuum-add-state (state)
  (interactive (list (pen-trim-max-chars (buffer-string-visible) 300)))
  (setq pen-terminal-states(cons state pen-terminal-states)))

(defun continuum-get-older ()
  (let ((r (reverse pen-terminal-states)))
    (if (and (not older-state)
             (> (length pen-terminal-states) 1))
        (second r))))

(defun continuum-get-old ()
  (let ((r (reverse pen-terminal-states)))
    (if (and (not old-state)
             (> (length pen-terminal-states) 1))
        (first r))))

(defun continuum-get-current ()
  (pen-trim-max-chars (buffer-string-visible) 300))

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