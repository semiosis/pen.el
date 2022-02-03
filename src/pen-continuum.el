;; A list of strings, each a snapshot of the terminal
(defvar pen-terminal-states '())

;; Run the command a couple of times before running the prompt

(defun continuum-add-state (state)
  (interactive (list (pen-trim-max-chars (buffer-string-visible) 300)))
  (setq pen-terminal-states(cons state pen-terminal-states)))

(defun continuum (older-state old-state)
  (interactive (list '(nil nil)))

  (let ((r (-reverse pen-terminal-states)))
    (if (and (not older-state)
             (> (length pen-terminal-states) 1))
        (setq older-state (second r)))
    (if (and (not old-state)
             (> (length pen-terminal-states) 1))
        (setq old-state (first r))))
  (pf-guess-your-terminal-s-future/2 older old))

(provide 'pen-continuum)