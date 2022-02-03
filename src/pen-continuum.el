;; A list of strings, each a snapshot of the terminal
(defset pen-terminal-states '())

;; Run the command a couple of times before running the prompt

(defun continuum-add-state (state)
  (interactive (list (pen-trim-max-chars (buffer-string-visible))))
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
  (pen-trim-max-chars (buffer-string-visible) 300))

(provide 'pen-continuum)