(defmacro pen-split-macro-test-inner ()
  `(progn
     (etv ,testval)))

(defun pen-split-macro-test-define-fun ()
  (eval
   `(defun split-macro-test-fun ()
      ,(macroexpand `(pen-split-macro-test-inner)))))

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

          (do-pen-batch
           (pen-var-value-maybe 'do-pen-batch))

          (final-expressions)

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

          (final-force-n-jobs
           (str (or
                 ,force-n-jobs
                 (pen-var-value-maybe 'force-n-jobs))))

          (final-n-jobs
           (str (or
                 (sor final-force-n-jobs)
                 (pen-var-value-maybe 'n-jobs)
                 ,n-jobs
                 pen-n-simultaneous-requests)))

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
                  (force-n-jobs (cdr (assoc 'force-n-jobs al)))
                  (api-endpoint (cdr (assoc 'api-endpoint al))))
             ;; (if temp
             ;;     (setq final-temperature temp))
             (if model
                 (setq final-model model))
             (if lm-command
                 (setq final-lm-command lm-command))
             (if api-endpoint
                 (setq final-api-endpoint api-endpoint))
             (if force-n-jobs
                 (setq final-force-n-jobs force-n-jobs))
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

          ;; To use in preprocessors, postprocessor postpostprocessor 
          (pipelines-varvals
           (asoc-merge
            final-pipelines))

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
           (let ((varvals-sofar))
             (cl-loop
              ;; (-zip-fill nil '(a b c) '(1 2 3) '("a" "b" "c"))
              for tp in (-zip-fill nil ',var-syms vals final-var-defaults)
              ;; cl-loop is opaque to what has been so far set, so I keep track of current vals with varvals-sofar
              collect
              (let ((sym (first tp))
                    (val (second tp))
                    (default (third tp)))
                (if (and (not (sor (second tp)))
                         (sor (third tp)))

                    ;; set the second from the third
                    ;; save to current varvals-sofar and use that in subsequent evaluations

                    ;; TODO if a val is empty, apply the default with the subprompts in scope
                    (let* ((var-al
                            (asoc-merge
                             `((func-name . ,,func-name)
                               (do-pen-batch . ,do-pen-batch)
                               (pen-no-select-result . ,no-select-result))
                             varvals-sofar
                             final-subprompts-al))
                           (thowaway var-al)
                           (valtmp
                            (eval
                             ;; let* implementation for vals
                             ;; (assoc 'pos-tags (alist2pairs '((pos-tags . "hi"))))
                             `(pen-let-keyvals
                               ',var-al
                               (eval-string ,(str default))))))
                      (pen-alist-set 'varvals-sofar sym valtmp)
                      valtmp)
                  val)))))

          (last-vals vals)

          (final-preprocessors
           ;; Unfortunately, can't do full template expansion here because we don't have vals. final-preprocessors is needed for vals 
           (cl-loop for fpp in final-preprocessors collect
                    (if fpp
                        (--> fpp
                          (pen-expand-template-keyvals it (-zip-fill "" ',vars vals))
                          (pen-expand-template-keyvals it (-zip-fill "" ',var-slugs vals))
                          (pen-expand-template-keyvals it pipelines-varvals)))))

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
              pen-default-logprobs
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

          (defs-varvals
           (asoc-merge
            '((func-name . ,func-name))
            final-subprompts-al
            (-zip-fill nil ',var-syms vals)))

          (final-defs
           (cl-loop
            for atp in final-defs
            collect
            (cons
             (car atp)
             (eval
              `(pen-let-keyvals
                ',defs-varvals
                (eval-string ,(str (cdr atp))))))))

          (validator-varvals
           (asoc-merge
            defs-varvals
            final-defs))

          ;; TODO Make the expand-template utilise variables in scope
          (final-validator
           (expand-template-al
            (expand-template
             (str (or (pen-var-value-maybe 'validator)
                      ,validator)))
            validator-varvals))

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
                    final-model   ;At this stage, could only have been set by force-engine
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
           (expand-template-al
            (expand-template
             (str (or (pen-var-value-maybe 'return-postprocessor)
                      ,return-postprocessor)))
            pipelines-varvals))

          (final-postprocessor
           (expand-template-al
            (expand-template
             (str (or (pen-var-value-maybe 'postprocessor)
                      ,postprocessor)))
            pipelines-varvals))

          (final-fz-pretty
           (expand-template
            (str (or (pen-var-value-maybe 'fz-pretty)
                     ,fz-pretty))))

          (final-postpostprocessor
           (expand-template-al
            (expand-template
             (str (or (pen-var-value-maybe 'postpostprocessor)
                      ,postpostprocessor)))
            pipelines-varvals))

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

          (final-expressions
           (or (pen-var-value-maybe 'expressions)
               ',expressions))

          ;; pipelines are available to expressions as <pipeline> expressions
          ;; pipelines are also available the 'expand-template' in this way <pipeline:var>
          ;; Expressions may be used inside various prompt parameters, such as max-tokens
          (final-expressions
           (if final-expressions
               (mapcar (lambda (atp)
                         (let ((k (car atp))
                               (v (cdr atp)))
                           (cons k (pen-expand-template-keyvals v final-pipelines))))
                       final-expressions)
             final-expressions))

          (al-for-expressions
           (asoc-merge
            `((final-prompt . ,final-prompt))
            final-subprompts-al))

          ;; How are expressions different from defs?
          ;; - They are not used inside the prompt. They may use the prompt definition to set other parameters, such as stop-sequence
          ;; - They are very late, where defs are very early.
          ;; - expressions may make direct use of pipelines
          (final-expressions
           (cl-loop
            for atp in final-expressions
            collect
            (cons
             (car atp)
             (eval
              `(pen-let-keyvals
                ',al-for-expressions
                (eval-string ,(str (cdr atp))))))))

          (final-stop-sequences
           (cl-loop for stsq in (or (pen-var-value-maybe 'stop-sequences)
                                    ',stop-sequences)
                    collect
                    (pen-unonelineify-safe (pen-expand-template-keyvals stsq final-expressions t final-pipelines))))

          (final-stop-sequence
           (pen-unonelineify-safe
            (expand-template
             (pen-expand-template-keyvals final-stop-sequence final-expressions t final-pipelines))))

          (final-stop-sequences
           (if (member final-stop-sequence final-stop-sequences)
               final-stop-sequences
             (cons final-stop-sequence final-stop-sequences)))

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
                    ("PEN_WHITESPACE_SUPPORT" . ,(if final-engine-whitespace-support
                                                     "y"
                                                   ""))
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
                    ("PEN_N_JOBS" . ,final-n-jobs)
                    ("PEN_SEARCH_THRESHOLD" . ,final-search-threshold)
                    ("PEN_GEN_UUID" . ,gen-id)
                    ("PEN_GEN_TIME" . ,gen-time)
                    ("PEN_GEN_DIR" . ,gen-dir)
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
                                       (->>
                                         (append (glob (concat rd "/split*_*"))
                                                 (glob (concat rd "/results*/split*_*"))
                                                 (glob (concat rd "/res*.txt"))
                                                 (glob (concat rd "/results*/res*.txt")))
                                         (-filter 'string-not-empty-nor-nil-p)
                                         (-filter 'f-exists-p)
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
                                                                  (pen-sn (concat
                                                                           (sh-construct-envs (pen-alist-to-list `(("FINAL_PROMPT" . ,final-prompt))))
                                                                           " "
                                                                           final-postprocessor)
                                                                          r))
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
                                      (pen-sn (concat
                                               (sh-construct-envs (pen-alist-to-list `(("FINAL_PROMPT" . ,final-prompt))))
                                               " "
                                               final-postpostprocessor) r)
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

;; TODO Make the transient system this way:
;; If initial-transient is on, then abort the function but provide
;; to `run-prompt-function-initial-transient` the var vals read interactively
;; along with

(defun run-prompt-function-initial-transient ()

  )

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
                                                             initial-transient
                                                             final-transient
                                                             client
                                                             server))
      ,doc
      (interactive ,(cons 'list all-iargs))

      (setq no-select-result
            (or no-select-result
                (pen-var-value-maybe 'pen-no-select-result)
                (pen-var-value-maybe 'do-pen-batch)))

      ;; force-custom, unfortunately disables call-interactively
      ;; i guess that it could also disable other values
      (let* ((is-interactive
              (or (interactive-p)
                  force-interactive))
             ;; (run-transient-prompt-config
             ;;  (and (interactive-p)
             ;;       (= (prefix-numeric-value current-prefix-arg) 1)))
             (client-fn-name
              (replace-regexp-in-string "^pf-" "pen-fn-" (str ',func-sym)))
             (client-fn-sym
              (intern client-fn-name))
             (gen-id (pen-uuid))
             (gen-time (time-to-seconds))
             (gen-date (pen-snc (concat "date +%d.%m.%y -d @" (str gen-time)) ))
             (gen-dir (f-join (pen-umn "$HOME/.pen/results")
                              (concat "results_"
                                      (str gen-time)
                                      "_"
                                      (str gen-date)
                                      "_"
                                      (str gen-id)))))
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
           (cl-macrolet ((expand-template
                          (string-sym)
                          `(--> ,string-sym
                             ;; Can't onelineify because some of the values substituted may have newlines and be unonelineified
                             ;; The t fixes this
                             (pen-onelineify-safe it)
                             ;; TODO Replace the engine-delimiter
                             ;; <delim>
                             (pen-expand-template-keyvals it final-subprompts-al t final-pipelines)
                             (pen-expand-template it vals t)
                             ;; I also want to encode newlines into <pen-newline> and <pen-dnl>
                             ;; But only for delim
                             (pen-expand-template-keyvals it (list (cons "delim" (pen-encode-string final-delimiter t))) t final-pipelines)
                             (pen-expand-template-keyvals it (list (cons "delim-1" (pen-encode-string (pen-snc "sed 's/.$//'" final-delimiter) t))) t final-pipelines)
                             (pen-expand-template-keyvals it var-keyvals-slugged t final-pipelines)
                             (pen-expand-template-keyvals it var-keyvals t final-pipelines)
                             (pen-expand-template-keyvals it final-defs t final-pipelines)
                             ;; (pen-expand-template-keyvals it final-expressions t final-pipelines)
                             (pen-unonelineify-safe it)))
                         (expand-template-al
                          (string-sym al)
                          `(--> ,string-sym
                             ;; Can't onelineify because some of the values substituted may have newlines and be unonelineified
                             ;; The t fixes this
                             (pen-onelineify-safe it)
                             (pen-expand-template-keyvals it ,al t final-pipelines)
                             (pen-unonelineify-safe it))))

             (setq pen-last-prompt-data `((face . ink-generated)
                                          ;; This is necessary because most modes
                                          ;; do not allow allow you to change the faces.
                                          ("INK_TYPE" . "generated")
                                          ("PEN_FUNCTION_NAME" . ,,func-name)
                                          ("PEN_GEN_TIME" . ,(str gen-time))))

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
               ,(macroexpand `(pen-define-prompt-function-pipeline))))))))))

(defun pen-generate-prompt-functions (&optional paths)
  "Generate prompt functions for the files in the prompts directory
Function names are prefixed with pf- for easy searching"
  (interactive)

  (setq pen-prompt-functions nil)
  (setq pen-prompt-aliases nil)
  (setq pen-prompts-failed nil)
  (setq pen-prompt-filter-functions nil)
  (setq pen-prompt-analyser-functions nil)
  (setq pen-prompt-completion-functions nil)
  (setq pen-prompt-functions-meta nil)
  (setq pen-prompt-functions-failed nil)
  (setq pen-prompts (make-hash-table :test 'equal))

  (pen-load-engines)

  (noupd
   (eval
    `(let ((paths
            (or ,paths (pen-list-prompt-paths))))
       (cl-macrolet ((expand-template
                      (string-sym)
                      `(--> ,string-sym
                         ;; Can't onelineify because some of the values substituted may have newlines and be unonelineified
                         ;; The t fixes this
                         (pen-onelineify-safe it)
                         (pen-expand-template-keyvals it subprompts-al t final-pipelines)
                         (pen-expand-template it vals t )
                         ;; I also want to encode newlines into <pen-newline> and <pen-dnl>
                         ;; But only for delim
                         (pen-expand-template-keyvals it (list (cons "delim" (pen-encode-string final-delimiter t))) t final-pipelines)
                         (pen-expand-template-keyvals it (list (cons "delim-1" (pen-encode-string (pen-snc "sed 's/.$//'" final-delimiter) t))) t final-pipelines)
                         (pen-expand-template-keyvals it var-keyvals-slugged t final-pipelines)
                         (pen-expand-template-keyvals it var-keyvals t final-pipelines)
                         (pen-unonelineify-safe it)))
                     ;; (expand-template-al
                     ;;  (string-sym al)
                     ;;  `(--> ,string-sym
                     ;;     ;; Can't onelineify because some of the values substituted may have newlines and be unonelineified
                     ;;     ;; The t fixes this
                     ;;     (pen-onelineify-safe it)
                     ;;     (pen-expand-template-keyvals it ,al t final-pipelines)
                     ;;     (pen-unonelineify-safe it)))
                     )

         (cl-loop for path in paths do
                  (message (concat "pen-mode: Loading .prompt file " path))

                  ;; Do a recursive prompt merge from includes
                  ;; ht-merge

                  ;; results in a hash table
                  (pen-try
                   (let*
                       (
                        ;; yaml-ht may change
                        (yaml-ht (pen-prompt-file-load path))
                        ;; but prompt-yaml-ht stays the same
                        (prompt-yaml-ht yaml-ht)

                        (path path)

                        (requirements (pen-vector2list (ht-get yaml-ht "requirements")))

                        (logprobs (ht-get yaml-ht "logprobs"))
                        (force-logprobs (ht-get yaml-ht "force-logprobs"))

                        (force-engine (ht-get yaml-ht "force-engine"))
                        (force-model (ht-get yaml-ht "force-model"))
                        (force-lm-command (ht-get yaml-ht "force-lm-command"))
                        (force-temperature (ht-get yaml-ht "force-temperature"))

                        (engine
                         (let* ((engine-title
                                 (or
                                  (ht-get yaml-ht "force-engine")
                                  (ht-get yaml-ht "engine")))
                                (engine (if (and
                                             engine-title
                                             pen-engines)
                                            (ht-get pen-engines engine-title))))
                           (if engine
                               (progn
                                 (setq yaml-ht (ht-merge yaml-ht engine))
                                 ;; Merge the original prompt keys back in, to override ones the engine may have set.
                                 ;; Because colliding prompt keys are more important.
                                 (setq yaml-ht (ht-merge yaml-ht prompt-yaml-ht))))
                           engine-title))

                        (engine (pen-resolve-engine engine requirements))

                        ;; function
                        (task-ink (ht-get yaml-ht "task"))
                        (language (ht-get yaml-ht "language"))
                        (task (ink-decode task-ink))
                        (task (if (and (sor task)
                                       (sor language))
                                  (pen-expand-template-keyvals
                                   task
                                   `(("language" . ,language)))
                                task))
                        (engine-whitespace-support (ht-get yaml-ht "engine-whitespace-support"))
                        (approximate-token-char-length
                         (or
                          (ht-get yaml-ht "approximate-token-char-length")
                          2.5))

                        (title (ht-get yaml-ht "title"))
                        (title (sor title
                                    task))
                        (title-slug (slugify title))

                        (aliases (pen-vector2list (ht-get yaml-ht "aliases")))

                        (variadic-var (pen-vector2list (ht-get yaml-ht "variadic-var")))

                        ;; lm-complete
                        (cache (pen-yaml-test yaml-ht "cache"))
                        ;; openai-complete.sh is the default LM completion command
                        ;; but the .prompt may specify a different one
                        (lm-command (or
                                     pen-override-lm-command
                                     (ht-get yaml-ht "lm-command")
                                     pen-default-lm-command))

                        (in-development (pen-yaml-test yaml-ht "in-development"))

                        ;; internals
                        (prompt (ht-get yaml-ht "prompt"))
                        (mode (ht-get yaml-ht "mode"))
                        (search-threshold (ht-get yaml-ht "search-threshold"))
                        (flags (ht-get yaml-ht "flags"))
                        (evaluator (ht-get yaml-ht "evaluator"))
                        (api-endpoint (ht-get yaml-ht "api-endpoint"))

                        (subprompts (ht-get yaml-ht "subprompts"))

                        ;; For examples (define-prompt-function signature). Not for define-prompt-function body.
                        ;; Body recalculates this.
                        (subprompts-al
                         (if subprompts
                             (ht->alist (-reduce 'ht-merge (pen-vector2list subprompts)))))

                        (payloads (pen--htlist-to-alist (ht-get yaml-ht "payloads")))

                        ;; info and hover are related
                        (info (pen-yaml-test yaml-ht "info"))
                        (hover (pen-yaml-test yaml-ht "hover"))
                        (prepend-previous (pen-yaml-test yaml-ht "prepend-previous"))
                        (force-prompt)
                        (formatter (pen-yaml-test yaml-ht "formatter"))
                        (linter (pen-yaml-test yaml-ht "linter"))
                        ;; This is both a code action and the default action
                        ;; sp +/"^action: pen-find-file" "$HOME/source/git/semiosis/prompts/prompts/recurse-directory-4.prompt"
                        (action (pen-yaml-test yaml-ht "action"))

                        (new-document (pen-yaml-test yaml-ht "new-document"))
                        (expand-jinja (pen-yaml-test yaml-ht "expand-jinja"))
                        (start-yas (pen-yaml-test yaml-ht "start-yas"))
                        (yas (pen-yaml-test yaml-ht "yas"))

                        ;; not normally given via .prompt. Rather, overridden
                        (inject-gen-start (ht-get yaml-ht "inject-gen-start"))
                        (interactive-inject (pen-yaml-test yaml-ht "interactive-inject"))
                        (inject-example (ht-get yaml-ht "inject-example"))
                        (inject-examples (pen-vector2list (ht-get yaml-ht "inject-examples")))
                        (continue-default (ht-get yaml-ht "continue-default"))

                        (end-yas (pen-yaml-test yaml-ht "end-yas"))

                        (include-prompt (pen-yaml-test yaml-ht "include-prompt"))

                        (no-gen (pen-yaml-test yaml-ht "no-gen"))

                        (repeater (ht-get yaml-ht "repeater"))

                        (engine-stop-sequence-validator (ht-get yaml-ht "engine-stop-sequence-validator"))
                        (engine-delimiter (or
                                           (ht-get yaml-ht "engine-delimiter")
                                           "###"))
                        (delimiter (or
                                    (ht-get yaml-ht "delimiter")
                                    engine-delimiter
                                    "###"))
                        (prefer-external (pen-yaml-test yaml-ht "prefer-external"))
                        (interpreter (pen-yaml-test yaml-ht "interpreter"))
                        (no-uniq-results (pen-yaml-test yaml-ht "no-uniq-results"))
                        (conversation (pen-yaml-test yaml-ht "conversation"))
                        (filter (pen-yaml-test yaml-ht "filter"))
                        (filter-off (pen-yaml-test-off yaml-ht "filter"))
                        (results-analyser (ht-get yaml-ht "results-analyser"))
                        ;; Don't actually use this.
                        ;; But I can toggle to use the prettifier with a bool
                        (prettifier (ht-get yaml-ht "prettifier"))
                        (fz-pretty (ht-get yaml-ht "fz-pretty"))
                        (collation-postprocessor (ht-get yaml-ht "pen-collation-postprocessor"))
                        (completion (pen-yaml-test yaml-ht "completion"))
                        (completion-off (pen-yaml-test-off yaml-ht "completion"))
                        (insertion (pen-yaml-test yaml-ht "insertion"))
                        (insertion-off (pen-yaml-test-off yaml-ht "insertion"))
                        ;; Is the prompt designed for an LM trained on code?
                        (utilises-code (pen-yaml-test yaml-ht "utilises-code"))
                        (utilises-code-off (pen-yaml-test-off yaml-ht "utilises-code"))
                        (no-trim-start (or (pen-yaml-test yaml-ht "no-trim-start")
                                           (pen-yaml-test yaml-ht "completion")))
                        (no-trim-end (pen-yaml-test yaml-ht "no-trim-end"))
                        (pipelines (pen--htlist-to-alist (ht-get yaml-ht "pipelines")))
                        (expressions (pen--htlist-to-alist (ht-get yaml-ht "expressions")))
                        (validator (ht-get yaml-ht "validator"))
                        (prompt-filter (ht-get yaml-ht "prompt-filter"))
                        (closer (ht-get yaml-ht "closer"))
                        (return-postprocessor (ht-get yaml-ht "return-postprocessor"))
                        (postprocessor (ht-get yaml-ht "postprocessor"))
                        (postpostprocessor (ht-get yaml-ht "postpostprocessor"))
                        (n-collate
                         (or (ht-get yaml-ht "n-collate")
                             1))
                        (n-max-collate (or (ht-get yaml-ht "n-max-collate")
                                           1))
                        (n-target (or (ht-get yaml-ht "n-target")
                                      1))

                        (engine-max-stop-sequence-size (or (ht-get yaml-ht "engine-max-stop-sequence-size")
                                                           20))

                        (engine-min-generated-tokens
                         (or (ht-get yaml-ht "engine-min-generated-tokens")
                             3))
                        (engine-max-generated-tokens
                         (or (ht-get yaml-ht "engine-max-generated-tokens")
                             4096
                             ;; 256
                             ))
                        (engine-max-n-completions
                         (or (ht-get yaml-ht "engine-max-n-completions")
                             10))
                        (n-completions
                         (progn
                           ;; (pen-log path)
                           ;; for some reason this is returning 5
                           ;; (pen-log (ht-get yaml-ht "n-completions"))
                           ;; It comes from openai.engine. If I'm forcing the engine, this will override.
                           (or (ht-get yaml-ht "n-completions") 5)))
                        (n-test-runs (ht-get yaml-ht "n-test-runs"))

                        ;; Execute some elisp in preparation for running this function
                        ;; This may set up elisp functions we need
                        (elisp (ht-get yaml-ht "elisp"))

                        (elisp
                         (progn (if (sor elisp)
                                    (eval-string elisp))
                                elisp))

                        ;; API

                        (model (ht-get yaml-ht "model"))
                        (mode (ht-get yaml-ht "mode"))
                        (frequency-penalty (ht-get yaml-ht "frequency-penalty"))
                        (presence-penalty (ht-get yaml-ht "presence-penalty"))
                        (repetition-penalty (ht-get yaml-ht "repetition-penalty"))
                        (length-penalty (ht-get yaml-ht "length-penalty"))

                        ;; min-tokens and max-tokens include the prompt
                        ;; These values may also be inferred from max-generated-tokens + an approximation of the prompt size.
                        (min-tokens (ht-get yaml-ht "min-tokens"))
                        (max-tokens (ht-get yaml-ht "max-tokens"))

                        ;; min-generated-tokens and max-generated-tokens do not include the prompt
                        ;; These values may also be inferred from max-tokens - an approximation of the prompt size.
                        ;; The desired number of generated tokens
                        (min-generated-tokens (ht-get yaml-ht "min-generated-tokens"))
                        (max-generated-tokens (ht-get yaml-ht "max-generated-tokens"))

                        (force-max-generated-tokens (ht-get yaml-ht "force-max-generated-tokens"))

                        (collation-temperature-stepper (ht-get yaml-ht "collation-temperature-stepper"))

                        ;; engine-min-tokens and engine-max-tokens include the prompt
                        (engine-min-tokens (ht-get yaml-ht "engine-min-tokens"))
                        (engine-max-tokens (ht-get yaml-ht "engine-max-tokens"))

                        (force-stop-sequence (ht-get yaml-ht "force-stop-sequence"))

                        (cant-n-complete (ht-get yaml-ht "cant-n-complete"))

                        (top-p (ht-get yaml-ht "top-p"))

                        ;; synonyms
                        (top-k (ht-get yaml-ht "top-k"))
                        (top-k (ht-get yaml-ht "best-of"))

                        (n-jobs (ht-get yaml-ht "n-jobs"))
                        (force-n-jobs (ht-get yaml-ht "force-n-jobs"))

                        (temperature (ht-get yaml-ht "temperature"))
                        (default-temperature (ht-get yaml-ht "default-temperature"))

                        ;; This is an override hint only
                        (force-completion nil)

                        (engine-strips-gen-starting-whitespace (ht-get yaml-ht "engine-strips-gen-starting-whitespace"))

                        (stop-sequences
                         (or (pen-vector2list (ht-get yaml-ht "stop-sequences"))
                             ;; (list "\n")
                             (list "#<long>#")))
                        (suggest-p
                         (or (pen-vector2list (ht-get yaml-ht "suggest-p"))
                             (list t)))

                        ;; These are automatically turned into prompt functions
                        (nl-suggest-p (pen-vector2list (ht-get yaml-ht "nl-suggest-p")))

                        (stop-sequence
                         (if stop-sequences (car stop-sequences)))

                        (stop-sequence
                         (if (and (sor engine-stop-sequence-validator)
                                  (pen-snq engine-stop-sequence-validator stop-sequence))
                             stop-sequence
                           (if stop-sequence
                               (progn
                                 (setq stop-sequences (cons stop-sequence stop-sequences))
                                 stop-sequence)
                             "#<long>#")))

                        (force-stop-sequence
                         (progn
                           (if force-stop-sequence
                               (setq stop-sequences (cons force-stop-sequence stop-sequences)))
                           force-stop-sequence))

                        (stop-patterns
                         (or (pen-vector2list (ht-get yaml-ht "stop-patterns"))
                             ;; By default, stop when you see ^Input
                             (list "^Input:")))

                        (split-patterns
                         (or (pen-vector2list (ht-get yaml-ht "split-patterns"))
                             nil
                             ;; (list "\n")
                             ))

                        (end-split-patterns
                         (or (pen-vector2list (ht-get yaml-ht "end-split-patterns"))
                             nil
                             ;; (list "\n")
                             ))

                        (translator
                         (let ((tr (ht-get yaml-ht "translator")))
                           (if (sor tr)
                               (add-to-list 'pen-translators tr))
                           tr))

                        ;; docs
                        (problems (pen-vector2list (ht-get yaml-ht "problems")))
                        (design-patterns (pen-vector2list (ht-get yaml-ht "design-patterns")))
                        (todo (pen-vector2list (ht-get yaml-ht "todo")))
                        (notes
                         (let* ((n (ht-get yaml-ht "notes"))
                                (n (if (vectorp n)
                                       (pen-list-to-orglist (pen-vector2list (ht-get yaml-ht "notes")))
                                     n)))
                           n))
                        (aims (pen-vector2list (ht-get yaml-ht "aims")))
                        (past-versions (pen-vector2list (ht-get yaml-ht "past-versions")))
                        (external-related
                         (let* ((n (ht-get yaml-ht "external-related")))
                           (if n
                               (cond
                                ((stringp n) (list n))
                                ((vectorp n) (pen-vector2list (ht-get yaml-ht "external-related")))
                                (t nil)))))
                        (related-prompts (pen-vector2list (ht-get yaml-ht "related-prompts")))
                        (future-titles (pen-vector2list (ht-get yaml-ht "future-titles")))

                        ;; variables - these are actually varnames. don't get confused
                        (vars (ht-get yaml-ht "vars"))

                        ;; used internally
                        (vars-list (pen-vector2list vars))

                        ;; Create the variables first
                        (var-defaults)
                        (examples)
                        (preprocessors)

                        ;; Initialise the var-related values with
                        ;; with what is under vars.
                        (vars
                         (cond
                          ;; It's a key-value
                          ((hash-table-p (car vars-list))
                           ;; generate vals from the values
                           ;; and replace vars
                           (let* ((vars-al (pen--htlist-to-alist vars))
                                  (keys (cl-loop
                                         for atp in vars-al
                                         collect
                                         (car atp)))
                                  (values (cl-loop
                                           for atp in vars-al
                                           collect
                                           (cdr atp))))

                             (if (hash-table-p (car (pen-vector2list (car values))))
                                 (let* ((als (cl-loop
                                              for atp in vars-al
                                              collect
                                              (pen--htlist-to-alist (pen-vector2list (cdr atp)))))

                                        (defaults
                                          (cl-loop
                                           for atp in als
                                           collect
                                           (cdr (assoc "default" atp))))

                                        (exs
                                         (cl-loop
                                          for atp in als
                                          collect
                                          (cdr (assoc "example" atp))))

                                        (pps
                                         (cl-loop
                                          for atp in als
                                          collect
                                          (cdr (assoc "preprocessor" atp)))))
                                   (setq var-defaults defaults)
                                   (setq examples exs)
                                   (setq preprocessors pps))
                               (setq var-defaults values))
                             keys))
                          ;; It's just the list of keys
                          (t vars-list)))

                        (examples
                         (let ((explicit-key (pen-vector2list (ht-get yaml-ht "examples"))))
                           (if explicit-key
                               explicit-key
                             examples)))

                        (examples
                         (if (vectorp (car examples))
                             (pen-vector2list (car examples))
                           examples))

                        (preprocessors
                         (let ((explicit-key (pen-vector2list (ht-get yaml-ht "preprocessors"))))
                           (if explicit-key
                               explicit-key
                             preprocessors)))

                        (var-defaults
                         ;; override what was taken from vars
                         ;; only if it exists
                         (let ((explicit-key (pen-vector2list (ht-get yaml-ht "var-defaults"))))
                           (if explicit-key
                               explicit-key
                             var-defaults)))

                        (doc (mapconcat
                              'identity
                              (-filter-not-empty-string
                               (list
                                title
                                (ht-get yaml-ht "doc")
                                (concat "\npath:\n" (pen-list-to-orglist (list path)))
                                (if design-patterns (concat "\ndesign-patterns:\n" (pen-list-to-orglist design-patterns)))
                                (if todo (concat "\ntodo:" (pen-list-to-orglist todo)))
                                (if aims (concat "\naims:" (pen-list-to-orglist aims)))
                                (if engine-stop-sequence-validator (concat "\nengine-stop-sequence-validator:" (str engine-stop-sequence-validator)))
                                (if force-stop-sequence (concat "\nforce-stop-sequence:" (str force-stop-sequence)))
                                (if force-temperature (concat "\nforce-temperature:" (str force-temperature)))
                                (if force-model (concat "\nforce-model:" (str force-model)))
                                (if stop-sequence (concat "\nstop-sequence:" (str stop-sequence)))
                                (if stop-sequences (concat "\nstop-sequences:" (pen-list-to-orglist stop-sequences)))
                                (if engine (concat "\nengine: " engine))
                                (if elisp (concat "\nelisp: " elisp))
                                (if lm-command (concat "\nlm-command: " lm-command))
                                (if model (concat "\nmodel: " model))
                                (if mode (concat "\nmode: " mode))
                                (if n-completions (concat "\nn-completions: " (str n-completions)))
                                (if engine-max-n-completions (concat "\nengine-max-n-completions: " (str engine-max-n-completions)))
                                (if n-collate (concat "\nn-collate: " (str n-collate)))
                                (if n-target (concat "\nn-target: " (str n-target)))
                                (if min-tokens (concat "\nmin-tokens: " (str min-tokens)))
                                (if max-tokens (concat "\nmax-tokens: " (str max-tokens)))
                                (if max-generated-tokens (concat "\nmax-generated-tokens: " (str max-generated-tokens)))
                                (if engine-min-tokens (concat "\nengine-min-tokens: " (str engine-min-tokens)))
                                (if engine-max-tokens (concat "\nengine-max-tokens: " (str engine-max-tokens)))
                                (if engine-whitespace-support
                                    (concat "\nengine-whitespace-support: yes")
                                  (concat "\nengine-whitespace-support: no"))
                                (if inject-gen-start (concat "\ninject-gen-start: " (pps inject-gen-start)))
                                (if task (concat "\ntask: " task))
                                (if notes (concat "\nnotes:" notes))
                                (if filter (concat "\nfilter: on"))
                                (if prepend-previous (concat "\nprepend-previous: on"))
                                (if cant-n-complete (concat "\ncant-n-complete: on"))
                                (if filter-off (concat "\nfilter-off: on"))
                                (if results-analyser (concat "\nresults-analyser: " results-analyser))
                                (if insertion (concat "\ninsertion: on"))
                                (if insertion-off (concat "\ninsertion-off: on"))
                                (if completion (concat "\ncompletion: on"))
                                (if completion-off (concat "\ncompletion-off: on"))
                                (if past-versions (concat "\npast-versions:\n" (pen-list-to-orglist past-versions)))
                                (if external-related (concat "\nexternal-related\n:" (pen-list-to-orglist external-related)))
                                (if related-prompts (concat "\nrelated-prompts:\n" (pen-list-to-orglist related-prompts)))
                                (if future-titles (concat "\nfuture-titles:\n" (pen-list-to-orglist future-titles)))
                                (if examples (concat "\nexamples:\n" (pen-list-to-orglist examples)))
                                (if preprocessors (concat "\npreprocessors:\n" (pen-list-to-orglist preprocessors)))
                                (if pipelines (concat "\npipelines:\n" (pps pipelines)))
                                (if expressions (concat "\nexpressions:\n" (pps expressions)))
                                (if var-defaults (concat "\nvar-defaults:\n" (pen-list-to-orglist var-defaults)))
                                (if prompt-filter (concat "\nprompt-filter:\n" (pen-list-to-orglist (list prompt-filter))))
                                (if postprocessor (concat "\npostprocessor:\n" (pen-list-to-orglist (list postprocessor))))
                                (if validator (concat "\nvalidator:\n" (pen-list-to-orglist (list validator))))
                                (if subprompts (concat "\nsubprompts:\n" (pps subprompts)))
                                (if payloads (concat "\nprompts:\n" (pps payloads)))
                                (if prompt (concat "\nprompt:\n" prompt))))
                              "\n"))

                        (defs (pen--htlist-to-alist (ht-get yaml-ht "defs")))
                        (envs (pen--htlist-to-alist (ht-get yaml-ht "envs")))

                        (var-slugs (mapcar 'slugify vars))
                        (all-var-syms
                         (if (string-equal "search" mode)
                             (cons 'documents (mapcar 'intern var-slugs))
                           (mapcar 'intern var-slugs)))
                        (var-syms
                         (let ((ss (mapcar 'intern var-slugs)))
                           (message (concat "_" prettifier))
                           (if (sor prettifier)
                               ;; Add to the function definition the prettify key if the .prompt file specifies a prettifier
                               (setq ss (append ss '(&key prettify))))
                           ss))
                        (func-name (concat pen-prompt-function-prefix title-slug "/" (str (length all-var-syms))))
                        (func-sym (intern func-name))
                        (alias-names
                         (cl-loop for a in aliases
                                  collect
                                  (concat pen-prompt-function-prefix (slugify a) "/" (str (length all-var-syms)))))
                        (alias-syms
                         (mapcar 'intern alias-names))

                        (examples
                         (cl-loop for e in examples collect
                                  (--> e
                                    (pen-expand-template-keyvals it subprompts-al)
                                    (pen-expand-template-keyvals it (-zip-fill "" vars examples))
                                    (pen-expand-template-keyvals it (-zip-fill "" var-slugs examples)))))

                        (iargs
                         (let ((iteration 0))
                           (cl-loop
                            for tp in (-zip-fill nil var-slugs var-defaults vars)
                            collect
                            (let ((example (or (sor (nth iteration examples)
                                                    "")
                                               ""))
                                  (varslug (car tp))
                                  (default (nth 1 tp))
                                  (varname (nth 2 tp))
                                  (default-readstring-cmd "(read-string-hist (concat title \" \" varname \": \") example)" ))
                              (message "%s" (concat "Example " (str iteration) ": " example))
                              (if (and
                                   (equal 0 iteration)
                                   (not default))
                                  ;; The first argument may be captured through selection
                                  `(if mark-active
                                       (pen-selected-text)
                                     ;; (eval-string default-readstring-cmd)
                                     ;; (read-string-hist ,(concat varslug ": ") ,example)
                                     (read-string-hist ,(concat varslug ": ") ,example)
                                     ;; TODO Find a way to do multiline entry
                                     ;; (if ,(> (length (s-lines example)) 1)
                                     ;;     (multiline-reader ,example)
                                     ;;   (read-string-hist ,(concat v ": ") ,example))
                                     )
                                ;; `(if ,(> (length (s-lines example)) 1)
                                ;;      (pen-etv ,example)
                                ;;    (if ,d
                                ;;        (eval-string ,(str d))
                                ;;      (read-string-hist ,(concat v ": ") ,example)))

                                ;; subprompts are available as variables to var-defaults
                                `(eval
                                  `(let ((func-name ,,func-name))
                                     (pen-let-keyvals
                                      ',',(pen-subprompts-to-alist subprompts)
                                      (if ,,default
                                          ;; This will be tried again later, when more vars are available
                                          (ignore-errors (eval-string ,,(str default)))
                                        (read-string-hist ,,(concat varname ": ") ,,example)))))))
                            do
                            (progn
                              (setq iteration (+ 1 iteration))
                              (message (str iteration))))))

                        (all-iargs
                         (if (string-equal "search" mode)
                             ;; (cons `(eval-string (concat "'" (read-string-hist "documents list:" nil nil nil ,func-name))) iargs)
                             (cons `(read-string-hist "documents list jsonl:" nil nil nil ,func-name) iargs)
                           iargs)))

                     (ht-set yaml-ht "path" path)
                     (ht-set pen-prompts func-name yaml-ht)
                     (add-to-list 'pen-prompt-functions-meta yaml-ht)

                     ;; var names will have to be slugged, too

                     (progn
                       (if (and (not in-development)
                                (sor func-name)
                                func-sym
                                (sor title))
                           (let ((funcsym (define-prompt-function)))
                             (if funcsym
                                 (progn
                                   (add-to-list 'pen-prompt-functions funcsym)
                                   (cl-loop for fn in alias-syms do
                                            (progn
                                              (if (not (eq fn funcsym))
                                                  (defalias fn funcsym))
                                              (add-to-list 'pen-prompt-aliases fn)))
                                   (if interpreter (add-to-list 'pen-prompt-interpreter-functions funcsym))
                                   (if filter (add-to-list 'pen-prompt-filter-functions funcsym))
                                   (if results-analyser (add-to-list 'pen-prompt-analyser-functions funcsym))
                                   (if completion (add-to-list 'pen-prompt-completion-functions funcsym)))
                               (add-to-list 'pen-prompt-functions-failed func-sym))

                             ;; Using memoization here is the more efficient way to memoize.
                             ;; TODO I'll sort it out later. I want an updating mechanism, which exists already using LM_CACHE.
                             ;; (if cache (memoize funcsym))
                             )))
                     (message (concat "pen-mode: Loaded prompt function " func-name)))
                   (add-to-list 'pen-prompts-failed path))))
       (if pen-prompt-functions-failed
           (progn
             (message "failed:")
             (message (pen-list2str pen-prompt-functions-failed))
             (message (concat (str (length pen-prompt-functions-failed)) " failed"))))
       (if pen-prompts-failed
           (progn
             (message "failed:")
             (message (pen-list2str pen-prompts-failed))
             (message (concat (str (length pen-prompts-failed)) " failed"))))))))

(provide 'pen-define-prompt-function)