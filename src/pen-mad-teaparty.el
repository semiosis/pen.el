(defun pen-run-after-time (secs &rest body)
  (eval
   `(run-with-timer ,secs nil (lambda () ,@body))))

(defun mtp-delay-start-chan ()
  (eval `(pen-run-after-time 3 '(with-current-buffer ,(current-buffer) (chan-loop-chat)))))

(defun pen-mtp-connect-with-name (name &optional pet start-chatbot)
  (interactive (list (fz (pen-list-fictional-characters (chan-get-users-string))
                         nil nil "Person: ")))
  (if pet
      (if start-chatbot
          (pen-nw (pen-cmd "pet" "-e" "(mtp-delay-start-chan)" "mtp" name) (concat "-n " (pen-q name)))
        (pen-nw (pen-cmd "pet" "mtp" name) (concat "-n " (pen-q name))))
    (pen-nw (pen-cmd "mtp" name) (concat "-n " (pen-q name)))))

(defun pen-mtp-connect-with-name-using-pet (name)
  (interactive (list (fz (pen-list-fictional-characters (chan-get-users-string))
                         nil nil "Person: ")))
  (pen-mtp-connect-with-name name t))

(defun pen-mtp-connect-with-name-using-pet-start-chatbot (name)
  (interactive (list (fz (pen-list-fictional-characters (chan-get-users-string))
                         nil nil "Person: ")))
  (pen-mtp-connect-with-name name t t))

(provide 'pen-mad-teaparty)