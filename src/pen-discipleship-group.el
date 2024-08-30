(require 'pen-dates-and-locales)

(defset hymn-yt-urls '("[[https://www.youtube.com/watch?v=K5qgKMWbo4c&t=1s][youtube.com: Wait On The Lord : Piano Instrumental Music With Scriptures & Autumn Scene d???CHRISTIAN piano]]"
                       "[[https://www.youtube.com/watch?v=z6vR_FV7s7c][youtube.com: 4 Hours Best TOP 27 Worship Piano Instrumental for Prayer and Meditation e,?e??i??i??]]"
                       "[[https://www.youtube.com/watch?v=9oVSJUk9wDg][youtube.com: The Love Of God : Instrumental Worship, Meditation & Prayer Music with Nature d???CHRISTIAN piano]]"
                       "[[https://www.youtube.com/watch?v=atM1QICvvtI][youtube.com: Praise - Elevation worship | Instrumental Worship | Soaking Music | Deep Prayer]]"
                       "[[https://www.youtube.com/watch?v=0v-JiclgWKE][youtube.com: Here I Am to Worship - 3 Hour Instrumental Soaking Worship for Prayer & Healing]]"
                       "[[https://www.youtube.com/watch?v=hRuVDZndzhU][youtube.com: ?Worship & Prayer Instrumental Music - Gentle Instrumental Church Hymns to Calm the Soul]]"
                       "[[https://www.youtube.com/watch?v=YIBNUIhqyFI][youtube.com: 24/7 HYMNS: A Peaceful Morning With JESUS  - soft piano hymns + loop]]"
                       "[[https://www.youtube.com/watch?v=K6BpMe9BlzU&t=2759s][youtube.com: 24/7 HYMNS:  Early Morning With The Father Hymns - soft piano hymns + loop]]"
                       "[[https://www.youtube.com/watch?v=S0j3BzPEy3w][youtube.com: 24/7 HYMNS: Thank God Its A New Day Hymns - soft piano hymns + loop]]"))

(defun dgs-get-weekly-hymn-music-link (&optional week)
  (setq week (or week (date-week-number)))

  (-select-mod-element hymn-yt-urls week))

;; e:/volumes/home/shane/notes/d-group-replicate
;; Show the F260 pdf
(comment (snc "cd \"/volumes/home/shane/notes/d-group-replicate\"; z Replicate\\ -\\ F260\\ Reading\\ Plan.pdf &"))

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
                 "Deuteronomy 1-7"))
          (12 . ("Deuteronomy 8-9"
                 "Deuteronomy 30-34"
                 "Joshua 1-4"))
          (13 . ("Joshua 5-8"
                 "Joshua 23-24"
                 "Judges 2-4"))
          (14 . ("Judges 6-7"
                 "Judges 13-16"
                 "Ruth 1-4"))
          (15 . ("I Samuel 1-3"
                 "I Samuel 8-10"
                 "I Samuel 13-16"))
          (16 . ("I Samuel 17-22"
                 "Psalm 22"
                 "I Samuel 24-25"
                 "I Samuel 28"
                 "I Samuel 31"))
          (17 . ("II Samuel 1-7"
                 "Psalm 18"
                 "Psalm 23"
                 "II Samuel 9"
                 "II Samuel 11-12"))
          (18 . ("II Samuel 24"
                 "Psalm 1"
                 "Psalm 19"
                 "Psalm 24"
                 "Psalm 51"
                 "Psalm 103"
                 "Psalm 119:1-128"))
          (19 . ("I Kings 2"
                 "I Kings 6"
                 "I Kings 8-9"
                 "Psalm 148-150"
                 
                 "Psalm 119:129-176"))
          (20 . ("Proverbs 1-4"
                 "Proverbs 16-18"
                 "Proverbs 31"
                 "I Kings 11-12"))
          (21 . ("I Kings 16:29-34"
                 "I Kings 17"
                 "II Kings 2"
                 "II Kings 5"
                 "II Kings 6:1-23"))
          (22 . ("Jonah 1-4"
                 "Hosea 1-3"
                 "Amos 1:1"
                 "Amos 9"
                 "Joel 1-3"))
          (23 . ("Isaiah 6"
                 "Isaiah 9"
                 "Isaiah 44-45"
                 "Isaiah 52-53"
                 "Isaiah 65-66"
                 "Micah 1"
                 "Micah 4:6-13"
                 "Micah 5"))
          (24 . ("II Kings 17-18"
                 "II Kings 19-21"
                 "II Kings 22-23"
                 "Jeremiah 1-2"
                 "Jeremiah 3:1-5"
                 "Jeremiah 25"
                 "Jeremiah 29"))
          (25 . ("Jeremiah 31:31-40"
                 "Jeremiah 32-33"
                 "Jeremiah 52"
                 "II Kings 24-25"
                 "Ezekiel 1:1-3"
                 "Ezekiel 36:16-38"
                 "Ezekiel 37"
                 "Daniel 1-2"
                 "Daniel 3-4"))
          (26 . ("Daniel 5-6"
                 "Daniel 9-10"
                 "Daniel 12"
                 "Ezra 1-2"
                 "Ezra 3-4"
                 "Ezra 5-6"))
          (27 . ("Zechariah 1:1-6"
                 "Zechariah 2"
                 "Zechariah 12"
                 "Ezra 7-8"
                 "Ezra 9-10"
                 "Esther 1-2"
                 "Esther 3-4"))
          (28 . ("Esther 5-7"
                 "Esther 8-10"
                 "Nehemiah 3-4"
                 "Nehemiah 5-6"))
          (29 . ("Nehemiah 7-8"
                 "Nehemiah 9-10"
                 "Nehemiah 11-12"))
          (30 . ("Nehemiah 13"
                 "Malachi 1-2"
                 "Malachi 3-4"))
          (31 . ("Luke 1-2"
                 "Matthew 1-2"
                 "Mark 1"
                 "John 1"))
          (32 . ("Matthew 3-4"
                 "Matthew 5-6"
                 "Matthew 7-8"))
          (33 . ("Luke 9:10-62"
                 "Mark 9-10"
                 "Luke 12"
                 "John 3-4"
                 "Luke 14"))
          (34 . ("John 6"
                 "Matthew 19:16-30"
                 "Luke 15-16"
                 "Luke 17:11-37"
                 "Luke 18"
                 "Mark 10"))
          (35 . ("John 11"
                 "Matthew 21:1-13"
                 "John 13-14"
                 "John 15-16"
                 "Matthew 24:1-31"))))

