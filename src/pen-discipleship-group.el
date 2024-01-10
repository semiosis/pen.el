(defun d-group-get-weekly-reading ()
  '((1 ("Luke 1-5"))
    (2 ("Luke 6-10"))
    (3 ("Luke 11-15"))
    (4 ("Luke 16-20"))
    (5 ("Luke 21-24"
        "Acts 1"))
    (6 ("Acts 2-6"))
    (7 ("Acts 7-11"))
    (8 ("Acts 12-14"
        "James 1-2"))
    (9 ("James 3-5"
        "Acts 15-16"))
    (10 ("Galatians 1-5"))
    (11 ("Galatians 6"
         "Acts 17-18"))
    (12 ("I Thessalonians 1-2"))
    (13 ("I Thessalonians 1-2"))))

(defun d-group-get-weekly-scripture-memory ()
  "Matthew 5:1-2")

(defun d-group-memorize-scripture ()
  (interactive)
  (dired (umn "$PEN/documents/notes/ws/discipleship-group/memorization")))

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
