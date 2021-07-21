(defun pen-diagnostics-test-key ()
  (interactive)
  (etv (snc "OPENAI_API_KEY=\"$(cat ~/.pen/openai_api_key)\" pen-openai api completions.create -e davinci -t 0.8 -M 60 -n 1 --stop '###' -p \"Hello\"")))

(provide 'pen-diagnostics)