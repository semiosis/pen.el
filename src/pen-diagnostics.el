(defun pen-diagnostics-test-key ()
  (interactive)
  (let ((output (concat "keytest: " (pen-onelineify (snc "OPENAI_API_KEY=\"$(cat ~/.pen/openai_api_key)\" pen-openai api completions.create -e davinci -t 0.8 -M 60 -n 1 --stop '###' -p \"Hello\"")))))
    (if (interactive-p)
        (etv output)
      output)))

(defun pen-diagnostics-test ()
  (let* ((plist)
         (testkey "yo" ;; (pen-diagnostics-test-key)
                  ))

    (plist-put plist :testkey testkey)
    (etv (plist2yaml plist))))

(provide 'pen-diagnostics)