(defun pen-diagnostics-test-key ()
  (interactive)
  (let ((output (snc "OPENAI_API_KEY=\"$(cat ~/.pen/openai_api_key)\" pen-openai api completions.create -e davinci -t 0.8 -M 60 -n 1 --stop '###' -p \"Hello\"")))
    (if (interactive-p)
        (etv (concat "key: " output))
      output)))

(defun pen-diagnostics-test ()

  )

(provide 'pen-diagnostics)