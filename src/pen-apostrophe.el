(defun apostrophe-start-chatbot-from-selection (text)
  (interactive (list (pen-screen-or-selection)))

  (if (not text)
      (setq text (pen-screen-or-selection)))

  (let* ((sme (pf-who-is-the-subject-matter-expert-for-/2 text))
         (blurb (pf-generate-wiki-blurb-for-a-famous-person/1 sme)))

    (never ((sme (eval `(upd (pf-who-is-the-subject-matter-expert-for-/1 ,text))))
            (blurb (eval `(upd (pf-generate-wiki-blurb-for-a-famous-person/1 ,sme))))))

    (let* ((el (pen-snc (pen-cmd "apostrophe" "-getcomintcmd" sme "" blurb))))
      ;; TODO Run multiple daemons and run tasks from a pool?
      (pen-e-sps (pen-lm (pen-eval-string el)))
      (never (sps (cmd "apostrophe" "" blurb))))))

(provide 'pen-apostrophe)