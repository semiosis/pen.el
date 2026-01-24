(defun select-bbs-server ()
  (interactive)
  (let* ((serverlist-string (pen-snc "list-bbs-servers"))
         (servernamelist (str2lines (pen-snc "cut -d , -f 1" serverlist-string)))
         (serveraddrlist (str2lines (pen-snc "cut -d , -f 2" serverlist-string)))
         (serverlist-tuples (-zip-lists servernamelist serveraddrlist))
         (sel (fz serverlist-tuples)))

    (if (not (s-blank-p sel))
        (let* ((index (-elem-index sel servernamelist))
               (serveradd (-nth index serveraddrlist)))

          ;; (pen-vterm (pen-nsfa (cmd "telnet" serveradd)))
          (nw (cmd "telnet" serveradd))))))

(provide 'pen-bbs)
