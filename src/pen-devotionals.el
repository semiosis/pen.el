(defun michael-youseff ()
  (interactive)
  ;; TODO Make this handle 'recent' properly
  (let* ((links (string2list (pen-snc "leading-the-way-recent")))
         (tuples (mapcar
                  (λ (e)
                    (list
                     (--> e
                          (s-replace-regexp "^\\[\\[" "" it)
                          (s-replace-regexp "\\]\\[.*" "" it))
                     (--> e
                          (s-replace-regexp "^\\[\\[.*\\]\\[" "" it)
                          (s-replace-regexp "\\]\\]$" "" it))))
                  links))
         (devurl
          (fz tuples nil nil "Leading the way: ")))

    (chrome devurl nil t)))


(defun davidjeremiah (&optional last_n)
  (interactive (list (string-to-int (sor (read-string-hist "last `n` devotionals:")
                                         "0"))))
  (let ((id (string-to-int (s-replace-regexp ":.*" "" (fz (davidjeremiah-list last_n)
                                                          nil nil "Devotional:")))))

    (listen-to-davidjeremiah id)))


(defun chuckswindoll (&optional last_n)
  (interactive)

  (let ((url (chomp (xurls (tpop "mfz -q \"'\""
                                 (snc "ocif chuckswindoll")
                                 :width_pc 50
                                 :output_b t)))))

    (if (test-n url)
        (chrome url nil t)))

  
  ;; (interactive (list (string-to-int (sor (read-string-hist "last `n` devotionals:")
  ;;                                        "0"))))
  ;; (let ((id (string-to-int (s-replace-regexp ":.*" "" (fz (davidjeremiah-list last_n)
  ;;                                                         nil nil "Devotional:")))))

  ;;   (listen-to-davidjeremiah id))
  )


(defun davidjeremiah-list (&optional last_n)
  (interactive (list (string-to-int (read-string-hist "last `n` devotionals:"))))
  (let* ((max_id (string-to-int (pen-snc "david-jeremiah-get-latest-radio-id")))
         (min_id (max 1 (- max_id last_n))))

    (mapcar
     (λ (tp)
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
