

(defun examplary-asktutor (broader-topic specific-topic question)
  (interactive (list
                (read-string-hist (concat "(xlr) ask tutor about " (pen-topic t) ": "))
                (read-string-hist (concat "(xlr) ask tutor about " (pen-broader-topic t) ": "))))
  (etv (eval
        `(ci (snc "ttp" (pen-pf-generic-tutor-for-any-topic ,cname ,pname ,question))))))

(provide 'examplary-libary)