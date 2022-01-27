(defun pen-start-gui-web-browser ()
  (interactive)
  (pen-sn "pen web" nil nil nil t))

(defun pen-public-web ()
  (interactive)
  (pen-sn "pen-lt --port 7681 -o" nil nil nil t))

(provide 'pen-web)