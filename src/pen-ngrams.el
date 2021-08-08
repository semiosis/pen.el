(defun pen-ngrams-postprocess (s)
  (snc "sed \"s/I 'm/I'm/g\"" s))

(defset pen-corpora '((15 "english 2012")
                      (16 "english fiction")
                      (26 "english 2019")))

(defun pen-ngrams-get (phrase year-start year-end corpus)
  (interactive (list (read-string-hist "pen-ngrams-get phrase: ")
                     (read-string-hist "pen-ngrams-get year-start: " "1800")
                     (read-string-hist "pen-ngrams-get year-end: " "2020")
                     26))
  (let ((ngrams
         (ecurl (format "https://books.google.com/ngrams/json?content=%s&year_start=%s&year_end=%s&corpus=%s&smoothing=3"
                        (snc "sed 's/%2A/*/g'" (url-encode-url phrase))
                        (or year-start "1800")
                        (or year-end "2020")
                        (or corpus 26)))
         ;; (snc "jq -r .[].ngram"
         ;;      (ecurl (format "https://books.google.com/ngrams/json?content=%s&year_start=%s&year_end=%s&corpus=%s&smoothing=3"
         ;;                     (snc "sed 's/%2A/*/g'" (url-encode-url phrase))
         ;;                     (or year-start "1800")
         ;;                     (or year-end "2020")
         ;;                     (or corpus 26))))
         ))
    (if (interactive-p)
        (etv ngrams)
      ngrams)))

 ;; | pen-htmldecode | postprocess

(provide 'pen-ngrams)