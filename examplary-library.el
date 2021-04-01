(defun examplary-asktutor (broad-topic specific-topic question)
  (interactive (list (read-string-hist (concat "asktutor about " (pen-topic t) ": "))))
  (etv (eval
        `(ci (snc "ttp" (pen-pf-generic-tutor-for-any-topic ,cname ,pname ,question))))))

(provide 'examplary-libary)