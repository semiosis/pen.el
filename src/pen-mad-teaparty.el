(defun pen-mtp-connect-with-name (name &optional pet)
  (interactive (list (fz (pen-list-fictional-characters)
                         nil nil "Person: ")))
  (if pet
      (pen-sps (pen-cmd "pet" "mtp" name))
    (pen-sps (pen-cmd "mtp" name))))

(defun pen-mtp-connect-with-name-using-pet (name)
  (interactive (list (fz (pen-list-fictional-characters)
                         nil nil "Person: ")))
  (pen-mtp-connect-with-name name t))

(provide 'pen-mad-teaparty)