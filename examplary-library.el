(defun org-brain-asktutor (question)
  (interactive (list (read-string-hist (concat "asktutor about " (pen-topic) ": "))))
  (let ((cname (org-brain-current-name))
        (pname (org-brain-parent-name)))

    (if (or (string-equal "infogetics" cname)
            (string-equal "fungible" cname))
        (setq cname "general knowledge"))

    (if (or (string-equal "infogetics" pname)
            (string-equal "fungible" pname))
        (setq pname cname))

    (etv (eval
          `(ci (snc "ttp" (pen-pf-generic-tutor-for-any-topic ,cname ,pname ,question)))))))

(provide 'examplary-libary)