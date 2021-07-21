(defun pen-diagnostics-test-key ()
  (interactive)
  (let ((output (concat
                 "keytest: "
                 (pen-onelineify
                  (snc
                   "OPENAI_API_KEY=\"$(cat ~/.pen/openai_api_key)\" pen-openai api completions.create -e davinci -t 0.8 -M 60 -n 1 --stop '###' -p \"Hello\"")))))
    (if (interactive-p)
        (etv output)
      output)))

;; Use =cl= when dealing with plists in emacs
;; (cl-remf

(defun pen-diagnostics-test ()
  (interactive)
  (let* ((plist '(:testkey nil))
         (testkey "yo" ;; (pen-diagnostics-test-key)
                  ))

    (plist-put plist :testkey "hi")
    ;; (etv (plist2yaml plist))
    (etv (pps plist))))

(provide 'pen-diagnostics)