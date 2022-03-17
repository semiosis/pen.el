(defset pen-common-prompt-functions '(pf-quick-fix-code/1))

(defun pen-run-common-prompt-function ()
  (interactive)
  (let ((pf (fz pen-common-prompt-functions nil nil "Common prompt function: ")))
    (call-interactively 'pf)))

(defun pen-complete-inner (lines-context)
  "Complete inner text by providing lines-later-context lines of surrounding context."
  (interactive (list 2))
  (if (not (listp current-prefix-arg))
      (setq lines-context (prefix-numeric-value current-prefix-arg)))

  (if (pen-selected)
      (call-interactively 'kill-region))
  (let ((prefix (pen-preceding-lines lines-context))
        (suffix (pen-proceeding-lines lines-context)))

    (insert
     (if (pen-code-p)
         (pf-complete-inner-code/2 prefix suffix)
       (pf-complete-inner-prose/2 prefix suffix)))))

(defun pen-complete-prefix (lines-later-context)
  "Complete preceding text by providing lines-later-context lines of latter context."  
  (interactive (list 2))

  (if (not (listp current-prefix-arg))
      (setq lines-later-context (prefix-numeric-value current-prefix-arg)))

  (if (pen-selected)
      (call-interactively 'kill-region))

  ;; Some prior context i.e. is a good idea to avoid getting 'once upon a time'
  (let ((prefix (pen-preceding-lines 1))
        (suffix (pen-proceeding-lines lines-later-context)))

    (insert
     (if (pen-code-p)
         (pf-complete-inner-code/2 prefix suffix)
       (pf-complete-inner-prose/2 prefix suffix)))))

(define-key pen-map (kbd "M-6") 'pen-complete-inner)
(define-key pen-map (kbd "M-_") 'pen-complete-inner)
(define-key pen-map (kbd "M-l M-{") 'pen-complete-prefix)

(provide 'pen-common)
