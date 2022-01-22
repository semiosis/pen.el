(defun pen-tm-asciinema-play (url &optional caption)
  (interactive (list (read-string "asciinema url:")
                     ""))

  (if (pen-internet-connected-p)
      (if (display-graphic-p)
          (eval
           `(pen-use-vterm
             (pen-nw (concat "pen-asciinema-play -h " (pen-q ,url)))))
        (pen-sn (concat "pen-asciinema-play " (pen-q url))))
    (error "The internet is not connected so the demos can't be played currently! Please connect to view asciinema videos.")))

(provide 'pen-asciinema)