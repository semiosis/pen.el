(defun pen-tm-asciinema-play (url &optional caption)
  (interactive (list (read-string "asciinema url:")
                     ""))

  (if (internet-connected-p)
      (if (display-graphic-p)
          (eval
           `(pen-use-vterm
             (pen-nw (concat "pen-asciinema-play -h " (pen-q ,url)))))
        (pen-sn (concat "pen-asciinema-play " (pen-q url))))
    (message "Internet is not connected")))

(provide 'pen-asciinema)