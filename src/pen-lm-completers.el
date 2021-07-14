(require 'pen-openai)

(defset pen-completion-backends
  ;; name completion command and a list of engines
  `(("OpenAI GPT-3" "openai-complete.sh" ,(pen-openai-list-engines))))

(provide 'pen-lm-completers)