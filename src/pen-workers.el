(defun pen-sps-worker (&optional id_num)
  (interactive)
  (if id_num
      (pen-sps (cmd "penw" id_num))
    (pen-sps (cmd "penw"))))

(defun pen-fix-workers ()
  (interactive)
  (pen-sps "pen-fix-workers"))

(defun pen-watch-workers ()
  (interactive)
  (pen-sps "pen-watch-workers"))

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

(provide 'pen-workers)
