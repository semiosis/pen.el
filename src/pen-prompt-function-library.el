;; sp +/"^- json: \"pen-str translate-to-english-1-json\"" "$PROMPTS/translate-to-english-1.prompt"
;; e:$PROMPTS/translate-to-english-1.prompt
(defun pen-show-translation (json)
  (interactive)
  (let ((ht (json-parse-string json)))
    (message (ht-get ht "original_language"))
    (pen-etv (ht-get ht "output"))

    ;; TODO Use pen-eipe
    ;; Use an overlay to display the original language
    ))

(provide 'pen-prompt-function-library)