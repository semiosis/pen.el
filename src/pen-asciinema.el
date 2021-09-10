(defun pen-tm-asciinema-play (url)
  (interactive (list (read-string "asciinema url:")))
  (pen-sn (concat "pen-asciinema-play " (pen-q url))))

(provide 'pen-asciinema)