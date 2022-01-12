(defun channel-start-chatbot-from-name (name &optional auto)
  (interactive (list (read-string-hist "person: ")))

  (if (and (not (pen-inside-docker))
           (not (pen-container-running)))
      (progn
        (pen-term-nsfa (pen-cmd "pen" "-n"))
        (message "Starting Pen server")))

  (if (not name)
      (setq name "Marco Polo"))

  (if auto
      (let* ((blurb (car (pen-one (pf-generate-wiki-blurb-for-a-famous-person/1 name :no-select-result t)))))

        (let* ((el (pen-snc (pen-cmd "channel-repl" "-getcomintcmd" name "" blurb))))
          (pen-e-sps (pen-lm (pen-eval-string el)))))
    (let* ((blurb (pf-generate-wiki-blurb-for-a-famous-person/1 name)))

      (let* ((el (pen-snc (pen-cmd "channel-repl" "-getcomintcmd" name "" blurb))))
        (pen-e-sps (pen-lm (pen-eval-string el)))))))

(provide 'pen-channel)