(defun pen-mtp-connect-with-name (name)
  (interactive (list (read-string-hist "Chatbot name")))
  (pen-sps (cmd "mtp") name))

(provide 'pen-mad-teaparty)