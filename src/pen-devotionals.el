;; Try to do my devotionals through this mechanism

(defun jeff-vines--word-for-today ()
  (interactive)
  (sps "jeff-vines--word-for-today"))

(defun alistair-begg--sermons ()
  (interactive)
  (sps "alistair-begg--sermons"))

;; desiring God
(defun john-piper ()
  "desiring God"
  (interactive))

(defun john-piper-messages ()
  "desiring God - Messages"
  (interactive)

  (sps (cmd "ranger" "/volumes/home/shane/dump/programs/httrack/mirrors/https-www-desiringgod-org-/www.desiringgod.org/messages")))

(defun john-piper-light-and-truth ()
  "desiring God - Classic Sermons (audio/video)"
  (interactive)

  ;; Each top-level html/directory in this directory is a sermon series with multiple parts

  (sps (cmd "ranger" "/volumes/home/shane/dump/programs/httrack/mirrors/https-www-desiringgod-org-/www.desiringgod.org/light-and-truth")))

(defun john-piper-labs ()
  "desiring God - Look at the Book

You look at a Bible text on the screen. You listen to John Piper. You watch his pen “draw out”
meaning. You see for yourself whether the meaning is really there. And (we pray!) all that God is
for you in Christ explodes with faith, and joy, and love."
  (interactive)

  (sps (cmd "ranger" "/volumes/home/shane/dump/programs/httrack/mirrors/https-www-desiringgod-org-/www.desiringgod.org/labs")))

(defun john-piper-articles ()
  "desiring God - Article"
  (interactive)

  (sps (cmd "ranger" "/volumes/home/shane/dump/programs/httrack/mirrors/https-www-desiringgod-org-/www.desiringgod.org/articles")))

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
