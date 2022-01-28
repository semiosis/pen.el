(defun pen-mtp-connect-with-name (name &optional pet)
  (interactive (list (read-string-hist "Chatbot name")))
  (if pet
      (pen-sps (pen-cmd "pet" "mtp" name))
    (pen-sps (pen-cmd "mtp" name))))

(defun pen-mtp-connect-with-name-using-pet (name)
  (interactive (list (read-string-hist "Chatbot name")))
  (pen-mtp-connect-with-name name t))

(provide 'pen-mad-teaparty)