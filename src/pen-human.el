(defun pen-display-p ()
  (pen-snq "display-p"))

(defun pen-start-hidden-terminal ()
  (interactive)
  (pen-sps "pen-hidden-terminal")
  (message "The hidden terminal has started somewhere."))

(provide 'pen-human)