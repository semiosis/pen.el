(require 'pen-personalities)

(defun pen-inside-docker ()
  (f-file-p "/.dockerenv"))

(defun pen-container-running ()
  (pen-snq (pen-cmd "pen" "-running-p")))

;; TODO Complete the apostrophe version of hhgttg
;; e:ihhgttg
(defun ihhgttg ()
  "`ihhgttg` stands for `Imaginary Hitchhiker's Guide To The Galaxy`"
  (interactive)
  (let* ((el (pen-snc (pen-cmd "apostrophe-repl" "-getcomintcmd" name "" blurb))))
    (pen-e-sps (pen-lm (pen-eval-string el)))))

(defun pen-list-fictional-characters (&optional including)
  (interactive)
  (if (sor including)
      (ilist 20 (concat "Fictional characters including " including))
    (ilist 20 "Fictional characters")))

(defun apostrophe-generate-blurb (person)
  ;; (pen-car (pf-generate-wiki-blurb-for-a-famous-person/1 ,name :no-select-result t))
  (eval `(pen-some (pf-generate-wiki-blurb-for-a-famous-person/1 ,person))))

(defun apostrophe-start-chatbot-from-name (name &optional auto)
  "A simple tit-for-tat conversation interface that prompts a language model for an interlocutor."
  (interactive (list
                (fz (pen-list-fictional-characters)
                    nil nil "Person: ")
                ;; (read-string-hist "person: ")
                ))

  (let ((apostrophe-engine
         (or (sor (pen-var-value-maybe 'force-engine)) "")))
    (if (and (not (pen-inside-docker))
             (not (pen-container-running)))
        (progn
          (pen-term-nsfa (pen-cmd "pen" "-n"))
          (message "Starting Pen server")))

    (if (not name)
        (setq name "Marco Polo"))

    (let* ((blurb
            (if auto
                (car
                 (eval
                  `(pen-engine
                    ,apostrophe-engine
                    (apostrophe-generate-blurb ,name)
                    ;; (pen-one (pf-generate-wiki-blurb-for-a-famous-person/1 ,name :no-select-result t))
                    )))
              ;; Select from possible blurbs, then do a final human edit with a different emacs daemon
              (pen-eipec
               (eval
                `(upd
                  (pen-engine
                   ,apostrophe-engine
                   (apostrophe-generate-blurb ,name)
                   ;; (pf-generate-wiki-blurb-for-a-famous-person/1 ,name :no-select-result nil)
                   )))
               nil nil nil nil "Edit the blurb then save and quit this file."))))

      (let* ((el (pen-snc (pen-cmd "apostrophe-repl" "-engine" apostrophe-engine "-getcomintcmd" name "" blurb))))
        (pen-e-sps (pen-lm (pen-eval-string el)))))))

(defun apostrophe-chat-about-selection (text)
  (interactive (list (str (pen-screen-or-selection))))

  (let ((apostrophe-engine
         (or (sor (pen-var-value-maybe 'force-engine)) "")))
    (if (and (not (pen-inside-docker))
             (not (pen-container-running)))
        (progn
          (pen-term-nsfa (pen-cmd "pen" "-n"))
          (message "Starting Pen server")))

    (if (not text)
        (setq text (str (pen-screen-or-selection))))

    (let* ((sme
            (eval
             `(pen-engine
               ,apostrophe-engine
               (pf-who-is-the-subject-matter-expert-for-/1 text))))
           (blurb
            (eval
             `(pen-engine
               ,apostrophe-engine
               (apostrophe-generate-blurb sme)
               ;; (pf-generate-wiki-blurb-for-a-famous-person/1 sme)
               ))))

      (let* ((el (pen-snc (pen-cmd "apostrophe-repl" "-engine" apostrophe-engine "-getcomintcmd" sme "" blurb))))
        (pen-e-sps (pen-lm (pen-eval-string el)))))))

(defun apostrophe-start-chatbot-from-selection (text)
  (interactive (list (str (pen-screen-or-selection))))

  (let ((apostrophe-engine
         (or (sor (pen-var-value-maybe 'force-engine)) "")))
    (if (and (not (pen-inside-docker))
             (not (pen-container-running)))
        (progn
          (pen-term-nsfa (pen-cmd "pen" "-n"))
          (message "Starting Pen server")))

    (if (not text)
        (setq text (str (pen-screen-or-selection))))

    (let* ((sme
            (eval
             `(pen-engine
               ,apostrophe-engine
               (pf-who-is-the-subject-matter-expert-for-/1 text))))
           (blurb
            (eval
             `(pen-engine
               ,apostrophe-engine
               (apostrophe-generate-blurb sme)
               ;; (pf-generate-wiki-blurb-for-a-famous-person/1 sme)
               ))))

      (let* ((el (pen-snc (pen-cmd "apostrophe-repl" "-engine" apostrophe-engine "-getcomintcmd" sme "" blurb))))
        (pen-e-sps (pen-lm (pen-eval-string el)))))))

(defun apostrophe-a-conversation-broke-out-here (text)
  (interactive (list (str (pen-selected-or-preceding-context))))

  (if (and (not (pen-inside-docker))
           (not (pen-container-running)))
      (progn
        (pen-term-nsfa (pen-cmd "pen" "-n"))
        (message "Starting Pen server")))

  (if (not text)
      (setq text (str (pen-screen-or-selection))))

  (let* ((el (pen-snc (pen-cmd "apostrophe-repl" "-getcomintcmd" "" "" text))))
    ;; TODO Run multiple daemons and run tasks from a pool?
    (pen-e-sps (pen-lm (pen-eval-string el)))))

(defun pen-list-incarnations-with-name (name)
  (interactive (list
                (fz (pen-list-personalities)
                    nil nil "Personality: ")))
  (let ((matching-incarnations
         (-filter 'identity
                  (loop for ik in (ht-keys pen-incarnations) collect
                        (if (string-equal
                             name
                             (ht-get (ht-get pen-incarnations ik) "personality-full-name-and-bio"))
                            ik
                          nil)))))
    (if (interactive-p)
        (pen-etv (pps matching-incarnations))
      matching-incarnations)))

(defun apostrophe-start-chatbot-from-personality (name &optional auto)
  "Spawn a new apostrophe session with a new incarnation."
  (interactive (list
                (fz (pen-list-personalities)
                    nil nil "Personality: ")))

  (let* ((incarnations (pen-list-incarnations-with-name name))
         (incarnation
          (if (and incarnations
                   (yes-or-no-p "Use existing?"))
              (fz incarnations nil nil "Incarnation: ")
            (pen-spawn-incarnation name))))

    (apostrophe-start-chatbot-from-incarnation incarnation)))

(defun apostrophe-start-chatbot-from-incarnation (name &optional auto)
  "Spawn a new apostrophe session from an existing incarnation."
  (interactive (list
                (fz (pen-list-incarnations)
                    nil nil "Incarnation: ")))

  (if (sor name)
      (let ((apostrophe-engine
             (or (sor (pen-var-value-maybe 'force-engine)) "")))
        (if (and (not (pen-inside-docker))
                 (not (pen-container-running)))
            (progn
              (pen-term-nsfa (pen-cmd "pen" "-n"))
              (message "Starting Pen server")))

        (let ((yaml (ht-get pen-incarnations name)))
          (let* ((blurb (ht-get yaml "description")))

            (let* ((el (pen-snc (pen-cmd "apostrophe-repl" "-engine" apostrophe-engine "-getcomintcmd" name "" blurb))))
              (pen-e-sps (pen-lm (pen-eval-string el)))))))))

(provide 'pen-apostrophe)
