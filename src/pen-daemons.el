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

(defun pen-qa ()
  (interactive)
  (pen-sps
   (pen-cmd "pen-e" "qa")))

(defun pen-ka ()
  (interactive)
  (pen-sps
   (pen-cmd "pen-e" "ka")))

(defun pen-sa ()
  (interactive)
  (pen-sps
   (pen-cmd "pen-e" "sa")))

(provide 'pen-daemons)