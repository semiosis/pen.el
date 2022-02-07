;; I suppose that `chann`, being the mantissa of chann.el is the unique name-or-names identifying Chann.el

;; ** TODO With Chann.el, I should be able to chat to a chatbot on IRC, and that chatbot should be able to control a terminal
;; - I could ask it to run some command for me, and it would have access to the terminal
;;   - This should be the first step
;; - Also, the actions it takes must be in response to what it sees on the terminal
;; - The chatbot should be able to relay information to me about the terminal
;; - The chatbot should be able to be given a task, such as responding to events, and execute that task
;;   - Therefore, I must be able
;;   - I need a prompt which interprets the task into a canonical format, and the runs a command loop
;;     - The task may be to continually monitor for a particular event and report back to me, or to run a command on the shell, or something
;; - Therefore, the chatbot needs
;;   - To see the chatroom
;;   - To see a terminal, running a TUI
;;   - To see a shell prompt

(defun channel-chatbot-from-name (name-or-names command &optional auto closeframe)
  "`name-or-names` is the name-or-names of the personalit(y|ies).
`command` is the terminal command the personality commands.
`auto`, if set to `t` will come up with the personality blurb without human interaction."
  (interactive (list (read-string-hist "personalit(y|ies): "
                                       "The March Hare, the Hatter and the Dormouse"
                                       nil
                                       "The March Hare, the Hatter and the Dormouse")
                     (fz '("madteaparty"
                           "bash"))))

  (if (and (not (pen-inside-docker))
           (not (pen-container-running)))
      (progn
        (pen-term-nsfa (pen-cmd "pen" "-n"))
        (message "Starting Pen server")))

  (if (not (sor name-or-names))
      (setq name-or-names "The March Hare, the Hatter and the Dormouse"))

  (if (not (sor command))
      (setq command (pen-cmd "madteaparty" name-or-names)))

  (let* ((blurb
          (if auto
              (car (pen-one (pf-generate-wiki-blurb-for-a-famous-person/1 name-or-names :no-select-result t)))
            (progn
              ;; Select from possible blurbs, then do a final human edit with a different emacs daemon
              (message "Final human edit of blurb")
              (pen-eipec
               (fz (pf-generate-wiki-blurb-for-a-famous-person/1 name-or-names :no-select-result nil)
                   nil nil "Select blurb:")))))
         (slug (slugify command nil 30))
         (bufname (concat "chann-" slug))
         ;; modename should give me
         ;; - a channel-term-mode,
         ;; - channel-term-mode-map, and
         ;; - channel-term-mode-hook
         (modename bufname)
         (buf
          ;; Do I want to run in a term? Or would I rather run this in a tmux split pane
          ;; I probably want to do both.
          (pen-term (pen-nsfa command) closeframe modename bufname t)))

    ;; If I want to spawn channel without an emacs term, then do it the following way.
    ;; Start a cterm with the channeled chatbot running as a program loop inside of that buffer
    ;; (let* ((el (pen-snc (pen-cmd "channel-repl" "-getcomintcmd" name-or-names "" blurb))))
    ;;   (pen-e-sps (pen-lm (pen-eval-string el))))
    ))

(defun channel-get-room ()
  (let* ((screen (buffer-string-visible)
                 ;; (pen-selected-or-preceding-context)
                 )
         (room (car (scrape-list "\\[#[a-z_-]+\\]" screen)))
         (room (pen-snc "sed 's/^mtp-//'" room)))
    room))

(defun channel-get-your-name ()
  (let* ((screen (buffer-string-visible)
                 ;; (pen-selected-or-preceding-context)
                 )
         (yourname (or
                    ;; MTP
                    (ignore-errors (s-replace-regexp "\\[\\(.*\\)(\\+i)\\]" "\\1" (car (scrape-list "\\[.*(\\+i)\\]" screen))))
                    ;; libera
                    (ignore-errors (pen-snc "grep -P -- \"[0-9]:libera/#\" | awk \"{print \\$2}\"" screen))
                    "you"))
         (yourname (pen-snc "tr -d '[!#:<>@ ]'" yourname))
         (yourname (pen-snc "sed 's/^mtp-//'" yourname)))
    yourname))