(defset d-group-weekly-readings-ot260
        '((1 . ("Genesis 1-6"
                "Psalm 1-5"))
          (2 . ("Genesis 7-12"
                "Psalm 6-10"))
          (3 . ("Genesis 15-19"
                "Psalm 11-15"))
          (4 . ("Genesis 20-25"
                "Psalm 16-20"))
          (5 . ("Genesis 26-30"
                "Psalm 21-25"))
          (6 . ("Genesis 31-37"
                "Psalm 26-30"))
          (7 . ("Genesis 39-43"
                "Psalm 31-35"))
          (8 . ("Genesis 44-48"
                "Psalm 36-40"))
          (9 . ("Genesis 49-50"
                "Exodus 1-3"
                "Psalm 41-45"))
          (10 . ("Exodus 4-8"
                 "Psalm 46-50"))
          (11 . ("Exodus 9-13"
                 "Psalm 51-55"))
          (12 . ("Exodus 14-20"
                 "Psalm 56-60"))
          (13 . ("Exodus 24-28"
                 "Psalm 61-65"))
          (14 . ("Exodus 29-33"
                 "Psalm 66-70"))
          (15 . ("Exodus 34-40"
                 "Leviticus 8-9"
                 "Psalm 71-75"))
          (16 . ("Leviticus 16"
                 "Leviticus 23"
                 "Leviticus 26"
                 "Numbers 11-12"
                 "Psalm 76-78"))
          (17 . ("Numbers 13-20"
                 "Psalm 81-85"))
          (18 . ("Numbers 21-35"
                 "Psalm 86-90"))
          (19 . ("Deuteronomy 1-5"
                 "Psalm 91-95"))
          (20 . ("Deuteronomy 6-9"
                 "Deuteronomy 30"
                 "Psalm 96-100"))
          (21 . ("Deuteronomy 31-34"
                 "Joshua 1-2"
                 "Psalm 101-105"))
          (22 . ("Joshua 3-7"
                 "Psalm 106-110"))
          (23 . ("Joshua 8"
                 "Joshua 23-24"
                 "Judges 2-3"
                 "Psalm 111-115"))
          (24 . ("Judges 4"
                 "Judges 6"
                 "Judges 8"
                 "Psalm 116-118"))
          (25 . ("Judges 15-16"
                 "Ruth 1-3"
                 "Psalm 119"))
          (26 . ("Ruth 4"
                 "I Samuel 1-3"
                 "I Samuel 1-8"
                 "Psalm 120-123"))
          (27 . ("I Samuel 9-15"
                 "Psalm 124-128"))
          (28 . ("I Samuel 16-20"
                 "Psalm 129-133"))
          (29 . ("I Samuel 21-25"
                 "Psalm 134-138"))
          (30 . ("I Samuel 28-31"
                 "II Samuel 1-5"
                 "Psalm 138-143"))
          (31 . ("II Samuel 6-12"
                 "Psalm 144-148"))
          (32 . ("II Samuel 24"
                 "I Kings 2-3"
                 "I Kings 6-8"
                 "Psalm 149-150"
                 "Proverbs 1-3"))
          (33 . ("I Kings 11-12"
                 "I Kings 17-19"
                 "Proverbs 4-8"))
          (34 . ("I Kings 21-22"
                 "II Kings 2-5"
                 "Proverbs 9-13"))
          (35 . ("II Kings 6"
                 "Jonah 1-4"
                 "Proverbs 14-18"))
          (36 . ("Hosea 1-3"
                 "Amos 9"
                 "Joel 1"
                 "Proverbs 19-23"))
          (37 . ("Joel 2-3"
                 "Isaiah 6"
                 "Isaiah 9"
                 "Isaiah 44"
                 "Proverbs 24-28"))
          (38 . ("Isaiah 45"
                 "Isaiah 52-53"
                 "Proverbs 29-31"
                 "Job 1-2"))
          (39 . ("Micah 1"
                 "Micah 5"
                 "II Kings 17-19"
                 "Job 3-7"))
          (40 . ("I Kings 20"
                 "II Kings 21-23"
                 "Jeremiah 1:4-5"
                 "Job 8-12"))
          (41 . ("Jeremiah 25"
                 "Jeremiah 29-33"
                 "Jeremiah 52"
                 "Job 13-17"))
          (42 . ("II Kings 24-25"
                 "Ezekiel 36-37"
                 "Daniel 1"
                 "Job 18-22"))))

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
                 "Romans 1-3"))
          (23 . ("Romans 4-8"))
          (24 . ("Romans 9-13"))
          (25 . ("Romans 14-16"
                 "Acts 20-21"))
          (26 . ("Acts 22-26"))
          (27 . ("Acts 27-28"
                 "Colossians 1-3"))
          (28 . ("Colossians 4"
                 "Ephesians 1-4"))
          (29 . ("Ephesians 5-6"
                 "Philippians 1-3"))
          (30 . ("Philippians 4"
                 "Philemon"
                 "Hebrews 1-3"))
          (31 . ("Hebrews 4-8"))
          (32 . ("Hebrews 9-13"))
          (33 . ("I Timothy 1-5"))
          (34 . ("I Timothy 6"
                 "II Timothy 1-4"))
          (35 . ("Titus 1-3"
                 "I Peter 1-2"))
          (36 . ("I Peter 3-5"
                 "II Peter 1-2"))
          (37 . ("II Peter 3"
                 "John 1-4"))
          (38 . ("John 5-9"))
          (39 . ("John 10-14"))
          (40 . ("John 15-19"))
          (41 . ("John 20-21"
                 "I John 1-3"))
          (42 . ("I John 4-5"
                 "II John"
                 "III John"))
          (43 . ("Revelation 1-5"))
          (44 . ("Revelation 6-10"))
          (45 . ("Revelation 11-15"))
          (46 . ("Revelation 16-20"))
          (47 . ("Revelation 21-22"
                 "Matthew 1-3"))
          (48 . ("Matthew 4-8"))
          (49 . ("Matthew 9-13"))
          (50 . ("Matthew 14-18"))
          (51 . ("Matthew 19-23"))
          (52 . ("Matthew 24-28"))))

