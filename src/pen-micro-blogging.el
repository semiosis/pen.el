(defun mb-learn-functions ()
  (interactive)
  (mu
   (let ((fp (pen-umn (fz (pen-mnm (list2str (glob "/home/shane/learn-functions/*/*.org")))
                      nil
                      nil
                      "learn-functions: "))))
     (if (file-exists-p fp)
         (e fp)))))

(defun mb-micro-summaries ()
  (interactive)
  (mu (enw (pen-lm (e "$HOME/micro-blogging/micro-summaries.org")))))

(defun mb-macro-summaries ()
  (interactive)
  (mu (enw (pen-lm (e "$HOME/micro-blogging/macro-summaries.org")))))

(defun mb-notes-on-topics ()
  (interactive)
  (mu (enw (pen-lm (e "$HOME/micro-blogging/notes-on-topics.org")))))

(defun mb-query-results ()
  (interactive)
  (mu (enw (pen-lm (e "$HOME/micro-blogging/query-results.org")))))

(defun open-micro-blogging ()
  (interactive)

  (let ((sel (qa
              -f "learn functions"
              -s "micro summaries"
              -m "macro summaries"
              -t "notes on topics"
              -q "query results")))
    (sw sel
        ("learn functions" (mb-learn-functions))
        ("micro summaries" (mb-micro-summaries))
        ("macro summaries" (mb-macro-summaries))
        ("notes on topics" (mb-notes-on-topics))
        ("query results" (mb-query-results)))))

(provide 'pen-micro-blogging)