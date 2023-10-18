(defun org-link-get-title (s)
  (--> s
       (s-replace-regexp ".*\\]\\[" "" it)
       (s-replace-regexp "\\]\\]$" "" it)))

(defun praise-edit-list ()
  (interactive)
  (find-file (umn "$PEN/documents/notes/ws/lists/peniel/praise-songs.txt")))

(defun praise ()
  ;; e:$HOME/.emacs.d/host/pen.el/scripts/praise
  (interactive)
  (let* ((fp "$PEN/documents/notes/ws/lists/peniel/praise-songs.txt")
         (contents_s (cat fp))
         (urls_s (xurls contents_s))
         (urls (str2lines urls_s))
         (ocs_s (pen-snc "oc" urls_s))
         (ocs (str2lines ocs_s))
         (titles (mapcar 'org-link-get-title ocs))
         (annoed_tps (-zip-lists urls titles))
         (sel (fz annoed_tps
                  nil nil "Praise song: ")))
    (if (test-n sel)
        (chrome sel nil nil t))))

(provide 'peniel)
