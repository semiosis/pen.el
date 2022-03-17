(defset pen-common-prompt-functions '(pf-quick-fix-code/1))

(defun pen-run-common-prompt-function ()
  (interactive)
  (let ((pf (fz pen-common-prompt-functions nil nil "Common prompt function: ")))
    (call-interactively 'pf)))

(defun pen-complete-inner ()
  (interactive)
  (let ((lines-context 2))

    (if (not (listp current-prefix-arg))
        (setq lines-context (prefix-numeric-value current-prefix-arg)))

    (if (pen-selected)
        (call-interactively 'kill-region))
    (let ((prefix (pen-preceding-lines lines-context))
          (suffix (pen-proceeding-lines lines-context)))

      (insert
       (if (pen-code-p)
           (pf-complete-inner-code/2 prefix suffix)
         (pf-complete--prose/2 prefix suffix))))))

(define-key pen-map (kbd "M-6") 'pen-complete-inner)

(provide 'pen-common)
