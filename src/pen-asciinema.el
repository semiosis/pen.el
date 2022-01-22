(defun pen-tm-asciinema-play (url)
  (interactive (list (read-string "asciinema url:")))

  (if (display-graphic-p)
      (pen-nw (concat "pen-asciinema-play -h " (pen-q url)))
    (pen-sn (concat "pen-asciinema-play " (pen-q url)))))

(provide 'pen-asciinema)