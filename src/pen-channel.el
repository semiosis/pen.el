(require 'alist)

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


;; TODO Automate the process for creating new users on libera
;; Do this for MTP.


;; TODO Make a separate prompt for spontaneous chat in some circumstances.
;; For example, to say something about their own life.


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
         (conversation (pen-snc "sed 's/^[0-9].*<[@ ]//' | sed 's/> /: /'" conversation))
         (conversation (pen-snc "grep -v -- \"\\*\"" conversation)))
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
  (let ((yourname (channel-get-your-name))
        (shortname (pen-snc "cut -d - -f 1" (channel-get-your-name))))
    (pen-snc
     (concat (pen-cmd "grep" "-vP" (concat "^" yourname ":"))
             " | "
             (pen-cmd "grep" "-iP" (concat "\\b(" yourname "|" shortname ")\\b")))
     (channel-get-conversation))))

;; (async-pf "pf-tweet-sentiment/1" (lambda (s) (pen-insert s)) "it's a great show")
;; (funcall (lambda (s) (pen-insert s)) "it's a great show")
;; (lambda (s) (pen-insert s))
;; (closure (t) (s) (pen-insert s))
;; (async-pf "pf-tweet-sentiment/1" (defun pen-insert-result (s) (pen-insert s)) "it's a great show")
;; (async-pf "pf-tweet-sentiment/1" (eval `(defun pen-insert-result (s) (with-current-buffer ,(current-buffer) (pen-insert s)))) "it's a great show")

;; (pen-tv (pen-sn (concat "sed '/^" (channel-get-your-name)/) (pen-sn "tac" (channel-get-conversation))))

;; I need to know how much time has passed since the last person spoke

(defun channel-nth-speaker-was-you (&optional n)
  (setq n (or n 1))
  (re-match-p (concat "^" (channel-get-your-name)) (pen-snc (concat "tac | sed -n '" (str n) "p'") (channel-get-conversation))))

(defun channel-last-speaker-was-you ()
  (channel-nth-speaker-was-you 1))

(defun channel-get-conversors ()
  ;; (-uniq (pen-sn "cut -d : -f 1" (channel-get-conversation-from-others)))
  (-filter-not-empty-string (-uniq (pen-str2lines (pen-sn "cut -d : -f 1" (channel-get-conversation))))))

(defset channel-base-probability 15)

(defset channel-chatter-amplifier 1)

(defvar channel-most-recent-mention '())

(defun channel-probability-of-speaking (&optional base-probability n-users n-mentions n-your-comments n-conversors lines-of-conversation last-speaker-p second-last-speaker-p third-last-speaker-p)
  ;; The more often other people mention you, the more likely the bot should interject
  ;; The more you have spoken, the less likely you should speak again
  ;; The more users talking, the less likely you should speak again

  (let* ((name (channel-get-your-name))
         (mentions (channel-get-conversation-mentioning-you))
         (most-recent-mention (pen-snc "sed -n '$p'" mentions))
         (old-most-recent-mention (cdr (assoc name channel-most-recent-mention)))
         (new-mention (not (string-equal old-most-recent-mention most-recent-mention))))

    (if new-mention
        (progn
          (remove-alist 'channel-most-recent-mention name)
          (add-to-list 'channel-most-recent-mention `(,name . ,most-recent-mention))))

    (setq base-probability (or base-probability channel-base-probability))
    (setq n-users (or n-users (length (channel-get-users))))
    (setq n-mentions (or n-mentions (length (pen-str2lines mentions))))
    (setq n-your-comments (or n-your-comments (length (pen-str2lines (channel-get-conversation-from-you)))))
    ;; (n-users (length (pen-str2lines (channel-get-conversation-from-you))))
    (setq n-conversors (or n-conversors (length (channel-get-conversors))))
    (setq lines-of-conversation (or lines-of-conversation (length (pen-str2lines (channel-get-conversation)))))

    (let ((p (max
              (/
               (- (+
                   ;; The following decrease probability:
                   channel-base-probability
                   ;; The number of users in the channel
                   (* 1 n-users)
                   ;; Then number of times you have visibly spoken
                   (* 1 n-your-comments)
                   ;; The number of conversors who have visibly spoken
                   (* 1 n-conversors)
                   (if (or last-speaker-p (ignore-errors (channel-last-speaker-was-you)))
                       10
                     0)
                   (if (or second-last-speaker-p (ignore-errors (channel-nth-speaker-was-you 2)))
                       5
                     0)
                   (if (or third-last-speaker-p (ignore-errors (channel-nth-speaker-was-you 3)))
                       1
                     0)
                   (max
                    (min
                     3
                     lines-of-conversation)
                    6))

                  ;; The following increase probability:
                  ;; - The number of times you have been mentioned
                  (* 4 n-mentions)
                  (if new-mention
                      15
                    0))
               channel-chatter-amplifier)
              channel-base-probability)))
      p)))

