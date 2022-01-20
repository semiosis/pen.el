(defun pen-fix-daemons ()
  (interactive)
  (pen-sps "pen-fix-daemons"))

(defun pen-watch-daemons ()
  (interactive)
  (pen-sps "pen-watch-daemons"))

(defun pen-rla ()
  (interactive)
  (pen-sps
   (pen-cmd "pen-e" "rla")))
(defalias 'pen-reload-all 'pen-rla)

(provide 'pen-daemons)