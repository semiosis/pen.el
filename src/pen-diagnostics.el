(defun pen-diagnostics-show-context ()
  (interactive)
  (let* ((plist (list
                 :semantic-path (get-path-semantic)
                 :last-final-command (snc "cat ~/.pen/last-final-command.txt")
                 :last-final-prompt (snc "cat ~/.pen/last-final-prompt.txt")
                 :pen-force-gpt-j-aix pen-force-gpt-j-aix
                 :pen-force-openai pen-force-openai)))
    (find-file (pen-tf "pen context" (plist2yaml plist) "yaml"))))

(defun pen-diagnostics-test-key ()
  (interactive)
  (let* ((aix-key (pen-snc "cat ~/.pen/aix_api_key"))
         (aix-cmd
          (concat
           (sh-construct-envs `(("AIX_API_KEY" ,aix-key)
                                ("PEN_PROMPT" "Once upon a time")
                                ("PEN_MAX_TOKENS" "60")
                                ("PEN_MODEL" "GPT-J-6B")
                                ("PEN_TOP_P" "1.0")
                                ("PEN_STOP_SEQUENCE" "###")))
           " "
           "pen-aix"))
         (output (concat
                  "openai keytest: "
                  (pen-onelineify
                   (pen-snc
                    "OPENAI_API_KEY=\"$(cat ~/.pen/openai_api_key)\" pen-openai api completions.create -e davinci -t 0.8 -M 10 -n 1 --stop '###' -p \"Hello\""))
                  "\n"
                  "aix keytest: "
                  (pen-onelineify (pen-snc aix-cmd)))))
    (if (interactive-p)
        (etv output)
      output)))

;; Use =cl= when dealing with plists in emacs
;; (cl-remf

(defun pen-diagnostics-test ()
  (interactive)
  (let* ((plist `(:testkey ,(pen-diagnostics-test-key))))

    ;; (plist-put plist :testkey (pen-diagnostics-test-key))

    ;; (etv (plist2yaml plist))
    (nbfs (plist2yaml plist) "pen diagnostics" 'yaml-mode)))

(provide 'pen-diagnostics)