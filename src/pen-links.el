(defun pen-go-to-prompt-function-definition (prompt-function-name-or-sym)
  (interactive (list (fz pen-prompt-functions nil nil "prompt function: ")))

  (let ((prompt-fp))
    (find-file )
    (wgrep (concat "\\b" pattern "\\b") (mu "$EMACSD/config"))))

(org-add-link-type "prompt" 'pen-go-to-prompt-function-definition)

(provide 'pen-links)