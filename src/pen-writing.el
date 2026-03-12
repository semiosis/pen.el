(define-derived-mode writing-mode text-mode "writing"
  "")

(defun org-latex-export-to-pdf-around-advice (proc &rest args)
  (pen-snc "check-maybe-misused-words" (buffer-string))
  (let ((res (apply proc args)))
    res))
(advice-add 'org-latex-export-to-pdf :around #'org-latex-export-to-pdf-around-advice)
;; (advice-remove 'org-latex-export-to-pdf #'org-latex-export-to-pdf-around-advice)

(provide 'pen-writing)
