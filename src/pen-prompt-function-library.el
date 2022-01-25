;; sp +/"^- json: \"pen-str translate-to-english-1-json\"" "$PROMPTS/translate-to-english-1.prompt"
;; e:$PROMPTS/translate-to-english-1.prompt
(defun pen-show-translation (json)
  (interactive)
  (let ((ht (json-parse-string json)))
    (message (ht-get ht "original_language"))
    (message (ht-get ht "output"))))

(provide 'pen-prompt-function-library)