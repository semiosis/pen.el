(defun pen-go-to-prompt-function-definition (prompt-function-name-or-sym)
  (interactive (list (fz pen-prompt-functions nil nil "prompt function: ")))

  (if (sor prompt-function-name-or-sym)
      (let* ((prompt-fn (str prompt-function-name-or-sym))
             (prompt-fp)))
    (find-file (concat pen-prompts-directory))
    (wgrep (concat "\\b" pattern "\\b") (mu "$EMACSD/config")))))

(org-add-link-type "prompt" 'pen-go-to-prompt-function-definition)

(provide 'pen-links)