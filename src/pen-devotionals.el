(defun davidjeremiah ()
  (interactive)
  (let ((id (string-to-int (s-replace-regexp ":.*" "" (fz (davidjeremiah-list 5000)
                                                          nil nil "Devotional:")))))

    (listen-to-davidjeremiah id)))


(defun davidjeremiah-list (&optional last_n)
  (interactive (list (string-to-int (read-string-hist "last `n` devotionals:"))))
  (let* ((max_id (string-to-int (pen-snc "david-jeremiah-get-latest-radio-id")))
         (min_id (max 1 (- max_id last_n))))

    (mapcar
     (lambda (tp)
       (concat (str (car tp)) ": " (cadr tp)))
     (reverse (cl-loop for x from min_id to max_id
                       collect
                       (list x (pen-snc (cmd "david-jeremiah-get-topic" x))))))))

(defun listen-to-davidjeremiah (&optional id)
  (interactive
   (let ((max_id (pen-snc "david-jeremiah-get-latest-radio-id")))
     (list (read-string-hist "id=" max_id))))
  
  (chrome (concat "https://www.davidjeremiah.org/radio/player?id=" (str id))
          nil t))


(provide 'pen-devotionals)
