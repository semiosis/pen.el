(defun define-prompt-function ()
  (eval
   `(cl-defun ,func-sym ,(append '(&optional) var-syms '(&key no-select-result))
      ,doc
      (interactive ,(cons 'list iargs))
      ;; force-custom, unfortunately disables call-interactively
      ;; i guess that it could also disable other values
      (let ((is-interactive (interactive-p)))
        (pen-force-custom
         (cl-macrolet ((expand-template
                        (string-sym)
                        `(--> ,string-sym
                           (pen-onelineify it)
                           (pen-expand-template-keyvals it subprompts)
                           (pen-expand-template it vals)
                           (pen-expand-template-keyvals it var-keyvals-slugged)
                           (pen-expand-template-keyvals it var-keyvals)
                           (pen-unonelineify it))))
           (let* (
                  ;; Keep in mind this both updates memoization and the bash cache
                  (do-pen-update (pen-var-value-maybe 'do-pen-update))

                  (pen-sh-update (or
                                  (pen-var-value-maybe 'pen-sh-update)
                                  do-pen-update))

                  (cache
                   (and (not do-pen-update)
                        (pen-var-value-maybe 'cache)))

                  (final-is-info
                   (or (pen-var-value-maybe 'do-etv)
                       (pen-var-value-maybe 'is-info)
                       ,is-info))

                  (subprompts ,subprompts)

                  (subprompts
                   (if subprompts
                       (ht->alist (-reduce 'ht-merge (vector2list subprompts)))))

                  (final-prompt ,prompt)

                  (vals
                   ;; If not called interactively then
                   ;; manually run interactive expressions
                   ;; when they exist.
                   (mapcar 'str
                           (if (not ,interactive-p)
                               (progn
                                 (cl-loop
                                  for sym in ',var-syms
                                  for iarg in ',iargs
                                  collect
                                  (let* ((initval (eval sym)))
                                    (if (and (not initval)
                                             iarg)
                                        (eval iarg)
                                      initval))))
                             ;; Don't include &key pretty
                             (cl-loop for v in ',var-syms until (eq v '&key) collect (eval v)))))

                  ;; preprocess the values of the parameters
                  (vals
                   (cl-loop
                    for tp in
                    (-zip-fill nil vals ',preprocessors)
                    collect
                    (let* ((v (car tp))
                           (pp (cdr tp)))
                      (if pp
                          (pen-sn pp v)
                        v))))

                  (final-prompt (if ,repeater
                                    (if (< 0 (length vals))
                                        (concat (pen-awk1 final-prompt)
                                                (string-replace "{}" (str (car (last vals))) ,repeater))
                                      (concat (pen-awk1 final-prompt)
                                              ,repeater))
                                  final-prompt))

                  (var-keyvals (-zip ',vars vals))
                  (var-keyvals-slugged (-zip ',var-slugs vals))

                  ;; n-collate currently isn't template expanded
                  (final-n-collate
                   (or (pen-var-value-maybe 'n-collate)
                       ,n-collate))

                  (final-n-completions
                   (expand-template
                    (str (or (pen-var-value-maybe 'n-completions)
                             ,n-completions))))

                  ;; The max tokens may be templated in via variable or even a subprompt
                  (final-max-tokens
                   (expand-template
                    (str (or (pen-var-value-maybe 'max-tokens)
                             ,max-tokens))))

                  (final-temperature
                   (expand-template
                    (str (or (pen-var-value-maybe 'temperature)
                             ,temperature))))

                  (final-top-p
                   (expand-template
                    (str (or (pen-var-value-maybe 'top-p)
                             ,top-p))))

                  (final-stop-sequences
                   (cl-loop for stsq in (or (pen-var-value-maybe 'stop-sequences)
                                            ',stop-sequences)
                            collect
                            (expand-template stsq)))

                  (final-stop-patterns
                   (or (pen-var-value-maybe 'stop-patterns)
                       ',stop-patterns))

                  (final-stop-sequence
                   (expand-template
                    (str (or (pen-var-value-maybe 'stop-sequence)
                             ,stop-sequence))))

                  (final-prompt
                   (expand-template final-prompt))

                  (final-prompt
                   (pen-log-final-prompt
                    (if ,prompt-filter
                        (sor (pen-snc ,prompt-filter final-prompt)
                             (concat "prompt-filter " ,prompt-filter " failed."))
                      final-prompt)))

                  ;; This gives string position, not byte position
                  ;; (string-search "s" "ガムツリshane")
                  (prompt-end-pos (or (byte-string-search "<:pp>" ,prompt)
                                      ;; (length final-prompt)
                                      (string-bytes final-prompt)))

                  (final-prompt (string-replace "<:pp>" "" final-prompt))

                  ;; check for cache update
                  (pen-sh-update
                   (or pen-sh-update (>= (prefix-numeric-value current-global-prefix-arg) 4)))

                  ;; Now that all values are loaded, re-template them so I can base values on other values

                  ;; construct the full command
                  (shcmd
                   (pen-log
                    (s-join
                     " "
                     (list
;;; This actually interfered with the memoization!
                      ;; (let ((updval (pen-var-value-maybe 'do-pen-update)))
                      ;;   (if updval
                      ;;       (concat
                      ;;        "export "
                      ;;        (sh-construct-envs '(("UPDATE" "y")))
                      ;;        "; ")))

                      ;; All parameters are sent as environment variables
                      (sh-construct-envs
                       ;; This is a bit of a hack for \n in prompts
                       ;; See `pen-restore-chars`
                       `(("PEN_PROMPT" ,(pen-encode-string final-prompt))
                         ("PEN_LM_COMMAND" ,,lm-command)
                         ("PEN_ENGINE" ,,engine)
                         ("PEN_MAX_TOKENS" ,final-max-tokens)
                         ("PEN_TEMPERATURE" ,final-temperature)
                         ("PEN_STOP_SEQUENCE" ,final-stop-sequence)
                         ("PEN_TOP_P" ,final-top-p)
                         ("PEN_CACHE" ,cache)
                         ("PEN_N_COMPLETIONS" ,final-n-completions)
                         ("PEN_END_POS" ,prompt-end-pos)))
                      ;; Currently always updating
                      "lm-complete"))))

                  ;; run the completion command and collect the result
                  (resultsdirs
                   (cl-loop
                    for i in (number-sequence 1 final-n-collate)
                    collect
                    (progn
                      (message (concat ,func-name " query " (int-to-string i) "..."))
                      ;; TODO Also handle PEN_N_COMPLETIONS
                      (let ((ret (pen-prompt-snc shcmd i)))
                        (message (concat ,func-name " done " (int-to-string i)))
                        ret))))

                  (results
                   (-uniq
                    (flatten-once
                     (cl-loop for rd in resultsdirs
                              collect
                              (if (sor rd)
                                  (->> (glob (concat rd "/*"))
                                    (mapcar 'e/cat)
                                    (mapcar (lambda (r) (if (and ,postprocessor (sor ,postprocessor)) (pen-sn ,postprocessor r) r)))
                                    (mapcar (lambda (r) (if (and (variable-p 'prettify)
                                                                 prettify
                                                                 ,prettifier
                                                                 (sor ,prettifier))
                                                            (pen-sn ,prettifier r)
                                                          r)))
                                    (mapcar (lambda (r) (if (not ,no-trim-start) (s-trim-left r) r)))
                                    (mapcar (lambda (r) (if (not ,no-trim-end) (s-trim-right r) r)))
                                    (mapcar (lambda (r)
                                              (cl-loop
                                               for stsq in final-stop-sequences do
                                               (let ((matchpos (pen-string-search stsq r)))
                                                 (if matchpos
                                                     (setq r (s-truncate matchpos r "")))))
                                              r))
                                    (mapcar (lambda (r)
                                              (cl-loop
                                               for stpat in final-stop-patterns do
                                               (let ((matchpos (re-match-p stpat r)))
                                                 (if matchpos
                                                     (setq r (s-truncate matchpos r "")))))
                                              r)))
                                (list (message "Try UPDATE=y or debugging")))))))

                  (result (if no-select-result
                              (length results)
                            (cl-fz results :prompt (concat ,func-name ": ") :select-only-match t))))

             ;; (tv (pps final-stop-sequences))
             ;; (tv "Hi")
             (if no-select-result
                 results
               (if is-interactive
                   (cond
                    ((or final-is-info
                         (>= (prefix-numeric-value current-prefix-arg) 4))
                     (etv result))
                    ;; Filter takes priority over insertion
                    ((and ,filter
                          mark-active)
                     ;; (replace-region (concat (pen-selected-text) result))
                     (if (sor result)
                         (replace-region result)
                       (error "pen filter returned empty string")))
                    ;; Insertion is for prompts for which a new buffer is not necessary
                    ((or ,insertion
                         ,completion)
                     (insert result))
                    (t
                     (etv result)))
                 result))))))))
  func-sym)