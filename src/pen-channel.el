(defun channel-chatbot-from-name (name command &optional auto)
  "`name` is the name of the personality.
`command` is the terminal command the personality commands.
`auto`, if set to `t` will come up with the personality blurb without human interaction."
  (interactive (list (read-string-hist "person: ")))

  (if (and (not (pen-inside-docker))
           (not (pen-container-running)))
      (progn
        (pen-term-nsfa (pen-cmd "pen" "-n"))
        (message "Starting Pen server")))

  (if (not name)
      (setq name "Marco Polo"))

  (let* ((blurb
          (if auto
              (car (pen-one (pf-generate-wiki-blurb-for-a-famous-person/1 name :no-select-result t)))
            ;; TODO Then a final human edit with a different emacs daemon
            (fz (pf-generate-wiki-blurb-for-a-famous-person/1 name :no-select-result nil)))))

    (let* ((el (pen-snc (pen-cmd "channel-repl" "-getcomintcmd" name "" blurb))))
      (pen-e-sps (pen-lm (pen-eval-string el)))))

  (if auto
      (let* ((blurb (car (pen-one (pf-generate-wiki-blurb-for-a-famous-person/1 name :no-select-result t)))))

        (let* ((el (pen-snc (pen-cmd "channel-repl" "-getcomintcmd" name "" blurb))))
          (pen-e-sps (pen-lm (pen-eval-string el)))))
    (let* ((blurb (pf-generate-wiki-blurb-for-a-famous-person/1 name)))

      (let* ((el (pen-snc (pen-cmd "channel-repl" "-getcomintcmd" name "" blurb))))
        (pen-e-sps (pen-lm (pen-eval-string el)))))))

(provide 'pen-channel)