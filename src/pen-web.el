(defun pen-has-gui-p ()
  (pen-snq "pen-has-gui-p"))

(defun pen-start-gui-web-browser ()
  (interactive)
  (if (pen-has-gui-p)
      (pen-sn "pen web" nil nil nil t)
    (error "Display server not available")))

(defun pen-get-ttyd-port ()
  (string-to-number
   (sor (pen-snc "cat ~/.pen/ports/ttyd.txt")
        "7681")))

(defun pen-public-web ()
  (interactive)
  (if (pen-internet-connected-p)
      (pen-sn (pen-cmd "unbuffer" "pen-lt" "--port" (str (pen-get-ttyd-port)) "-o") nil nil nil t)
    (error "The internet is not connected so you won't be able to expose Pen.el publically")))

(provide 'pen-web)
