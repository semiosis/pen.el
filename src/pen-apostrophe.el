(defun apostrophe-start-chatbot-from-selection (text)
  (interactive (list (pen-screen-or-selection)))

(let* ((sme (pf-who-is-the-subject-matter-expert-for-/1 text))
       (blurb (pf-generate-wiki-blurb-for-a-famous-person/1 sme)))

  (let* ((el (pen-snc (pen-cmd "apostrophe" "-getcomintcmd" sme "" blurb))))
    ;; This locks when run inside of emacs.
    ;; I need to run multiple daemons and run tasks from a pool so this doesn't happen.
    (pen-e-sps (pen-lm (pen-eval-string el)))
    (never (sps (cmd "apostrophe" "" blurb))))))

(provide 'pen-apostrophe)