(defun d-group-get-weekly-reading (&optional week reading-list)
  (setq week (or week (date-week-number)))
  (setq reading-list (or reading-list d-group-weekly-readings-nt260))
  (list2str (cdr (assoc (date-week-number) reading-list))))

(defun d-group-get-weekly-reading-nt (&optional week)
  (d-group-get-weekly-reading week d-group-weekly-readings-nt260))

(defun d-group-get-weekly-reading-fnd (&optional week)
  (d-group-get-weekly-reading week d-group-weekly-readings-foundations260))

(defun d-group-get-weekly-reading-ot (&optional week)
  (d-group-get-weekly-reading week d-group-weekly-readings-ot260))

(defset d-group-weekly-scripture-memory-ot260
        '((1 . ("Psalm 1:1-2"))
          (2 . ("Psalm 6:1-2"))
          (3 . ("Psalm 13:5"))
          (4 . ("Psalm 16:1-2"))
          (5 . ("Genesis 26:3-5"))
          (6 . ("Psalm 27:4"))
          (7 . ("Psalm 31:3"))
          (8 . ("Psalm 40:1-3"))
          (9 . ("Matthew 22:37-38"))
          (10 . ("Psalm 46:1"))
          (11 . ("Psalm 51:1-2"))
          (12 . ("Psalm 57:2"))
          (13 . ("Psalm 63:1-3"))
          (14 . ("Psalm 68:5"))
          (15 . ("Psalm 71:5-6"))
          (16 . ("Psalm 77:11-12"))
          (17 . ("Psalm 84:11"))
          (18 . ("Psalm 86:15"))
          (19 . ("Deuteronomy 1:29-30"))
          (20 . ("Deuteronomy 6:4-5"))
          (21 . ("Joshua 1:8-9"))
          (22 . ("Joshua 107:9"))
          (23 . ("Joshua 23:14"))
          (24 . ("Psalm 119:18"))
          (25 . ("Psalm 119:50"))
          (26 . ("Psalm 119:156"))
          (27 . ("Psalm 127:1"))
          (28 . ("1 Samuel 16:7"))
          (29 . ("Psalm 138:2"))
          (30 . ("Psalm 141:3"))
          (31 . ("Psalm 145:8-9"))
          (32 . ("Proverbs 3:5-6"))
          (33 . ("Proverbs 4:23"))
          (34 . ("Proverbs 12:11"))
          (35 . ("Proverbs 14:7"))
          (36 . ("Hosea 6:3"))
          (37 . ("Isaiah 9:6"))
          (38 . ("Isaiah 53:6"))
          (39 . ("2 Kings 1:3-4"))
          (40 . ("Jeremiah 1:4-5"))
          (41 . ("Jeremiah 29:13"))
          (42 . ("Ezekiel 36:26-27"))))

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
          (12 . ("Matthew 5:23-24"))
          (13 . ("Matthew 5:25-26"))
          (14 . ("Matthew 5:27-28"))
          (15 . ("Matthew 5:29-30"))
          (16 . ("Matthew 5:31-32"))
          (17 . ("Matthew 5:33-35"))
          (18 . ("Matthew 5:36-37"))
          (19 . ("Matthew 5:38-40"))
          (20 . ("Matthew 5:40-42"))
          (21 . ("Matthew 5:43-45"))
          (22 . ("Matthew 5:45-46"))
          (23 . ("Matthew 5:47-48"))
          (24 . ("Matthew 6:1-2"))
          (25 . ("Matthew 6:3-4"))
          (26 . ("Matthew 6:5-6"))
          (27 . ("Matthew 6:7-8"))
          (28 . ("Matthew 6:9-11"))
          (29 . ("Matthew 6:12-13"))
          (30 . ("Matthew 6:14-15"))
          (31 . ("Matthew 6:16-18"))
          (32 . ("Matthew 6:19-21"))
          (33 . ("Matthew 6:22-24"))
          (34 . ("Matthew 6:25-26"))
          (35 . ("Matthew 6:27-28"))
          (36 . ("Matthew 6:29-30"))
          (37 . ("Matthew 6:31-32"))
          (38 . ("Matthew 6:33-34"))
          (39 . ("Matthew 7:1-2"))
          (40 . ("Matthew 7:3-4"))
          (41 . ("Matthew 7:5-6"))
          (42 . ("Matthew 7:7-8"))
          (43 . ("Matthew 7:9-10"))
          (44 . ("Matthew 7:11-12"))
          (45 . ("Matthew 7:13-14"))
          (46 . ("Matthew 7:15-16"))
          (47 . ("Matthew 7:17-18"))
          (48 . ("Matthew 7:19-20"))
          (49 . ("Matthew 7:21-23"))
          (50 . ("Matthew 7:24-25"))
          (51 . ("Matthew 7:26-27"))
          (52 . ("Matthew 7:28-29"))))

