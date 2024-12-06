(defun praise-2hrs ()
  (interactive)

  ;; TODO Launch praise
  ;; Start at a random time.

  ;; 2:15:24
  ;; myrc-get youtube_key

  (let* ((vid "9bZkp7q19f0")
         (duration (snc (cmd "get-youtube-video-duration" vid)))))

  (chrome "[[https://www.youtube.com/watch?v=iKb0GTI9T7Y][youtube.com: 2 Hours Non Stop Worship Songs With Lyrics - WORSHIP & PRAISE SONGS - Christian Gospel Songs 2022 {@musicpraise7618}]]" nil t))

(defun hillsong ()
  (interactive)
  (chrome "[[https://www.youtube.com/watch?v=_1HGZ_9aRhI][youtube.com: Hillsong Worship Best Praise Songs Collection 2023 - Gospel Christian Songs Of Hillsong Worship {@HallelujahHarmony68}]]" nil t))

(defun vintage-christmas-music ()
  (interactive)
  (chrome "[[https://www.youtube.com/watch?v=VIydA6_K71Y][youtube.com: 4 Hours Of Vintage Department Store Christmas Music - Customusic Tapes {@highnumbers}]]" nil t))

(defun bethel ()
  (interactive)
  (chrome "[[https://www.youtube.com/watch?v=MtH0vvSbqcI][youtube.com: Best Bethel Music Gospel Praise and Worship Songs 2022 - Most Popular Bethel Music Medley {@gospelmusic9582}]]" nil t))

(defun psalms-1-50 ()
  (interactive)
  (chrome "[[https://www.youtube.com/watch?v=17CU60yLnLE][youtube.com: The book of Psalms 1-50 read by David Suchet {@JonahInWales}]]" nil t))

(provide 'pen-music)
