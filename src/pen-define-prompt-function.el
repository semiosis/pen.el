(defmacro pen-split-macro-test-inner ()
  `(progn
     (etv ,testval)))

(defun pen-split-macro-test-define-fun ()
  (eval
   `(defun split-macro-test-fun ()
      ,(expand-macro `(pen-split-macro-test-inner)))))

(defun pen-split-macro-test ()
  (let ((testval "shane"))
    (pen-split-macro-test-define-fun))
  (split-macro-test-fun))

;; (comment (pen-split-macro-test))

(defmacro pen-define-prompt-function-pipeline ()
    `(let* (;; Keep in mind this both updates memoization and the bash cache

           ;; the differences has been confused. Treat as the same
           (do-pen-update
            (or
             ;; H-u -- this doesn't work with some interactive functions, such as (interactive (list (read-string "kjlfdskf")))
             (>= (prefix-numeric-value current-global-prefix-arg) 4)
             ;; C-u 0
             (= (prefix-numeric-value current-prefix-arg) 0)
             (pen-var-value-maybe 'do-pen-update)))

           (pen-sh-update
            (or
             (>= (prefix-numeric-value current-global-prefix-arg) 4)
             ;; C-u 0
             (= (prefix-numeric-value current-prefix-arg) 0)
             (pen-var-value-maybe 'pen-sh-update)
             do-pen-update))

           (cache
            (and (not do-pen-update)
                 (pen-var-value-maybe 'cache)))

           (final-path
            (let ((fpath
                   (or (pen-var-value-maybe 'path)
                       ,path)))
              (setq pen-last-prompt-data
                    (asoc-merge pen-last-prompt-data (list (cons "PEN_PROMPT_PATH" fpath))))
              fpath))

           ;; TODO Consider overriding model, temperature and lm-command again
           ;; based on this value
           ;; Currently, this is inert.
           (final-engine
            ;; (expand-template
            ;;  (str (or
            ;;        ,force-engine
            ;;        pen-force-engine
            ;;        (pen-var-value-maybe 'engine)
            ;;        ,engine)))
            (str (or
                  (and
                   (not pen-prompt-force-engine-disabled)
                   (sor ,force-engine))
                  pen-force-engine
                  (pen-var-value-maybe 'engine)
                  ,engine)))

           (final-temperature)
           (final-lm-command)
           (final-model)

           (final-api-endpoint
            (or (pen-var-value-maybe 'api-endpoint)
                ,api-endpoint))

           ;; Actually, only override model, temperature and lm-command again if force-engine is set.
           ;; And with final-force-engine, only override final-model, final-temperature and final-lm-command.
           ;; Don't override final-'force'-model, etc.
           (final-engine
            (let* ((engine (ht-get pen-engines final-engine))
                   (keys (mapcar 'intern (mapcar 'slugify (ht-keys engine))))
                   (vals (ht-values engine))
                   (tups (-zip-lists keys vals))
                   (al (pen-list2alist tups))
                   (temp (cdr (assoc 'default-temperature al)))
                   (model (cdr (assoc 'model al)))
                   (lm-command (cdr (assoc 'lm-command al)))
                   (api-endpoint (cdr (assoc 'api-endpoint al))))
              ;; (if temp
              ;;     (setq final-temperature temp))
              (if model
                  (setq final-model model))
              (if lm-command
                  (setq final-lm-command lm-command))
              (if api-endpoint
                  (setq final-api-endpoint api-endpoint))
              final-engine))

           (final-flags
            (or (pen-var-value-maybe 'flags)
                ,flags))

           (final-cant-n-complete
            (or (pen-var-value-maybe 'cant-n-complete)
                ,cant-n-complete))

           (final-evaluator
            (or (pen-var-value-maybe 'evaluator)
                ,evaluator))

           (final-variadic-var
            (or (pen-var-value-maybe 'variadic-var)
                ,variadic-var))

           (final-delimiter
            (or (pen-var-value-maybe 'delimiter)
                ,delimiter
                final-engine-delimiter))

           (final-flags
            (if final-flags
                ;; If this is broken then stuff it
                (ignore-errors
                  (mapconcat
                   (lambda (s) (concat "<" s ">"))
                   (-filter
                    'identity
                    (pen-vector2list final-flags))
                   " "))))

           ;; hover, info and new-document are related
           (final-info
            (progn
              (comment
               (pen-log (concat "(pen-var-value-maybe 'do-etv) " (str (pen-var-value-maybe 'do-etv))))
               (pen-log (concat "(pen-var-value-maybe 'info) " (str (pen-var-value-maybe 'info))))
               (pen-log (concat "',info " (str ',info)))
               (pen-log (concat "(not (pen-var-value-maybe 'no-info)) " (str (not (pen-var-value-maybe 'no-info))))))
              (and (or (pen-var-value-maybe 'do-etv)
                       (pen-var-value-maybe 'info)
                       ',info)
                   (not (pen-var-value-maybe 'no-info)))))

           (final-new-document
            (and (or (pen-var-value-maybe 'do-etv)
                     (pen-var-value-maybe 'new-document)
                     ',new-document)
                 (not (pen-var-value-maybe 'no-new-document))))

           (final-utilises-code
            (and (or (pen-var-value-maybe 'utilises-code)
                     ',utilises-code)
                 (not
                  (or (pen-var-value-maybe 'utilises-code-off)
                      ',utilises-code-off))))

           (final-prepend-previous
            (or (pen-var-value-maybe 'prepend-previous)
                ',prepend-previous))

           (final-hover
            (or (pen-var-value-maybe 'hover)
                ',hover))

           (final-linter
            (or (pen-var-value-maybe 'linter)
                ',linter))

           (final-formatter
            (or (pen-var-value-maybe 'formatter)
                ',formatter))

           (final-action
            (or (pen-var-value-maybe 'action)
                ',action))

           (final-collation-temperature-stepper
            (or (pen-var-value-maybe 'collation-temperature-stepper)
                ,collation-temperature-stepper))

           (final-engine-whitespace-support
            (or
             (pen-var-value-maybe 'engine-whitespace-support)
             ,engine-whitespace-support))

           (final-prompt-hist-id
            (let ((phi
                   (or (pen-var-value-maybe 'pen-prompt-hist-id)
                       (pen-var-value-maybe 'prompt-hist-id))))
              (if phi
                  (setq phi (slugify phi)))
              phi))

           (final-include-prompt
            (or (pen-var-value-maybe 'pen-include-prompt)
                (pen-var-value-maybe 'include-prompt)
                ,include-prompt))

           (final-no-gen
            (or (pen-var-value-maybe 'pen-no-gen)
                (pen-var-value-maybe 'no-gen)
                ,no-gen))

           (final-train-function
            (or (pen-var-value-maybe 'pen-train-function)))

           (final-force-results
            (or (pen-var-value-maybe 'pen-force-results)))

           (final-results-analyser
            (or (pen-var-value-maybe 'results-analyser)
                ,results-analyser))

           (final-analyse
            (and
             final-results-analyser
             (pen-var-value-maybe 'analyse)))

           (final-interpreter
            (or (pen-var-value-maybe 'interpreter)
                ,interpreter))

           (final-no-uniq-results
            (or (pen-var-value-maybe 'no-uniq-results)
                ,no-uniq-results))

           (final-expand-jinja
            (or (pen-var-value-maybe 'expand-jinja)
                ,expand-jinja))

           (final-start-yas
            (or (pen-var-value-maybe 'start-yas)
                ,start-yas))

           (final-end-yas
            (or (pen-var-value-maybe 'yas)
                (pen-var-value-maybe 'end-yas)
                ,yas
                ,end-yas))

           (final-var-defaults
            (or (pen-var-value-maybe 'var-defaults)
                ',var-defaults))

           (final-subprompts
            (or (pen-var-value-maybe 'subprompts)
                ,subprompts))

           (final-defs
            (or (pen-var-value-maybe 'defs)
                ',defs))

           (final-envs
            (pen--htlist-to-alist
             (or (pen-var-value-maybe 'envs)
                 ',envs)))

           ;; Pipelines are just some named shell pipelines that a specific to a prompt
           ;; that come with the prompt.
           (final-pipelines
            (or (pen-var-value-maybe 'pipelines)
                ',pipelines))

           (final-expressions
            (or (pen-var-value-maybe 'expressions)
                ',expressions))

           ;; pipelines are available to expressions as <pipeline> expressions
           ;; pipelines are also available the 'expand-template' in this way <pipeline:var>
           ;; Expressions may be used inside various prompt parameters, such as max-tokens
           (final-expressions
            (if final-expressions
                (mapcar (lambda (pp)
                          (pen-expand-template-keyvals
                           pp
                           final-pipelines
                           nil
                           final-pipelines))
                        final-expressions)
              final-expressions))

           (final-preprocessors
            (or (pen-var-value-maybe 'preprocessors)
                ',preprocessors))

           (final-preprocessors
            (if final-preprocessors
                (mapcar (lambda (pp) (pen-expand-template-keyvals pp final-pipelines nil final-pipelines)) final-preprocessors)
              final-preprocessors))

           (final-subprompts-al
            (if final-subprompts
                (ht->alist (-reduce 'ht-merge (pen-vector2list final-subprompts)))))

           (final-force-prompt
            (or
             override-prompt
             (pen-var-value-maybe 'force-prompt)
             ,force-prompt))

           (final-prompt
            (or
             final-force-prompt
             ,prompt))

           (final-prompt (if final-start-yas
                             (pen-yas-expand-string final-prompt)
                           final-prompt))

           (final-defs
            (cl-loop
             for atp in final-defs
             collect
             (cons
              (car atp)
              (eval
               `(pen-let-keyvals
                 ',final-subprompts-al
                 (eval-string ,(str (cdr atp))))))))

           (final-envs
            ;; Filter is needed because of ignore-errors
            (-filter
             'identity
             (cl-loop
              for atp in final-envs
              collect
              ;; This required an ignore-errors
              ;; To fix eww.
              ;; Some image urls would kill lg-generate-alttext.
              ;; A bad last-final-command is formed
              (ignore-errors
                (cons
                 (car atp)
                 (let ((val (eval
                             `(pen-let-keyvals
                               ',final-subprompts-al
                               (eval-string ,(str (cdr atp)))))))
                   (cond
                    ((and (booleanp val)
                          val)
                     "y")
                    (t (str val)))))))))

           (vals
            ;; If not called interactively then
            ;; manually run interactive expressions
            ;; when they exist.
            (mapcar 'str
                    (if (not is-interactive)
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

           (last-vals-exprs vals)

           (vals
            (cl-loop
             for tp in (-zip-fill nil vals final-var-defaults)
             collect
             (if (and (not (sor (car tp)))
                      (sor (cdr tp)))
                 ;; TODO if a val is empty, apply the default with the subprompts in scope
                 (let ((func-name ,func-name))
                   (eval
                    `(pen-let-keyvals
                      ',final-subprompts-al
                      (eval-string ,(str (cdr tp))))))
               (car tp))))

           (last-vals vals)

           (final-preprocessors
            ;; Unfortunately, can't do full template expansion here because we don't have vals. final-preprocessors is needed for vals 
            (cl-loop for fpp in final-preprocessors collect
                     (if fpp
                         (--> fpp
                           (pen-expand-template-keyvals it (-zip-fill "" ',vars vals))
                           (pen-expand-template-keyvals it (-zip-fill "" ',var-slugs vals))))))

           ;; preprocess the values of the parameters
           (vals
            (cl-loop
             for tp in
             (-zip-fill nil vals final-preprocessors)
             collect
             (let* ((v (car tp))
                    (pp (cdr tp)))
               (if (sor final-delimiter)
                   (let ((sedcmd
                          (if (re-match-p "\n" final-delimiter)
                              ;; Just avoid this safety measure,
                              ;; if the delim contains a newline,
                              ;; because escaping \n will cause problems
                              "cat"
                            (concat
                             "sed 's/" final-delimiter "/"
                             (pen-snc "sed 's=.=\\\\\\\\&=g'" final-delimiter)
                             "/'"))))
                     (if (sor pp)
                         (setq pp (concat sedcmd " | " pp))
                       (setq pp sedcmd))))
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

           ;; When it comes to adding consistency, I must add consistency based on partial functions.
           ;; Otherwise, there'd be a single history/training which is prepended to all ifuntions.
           ;; OK, so how do we specify that?
           ;; I must specify 'constraint variables' for training .
           ;; When idefun is defined, specify a =prompt-hist-id=

           ;; The following needs
           (parameter-slug
            (s-join "."
                    (mapcar (lambda (kv)
                              (let* ((k (car kv))
                                     (v (cdr kv))
                                     (kslug (slugify (s-left 10 k)))
                                     (vslug (slugify (s-left 10 v)))
                                     (khash (s-left 10 (sha1 k)))
                                     (vhash (s-left 10 (sha1 v)))
                                     (kslug (concat kslug "-" khash))
                                     (vslug (concat vslug "-" vhash)))
                                (concat kslug "_" vslug)))
                            var-keyvals-slugged)))

           ;; n-collate currently isn't template expanded
           (final-n-collate
            (or (pen-var-value-maybe 'n-collate)
                ,n-collate))

           (final-n-max-collate
            (or (pen-var-value-maybe 'n-max-collate)
                ,n-max-collate))

           (final-n-target
            (or (pen-var-value-maybe 'n-target)
                ,n-target))

           ;; (final-pretext
           ;;  (expand-template pretext))

           (final-interactive-inject
            (or (pen-var-value-maybe 'pen-interactive-inject)
                (pen-var-value-maybe 'interactive-inject)
                ',interactive-inject))

           (final-inject-example
            (expand-template ,inject-example))

           (final-continue-default
            (or (pen-var-value-maybe 'pen-continue-default)
                (pen-var-value-maybe 'continue-default)
                override-prompt
                ,continue-default))

           (final-inject-examples
            (cl-loop for e in ',inject-examples collect
                     (expand-template e)))

           (final-inject-gen-start
            (expand-template
             (or
              inject-gen-start
              (pen-var-value-maybe 'inject-gen-start)
              ,inject-gen-start
              (and final-interactive-inject
                   is-interactive
                   (not final-continue-default)
                   (if final-inject-examples
                       (read-string-hist
                        (concat ,func-name " " parameter-slug " inject: ")
                        (fz final-inject-examples nil nil
                            (concat ,func-name " " parameter-slug " inject: ")))
                     (read-string-hist (concat ,func-name " " parameter-slug " inject: ") final-inject-example))))))

           (final-engine-max-n-completions
            (expand-template
             (str (or (pen-var-value-maybe 'engine-max-n-completions)
                      ,engine-max-n-completions))))

           (final-n-completions
            (progn
              (pen-log "(pen-var-value-maybe 'n-completions)" (pen-var-value-maybe 'n-completions))
              (pen-log ",n-completions" (pen-var-value-maybe ,n-completions))
              (expand-template
               (str (or
                     (pen-var-value-maybe 'force-n-completions)
                     ;; For some reason, the override is set to 5. Debug this
                     (pen-var-value-maybe 'n-completions)
                     ,n-completions)))))

           (final-n-completions
            (progn
              ;; (pen-log "n-completions" final-n-completions)
              ;; (pen-log "final-engine-max-n-completions" final-engine-max-n-completions)
              ;; (pen-log "final-n-completions" (str (pen-hard-bound final-n-completions 1 final-engine-max-n-completions)))
              (pen-hard-bound final-n-completions 1 final-engine-max-n-completions)))

           (final-n-collate
            (if (and
                 final-cant-n-complete
                 (nor final-n-collate)
                 (nor final-n-completions))
                (setq final-n-collate
                      (* (pen-str2num
                          (or final-n-collate 1))
                         (pen-str2num
                          (or
                           final-n-completions 1))))))

           ;; min-tokens is not really adjustable
           ;; without enough tokens to run a prompt, it should fail
           ;; TODO Make a hard fail here
           ;; TODO Make a distinction between min and max generated tokens
           ;; and min and max prompt tokens
           ;; Can't do this yet anyway, because non-specified engine max becomes 0
           ;; and that changes max
           ;; (final-min-tokens (pen-hard-bound
           ;;                    final-min-tokens
           ;;                    final-engine-min-tokens
           ;;                    final-engine-max-tokens))

           ;; (final-max-tokens (pen-hard-bound
           ;;                    final-max-tokens
           ;;                    final-engine-min-tokens
           ;;                    final-engine-max-tokens))

           (final-engine-min-generated-tokens
            (pen-str2num
             (expand-template
              (str (or (pen-var-value-maybe 'engine-min-generated-tokens)
                       ,engine-min-generated-tokens)))))

           (final-engine-max-generated-tokens
            (pen-str2num
             (expand-template
              (str (or (pen-var-value-maybe 'engine-max-generated-tokens)
                       ,engine-max-generated-tokens)))))

           (final-engine-min-tokens
            (pen-str2num
             (expand-template
              (str (or (pen-var-value-maybe 'engine-min-tokens)
                       ,engine-min-tokens)))))

           (final-engine-max-tokens
            (pen-str2num
             (expand-template
              (str (or (pen-var-value-maybe 'engine-max-tokens)
                       ,engine-max-tokens
                       2048)))))

           (final-min-tokens
            (pen-str2num
             (expand-template
              (str (or (pen-var-value-maybe 'min-tokens)
                       ,min-tokens)))))

           (final-force-temperature
            (or
             (pen-var-value-maybe 'force-temperature)
             ,force-temperature))

           (final-logprobs
            (or
             (pen-var-value-maybe 'logprobs)
             ,logprobs))

           ;; This is used for things such as beam search
           ;; Not a part of a prompt, usually.
           ;; But the depth of the beam might be a good configure option for a prompt.
           (final-force-logprobs
            (or
             (pen-var-value-maybe 'force-logprobs)
             ,force-logprobs))

           (final-logprobs
            (or
             (and
              pen-logprobs-on
              (or
               final-force-logprobs
               pen-force-logprobs
               (pen-var-value-maybe 'logprobs)
               ,logprobs))
             ""))

           (final-default-temperature
            (expand-template
             (str (or (pen-var-value-maybe 'default-temperature)
                      ,default-temperature))))

           (final-temperature
            (expand-template
             (str (or
                   final-force-temperature
                   pen-force-temperature
                   temperature
                                        ;At this stage, could only have been set by force-engine
                   final-temperature
                   (pen-var-value-maybe 'temperature)
                   ,temperature
                   final-default-temperature))))

           (final-validator
            (expand-template
             (str (or (pen-var-value-maybe 'validator)
                      ,validator))))

           (final-mode
            (expand-template
             (str (or (pen-var-value-maybe 'mode)
                      ,mode))))


           (final-force-lm-command
            (or (pen-var-value-maybe 'force-lm-command)
                ,force-lm-command))

           (final-lm-command
            (expand-template
             (str (or
                   final-force-lm-command
                   final-lm-command ;At this stage, could only have been set by force-engine
                   (pen-var-value-maybe 'lm-command)
                   ,lm-command))))

           (final-force-model
            (or
             (pen-var-value-maybe 'force-model)
             ,force-model))

           (final-model
            (progn
              (comment
               (pen-etv (pps
                         `(expand-template
                           (str (or
                                 ,final-force-model
                                 ,final-model ;At this stage, could only have been set by force-engine
                                 ,(pen-var-value-maybe 'model)
                                 ,,model))))))
              (expand-template
               (str (or
                     final-force-model
                     final-model ;At this stage, could only have been set by force-engine
                     (pen-var-value-maybe 'model)
                     ,model)))))

           (final-frequency-penalty
            (expand-template
             (str (or (pen-var-value-maybe 'frequency-penalty)
                      ,frequency-penalty))))

           (final-presence-penalty
            (expand-template
             (str (or (pen-var-value-maybe 'presence-penalty)
                      ,presence-penalty))))

           (final-repetition-penalty
            (expand-template
             (str (or (pen-var-value-maybe 'repetition-penalty)
                      ,repetition-penalty))))

           (final-length-penalty
            (expand-template
             (str (or (pen-var-value-maybe 'length-penalty)
                      ,length-penalty))))

           (final-approximate-token-char-length
            (pen-num
             (expand-template
              (str (or (pen-var-value-maybe 'approximate-token-char-length)
                       ,approximate-token-char-length)))))

           (final-top-p
            (expand-template
             (str (or (pen-var-value-maybe 'top-p)
                      ,top-p))))

           (final-top-k
            (expand-template
             (str (or (pen-var-value-maybe 'top-k)
                      ,top-k))))

           (final-top-k
            (if (and (sor final-top-k)
                     final-n-completions)
                (pen-hard-bound
                 final-top-k
                 ;; top-k can't go below n-completions
                 final-n-completions
                 100
                 ;; final-n-completions
                 )))

           (final-action
            (expand-template
             (str (or (pen-var-value-maybe 'action)
                      ,action))))

           ;; This could be a pf- function, elisp or shell command.
           ;; It completes until it doesn't complete anymore. 
           (final-closer
            (expand-template
             (str (or (pen-var-value-maybe 'closer)
                      ,closer))))

           (final-return-postprocessor
            (expand-template
             (str (or (pen-var-value-maybe 'return-postprocessor)
                      ,return-postprocessor))))

           (final-postprocessor
            (expand-template
             (str (or (pen-var-value-maybe 'postprocessor)
                      ,postprocessor))))

           (final-fz-pretty
            (expand-template
             (str (or (pen-var-value-maybe 'fz-pretty)
                      ,fz-pretty))))

           (final-postpostprocessor
            (expand-template
             (str (or (pen-var-value-maybe 'postpostprocessor)
                      ,postpostprocessor))))

           (final-filter
            (and (or ',filter
                     (pen-var-value-maybe 'filter))
                 (not (or ',filter-off
                          (pen-var-value-maybe 'filter-off)))))

           (final-insertion
            (and (or ',insertion
                     (pen-var-value-maybe 'insertion))
                 (not (or ',insertion-off
                          (pen-var-value-maybe 'insertion-off)))))

           (final-completion
            (and (or ',completion
                     (pen-var-value-maybe 'completion))
                 (not (or ',completion-off
                          (pen-var-value-maybe 'completion-off)))))

           (final-force-completion
            (or ',force-completion
                (pen-var-value-maybe 'force-completion)))

           (final-force-stop-sequence
            (or (pen-var-value-maybe 'force-stop-sequence)
                ,force-stop-sequence))

           (final-engine-strips-gen-starting-whitespace
            (or (pen-var-value-maybe 'engine-strips-gen-starting-whitespace)
                ,engine-strips-gen-starting-whitespace))

           ;; These are media payloads for multi-modal prompts.
           ;; They are only URLs and file paths.
           ;; The final prompting script deals with them.
           ;; The entirety of this is sent as json in an environment variable.
           (final-payloads
            (or (pen-var-value-maybe 'payloads)
                ',payloads))

           (final-payloads
            (cl-loop for pl in final-payloads
                     collect
                     (let ((v (if (re-match-p "^(" (cdr pl))
                                  (eval-string (cdr pl))
                                (expand-template (cdr pl)))))
                       (cons (car pl) v))))

           (final-payloads
            (or
             (if final-payloads
                 (json--encode-alist final-payloads)
               nil)
             ""))

           (final-stop-patterns
            (or (pen-var-value-maybe 'stop-patterns)
                ',stop-patterns))

           ;; These happen before the postprocessing
           (final-search-threshold
            (or (pen-var-value-maybe 'search-threshold)
                ',search-threshold))

           (final-split-patterns
            (or (pen-var-value-maybe 'split-patterns)
                ',split-patterns))

           ;; These happen after the postprocessing
           (final-end-split-patterns
            (or (pen-var-value-maybe 'end-split-patterns)
                ',end-split-patterns))

           (final-engine-max-stop-sequence-size
            (expand-template
             (str (or
                   (pen-var-value-maybe 'engine-max-stop-sequence-size)
                   ,engine-max-stop-sequence-size))))

           (final-stop-sequence
            (expand-template
             (str (or
                   final-force-stop-sequence
                   (pen-var-value-maybe 'stop-sequence)
                   ,stop-sequence))))

           (final-stop-sequence
            (if (sor final-engine-max-stop-sequence-size)
                (let ((l (string-to-number
                          final-engine-max-stop-sequence-size)))
                  (pen-log "Warning: stop sequence trimmed")
                  (s-left l final-stop-sequence))
              final-stop-sequence))

           (final-stop-sequences
            (cl-loop for stsq in (or (pen-var-value-maybe 'stop-sequences)
                                     ',stop-sequences)
                     collect
                     (expand-template stsq)))

           (final-stop-sequences
            (if (member final-stop-sequence final-stop-sequences)
                final-stop-sequences
              (cons final-stop-sequence final-stop-sequences)))

           (final-translator
            (expand-template
             (str (or (pen-var-value-maybe 'translator)
                      ,translator))))

           ;; These might be variables to the function.
           ;; They're used for search mode.
           (final-query
            (expand-template
             (str (or (pen-var-value-maybe 'query)
                      ""))))

           (final-counterquery
            (expand-template
             (str (or (pen-var-value-maybe 'counterquery)
                      ""))))

           (final-prompt
            (expand-template final-prompt))

           (final-prompt
            (if ,prompt-filter
                (sor (pen-snc ,prompt-filter final-prompt)
                     (concat "prompt-filter " ,prompt-filter " failed."))
              final-prompt))

           (final-prompt (if final-end-yas
                             (auto-yes
                              (pen-yas-expand-string final-prompt))
                           final-prompt))

           ;; This gives string position, not byte position
           ;; (string-search "s" "ガムツリshane")

           (final-prompt (s-remove-trailing-newline final-prompt))

           ;; (let ((override-prompt "Hi,")) (pf-who-is-the-subject-matter-expert-for-/1))

           (final-prompt
            (progn
              (while
                  (setq pos
                        ;; (byte-string-search "<:fz-eol>" final-prompt)
                        (string-search "<:fz-eol>" final-prompt))

                (let* ((completions
                        (eval
                         `(let* ((force-prompt ,(s-left pos final-prompt))
                                 (stop-sequence "\n")
                                 (stop-sequences '("\n"))
                                 (max-tokens 50)
                                 (do-pen-batch t)
                                 (pen-no-select-result t))
                            ;; (,',func-sym)
                            (pf-generic-completion-50-tokens/1))))
                       (completion (fz completions nil nil "select part:")))

                  (setq final-prompt
                        ;; (pen-etv (pen-sn "sed -z 's/<:fz-eol>/hello/'" (cat "/tmp/o8EnBA9BpZ")))
                        (concat
                         (replace-regexp-in-string
                          "\\(<:fz-eol>\\).*"
                          completion
                          final-prompt nil nil 1)
                         ""))))
              final-prompt))

           ;; How to assign which prompt function to use for this?
           ;; I need to be able to override the prompt of the current prompt function, or any prompt function for that matter.
           ;; And use the part up to here as the prompt, and simply recurse.

           ;; Somewhere around here handle fz-eol

           ;; Maybe just use <:pp> instead
           ;; (query-pos (or (byte-string-search "<:qp>" final-prompt)
           ;;                ""))

           (final-prompt
            (if (and final-continue-default
                     ;; consider making it always run instead of checking interactive
                     is-interactive)
                (let ((pos (re-match-p "<:pp>" final-prompt)))
                  (if pos
                      (string-replace "<:pp>" (concat (eval-string final-continue-default) "<:pp>") final-prompt)
                    (concat final-prompt (eval-string final-continue-default))))
              final-prompt))

           (final-prompt
            (if (sor final-inject-gen-start)
                (if (re-match-p "<:pp>" final-prompt)
                    (concat final-prompt final-inject-gen-start)
                  (concat final-prompt "<:pp>" final-inject-gen-start))
              final-prompt))
           ;; This is where to start collecting from

           (final-generated-prompt final-prompt)

           (func-name-slug (slugify ,func-name))

           (func-hist-dir
            (let ((fhd
                   (if final-prompt-hist-id
                       (f-join genhistdir func-name-slug final-prompt-hist-id)
                     (f-join genhistdir func-name-slug))))

              (if (not (f-directory-p fhd))
                  ;; (f-mkdir fhd)
                  (pen-sn (pen-cmd-q "mkdir" "-p" fhd)))

              (if (and do-pen-update
                       (f-directory-p fhd)
                       ;; Ensure that without being specific, it doesn't erase the entire directory
                       final-prompt-hist-id)
                  (pen-sn (pen-cmd-q "rm" "-rf" fhd)))

              (if (not (f-directory-p fhd))
                  (f-mkdir fhd))

              ;; (if (or final-prepend-previous
              ;;         final-train-function)
              ;;     (if (not (f-directory-p fhd))
              ;;         (f-mkdir fhd)))

              fhd))

           ;; add previous - used as an example
           (final-prompt
            (let ((lastgenpath (f-join func-hist-dir "last-generated-prompt-and-result.txt")))
              (if (and (or final-prepend-previous
                           ;; final-train-function
                           )
                       (f-exists-p lastgenpath))
                  (concat
                   (awk1 (cat lastgenpath))
                   final-stop-sequence
                   ;; final-delimiter "\n"
                   "\n\n"
                   final-prompt)
                final-prompt)))

           ;; pretext is useful for examples for the generation
           (final-prompt (concat pretext final-prompt))

           (collect-from-pos
            (or (byte-string-search "<:pp>" final-prompt)
                ;; (length final-prompt)
                (string-bytes final-prompt)))

           (final-prompt (string-replace "<:pp>" "" final-prompt))

           (end-pos (string-bytes final-prompt))

           ;; pen-log-final-prompt actually chomps it
           (logged (pen-log-final-prompt (concat final-prompt "<END>")))

           (trailing-whitespace (s-trailing-whitespace final-prompt))

           ;; (test (pen-etv (qne (s-trailing-whitespace final-prompt))))

           (final-prompt (if final-engine-whitespace-support
                             final-prompt
                           (s-remove-trailing-whitespace final-prompt)))

           ;; Now that all values are loaded, re-template them so I can base values on other values

           (pen-approximate-prompt-token-length
            (pen-approximate-token-length
             final-prompt
             (pen-num final-approximate-token-char-length)))

           (final-min-generated-tokens
            (let* ((prompt-length pen-approximate-prompt-token-length)
                   (token-char-length (pen-num final-approximate-token-char-length)))
              (or
               (pen-str2num
                (eval-string
                 ;; template is expanded twice so macros can have input and output
                 (expand-template
                  (pen-expand-macros
                   (expand-template
                    (str (or (pen-var-value-maybe 'min-generated-tokens)
                             ,min-generated-tokens)))))))
               0)))

           (final-max-generated-tokens
            (let* ((prompt-length pen-approximate-prompt-token-length)
                   (token-char-length (pen-num final-approximate-token-char-length)))
              (or
               (pen-str2num
                (eval-string
                 ;; template is expanded twice so macros can have input and output
                 (expand-template
                  (pen-expand-macros
                   (expand-template
                    (str (or (pen-var-value-maybe 'max-generated-tokens)
                             ,max-generated-tokens)))))))
               0)))

           ;; (testme
           ;;  (pen-etv final-max-generated-tokens))

           ;; The max tokens may be templated in via variable or even a subprompt
           (final-max-tokens
            (let* ((prompt-length pen-approximate-prompt-token-length))
              ;; pen-str2num
              (eval-string (expand-template
                            (str (or (pen-var-value-maybe 'max-tokens)
                                     ,max-tokens
                                     final-engine-max-tokens))))))

           ;; Ensure that the max tokens isn't more than the sum of the token length of the prompt + requested
           (final-max-tokens
            (if (< final-engine-max-tokens final-max-tokens)
                final-engine-max-tokens
              final-max-tokens))

           (final-max-generated-tokens
            (if (or
                 ;; (not final-max-generated-tokens)
                 (= 0 final-max-generated-tokens))
                (- final-max-tokens pen-approximate-prompt-token-length)
              final-max-generated-tokens))

           (final-min-generated-tokens
            (pen-hard-bound
             final-min-generated-tokens
             final-engine-min-generated-tokens
             final-engine-max-generated-tokens))

           (final-max-generated-tokens
            (pen-hard-bound
             final-max-generated-tokens
             final-engine-min-generated-tokens
             final-engine-max-generated-tokens))

           (final-max-tokens
            (let ((approx-total-tokens-from-max-gen
                   (+ pen-approximate-prompt-token-length
                      final-max-generated-tokens)))
              (if (and
                   final-max-generated-tokens
                   (< 0 final-max-generated-tokens)
                   (< approx-total-tokens-from-max-gen final-max-tokens))
                  approx-total-tokens-from-max-gen
                final-max-tokens)))

           (data
            (let ((data
                   ;; The prompt loses unicode here. I think I need to convert to base64 maybe
                   ;; And if I do, put it just outside pen-encode-string
                   `(
                     ("PEN_PROMPT" .
                      ;; Sort this out later
                      ,(pen-encode-string final-prompt)
                      ;; ,(pen-snc "base64" (pen-encode-string final-prompt))
                      ;; ,(pen-snc "base64" final-prompt)
                      )
                     ;; ("PEN_PROMPT" . ,(pen-encode-string final-prompt))
                     ("PEN_LM_COMMAND" . ,final-lm-command)
                     ("PEN_MODEL" . ,final-model)
                     ;; This must go into last-prompt-data for ink
                     ("PEN_ENGINE" . ,final-engine)
                     ("PEN_API_ENDPOINT" . ,final-api-endpoint)
                     ("PEN_PAYLOADS" . ,final-payloads)
                     ;; TODO Implement query and counterquery for more accurate semantic search
                     ("PEN_QUERY" . ,final-query)
                     ("PEN_COUNTERQUERY" . ,final-counterquery)
                     ("PEN_LOGPROBS" . ,(str final-logprobs))
                     ("PEN_APPROXIMATE_PROMPT_LENGTH" . ,pen-approximate-prompt-token-length)
                     ("PEN_ENGINE_MIN_TOKENS" . ,final-engine-min-tokens)
                     ("PEN_ENGINE_MAX_TOKENS" . ,final-engine-max-tokens)
                     ("PEN_MIN_TOKENS" . ,final-min-tokens)
                     ("PEN_MAX_TOKENS" . ,final-max-tokens)
                     ("PEN_REPETITION_PENALTY" . ,final-repetition-penalty)
                     ("PEN_FREQUENCY_PENALTY" . ,final-frequency-penalty)
                     ("PEN_PRESENCE_PENALTY" . ,final-presence-penalty)
                     ("PEN_LENGTH_PENALTY" . ,final-length-penalty)
                     ("PEN_MIN_GENERATED_TOKENS" . ,final-min-generated-tokens)
                     ("PEN_MAX_GENERATED_TOKENS" . ,final-max-generated-tokens)
                     ("PEN_TEMPERATURE" . ,final-temperature)
                     ("PEN_MODE" . ,final-mode)
                     ("PEN_STOP_SEQUENCE" . ,(pen-encode-string final-stop-sequence t))
                     ;; (json-encode-list (mapcar 'pen-encode-string '("hello my ;\"" "friend")))
                     ;; ("PEN_STOP_SEQUENCES" . ,(json-encode-list (mapcar 'pen-encode-string final-stop-sequences t)))
                     ("PEN_STOP_SEQUENCES" . ,(json-encode-list final-stop-sequences))

                     ;; TODO Force multiple prompts later
                     ;; Also need multi-prompts to understand different prompt lengths for results
                     ;; ("PEN_PROMPTS" . ,(json-encode-list final-prompts))
                     ;; documents must be a json list of strings
                     ("PEN_DOCUMENTS" . ,(pen-var-value-maybe 'documents))

                     ("PEN_TOP_P" . ,final-top-p)
                     ("PEN_TOP_K" . ,final-top-k)
                     ("PEN_FLAGS" . ,final-flags)
                     ;; 'best of' IS 'top k'
                     ;; ("PEN_BEST_OF" . ,final-best-of)
                     ("PEN_CACHE" . ,cache)
                     ("PEN_USER_AGENT" . ,pen-user-agent)
                     ("PEN_TRAILING_WHITESPACE" . ,trailing-whitespace)
                     ("PEN_N_COMPLETIONS" . ,(str final-n-completions))
                     ;; ("PEN_ENGINE_MAX_N_COMPLETIONS" . ,final-engine-max-n-completions)
                     ("PEN_ENGINE_MIN_GENERATED_TOKENS" . ,final-engine-min-generated-tokens)
                     ("PEN_ENGINE_MAX_GENERATED_TOKENS" . ,final-engine-max-generated-tokens)
                     ("PEN_COLLECT_FROM_POS" . ,collect-from-pos)
                     ("PEN_END_POS" . ,end-pos)
                     ("PEN_SEARCH_THRESHOLD" . ,final-search-threshold)
                     ;; ("PEN_QUERY_POS" . ,query-pos)
                     ("PEN_INJECT_GEN_START" . ,(pen-encode-string final-inject-gen-start t)))))
              (setq pen-last-prompt-data
                    (asoc-merge pen-last-prompt-data data))
              (setq pen-last-prompt-data
                    (asoc-merge pen-last-prompt-data (list (cons "PEN_VALS" (pps last-vals))
                                                           ;; (cons "PEN_END_POS" end-pos)
                                                           )))
              ;; (pen-etv data)
              data
              ;; data
              ))

           (tempa
            (let ((le (pen-log (eval `(pen-cmd "penf" "-u" (sym2str ',',func-sym) ,@last-vals-exprs))))
                  (lv (pen-log (eval `(pen-cmd "penf" "-u" (sym2str ',',func-sym) ,@last-vals))))
                  (lel (pen-log (concat
                                 "(pen-single-generation ("
                                 (eval `(sym2str ',',func-sym))
                                 " "
                                 (eval `(pen-cmd ,@last-vals))
                                 " :no-select-result t))"))))
              (tee (f-join penconfdir "last-pen-command-exprs.txt") le)
              (tee (f-join penconfdir "last-pen-command.txt") lv)
              (tee-a (f-join penconfdir "all-pen-commands-exprs.txt") le)
              (tee-a (f-join penconfdir "all-pen-commands.txt") lv)
              (tee-a (f-join penconfdir "all-pen-commands.txt") lel)))

           (results)

           (resultsdirs
            (if (not no-gen)
                (progn
                  (let* ((collation-data data)
                         (collation-temperature (alist-get "PEN_TEMPERATURE" collation-data nil nil 'equal)))
                    (cl-loop
                     for i in (number-sequence 1 final-n-collate)
                     collect
                     (progn
                       (message (concat ,func-name " query " (int-to-string i) "..."))
                       ;; TODO Also handle PEN_N_COMPLETIONS
                       (let* ((ret (pen-prompt-snc
                                    (pen-log
                                     (s-join
                                      " "
                                      (list
                                       ;; ;; This actually interfered with the memoization!
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
                                        (append (pen-alist-to-list final-envs)
                                                `(("ALSO_EXPORT" ,(sh-construct-envs (pen-alist-to-list final-envs))))
                                                (pen-alist-to-list collation-data)))
                                       ;; Currently always updating
                                       "lm-complete"))) i)))

                         (message (concat ,func-name " done " (int-to-string i)))
                         ret))
                     do
                     (pen-try
                      ;; Update the collation-temperature
                      (if (sor final-collation-temperature-stepper)
                          (progn
                            (setq collation-temperature
                                  (str
                                   (eval-string
                                    (pen-expand-template-keyvals
                                     final-collation-temperature-stepper
                                     `(("temperature" . ,collation-temperature))))))
                            (evil--add-to-alist
                             'collation-data
                             "PEN_TEMPERATURE"
                             collation-temperature)))
                      (message "collation temperature stepper failed")))))))

           (final-no-gen
            (or final-no-gen
                (pen-engine-disabled-p final-engine)))

           (results
            (cond
             (final-force-results final-force-results)
             (final-no-gen (progn
                             (message "Prompting function aborted")
                             '("")))
             (t (pen-maybe-uniq
                 final-no-uniq-results
                 (flatten-once
                  (cl-loop for rd in resultsdirs
                           collect
                           (if (sor rd)
                               (let* ((processed-results
                                       (-flatten
                                        (->> (glob (concat rd "/*"))
                                          (mapcar 'e/cat)
                                          (mapcar
                                           (lambda (r)
                                             (if final-split-patterns
                                                 (cl-loop
                                                  for stpat in final-split-patterns collect
                                                  (s-split stpat r))
                                               (list r)))))))
                                      (processed-results
                                       (->> processed-results
                                         (mapcar (lambda (r)
                                                   (cl-loop
                                                    for stsq in final-stop-sequences do
                                                    (let ((matchpos (pen-string-search (regexp-quote stsq) r)))
                                                      (if matchpos
                                                          (setq r (s-truncate matchpos r "")))))
                                                   r))
                                         (mapcar (lambda (r)
                                                   (cl-loop
                                                    for stpat in final-stop-patterns do
                                                    (let ((matchpos (re-match-p stpat r)))
                                                      (if matchpos
                                                          (setq r (s-truncate matchpos r "")))))
                                                   r))
                                         ;; TODO Add multiplexing
                                         ;; TODO in iλ? I need an imaginary map function which performs the multiplex
                                         ;; I should add this capability manually.
                                         ;; Or do I want an =icompose=?
                                         (mapcar (lambda (r) (if (and final-postprocessor (sor final-postprocessor))
                                                                 (if (string-match "^pf-" final-postprocessor)
                                                                     (eval `(car (pen-one (apply (str2sym ,final-postprocessor) (list ,r)))))
                                                                   (pen-sn final-postprocessor r))
                                                               r)))
                                         (mapcar (lambda (r) (if (or
                                                                  (and
                                                                   (or is-interactive
                                                                       (and (variable-p 'prettify)
                                                                            prettify))
                                                                   ,prettifier
                                                                   (sor ,prettifier))
                                                                  (and (not no-select-result)
                                                                       ,fz-pretty))
                                                                 (pen-sn ,prettifier r)
                                                               r)))

                                         (mapcar (lambda (r) (if (or (not ,no-trim-start)
                                                                     ;; (sor final-inject-gen-start)
                                                                     )
                                                                 (s-trim-left r) r)))
                                         (mapcar (lambda (r) (if (not ,no-trim-end) (s-trim-right r) r)))))

                                      (processed-results
                                       (-flatten
                                        (->> processed-results
                                          (mapcar
                                           (lambda (r)
                                             (if final-end-split-patterns
                                                 (cl-loop
                                                  for stpat in final-end-split-patterns collect
                                                  (s-split stpat r))
                                               (list r)))))))

                                      (processed-results
                                       (->> processed-results
                                         (-filter
                                          (lambda (r)
                                            (or
                                             final-engine-whitespace-support
                                             (not (sor trailing-whitespace))
                                             (not (pen-snq (pen-cmd "pen-str" "has-starting-specified-whitespace" trailing-whitespace) r)))))))

                                      (processed-results
                                       (->> processed-results
                                         (-filter
                                          (lambda (r)
                                            (if
                                                (not final-engine-whitespace-support)
                                                (concat trailing-whitespace r)
                                              r)))))

                                      ;; (processed-results
                                      ;;  (mapcar
                                      ;;   (lambda (r)
                                      ;;     (if (and (not final-engine-whitespace-support)
                                      ;;              (sor trailing-whitespace))
                                      ;;         (s-remove-starting-specified-whitespace r trailing-whitespace)
                                      ;;       ;; (pen-sn (pen-cmd "pen-str" "remove-starting-specified-whitespace" trailing-whitespace) r)
                                      ;;       r))
                                      ;;   processed-results))

                                      (processed-results
                                       (->> processed-results
                                         (-filter
                                          (lambda (r)
                                            (or
                                             (not final-validator)
                                             ;; Theoretically, both a shell script and elisp should have access to prompt-length and result-length
                                             (let* ((al `((prompt-length . ,pen-approximate-prompt-token-length)
                                                          (gen-length . ,(round (/ (length r)
                                                                                   (or
                                                                                    (pen-num final-approximate-token-char-length)
                                                                                    pen-default-approximate-token-length-divisor))))))
                                                    (valr (pen-expand-template-keyvals final-validator al)))
                                               (eval
                                                `(pen-let-keyvals
                                                  ',al
                                                  (if (re-match-p "^(" ,valr)
                                                      (eval-string ,valr)
                                                    (pen-snq ,valr ,r)))))))))))
                                 processed-results)
                             (list (message "Try UPDATE=y or debugging")))))))))

           (results
            (if final-include-prompt
                (mapcar
                 (lambda (s) (concat final-prompt s))
                 results)
              results))

           ;; Avoid using this. Factor it out.
           (results (if (and (not final-no-gen)
                             (sor final-postpostprocessor))
                        (mapcar
                         (lambda (r) (if (and final-postpostprocessor (sor final-postpostprocessor))
                                         (pen-sn final-postpostprocessor r)
                                       r))
                         results)
                      results))

           ;; This is where 'result' is introduced
           (result
            (if final-analyse
                ;; I need to do more work on this
                (pen-snc final-results-analyser (pen-list2str (mapcar 'pen-onelineify results)))
              (if no-select-result
                  ;; This behaviour isn't the best
                  (length results)
                ;; This may insert immediately, so it's important to force selection
                (cl-fz results :prompt (concat ,func-name ": ") :select-only-match select-only-match))))

           (result
            (if (and final-return-postprocessor (sor final-return-postprocessor))
                (if (string-match "^pf-" final-return-postprocessor)
                    (eval `(car (pen-one (apply (str2sym ,final-return-postprocessor) (list ,result)))))
                  (pen-sn final-return-postprocessor result))
              result))

           (result
            (if (and final-evaluator (sor final-evaluator))
                (eval-string final-evaluator)
              result))

           (inert-save-hist
            (progn
              (if (and (or final-prepend-previous
                           final-train-function)
                       (f-directory-p penconfdir))
                  (let ((r (if (numberp result)
                               (car results)
                             result)))

                    (tee (f-join func-hist-dir
                                 "last-generated-prompt-and-result.txt")
                         (concat final-generated-prompt r))
                    (tee (f-join func-hist-dir
                                 "last-generated.txt")
                         final-generated-prompt)
                    (tee (f-join func-hist-dir
                                 "last-final-prompt.txt")
                         final-prompt)
                    (tee (f-join func-hist-dir
                                 (concat (str gen-time) "-generated.txt"))
                         final-generated-prompt)
                    (tee (f-join func-hist-dir
                                 (concat (str gen-time) ".txt"))
                         final-prompt)))
              nil)))

      ;; TODO here save the function that ran and the selection

      ;; TODO Obtain the function name too
      (setq pen-last-prompt-data
            (asoc-merge pen-last-prompt-data (list (cons "PEN_RESULT" (str result))
                                                   (cons "PEN_RESULTS" (json-encode-list results)))))

      ;; Now save this to a list somewhere
      (pen-append-to-file
       (concat
        "\n'"
        (pen-snc "tr -d '\\n'" (pps pen-last-prompt-data)))
       (f-join penconfdir "prompt-hist.el"))

      ;; (pen-etv (pps final-stop-sequences))
      ;; (pen-etv final-insertion)
      (pen-log (concat
                "insertion: " (str (type final-insertion)) " " (str final-insertion)
                " "
                "info: " (str final-info)
                " "
                "filter: " (str final-filter)
                " "
                "new-document: " (str final-new-document)
                " "
                "current-prefix-arg: " (pps current-prefix-arg)))

      (if no-select-result
          results
        (if is-interactive
            (cond
             ((sor final-action)
              (progn
                (apply (intern final-action) (list result))
                result))
             ((or
               (string-equal final-mode "search")
               final-info
               final-new-document
               (>= (prefix-numeric-value current-prefix-arg) 4))
              (pen-log "pen new doc")
              (pen-etv (ink-decode (ink-propertise result))))
             ;; (final-analyse
             ;;  (pen-etv result))
             ;; Filter takes priority over insertion
             ((and final-filter
                   mark-active)
              ;; (pen-replace-region (concat (pen-selected-text) result))
              (pen-log "pen filtering")
              (if (sor result)
                  (pen-replace-region (ink-propertise result))
                (error "pen filter returned empty string")))

             ;; These are the overrides
             ;; Insertion is for prompts for which a new buffer is not necessary
             ((or final-force-completion)
              (pen-log "pen completing")
              (pen-complete-insert (ink-propertise result)))

             ;; These are the defaults
             ((or final-insertion
                  final-completion)
              (pen-log "inserting")
              (pen-complete-insert (ink-propertise result)))
             (t
              (pen-log "pen defaulting")
              (pen-etv (ink-propertise result))))
          result))))

(defun define-prompt-function ()
  (eval
   ;; Annoyingly, cl-defun does not support &rest, so I provide it as the variadic-var, here
   `(cl-defun ,func-sym ,(append '(&optional) all-var-syms '(&key
                                                             no-select-result
                                                             include-prompt
                                                             no-gen
                                                             select-only-match
                                                             variadic-var
                                                             pretext
                                                             inject-gen-start
                                                             continue-default
                                                             temperature
                                                             override-prompt
                                                             force-interactive
                                                             prompt-hist-id
                                                             client
                                                             server))
      ,doc
      (interactive ,(cons 'list all-iargs))

      (setq no-select-result
            (or no-select-result
                (pen-var-value-maybe 'pen-no-select-result)))

      ;; force-custom, unfortunately disables call-interactively
      ;; i guess that it could also disable other values
      (let* ((is-interactive
              (or (interactive-p)
                  force-interactive))
             (client-fn-name
              (replace-regexp-in-string "^pf-" "pen-fn-" (str ',func-sym)))
             (client-fn-sym
              (intern client-fn-name))
             (gen-time (time-to-seconds)))
        (if client
            (apply client-fn-sym
                   (append
                    (mapcar 'eval ',all-var-syms)
                    (list
                     :no-select-result no-select-result
                     :include-prompt include-prompt
                     :no-gen no-gen
                     :select-only-match select-only-match
                     :variadic-var variadic-var
                     :inject-gen-start inject-gen-start
                     :temperature temperature
                     :override-prompt override-prompt
                     :force-interactive is-interactive
                     ;; inert for client
                     ;; client
                     ;; server
                     )))
          (pen-force-custom
           (cl-macrolet  ((expand-template
                           (string-sym)
                           `(--> ,string-sym
                              ;; Can't onelineify because some of the values substituted may have newlines and be unonelineified
                              ;; The t fixes this
                              (pen-onelineify-safe it)
                              ;; TODO Replace the engine-delimiter
                              ;; <delim>
                              (pen-expand-template-keyvals it final-subprompts-al t final-pipelines)
                              (pen-expand-template it vals t )
                              ;; I also want to encode newlines into <pen-newline> and <pen-dnl>
                              ;; But only for delim
                              (pen-expand-template-keyvals it (list (cons "delim" (pen-encode-string final-delimiter t))) t final-pipelines)
                              (pen-expand-template-keyvals it (list (cons "delim-1" (pen-encode-string (pen-snc "sed 's/.$//'" final-delimiter) t))) t final-pipelines)
                              (pen-expand-template-keyvals it var-keyvals-slugged t final-pipelines)
                              (pen-expand-template-keyvals it var-keyvals t final-pipelines)
                              (pen-expand-template-keyvals it final-defs t final-pipelines)
                              (pen-unonelineify-safe it))))

             (setq pen-last-prompt-data `((face . ink-generated)
                                          ;; This is necessary because most modes
                                          ;; do not allow allow you to change the faces.
                                          ("INK_TYPE" . "generated")
                                          ("PEN_FUNCTION_NAME" . ,,func-name)
                                          ("PEN_GEN_UUID" . ,(pen-uuid))
                                          ("PEN_GEN_TIME" . ,gen-time)))

             (pen-append-to-file
              (concat
               "\n'"
               (pen-snc "tr -d '\\n'" (pps pen-last-prompt-data)))
              (f-join penconfdir "prompt-hist-preselect.el"))

             (if (or (pen-prompt-disabled-p ,func-name)
                     (pen-prompt-disabled-p ,title))
                 (progn (message "Prompting function aborted")
                        nil)

               ;; Many a  transformation pipeline here could benefit from transducers
               ;; https://dev.solita.fi/2021/10/14/grokking-clojure-transducers.html
               ;; https://github.com/FrancisMurillo/transducer.el
               ,(expand-macro `(pen-define-prompt-function-pipeline))))))))))

(provide 'pen-define-prompt-function)