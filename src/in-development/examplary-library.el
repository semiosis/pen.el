(defun examplary-asktutor (broader-topic specific-topic question)
  (interactive (list
                (read-string-hist (concat "(xlr) ask tutor about " (pen-topic t) ": "))
                (read-string-hist (concat "(xlr) ask tutor about " (pen-broader-topic t) ": "))))
  (pen-etv (eval
        `(ci (pen-snc "ttp" (pf-generic-tutor-for-any-topic/2 ,cname ,pname ,question))))))

(provide 'examplary-library)