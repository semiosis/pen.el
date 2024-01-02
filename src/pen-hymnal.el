;; Make it easy to
;; - search for a hymn,
;; - listen to it,
;; - print the sheet music
;; - read the lyrics / hymn / psalm
;; - read the sheet music

(defun sh/play-hymn ()
  (interactive)
  (sps "play-hymn"))

(defun sh/praise-Him-from-whom-all-blessings-flow ()
  (interactive)
  (sps (cmd "play-hymn" "Praise God From Whom All Blessings Flow-Old 100th")))

(defun sh/play-hymn-last ()
  (interactive)
  (sps (cmd "play-hymn" "-last")))

;; There should be a prefix such as H-u or something
;; which then triggers the transient to appear, which is the configuration
;; for this function, allowing me to set 'last'.

;; (play-hymn :last t)
;; (play-hymn :last t :norepeat t)

;; TODO Make transient advice for functions.
;; - advise a function
;;   - automatically create a transient for the function that appears with H-u.
;; (helpful--signature 'play-hymn)

(defun sh/last-hymn ()
  (interactive)
  (ifi-etv
   (snc "play-hymn -st -last")))

(defun getopts-to-cl-args (optstring)
  (interactive (list (read-string "opts string:")))
  (let* ((ntuple (s-split "=" optstring))
         (key (s-replace "^--" "" (first ntuple)))
         (val (second ntuple)))
    (ifietv
     key)))
;; e:q-cip
;; (cmd-cip "-5" 5 "hello" "=h")

(defun hymn-getopts-to-args ()
  (interactive)
  (etv
   (mapcar
    (lambda (a)
      (let* ((ntuple (s-split "=" a))
             (key (s-replace "^--" "" (first ntuple)))
             (val (second ntuple)))
        key))
    '("--last" "--norepeat=nil"))))

(defun play-hymn-with-transient ()
  (interactive)
  (let* ((fun-sym 'play-hymn)
         (sig (helpful--signature fun-sym)))

    ;; (play-hymn &key LAST_B NOREPEAT)
    (etv sig)

    ;; H-u
    (if (>= (prefix-numeric-value current-global-prefix-arg) 4)
        (progn (tdp transient-play-hymn ()
                 "play-hymn arguments"

                 :value '("--last" "--norepeat=nil")

                 ["play-hymn"
                  ("l" "last" "--last")
                  ("R" "norepeat" "--norepeat=")]
                 ["Commands"
                  ;; :transient t makes the transient stay up
                  ("RET" "Accept" (lambda ()
                                    (interactive)
                                    (etv
                                     (str (transient-args 'transient-play-hymn)))
                                    (let ((current-global-prefix-arg nil))
                                      (call-function 'play-hymn :last_b t))) :transient nil)])
               (transient-play-hymn))
      (let ((last_b)
            (norepeat))

        (play-hymn :last_b last_b :norepeat norepeat)))))

(cl-defun play-hymn (&key last_b norepeat)
  (interactive)
  (let* ((hymnal_dir "/volumes/home/shane/dump/programs/httrack/mirrors/http-openhymnal-org-/openhymnal.org")
         (pdf_dir (f-join hymnal_dir "Pdf"))
         (lyrics_dir (f-join hymnal_dir "Lyrics"))
         (mp3_dir (f-join hymnal_dir "Mp3"))
         (midi_dir (f-join hymnal_dir "Midi"))
         (hymn_titles_mant
          (--> (f-files mp3_dir)
               (mapcar 'f-basename it)
               (mapcar 'f-mant it)))
         (lyrics_files
          (mapcar (lambda (m) (f-join lyrics_dir (concat m ".html.txt"))) hymn_titles_mant))
         (lyrics_firstlines
          (mapcar (lambda (fp) (s-join " "
                                       (-take 2
                                              (-filter
                                               (lambda (s)
                                                 (string-match-p "^[0-9]+\\." s))
                                               (str2lines (e/cat fp)))))) lyrics_files))
         (hymn_titles_readable
          (mapcar (lambda (s) (s-replace-regexp "_" " " s)) hymn_titles_mant))
         (selected_hymn (or
                         (and last_b
                              (snc "play-hymn -st -last"))
                         (fz (-zip-lists hymn_titles_readable lyrics_firstlines) nil nil "Hymn: "))))
    (if (sor selected_hymn)
        (progn
          (write-to-file selected_hymn (umn "$TMPDIR/play-hymn_last_sel.txt"))
          (let* ((selected_hymn_mant (s-replace-regexp " " "_" selected_hymn))
                 (midi_fp (f-join midi_dir (concat selected_hymn_mant ".mid")))
                 (mp3_fp (f-join mp3_dir (concat selected_hymn_mant ".mp3")))
                 (pdf_fp (f-join pdf_dir (concat selected_hymn_mant ".pdf")))
                 (lyrics_fp (f-join lyrics_dir (concat selected_hymn_mant ".html.txt")))
                 (vlc_slug (cmd "cvlc" mp3_fp)))
            ;; (sps (cmd "timidity" midi_fp))
            (if norepeat
                (sps (cmd "cvlc" mp3_fp))
              (sps (cmd "rpt" "-ask" "cvlc" mp3_fp)))
            ;; (start-process-shell-command vlc_slug nil (cmd "cvlc" mp3_fp))
            (sn (cmd "z" pdf_fp) nil nil nil t)
            ;; (call-interactively 'list-processes)
            ;; (etv (cat lyrics_fp))
            )))))
(defalias 'sing-hymn 'play-hymn)

(define-key pen-map (kbd "H-N") 'play-hymn-with-transient)

(provide 'pen-hymnal)
