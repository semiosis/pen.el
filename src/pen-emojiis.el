(defset pen-emoji-list
  `((":githubparrot:" "GitHub Parrot")
    ("😔" "Pensive Face")
    ("😯" "Hushed Face")
    ("🍓" "Strawberry")
    ("😐" "Neutral Face")
    ("😑" "Expressionless Face")
    ("🤨" "Face With Raised Eyebrow. Suspicious")
    ("🤦" "facepalm")
    ("👎" "thumbs down sign")
    ("👎" "thumbs down")
    ("🤔")
    ("🙄" "Face With Rolling Eye")
    ("🖖" "Vulcan salute")
    ("💫" "Dizzy")
    ("(◠‿◠✿)" "Happy")
    ("┏━┓┏━┓┏━┓ ︵ /(^.^/)" "Caterpiller")))

;; TODO Make my emacs use the OpenAI API for this
(defun pick-emoji ()
  (interactive)
  (let ((selection (fz ;; (mapcar 'second pen-emoji-list)
                    (mapcar 'tuple-swap
                            (cl-loop for tp in pen-emoji-list collect
                                     (list (first tp)
                                           (or (cadr tp)
                                               (first tp)))))
                    nil
                    nil
                    "Pick emoji: ")))
    (insert
     (first
      (first
       (-filter
        (lambda (x)
          (equal (cadr x) selection))
        pen-emoji-list))))))

;; (define-key global-map (kbd "H-V") 'pick-emoji)

(provide 'pen-emojiis)
