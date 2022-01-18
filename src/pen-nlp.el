(defset pen-average-word-lengths
  '(("english" . 5.1)))

(defun pen-get-average-word-length ()
  (alist-get "english" pen-average-word-lengths nil nil 'string-equal))

(defun ngram-suggest (query)
  (interactive (list (read-string-hist "ngram-suggest query: ")))

  (if (string-match "^[^*]+$" query)
      (setq query (concat query " *")))

  (let ((res (s-lines (pen-snc "ngram-complete" query))))
    (if (interactive-p)
        (xc (fz res
                nil nil "ngram-suggest copy: "))
      res)))

(defun gen-google-ngram-queries (s i)
  (-filter-not-empty-string
   (str2list
    (pen-snc
     (concat
      "echo "
      (pen-q s)
      " | google-ngram-query-combinations "
      (str i)
      ;; " | perl -e 'print sort { length($b) <=> length($a) } <>'"
      )))))

(defun ngram-query-replace-this ()
  (interactive)
  (if (not mark-active)
      (let* ((get-current-line-string-str (chomp (get-current-line-string)))
             (col (+ 1 (current-column)))
             (suggestions (ngram-suggest (fz (gen-google-ngram-queries line-str col)
                                             nil nil "ngram-query-replace-this query: "))))
        (if (-filter-not-empty-string suggestions)
            (let ((replacement (fz suggestions
                                   nil nil "ngram-query-replace-this replacement: ")))
              (if (sor replacement)
                  (nbfs replacement)))))))

(defun ngram-query-replace ()
  (interactive)
  (if mark-active
      (let* ((query (if mark-active
                        (pen-selection)))
             (reformulated-query (if (string-match-p "\\*" query)
                                     query
                                   (let ((wildcard-word (fz (split-string query " " t)
                                                            nil nil "ngram-query-replace wildcard-word: ")))
                                     (if wildcard-word
                                         (s-replace-regexp (eatify wildcard-word) "*" query)
                                       query))))
             (suggestions (ngram-suggest reformulated-query)))
        (if (-filter-not-empty-string suggestions)
            (let ((replacement (fz suggestions
                                   nil nil "ngram-query-replace suggestions: ")))
              (if replacement
                  (progn
                    (cua-delete-region)
                    (insert replacement))))))
    (ngram-query-replace-this)))


(provide 'pen-nlp)