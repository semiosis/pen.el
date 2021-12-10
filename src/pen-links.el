(defun pen-go-to-prompt-function-definition (prompt-function-name-or-sym)
  (interactive (list (fz pen-prompt-functions nil nil "prompt function: ")))

  (if (sor prompt-function-name-or-sym)
      (let* ((prompt-fn (s-replace-regexp "^\\(pf\\|pen-fn\\)-\\(.*\\)/\\([0-9]*\\)" "\\2-\\3.prompt" (str prompt-function-name-or-sym))))
        (find-file (etv (f-join pen-prompts-directory "prompts" prompt-fn))))))

(org-add-link-type "prompt" 'pen-go-to-prompt-function-definition)

(provide 'pen-links)