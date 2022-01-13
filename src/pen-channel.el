;; I suppose that `chann`, being the mantissa of chann.el is the unique name-or-names identifying Chann.el

(defun channel-chatbot-from-name (name-or-names command &optional auto)
  "`name-or-names` is the name-or-names of the personalit(y|ies).
`command` is the terminal command the personality commands.
`auto`, if set to `t` will come up with the personality blurb without human interaction."
  (interactive (list (read-string-hist "personalit(y|ies): ")))

  (if (and (not (pen-inside-docker))
           (not (pen-container-running)))
      (progn
        (pen-term-nsfa (pen-cmd "pen" "-n"))
        (message "Starting Pen server")))

  (if (not name-or-names)
      (setq name-or-names "The March Hare, the Hatter and the Dormouse"))

  (let* ((blurb
          (if auto
              (car (pen-one (pf-generate-wiki-blurb-for-a-famous-person/1 name-or-names :no-select-result t)))
            ;; Select from possible blurbs, then do a final human edit with a different emacs daemon
            (pen-eipec
             (fz (pf-generate-wiki-blurb-for-a-famous-person/1 name-or-names :no-select-result nil)))))
         (slug (slugify command nil 30))
         (bufname (concat "chann-" slug))
         (buf
          ;; Do I want to run in a term? Or would I rather run this in 
          (pen-term (pen-nsfa command) t bufname)))

    ;; TODO Start a cterm with the channeled chatbot running as a program loop inside of that buffer
    (let* ((el (pen-snc (pen-cmd "channel-repl" "-getcomintcmd" name-or-names "" blurb))))
      (pen-e-sps (pen-lm (pen-eval-string el))))))

(provide 'pen-channel)