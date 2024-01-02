(defun praise-2hrs ()
  (interactive)

  ;; TODO Launch praise
  ;; Start at a random time.

  ;; 2:15:24
  ;; myrc-get youtube_key

  (let* ((vid "9bZkp7q19f0")
         (duration (snc (cmd "get-youtube-video-duration" vid)))))

  (chrome "https://www.youtube.com/watch?v=kJcAbgoQWIk&ab_channel=AaliyahTzur" nil t))

(defun hillsong ()
  (interactive)
  (chrome "https://www.youtube.com/watch?v=MHu3cH34-0g&ab_channel=ChristianHillsongMusic" nil t))

(defun vintage-christmas-music ()
  (interactive)
  (chrome "https://www.youtube.com/watch?v=VIydA6_K71Y&ab_channel=HighNumbers" nil t))

(defun bethel ()
  (interactive)
  (chrome "https://www.youtube.com/watch?v=MtH0vvSbqcI&ab_channel=GospelMusic" nil t))

(provide 'pen-music)
