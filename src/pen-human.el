(defun pen-display-p ()
  (pen-snq "display-p"))

(defun pen-start-hidden-terminal (&optional in-cterm)
  (interactive)
  (if in-cterm
      (pen-sps "pen-hidden-terminal -pet")
    (pen-sps "pen-hidden-terminal")
    ;; (pen-term "pen-hidden-terminal -h")
    )
  (message "The hidden terminal has started somewhere."))

(defun pen-start-hidden-terminal-in-pet ()
  (interactive)
  (pen-start-hidden-terminal t))

(defun pen-start-pet-in-hidden-terminal ()
  (interactive)
  (pen-sps "pen-hidden-terminal -pet-in"))

(provide 'pen-human)