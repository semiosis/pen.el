(defun praise ()
  ;; e:$HOME/.emacs.d/host/pen.el/scripts/praise
  (interactive)
  (let* ((fp "$PEN/documents/notes/ws/lists/peniel/praise-songs.txt")
         (contents (cat fp))
         (urls (xurls contents))
         (ocs (pen-snc "org clink" contents))
         (str2lines contents)
         (annoed (mapcar (lambda (e) ) tps) ))
    (fz annoed
        nil nil "Praise song: ")))

(provide 'peniel)
