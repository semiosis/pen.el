;; Need functions for listing music file types
(defvar music-extensions '(mp4 m4a webm mkv mp3))

(defun everynoise ()
  (interactive)
  (eww "https://everynoise.com/"))
(defalias 'random-music 'everynoise)

;; (syms2str music-extensions)
;; (list2str music-extensions)

(defun kill-music ()
  (interactive)
  (vuiet-stop)
  (pen-sn "kill-music")
  (pen-sn "killall vlc"))

(cl-defun play-video-path (fp &optional window-function external-cmd &key loop)
  (kill-music)
  (if (not window-function)
      (setq window-function 'sps))
  (if (not (sor external-cmd))
      (setq external-cmd "play-video"))
  (if loop
      (setq external-cmd (cmd "repeat.sh" external-cmd)))
  (shut-up
    (let ((use-tty-str (if use-tty "export USETTY=y; " "")))
      (eval `(,window-function (concat use-tty-str external-cmd " " (pen-q fp)) "-d")))))

(cl-defun play-youtube-url (url &optional window-function &key loop)
  (play-video-path url window-function "yt -v" :loop loop))

(cl-defun play-movie (path &optional term-and-transcript use-tty &key loop)
  (setq path (pen-umn path))
  (kill-music)
  (let ((use-tty-str (if use-tty "export USETTY=y; " ""))
        (play-function (if (string-match "\\bhttp" path)
                           'play-youtube-url
                         'play-video-path)))
    (if term-and-transcript
        (progn
          (eval `(,play-function path 'spv :loop ,loop))
          (sleep-for-for-for-for 0.1)
          (pen-sph (concat "readsubs " (pen-q path)) "-d"))
      (eval `(,play-function path))))
  nil)
(cl-defun pm (path &optional term-and-transcript &key loop)
  (play-movie path term-and-transcript t :loop t))
(defalias 'play-video 'play-movie)


(defun play-movie-with-transcript (path)
  (interactive (list (read-string-hist "youtube url: ")))
  (play-movie path t))
(defalias 'pmt 'play-movie-with-transcript)

(defun play-song (path &optional loop)
  (setq path (pen-umn path))

  (if loop
      (shut-up (eval `(bd play-song -l ,path)))
    (shut-up (eval `(bd play-song ,path))))
  nil)
(defalias 'ps 'play-song)

(defun play-playlist (path)
  (shut-up (eval ` (bd play-yt-playlist ,(e/q path))))
  nil)

(defun get-yt-playlist (path)
  (interactive (list (read-string "path:")))

  (if (string-empty-p path) (setq path "[[https://www.youtube.com/playlist?list=PLGYGe2PKknX2kydiv28aq8dBXBWeJfxgg][The Lion King 2019 soundtrack - YouTube]]"))

  (let ((result (e/chomp (pen-sn (concat "pen-ci yt-list-playlist-urls " (e/q path))))))
    (if (called-interactively-p 'any)
        (new-buffer-from-string result)
      result)))

(defun get-yt-playlist-json (path)
  (interactive (list (read-string "path:")))

  (if (string-empty-p path) (setq path "[[https://www.youtube.com/playlist?list=PLGYGe2PKknX2kydiv28aq8dBXBWeJfxgg][The Lion King 2019 soundtrack - YouTube]]"))

  (let ((result (e/chomp (pen-sn (concat "pen-ci yt-playlist-json " (e/q path))))))
    (if (called-interactively-p 'any)
        (new-buffer-from-string result)
      result)))

(defun org-clink-urls (ms)
  (interactive)

  (pen-sn "oc" ms))

(defalias 'oc 'org-clink-urls)

(defun lion-king-2019 ()
  (interactive)
  (play-playlist "[[https://www.youtube.com/playlist?list=PLGYGe2PKknX2kydiv28aq8dBXBWeJfxgg][The Lion King 2019 soundtrack - YouTube]]"))

(defun daft-punk-discovery ()
  (interactive)
  (play-playlist "[[https://www.youtube.com/playlist?list=OLAK5uy_lMA_iEf3aqk5YSDsnrPKojXegOiecSF94][Discovery - YouTube]]"))

(defun swordfish-ost ()
  (interactive)
  (play-playlist "[[https://www.youtube.com/playlist?list=OLAK5uy_mPdRDb_IJmG3DDeOlSwI5_rKKtAEZogys][Swordfish The Album (Original Motion Picture Soundtrack) - YouTube]]"))

;; (get-yt-playlist "[[https://www.youtube.com/playlist?list=OLAK5uy_mPdRDb_IJmG3DDeOlSwI5_rKKtAEZogys][Swordfish The Album (Original Motion Picture Soundtrack) - YouTube]]")

(defun brother-bear ()
  (interactive)
  (play-playlist "[[https://www.youtube.com/playlist?list=PLA8VHLKYzqTsKkpZ1SeJ1HmcGH6qHZTlt][Brother Bear OST - YouTube]]"))

(defun clubbed-to-death ()
  (interactive)
  (play-playlist "[[https://www.youtube.com/watch?v=pFS4zYWxzNA][clubbed to death - Matrix soundtrack - YouTube]]"))

(defun furious-angels ()
  (interactive)
  ;; (bld play-song "$DUMP$NOTES/ws/music/furious-angels/Rob Dougan - Furious Angels-jtAmFKaThNE.m4a")
  (bld play-song "[[https://www.youtube.com/watch?v=PJ8vJ2Qjuuc][Furious Angels - Rob Dougan - YouTube]]"))

(defun mus-epic1 ()
  (interactive)
  (bld play-song "[[https://www.youtube.com/watch?v=8oXo_QsxtDM][The Best of Epic Music August 2018 | Epic Powerful & Heroic Music Mix - YouTube]]"))

(defun ytsearch (query)
  (if (string-match-p "\\bhttps?:" query)
      (setq query (e/chomp (sh/xurls query)))
    (pen-cl-sn (concat "yt-search " (pen-q query)) :chomp t)))

(defun search-play-yt (query-or-url &optional audioonly)
  (interactive (list (read-string-hist "yt play-song: " (my/selected-text))))

  (kill-music)
  (if (string-match-p "\\bhttps?:" query-or-url)
      (setq query-or-url (e/chomp (sh/xurls query-or-url)))
    (setq query-or-url (ytsearch query-or-url)))

  (if audioonly
      (my/shut-up (pen-cl-sn (concat "play-song " (pen-q query-or-url)) :detach t :chomp t))
    (pen-sps (concat "yt -tty -v " (pen-q query-or-url)) "-d")))

(defalias 'yt 'search-play-yt)

(defun yta (query-or-url)
  (interactive (list (read-string-hist "yt play-song: ")))

  (yt query-or-url t))
(defalias 'ya 'yta)

(defun search-play-yt-transcript (query-or-url &optional lang)
  (interactive (list (read-string-hist "youtube query-or-url: " (my/selected-text))))

  (kill-music)
  (if (string-match-p "\\bhttps?:" query-or-url)
      (setq query-or-url (e/chomp (sh/xurls query-or-url)))
    (setq query-or-url (ytsearch query-or-url)))

  (if (not lang)
      (setq lang "en"))

  (pen-spv (concat "yt -tty -v " (pen-q query-or-url)) "-d")
  (sleep-for-for-for-for 0.1)
  (rst query-or-url))

(defalias 'ytt 'search-play-yt-transcript)

(defun ytt-fr (query)
  (interactive (list (read-string-hist "youtube query: ")))
  (ytt query "fr"))

(defun ytt-it (query)
  (interactive (list (read-string-hist "youtube query: ")))
  (ytt query "it"))

(defun readsubs (url &optional do-etv)
  (interactive (list (read-string-hist "yt query: ")))

  (if (string-match "^\\[\\[http" url)
      (setq url (e/chomp (pen-snc "xurls" url))))

  (if (and (not (string-match "^http" url))
           (sor url))
      (setq url (ytsearch url)))

  (setq do-etv
        (or
         do-etv
         (interactive-p)))

  (let ((transcript (pen-cl-sn (concat "unbuffer pen-ci readsubs " (pen-q url) " | cat") :chomp t)))
    (if do-etv
        (tvs transcript)
      transcript)))
(defalias 'rs 'readsubs)

(defun rst (url)
  (interactive (list (read-string-hist "yt query: ")))
  (tvs (readsubs url)))

(defun readsubs-fr (url)
  (interactive (read-string-hist "yt query: "))
  (pen-cl-sn (concat "unbuffer pen-ci readsubs.bak -l fr " (pen-q url) " | cat") :chomp t))

(defun mus-epic ()
  (interactive)
  "Search for epic music and play it."
  (search-play-yt "epic music"))

(defun elements-of-life ()
  (interactive)
  (play-song "[[https://www.youtube.com/watch?v=V9HKtPVms_Y][Tiesto elements of Life - YouTube]]"))

(defun prince-of-egypt-reprise ()
  (interactive)
  (play-song "https://www.youtube.com/watch?v=E1rEmAQJ7EQ&t=415"))

(defun neverending-story ()
  (interactive)
  (bld play-song "[[https://www.youtube.com/watch?v=heHdOTt_iGc&t][The Neverending Story (1984)  Soundtrack  - YouTube]]"))

(defun dark-knight-end-credits ()
  (interactive)
  (bld play-song "[[https://www.youtube.com/watch?v=fTr89ENLZPc][The Dark Knight - End Credits Music (HQ) - YouTube]]"))

(defun dark-knight-theme ()
  (interactive)
  (bld play-song "[[https://www.youtube.com/watch?v=w1B3Mgklfd0][Batman The Dark Knight Theme - Hans Zimmer - YouTube]]"))

(defun dark-knight-watchful-guardian ()
  "5 / 5"
  (interactive)
  (bld play-song "[[https://www.youtube.com/watch?v=buejiFXN7Hw][Hans Zimmer - A Watchful Guardian The Dark Knight - YouTube]]"))

(defun william-tell-overture ()
  (interactive)
  (bld play-song "[[https://www.youtube.com/watch?v=xoBE69wdSkQ][ROSSINI: William Tell Overture (full version) - YouTube]]"))
(defalias 'wto 'william-tell-overture)

(defun real-estate-its-real ()
  (interactive)
  (play-song "[[https://youtu.be/4HWcViTXdYc][Real Estate - Its Real (Official Video) - YouTube]]"))

(defun pen-media-test ()
  (interactive)
  (pm "[[https://www.youtube.com/watch?v=ZqZdfxc-fq0][Simpsons - Planet of the Apes, the musical - YouTube]]"))