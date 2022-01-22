(defun pen-tm-asciinema-play (url &optional caption)
  (interactive (list (read-string "asciinema url:")
                     ""))

  (if (pen-internet-connected-p)
      (if (display-graphic-p)
          (eval
           `(pen-use-vterm
             (pen-nw (concat "pen-asciinema-play -h " (pen-q ,url)))))
        (pen-sn (concat "pen-asciinema-play " (pen-q url))))
    (error "Please connect to the internet")))

(provide 'pen-asciinema)