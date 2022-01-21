(defun pen-mtp-connect-with-name (name)
  (interactive (list (read-string-hist "Chatbot name")))
  (pen-sps (pen-cmd "mtp" name)))

(provide 'pen-mad-teaparty)