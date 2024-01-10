(require 'pen-dates-and-locales)

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

(defun d-group-get-weekly-reading (&optional week)
  (setq week (or week (date-week-number)))
  (list2str (cdr (assoc week d-group-weekly-readings-nt260))))

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
  (if (sor ref)
      (concat "[[sh:tpop nem nasb " ref " ][" ref "]]")
    ""))

;; (d-group-weekly-scripture-memory-hear-journal-table-rows 5)
(defun d-group-weekly-scripture-memory-hear-journal-table-rows (&optional week)
  (setq week (or week (date-week-number)))
  (list2str
   (loop for row in
         (-zip-lists-fill "" (str2lines (d-group-get-weekly-reading week)) (str2lines (d-group-get-weekly-scripture-memory week)))
         collect
         (concat "| " (d-group-linkify-bible-verse-ref (car row)) " | " (d-group-linkify-bible-verse-ref (cadr row)) " |")))
  ;; (pen-yas-expand-string "| [[sh:tpop nem nasb `(d-group-get-weekly-scripture-memory)`]] | [[sh:tpop nem nasb `(d-group-get-weekly-reading)`]] |")
  )

(defun d-group-weekly-journal ()
  (interactive)
  (dired (umn "$PEN/documents/notes/ws/discipleship-group/weekly-journal")))

(defun d-group-hear-preparation ()
  (interactive)
  (dired (umn "$PEN/documents/notes/ws/discipleship-group/preparation")))

;; [[brain:agenda/Church::Discipleship group <2023-12-29 Fri 12:00 +1w>]]
(defun d-group-agenda ()
  (interactive)
  (org-link-open-from-string "[[brain:agenda/Church::Discipleship group <2023-12-29 Fri 12:00 +1w>]]"))

(provide 'pen-discipleship-group)
