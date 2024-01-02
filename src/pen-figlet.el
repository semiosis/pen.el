(defun insert-figlet (&optional input)
  (interactive (list (read-string-hist "input")))
  (pen-insert (snc "figlet | cat" input)))

(defun insert-figlet-org (text)
  (interactive (list (read-string-hist "text")))
  (pen-insert (org-babel-template-gen
               (snc "figlet | cat" text)
               "text")))

(provide 'pen-figlet)
