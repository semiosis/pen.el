(defset pen-common-prompt-functions '(pf-quick-fix-code/1))

(defun pen-run-common-prompt-function ()
  (interactive)
  (let ((pf (fz pen-common-prompt-functions nil nil "Common prompt function: ")))
    (call-interactively 'pf)))


(defun pen-complete-inner (lines-context)
  (interactive "p")

  (tv lines-context)

  (if (pen-selected)
      (call-interactively 'kill-region))
  (let ((prefix (pen-preceding-lines 2))
        (suffix (pen-proceeding-lines 2)))

    (insert
     (if (pen-code-p)
         (pf-complete-inner-code/2 prefix suffix)
       (pf-complete--prose/2 prefix suffix)))))

(define-key pen-map (kbd "M-6") 'pen-complete-inner)

(provide 'pen-common)
