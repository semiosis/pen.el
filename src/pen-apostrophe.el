(defun pen-inside-docker ()
  (f-file-p "/.dockerenv"))

(defun pen-container-running ()
  (pen-snq (cmd "pen" "-running-p")))

;; TODO Complete the apostrophe version of hhgttg
;; e:ihhgttg
(defun ihhgttg ()
  (interactive)
  (let* ((el (pen-snc (pen-cmd "apostrophe-repl" "-getcomintcmd" name "" blurb))))
    (pen-e-sps (pen-lm (pen-eval-string el)))))

(defun apostrophe-start-chatbot-from-name (name &optional auto)
  (interactive (list (read-string-hist "person: ")))

  (if (and (not (pen-inside-docker))
           (not (pen-container-running)))
      (progn
        (pen-term-nsfa (cmd "pen" "-n"))
        (message "Starting Pen server")))

  (if (not name)
      (setq name "Marco Polo"))

  (if auto
      (let* ((blurb (car (pen-one (pf-generate-wiki-blurb-for-a-famous-person/1 name :no-select-result t)))))

        (let* ((el (pen-snc (pen-cmd "apostrophe-repl" "-getcomintcmd" name "" blurb))))
          (pen-e-sps (pen-lm (pen-eval-string el)))))
    (let* ((blurb (pf-generate-wiki-blurb-for-a-famous-person/1 name)))

      (let* ((el (pen-snc (pen-cmd "apostrophe-repl" "-getcomintcmd" name "" blurb))))
        (pen-e-sps (pen-lm (pen-eval-string el)))))))

(defun apostrophe-start-chatbot-from-selection (text)
  (interactive (list (str (pen-screen-or-selection))))

  (if (and (not (pen-inside-docker))
           (not (pen-container-running)))
      (progn
        (pen-term-nsfa (cmd "pen" "-n"))
        (message "Starting Pen server")))

  (if (not text)
      (setq text (str (pen-screen-or-selection))))

  (let* ((sme (pf-who-is-the-subject-matter-expert-for-/1 text))
         (blurb (pf-generate-wiki-blurb-for-a-famous-person/1 sme)))

    (never ((sme (eval `(upd (pf-who-is-the-subject-matter-expert-for-/1 ,text))))
            (blurb (eval `(upd (pf-generate-wiki-blurb-for-a-famous-person/1 ,sme))))))

    (let* ((el (pen-snc (pen-cmd "apostrophe-repl" "-getcomintcmd" sme "" blurb))))
      ;; TODO Run multiple daemons and run tasks from a pool?
      (pen-e-sps (pen-lm (pen-eval-string el)))
      (never (sps (pen-cmd "apostrophe-repl" "" blurb))))))

(defun apostrophe-a-conversation-broke-out-here (text)
  (interactive (list (str (pen-selected-or-preceding-context))))

  (if (and (not (pen-inside-docker))
           (not (pen-container-running)))
      (progn
        (pen-term-nsfa (cmd "pen" "-n"))
        (message "Starting Pen server")))

  (if (not text)
      (setq text (str (pen-screen-or-selection))))

  (let* ((el (pen-snc (pen-cmd "apostrophe-repl" "-getcomintcmd" "" "" text))))
    ;; TODO Run multiple daemons and run tasks from a pool?
    (pen-e-sps (pen-lm (pen-eval-string el)))))

(provide 'pen-apostrophe)