(defun channel-get-users ()
  (let* ((screen (buffer-string-visible))
         (conversation (pen-snc "sed \"/^[0-9]/s/^/\\n/g\" | sed -z \"s/\\n    \\+/ /g\" | sed '/^[^0-9]/d'" screen))
         (users-joined (pen-str2lines (pen-snc "sed -n '/-!-.*has joined/p' | cut -d ' ' -f 3 | tr -d '[[]@]'" (buffer-string-visible))))
         (users (s-split " " (pen-snc "sed -n '/Users/{n;n;p}' | grep '\\[' | sed 's/[^ ]* //' | tr -d '[[]@]' | sed 's/  / /g'" conversation)))
         (users-from-conversation (pen-str2lines (pen-snc "tr -d '[<>@ ]'" (scrape "<[ @][^>]*>" conversation))))
         ;; (yo (pen-tv (pps (-uniq (-sort #'string-lessp users-from-conversation)))))
         (total-users (-filter-not-empty-string
                                    (-uniq (-sort #'string-lessp (append
                                                                    users-joined
                                                                    users
                                                                    users-from-conversation))))))
    ;; (total-users (mapcar (lambda (s) (pen-snc "s/^mtp-//" s)) total-users)))
    total-users))

(defun channel-get-users-string ()
  (let* ((total-users (s-join ", " (channel-get-users)))
         (total-users (or (sor total-users) "all of them")))
    total-users))

;; For the moment I should preprocess IRC content to make it better
;; sed "/^[0-9]/s/^/\n/g" | sed -z "s/\n \+/ /g" | sed '/^[^0-9]/d'
(defun channel-get-conversation ()
  (let* ((screen (buffer-string-visible)
                 ;; (pen-selected-or-preceding-context)
                 )
         (conversation (pen-snc "sed \"/^[0-9]/s/^/\\n/g\" | sed -z \"s/\\n    \\+/ /g\" | sed '/^[^0-9]/d'" screen))
         (conversation (pen-snc "grep -v -- \"\\[\"" conversation))
         (conversation (pen-snc "grep -vP -- \"^$\"" conversation))
         (conversation (pen-snc "grep -v -- \"-\\!-\"" conversation))
         ;; channel info
         (conversation (pen-snc "grep -v -- \":::\"" conversation))
         ;; room line
         (conversation (pen-snc "grep -v -- \"/#\"" conversation))
         (conversation (pen-snc "sed 's/^<[@ ]\\(.*\\)>/\\1:/'" conversation))
         (conversation (pen-snc "sed 's/^[0-9].*<[@ ]//' | sed 's/> /: /'" conversation)))
    conversation))

(defun channel-get-conversation-from-others ()
  (pen-snc
   (pen-cmd "grep" "-vP" (concat "^" (channel-get-your-name) ":"))
   (channel-get-conversation)))

(defun channel-get-conversation-from-you ()
  (pen-snc
   (pen-cmd "grep" "-P" (concat "^" (channel-get-your-name) ":"))
   (channel-get-conversation)))

(defun channel-get-conversation-mentioning-you ()
  (pen-snc
   (concat (pen-cmd "grep" "-vP" (concat "^" (channel-get-your-name) ":"))
           " | "
           (pen-cmd "grep" "-P" (concat "\\b" (channel-get-your-name) "\\b")))
   (channel-get-conversation)))

;; (async-pf "pf-tweet-sentiment/1" (lambda (s) (pen-insert s)) "it's a great show")
;; (funcall (lambda (s) (pen-insert s)) "it's a great show")
;; (lambda (s) (pen-insert s))
;; (closure (t) (s) (pen-insert s))
;; (async-pf "pf-tweet-sentiment/1" (defun pen-insert-result (s) (pen-insert s)) "it's a great show")
;; (async-pf "pf-tweet-sentiment/1" (eval `(defun pen-insert-result (s) (with-current-buffer ,(current-buffer) (pen-insert s)))) "it's a great show")

;; (pen-tv (pen-sn (concat "sed '/^" (channel-get-your-name)/) (pen-sn "tac" (channel-get-conversation))))

;; I need to know how much time has passed since the last person spoke

(defun channel-last-speaker-was-you ()
  (re-match-p (concat "^" (channel-get-your-name)) (pen-snc "sed -n '$p'" (channel-get-conversation))))

(defun channel-get-conversors ()
  ;; (-uniq (pen-sn "cut -d : -f 1" (channel-get-conversation-from-others)))
  (-filter-not-empty-string (-uniq (pen-str2lines (pen-sn "cut -d : -f 1" (channel-get-conversation))))))

(defun channel-should-i-interject-p ()
  ;; The more often other people mention you, the more likely the bot should interject
  ;; The more you have spoken, the less likely you should speak again
  ;; The more users talking, the less likely you should speak again
  (let ((n-mentions (length (pen-str2lines (channel-get-conversation-mentioning-you))))
        (n-your-comments (length (pen-str2lines (channel-get-conversation-from-you))))
        ;; (n-users (length (pen-str2lines (channel-get-conversation-from-you))))
        (n-conversors (length (channel-get-conversors))))))

(defun channel-say-something (&optional b auto)
  (interactive)
  (let ((cb (or b (current-buffer))))
    (with-current-buffer cb
      (let* ((room (channel-get-room))
             (yourname (channel-get-your-name))
             (conversation (channel-get-conversation))
             (users (channel-get-users))
             (users-string (channel-get-users-string))
             ;; The more often other people mention you, the more likely the bot should interject
             ;; The more you have spoken, the less likely you should speak again
             (interjection-chance (= 1 (random (+ 10 (length users))))))

        ;; TODO The more users speaking, the less likely to interject

        (cond
         ((or (and (not (channel-last-speaker-was-you))
                   ;; The more users speaking the slower
                   (= 1 (random (+ 10 (length users)))))
              (or (not auto)))
          (async-pf "pf-say-something-on-irc/4"
                    (eval
                     `(lambda (result)
                        (with-current-buffer ,cb
                          (pen-insert result)
                          (if ,auto
                              (pen-insert "\n")))))
                    room users-string conversation yourname))
         ((or (not (channel-last-speaker-was-you))
              (= 1 (random 15))
              (or (not auto)))
          (async-pf "pf-say-something-on-irc/4"
                    (eval
                     `(lambda (result)
                        (with-current-buffer ,cb
                          (pen-insert result)
                          (if ,auto
                              (pen-insert "\n")))))
                    room users-string conversation yourname)))))))

(defun channel (personality)
  (interactive (list
                (fz (pen-list-fictional-characters channel-get-users-string)
                    nil nil "Person: ")
                ;; (read-string-hist "person: ")
                ))

  ;; TODO
  ;; - Initiate a Mad-TeaParty client
  ;; - Run a loop which gets the chatbot to speak
  )


;; TODO I have to make this even work
;; TODO I have to make this asynchronous with emacs async - This is a must
;; and also make use of the daemons.
;; TODO I have to make this bound to a certain buffer
;; I must ensure that for emacs daemons, they use their own stdout return file

(defset channel-timers '())

(defun buffer-killed? (buffer)
  "Return t if BUFFER is killed."
  (not (buffer-live-p buffer)))

;; TODO I must make a universal timer that is able to randomize the wait for specific chatbots
;; Therefore, the timer must run fairly frequently, and I may need to use a modulo or something to determine when chatbots speak

;; The timer for each chatbot should be chaotic - use prime numbers, say, but be a fraction - i should divide by some prime number

(defvar channel-init-time 2)
(defvar channel-read-time 15)

(defun channel-loop-chat ()
  (interactive)
  (let* ((n (channel-get-your-name))
         (b (current-buffer))
         ;; TODO Use an imaginary function to specify how many seconds is a good time to reply?
         ;; Or just make it randomish?
         ;; Do both
         (timer (assoc n channel-timers)))

    (if (sor n)
        (if timer
            (progn
              (message "Chatbot with that name already running")
              timer)
          (let ((newtimer (run-with-timer channel-init-time channel-read-time
                                          (eval
                                           `(lambda ()
                                              (if (buffer-killed? ,b)
                                                  (cancel-timer (cdr (assoc ,n channel-timers)))
                                                (with-current-buffer ,b
                                                  ;; (pen-insert "hello")
                                                  (channel-say-something ,b t))))))))
            (add-to-list 'channel-timers
                         `(,n . ,newtimer))))
      (error "Could not determine chatbot name from screen"))))

(provide 'pen-channel)