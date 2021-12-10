(defun pen-go-to-prompt-function-definition (prompt-function-name-or-sym)
  (interactive (list (fz pen-prompt-functions nil nil "prompt function: ")))

  (wgrep (concat "\\b" pattern "\\b") (mu "$EMACSD/config"))
  ;; (mu (sps (concat "cd $EMACSD/config; ead " (q pattern))))
  )
(org-add-link-type "prompt" 'pen-go-to-prompt-function-definition)

(provide 'pen-links)