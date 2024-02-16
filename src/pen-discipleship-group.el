(require 'pen-dates-and-locales)

;; It's better to compact the verses than to separate into days
;; It's easier to handle them that way.
(defset d-group-weekly-readings-foundations260
        '((1 . ("Genesis 1-9"
                "Job 1-2"))
          (2 . ("Job 38-42"
                "Genesis 11-17"))
          (3 . ("Genesis 18-26"))
          (4 . ("Genesis 27-28"))
          (5 . ("Genesis 39-47"))
          (6 . ("Genesis 48-50"
                "Exodus 1-7"))
          (7 . ("Exodus 8-17"))
          (8 . ("Exodus 18-31"))
          (9 . ("Exodus 32-40"
                "Leviticus 8-17"))
          (10 . ("Leviticus 18-26"
                 "Numbers 11-17"))
          (11 . ("Numbers 20"
                 "Numbers 27"
                 "Numbers 34-35"
                 "Deuteronomy 1-7"))))

;; New Testament 260
;; A 260-day Bible reading plan
(defset d-group-weekly-readings-nt260
        '((1 . ("Luke 1-5"))
          (2 . ("Luke 6-10"))
          (3 . ("Luke 11-15"))
          (4 . ("Luke 16-20"))
          (5 . ("Luke 21-24"
                "Acts 1"))
          (6 . ("Acts 2-6"))
          (7 . ("Acts 7-11"))
          (8 . ("Acts 12-14"
                "James 1-2"))
          (9 . ("James 3-5"
                "Acts 15-16"))
          (10 . ("Galatians 1-5"))
          (11 . ("Galatians 6"
                 "Acts 17-18"
                 "I Thessalonians 1-2"))
          (12 . ("I Thessalonians 3-5"
                 "II Thessalonians 1-2"))
          (13 . ("II Thessalonians 3"
                 "Acts 19"
                 "I Corinthians 1-3"))
          (14 . ("I Corinthians 4-8"))
          (15 . ("I Corinthians 9-13"))
          (16 . ("I Corinthians 14-16"
                 "II Corinthians 1-2"))
          (17 . ("II Corinthians 3-7"))
          (18 . ("II Corinthians 8-12"))
          (19 . ("II Corinthians 13"
                 "Mark 1-4"))
          (20 . ("Mark 5-9"))
          (21 . ("Mark 10-14"))
          (22 . ("Mark 15-16"
                 "Romans 1-3"))))

(defun d-group-get-weekly-reading (&optional week reading-list)
  (setq week (or week (date-week-number)))
  (setq reading-list (or reading-list d-group-weekly-readings-nt260))
  (list2str (cdr (assoc (date-week-number) reading-list))))

(defun d-group-get-weekly-reading-nt (&optional week)
  (d-group-get-weekly-reading week d-group-weekly-readings-nt260))

(defun d-group-get-weekly-reading-ot (&optional week)
  (d-group-get-weekly-reading week d-group-weekly-readings-foundations260))

(defset d-group-weekly-scripture-memory-nt260
        '((1 . ("Matthew 5:1-2"))
          (2 . ("Matthew 5:3-4"))
          (3 . ("Matthew 5:5-6"))
          (4 . ("Matthew 5:7-8"))
          (5 . ("Matthew 5:9-10"))
          (6 . ("Matthew 5:11-12"))
          (7 . ("Matthew 5:13-14"))
          (8 . ("Matthew 5:15-16"))
          (9 . ("Matthew 5:17-18"))
          (10 . ("Matthew 5:19-20"))
          (11 . ("Matthew 5:21-22"))
          (12 . ("Matthew 5:23-24"))))

(defun d-group-get-weekly-scripture-memory (&optional week)
  (setq week (or week (date-week-number)))
  (list2str (cdr (assoc week d-group-weekly-scripture-memory-nt260))))

(defun d-group-linkify-bible-verse-ref (ref &optional tpop)
  (let ((tmwindowtype
         (if tpop
             "bible-read-passage"
           ;; "sps nem"
           ;; Use emacs
           "bible-study-passage")))

    (if (sor ref)
        (concat "[[sh:" tmwindowtype " nasb " ref " ][" ref "]]")
      "")))

;; (d-group-weekly-scripture-memory-hear-journal-table-rows 5)
(defun d-group-weekly-scripture-memory-hear-journal-table-rows (&optional week)
  (setq week (or week (date-week-number)))
  (list2str
   (loop for row in
         (-zip-lists-fill ""
                          (str2lines (d-group-get-weekly-scripture-memory week))
                          (str2lines (d-group-get-weekly-reading-nt week))
                          (str2lines (d-group-get-weekly-reading-ot week)))
         collect
         (concat "| " (d-group-linkify-bible-verse-ref (car row) t) " | " (d-group-linkify-bible-verse-ref (cadr row)) " | " (d-group-linkify-bible-verse-ref (third row)) " |")))
  ;; (pen-yas-expand-string "| [[sh:bible-read-passage nasb `(d-group-get-weekly-scripture-memory)`]] | [[sh:bible-read-passage nasb `(d-group-get-weekly-reading)`]] |")
  )

(defun d-group-weekly-journal-dir ()
  (interactive)
  (if (interactive-p)
      (dired (umn "$PEN/documents/notes/ws/discipleship-group/weekly-journal"))
    (umn "$PEN/documents/notes/ws/discipleship-group/weekly-journal")))

(defun d-group-hear-preparation ()
  (interactive)
  (if (interactive-p)
      (dired (umn "$PEN/documents/notes/ws/discipleship-group/preparation"))
    (umn "$PEN/documents/notes/ws/discipleship-group/preparation")))

;; [[brain:agenda/Church::Discipleship group <2023-12-29 Fri 12:00 +1w>]]
(defun d-group-agenda ()
  (interactive)
  (org-link-open-from-string "[[brain:agenda/Church::Discipleship group <2023-12-29 Fri 12:00 +1w>]]"))

(defun d-group-weekly-journal ()
  (interactive)
  (let* ((dir (d-group-weekly-journal-dir))
         (fp (f-join dir (weekfile t))))
    (if (and (file-exists-p fp)
             (not (test-s fp)))
        (f-delete fp))
    (e fp)))

(provide 'pen-discipleship-group)