;; "Psalm 139"

(defun d-group-get-weekly-scripture-memory-nt (&optional week)
  (setq week (or week (date-week-number)))
  (list2str (cdr (assoc week d-group-weekly-scripture-memory-nt260))))

(defun d-group-get-weekly-scripture-memory-ot (&optional week)
  (setq week (or week (date-week-number)))
  (list2str (cdr (assoc week d-group-weekly-scripture-memory-ot260))))

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
                          (str2lines (d-group-get-weekly-scripture-memory-nt week))
                          (str2lines (d-group-get-weekly-reading-nt week))
                          (str2lines (d-group-get-weekly-reading-fnd week))
                          (str2lines (d-group-get-weekly-scripture-memory-ot week))
                          (str2lines (d-group-get-weekly-reading-ot week)))
         collect
         (concat "| " (d-group-linkify-bible-verse-ref (car row) t) " | " (d-group-linkify-bible-verse-ref (cadr row)) " | " (d-group-linkify-bible-verse-ref (third row)) " | " (d-group-linkify-bible-verse-ref (fourth row) t) " | " (d-group-linkify-bible-verse-ref (fifth row)) " |")))
  ;; (pen-yas-expand-string "| [[sh:bible-read-passage nasb `(d-group-get-weekly-scripture-memory-nt)`]] | [[sh:bible-read-passage nasb `(d-group-get-weekly-reading)`]] |")
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
