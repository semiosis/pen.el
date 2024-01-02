;; e:$PEN/documents/notes/ws/lists/peniel/star.el

(defun org-link-get-title (s)
  (--> s
       (s-replace-regexp ".*\\]\\[" "" it)
       (s-replace-regexp "\\]\\]$" "" it)))

(defun praise-edit-list ()
  (interactive)
  (find-file (umn "$PEN/documents/notes/ws/lists/peniel/praise-songs.org")))

(defun praise ()
  ;; e:$HOME/.emacs.d/host/pen.el/scripts/praise
  (interactive)
  (let* ((contents_fp (pen-snc "ocif -otf praise-list-songs"))
         ;; (contents_s (pen-snc "ocif praise-list-songs"))
         (contents_s (cat contents_fp))
         (urls_s (awk1 (xurls contents_s)))
         (urls (str2lines urls_s))
         (ocs_s (pen-snc "ci -nd -f oc" urls_s))
         (ocs (str2lines ocs_s))
         (titles (mapcar 'org-link-get-title ocs))
         (annoed_tps (-zip-lists urls titles))
         (sel (fz annoed_tps
                  nil nil "Praise song: ")))
    (if (test-n sel)
        (progn
          ;; YouTube subtitles are not accurate
          (new-buffer-from-string (pen-readsubs sel))
          (play-song-chrome sel)))))

;; Who You say I am (Irish accent) -  https://youtu.be/MHu3cH34-0g?t=740

;; TODO Make this open up in bible-mode
;; j:bible-mode--open-search
;; j:bible-mode--display-search
(defun blessings ()
  (interactive)
  ;; (tpop "blessings")
  ;; (nbfs (snc "ocif blessings -pp"))
  (find-file (snc "ocif -otf blessings -pp"))
  ;; (nbfs (snc "ocif show-promises"))
  )
(defalias 'promises 'blessings)

(defun nicene-creed ()
  (interactive)
  (find-file (umn "$PEN/documents/Christianity/Nicene-Creed.txt")))

(defun commandments-of-Jesus ()
  (interactive)
  (find-file (umn "$PEN/documents/bible-notes/commandments-of-Jesus.org")))

(defun prophesies-fortelling-Jesus-fulfilled ()
  (interactive)
  (find-file (umn "$PEN/documents/bible/44-prophecies-of-Jesus-Christ-fulfilled.org")))

(defun devotional-for-today ()
  (interactive)
  ;; (sps (cmd "cvlc" "https://resources.vision.org.au/audio/thewordfortoday/20231213.mp3"))
  
  (sps (cmd "cvlc" "https://resources.vision.org.au/audio/thewordfortoday/" (date "%Y%m%d") ".mp3"))
  
  ;; (chrome "https://vision.org.au/the-word-for-today-reading/" t)
  )

(provide 'peniel)
