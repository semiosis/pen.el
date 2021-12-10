(defun pen-go-to-prompt-function-definition (prompt-function-name-or-sym)
  (interactive (list (fz pen-prompt-functions nil nil "prompt function: ")))

  ;; I could, rather, consult the prompt function database
  (if (sor prompt-function-name-or-sym)
      (let* ((prompt-fn
              (->> (str prompt-function-name-or-sym)
                (s-replace-regexp "\\.prompt$" "")
                (s-replace-regexp "^\\(pf\\|pen-fn\\)-" "")
                (s-replace-regexp "/" "-")
                (string-replace "--" "-")
                (s-replace-regexp "$" ".prompt"))))
        (find-file (f-join pen-prompts-directory "prompts" prompt-fn)))))

(org-add-link-type "prompt" 'pen-go-to-prompt-function-definition)

(provide 'pen-links)