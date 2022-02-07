(defun pen-mtp-connect-with-name (name &optional pet start-chatbot)
  (interactive (list (fz (pen-list-fictional-characters (channel-get-users-string))
                         nil nil "Person: ")))
  (if pet
      (if start-chatbot
          (pen-sps (pen-cmd "pet" "-e" "(channel-loop-chat)" "mtp" name))
        (pen-sps (pen-cmd "pet" "mtp" name)))
    (pen-sps (pen-cmd "mtp" name))))

(defun pen-mtp-connect-with-name-using-pet (name)
  (interactive (list (fz (pen-list-fictional-characters (channel-get-users-string))
                         nil nil "Person: ")))
  (pen-mtp-connect-with-name name t))

(defun pen-mtp-connect-with-name-using-pet-start-chatbot (name)
  (interactive (list (fz (pen-list-fictional-characters (channel-get-users-string))
                         nil nil "Person: ")))
  (pen-mtp-connect-with-name name t t))

(provide 'pen-mad-teaparty)