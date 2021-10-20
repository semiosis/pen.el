(defun pen-strip-unicode (s)
  (pen-snc "pen-c strip-unicode" s))

(defun pen-tmp-preview (slug)
  (pen-strip-unicode
   (pen-snc
    (pen-cmd
     "head" "-n" 5
     (f-join
      penconfdir
      "temp"
      (concat (slugify slug) ".txt"))))))

(defun pen-diagnostics-show-context ()
  (interactive)
  (if (and (sor penconfdir)
           (f-directory-p penconfdir))
      (let* ((plist (list
                     :semantic-path (get-path-semantic)
                     :last-final-command (pen-snc "cat ~/.pen/last-final-command.txt")
                     ;; strangely, some characters break plist2yaml plist
                     :last-final-prompt (pen-strip-unicode (pen-snc "cat ~/.pen/last-final-prompt.txt"))
                     :last-pen-command-exprs (pen-snc "cat ~/.pen/last-pen-command-exprs.txt")
                     :last-pen-command (pen-snc "cat ~/.pen/last-pen-command.txt")
                     :pen-force-engine pen-force-engine
                     :lm-complete-stderr (pen-tmp-preview "lm-complete-stderr")
                     :lm-complete-stdout (pen-tmp-preview "lm-complete-stdout")
                     :lm-complete-results
                     (pen-snc
                      (concat
                       "find "
                       (pen-q (pen-snc (pen-cmd "cat" (f-join penconfdir "temp" "lm-complete-stdout.txt"))))
                       " | while read line; do cat \$line; echo; done"))
                     :openai-last-output (pen-tmp-preview "openai-temp")
                     :openai-last-output-fp (f-join penconfdir "temp" "openai-temp.txt")
                     :hf-last-output (pen-tmp-preview "hf-temp")
                     :hf-last-output-fp (f-join penconfdir "temp" "hf-temp.txt")
                     :nlpcloud-last-output (pen-tmp-preview "nlpcloud-temp")
                     :nlpcloud-last-output-fp (f-join penconfdir "temp" "nlpcloud-temp.txt")
                     :aix-last-output (pen-tmp-preview "aix-temp")
                     :aix-last-output-fp (f-join penconfdir "temp" "aix-temp.txt")
                     :ruby-gen-next-user-prompt (f-join penconfdir "temp" "ruby-gen-next-user-prompt.txt")
                     ;; This is usually so long it causes problems
                     ;; :ai21-last-output (pen-snc (pen-cmd "cat" "/tmp/ai21-temp.txt"))
                     )))
        (find-file (pen-tf "pen context" (plist2yaml plist) "yaml")))))

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
        (pen-etv output)
      output)))

;; Use =cl= when dealing with plists in emacs
;; (cl-remf

(defun pen-diagnostics-test ()
  (interactive)
  (let* ((plist `(:testkey ,(pen-diagnostics-test-key))))

    ;; (plist-put plist :testkey (pen-diagnostics-test-key))

    ;; (pen-etv (plist2yaml plist))
    (nbfs (plist2yaml plist) "pen diagnostics" 'yaml-mode)))

(provide 'pen-diagnostics)