(defun channel-say-something (&optional real-cb b auto)
  (interactive)
  (let ((lrcb (or real-cb (current-buffer)))
        (cb (or b (current-buffer))))
    (with-current-buffer cb
      (let* ((room (channel-get-room))
             (yourname (channel-get-your-name))
             (conversation (channel-get-conversation))
             (users (channel-get-users))
             (users-string (channel-get-users-string))
             ;; The more often other people mention you, the more likely the bot should interject
             ;; The more you have spoken, the less likely you should speak again
             (interjection-chance (= 1 (random (+ channel-base-probability (length users))))))

        ;; TODO The more users speaking, the less likely to interject

        (let* ((p (channel-probability-of-speaking))
               (roll (random p)))
          ;; 1 and 2 both are successful rolls
          (if (or (< roll 4)
                  (not auto))
              (async-pf "pf-say-something-on-irc/4"
                        (eval
                         `(lambda (result)
                            (with-current-buffer ,cb
                              (pen-insert result)
                              (if ,auto
                                  (pen-insert "\n")))))
                        room users-string conversation yourname)
            (if (eq lrcb cb)
                (message (concat (str (time-to-seconds)) " Chance of " yourname " speaking: 1/" (str (channel-probability-of-speaking)) " result: " (str roll))))))))))

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

(defvar channel-timers '())



(defun buffer-killed? (buffer)
  "Return t if BUFFER is killed."
  (not (buffer-live-p buffer)))

;; TODO I must make a universal timer that is able to randomize the wait for specific chatbots
;; Therefore, the timer must run fairly frequently, and I may need to use a modulo or something to determine when chatbots speak

;; The timer for each chatbot should be chaotic - use prime numbers, say, but be a fraction - i should divide by some prime number

(defset channel-init-time 2)

;; Don't do this too often? - Definitely not. Too short a timer (i.e. 5) will kill the timer
;; Instead, rely on channel-chatter-amplifier
(defset channel-read-time 5)

(defun channel-cancel-all-timers ()
  (interactive)
  (loop for ti in channel-timers do
        (cancel-timer (cdr ti))
        (remove-alist 'channel-timers (car ti)))
  (message "Channel chatbots cancelled"))

(defun channel-activate-all-timers ()
  (loop for ti in channel-timers do
        (timer-activate-when-idle (cdr ti))))

(defun channel-loop-chat ()
  (interactive)
  (let* ((n (channel-get-your-name))
         (b (current-buffer))
         ;; TODO Use an imaginary function to specify how many seconds is a good time to reply?
         ;; Or just make it randomish?
         ;; Do both
         (timer (assoc n channel-timers)))

    (if (sor n)
        (progn
          (if timer
              (progn
                (cancel-timer (cdr timer))
                (remove-alist 'channel-timers n)
                (message "Restarting chatbot")))
          (progn
            (message "Starting chatbot")
            (let ((newtimer (run-with-timer channel-init-time channel-read-time
                                            (eval
                                             `(lambda ()
                                                ;; (channel-activate-all-timers)
                                                (ignore-errors
                                                  (if (buffer-killed? ,b)
                                                      (progn
                                                        (cancel-timer (cdr (assoc ,n channel-timers)))
                                                        (remove-alist 'channel-read-time ,n))
                                                    (let ((real-cb (current-buffer)))
                                                      (with-current-buffer ,b
                                                        ;; (pen-insert "hello")
                                                        (channel-say-something real-cb ,b t))))))))))
              (add-to-list 'channel-timers
                           `(,n . ,newtimer)))))
      (error "Could not determine chatbot name from screen"))))

(provide 'pen-channel)