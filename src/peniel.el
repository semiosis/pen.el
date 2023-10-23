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
  (let* ((contents_s (pen-snc "ocif praise-list-songs"))
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

;; TODO Make this open up in bible-mode
;; j:bible-mode--open-search
;; j:bible-mode--display-search
(defun blessings ()
  (interactive)
  ;; (tpop "blessings")
  (nbfs (snc "ocif blessings -pp"))
  ;; (nbfs (snc "ocif show-promises"))
  )
(defalias 'promises 'blessings)

(provide 'peniel)
