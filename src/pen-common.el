(defset pen-common-prompt-functions '(pf-quick-fix-code/1))

(defun pen-run-common-prompt-function ()
  (interactive)
  (let ((pf (fz pen-common-prompt-functions nil nil "Common prompt function: ")))
    (call-interactively 'pf)))

(defun pen-complete-inner ()
  (interactive)
  (let ((prefix (pen-preceding-text 2))
        (suffix (pen-proceeding-text 2)))

    (insert
     (pf-complete-inner-prose/2 prefix suffix))))

(provide 'pen-common)