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
  (let* ((el (pen-snc (pen-cmd "apostrophe-repl" "-getcomintcmd" name "" final-blurb))))
    (pen-e-sps (pen-lm (pen-eval-string el)))))

(defun pen-list-fictional-characters (&optional including)
  (interactive)
  (if (sor including)
      (ilist 20 (concat "Fictional characters including " including))
    (ilist 20 "Fictional characters")))

(defun apostrophe-generate-blurb (person)
  ;; (pen-car (pf-generate-wiki-blurb-for-a-famous-person/1 ,name :no-select-result t))
  (eval `(pen-some (pf-generate-wiki-blurb-for-a-famous-person/1 ,person))))

(defun car-maybe (e)
  (cond ((listp e)
         (car e))
        (t e)))

;; (apostrophe-start-chatbot-from-name "Harry Potter" nil "This is a conversation about how to get out of the room of requirement" "Hermione Granger")
(defun apostrophe-start-chatbot-from-name (their-name &optional auto blurb your-name)
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

    (if (not their-name)
        (setq their-name "Marco Polo"))

    (let* ((final-your-name (or your-name "you"))
           (final-blurb
            (or blurb
                (if auto
                    (car-maybe
                     (eval
                      `(pen-engine
                        ,apostrophe-engine
                        (apostrophe-generate-blurb ,their-name)
                        ;; (pen-one (pf-generate-wiki-blurb-for-a-famous-person/1 ,their-name :no-select-result t))
                        )))
                  ;; Select from possible blurbs, then do a final human edit with a different emacs worker
                  (pen-eipec
                   (eval
                    `(upd
                      (pen-engine
                       ,apostrophe-engine
                       (apostrophe-generate-blurb ,their-name)
                       ;; (pf-generate-wiki-blurb-for-a-famous-person/1 ,their-name :no-select-result nil)
                       )))
                   nil nil nil nil "Edit the final-blurb then save and quit this file.")))))

      (let* ((el (pen-snc (pen-cmd "apostrophe-repl" "-engine" apostrophe-engine "-your-name" final-your-name "-getcomintcmd" their-name "" final-blurb))))
        (pen-e-sps (pen-lm (pen-eval-string el)))))))

(defun apostrophe-chat-about-selection (text &optional expert blurb)
  (interactive (list (str (pen-screen-verbatim-or-selection))))

  (let ((apostrophe-engine
         (or (sor (pen-var-value-maybe 'force-engine)) "")))
    (if (and (not (pen-inside-docker))
             (not (pen-container-running)))
        (progn
          (pen-term-nsfa (pen-cmd "pen" "-n"))
          (message "Starting Pen server")))

    (if (not text)
        (setq text (str (pen-screen-verbatim-or-selection-ask))))

    (let* ((sme
            (or expert
                (eval
                 `(pen-engine
                   ,apostrophe-engine
                   (pf-who-is-the-subject-matter-expert-for-/1 text)))))
           (final-blurb
            (or blurb
                (eval
                 `(pen-engine
                   ,apostrophe-engine
                   (apostrophe-generate-blurb sme)
                   ;; (pf-generate-wiki-blurb-for-a-famous-person/1 sme)
                   ))))
           (final-blurb
            (if (not (and text (string-empty-p text)))
                (concat
                 final-blurb
                 ;; "<pen-newline>The topic of conversation is the following:<pen-newline>"
                 "\nThe topic of conversation is the following:\n"
                 text)))

           (final-blurb
            (if final-blurb
                (pen-encode-string final-blurb))))

      (let* ((el
              (if final-blurb
                  (pen-snc (pen-cmd "apostrophe-repl" "-engine" apostrophe-engine "-getcomintcmd" sme "" final-blurb))
                (pen-snc (pen-cmd "apostrophe-repl" "-engine" apostrophe-engine "-getcomintcmd" sme "")))))
        (pen-e-sps (pen-lm (pen-eval-string el)))))))

(defun apostrophe-start-chatbot-from-selection (text &optional expert final-blurb)
  (interactive (list (str (pen-screen-verbatim-or-selection))))

  (let ((apostrophe-engine
         (or (sor (pen-var-value-maybe 'force-engine)) "")))
    (if (and (not (pen-inside-docker))
             (not (pen-container-running)))
        (progn
          (pen-term-nsfa (pen-cmd "pen" "-n"))
          (message "Starting Pen server")))

    (if (not text)
        (setq text (str (pen-screen-verbatim-or-selection))))

    (let* ((sme
            (or expert
                (eval
                 `(pen-engine
                   ,apostrophe-engine
                   (pf-who-is-the-subject-matter-expert-for-/1 text)))))
           (final-blurb
            (or final-blurb
                (eval
                 `(pen-engine
                   ,apostrophe-engine
                   (apostrophe-generate-blurb sme)
                   ;; (pf-generate-wiki-blurb-for-a-famous-person/1 sme)
                   )))))

      (let* ((el (pen-snc (pen-cmd "apostrophe-repl" "-engine" apostrophe-engine "-getcomintcmd" sme "" final-blurb))))
        (pen-e-sps (pen-lm (pen-eval-string el)))))))

(defun apostrophe-a-conversation-broke-out-here (text)
  (interactive (list (str (pen-selected-or-preceding-context))))

  (if (and (not (pen-inside-docker))
           (not (pen-container-running)))
      (progn
        (pen-term-nsfa (pen-cmd "pen" "-n"))
        (message "Starting Pen server")))

  (if (not text)
      (setq text (str (pen-screen-verbatim-or-selection))))

  (let* ((el (pen-snc (pen-cmd "apostrophe-repl" "-getcomintcmd" "" "" text))))
    ;; TODO Run multiple workers and run tasks from a pool?
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
          (let* ((final-blurb (ht-get yaml "description")))

            (let* ((el (pen-snc (pen-cmd "apostrophe-repl" "-engine" apostrophe-engine "-getcomintcmd" name "" final-blurb))))
              (pen-e-sps (pen-lm (pen-eval-string el)))))))))

(defun guru (&optional a:text a:topic)
  (interactive)
  (let* ((text
          (or (sor a:text)
              (str (pen-screen-verbatim-or-selection t))))
         (topic
          (or (sor a:topic)
              (pen-read-string "Guru Topic:")
              ;; (pen-batch (pen-detect-language-ask))
              ))
         (topic (or (sor topic)
                    (and (sor text)
                         (pen-detect-language-lm-ask a:text))
                    "knowledge"))
         (sme-name (concat topic " guru")))
    (apostrophe-chat-about-selection
     text
     sme-name
     (concat sme-name " is an expert in " topic "."))))

(define-key global-map (kbd "H-U") 'guru)

(provide 'pen-apostrophe)
