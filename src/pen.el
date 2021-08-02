;;; pen.el --- Prompt Engineering functions

;; For string-empty-p
(require 'subr-x)
(require 'pen-support)
(require 'pen-global-prefix)
(require 'dash)
(require 'projectile)
(require 'transient)
(require 'iedit)
(require 'ht)
(require 'helm)
(require 'memoize)
(require 'ivy)
(require 'pp)
(require 's)
(require 'cl-macs)
(require 'company)
(require 'selected)
(require 'pcsv)
(require 'pcre2el)

(require 'pen-custom)

(defvar my-completion-engine 'pen-company-filetype)

(defvar pen-map (make-sparse-keymap)
  "Keymap for `pen.el'.")
(defvar-local pen.el nil)

;; Zone plate for Laria
(defvar pen-current-lighter " ⊚")
(defun pen-compose-mode-line ()
  ;; Only change every second
  (let* ((m (mod (second (org-time-since 0)) 10))
         (newlighter
          (cond
           ((eq 0 m) " ☆")
           ((eq 1 m) " ○")
           ((eq 2 m) " ◎")
           ((eq 3 m) " ⊙")
           ((eq 4 m) " ⊚")
           ((eq 5 m) " ◎")
           ((eq 6 m) " ⊙")
           ((eq 7 m) " ⊚")
           ((eq 8 m) " ◎")
           ((eq 9 m) " ○")
           (t " ⊚"))))
    (setq pen-current-lighter newlighter)
    newlighter))

(define-minor-mode pen
  "Mode for working with language models in your buffers."
  :global t
  :init-value t
  ;; zone plate
  :lighter (:eval (pen-compose-mode-line))
  :keymap pen-map)

(defset pen-prompt-functions nil)
(defset pen-prompt-filter-functions nil)
(defset pen-prompt-completion-functions nil)
(defset pen-prompt-functions-meta nil)

(defun pen-yaml-test (yaml key)
  (ignore-errors
    (if (and yaml
             (sor key))
        (ht-get yaml key))))

(defun pen-list-filter-functions ()
  (interactive)
  (let ((funs (-filter (lambda (y) (pen-yaml-test y "filter"))
                       pen-prompt-functions-meta)))
    (if (interactive-p)
        (etv (pps funs))
      funs)))

(defun pen-list-completion-functions ()
  (interactive)
  (let ((funs (-filter (lambda (y) (pen-yaml-test y "completion"))
                       pen-prompt-functions-meta)))
    (if (interactive-p)
        (etv (pps funs))
      funs)))

(defun pen-encode-string (s)
  (->> s
    ;; (string-replace ";" "<pen-semicolon>")
    (string-replace "\"" "<pen-doublequote>")
    (string-replace ":" "<pen-colon>")
    (string-replace "'" "<pen-singlequote>")
    (string-replace "`" "<pen-backtick>")
    (string-replace "\\n" "<pen-notnewline>")
    (string-replace "$" "<pen-dollar>")))

(defun byte-string-search (needle haystack)
  "get byte position or needing in haystack"
  (let ((b (new-buffer-from-string haystack))
        (pos (string-search needle haystack)))
    (if pos
        (with-current-buffer b
          (let ((y (position-bytes pos)))
            (kill-buffer b)
            y))
      (progn
        (kill-buffer b)
        nil))))

(defun pen-expand-template (s vals)
  "expand template from list"
  (let ((i 1))
    (chomp
     (progn
       (cl-loop
        for val in vals do
        (setq s (string-replace (format "<%d>" i) val s))
        (setq i (+ 1 i)))
       s))))

(defun pen-expand-template-keyvals (s keyvals)
  "expand template from alist"
  (let ((i 1))
    (chomp
     (progn
       (cl-loop
        for kv in keyvals do
        (let ((key (str (car kv)))
              (val (str (cdr kv))))
          (setq s (string-replace (format "<%s>" key) val s))
          (setq s (string-replace (format "<%d>" i) val s))
          (setq i (+ 1 i))))
       s))))

(defun pen-prompt-snc (cmd resultnumber)
  "This is like pen-snc but it will memoize the function. resultnumber is necessary because we want n unique results per function"
  (pen-snc cmd))

(defun tee (fp input)
  (sn (cmd "tee" fp) input))

(defun pen-log-final-prompt (prompt)
  (if (f-directory-p penconfdir)
      (tee (f-join penconfdir "last-final-prompt.txt") prompt))
  prompt)

;; Use lexical scope. It's more reliable than lots of params.
;; Expected variables:
;; (func-name func-sym var-syms var-defaults doc prompt
;;  iargs prettifier cache path var-slugs n-collate
;;  filter completion lm-command stop-sequences stop-sequence max-tokens
;;  temperature top-p engine no-trim-start no-trim-end preprocessors
;;  postprocessor prompt-filter n-completions)
;; (let ((max-tokens 1)) (funcall (cl-defun yo () (etv max-tokens))))
;; (let ((max-tokens 1)) (funcall 'pf-asktutor "emacs" "key bindings" "How do I kill a buffer?" :no-select-result t))
(defun define-prompt-function ()
  (eval
   `(cl-defun ,func-sym ,(append '(&optional) var-syms '(&key no-select-result))
      ,doc
      (interactive ,(cons 'list iargs))
      (let* (
             ;; Keep in mind this both updates memoization and the bash cache
             (do-pen-update (pen-var-value-maybe 'do-pen-update))

             (cache
              (and (not do-pen-update)
                   (pen-var-value-maybe 'cache)))

             (final-is-info
              (or (pen-var-value-maybe 'do-etv)
                  (pen-var-value-maybe 'is-info)
                  ,is-info))

             (final-n-collate
              (or (pen-var-value-maybe 'n-collate)
                  ,n-collate))

             (final-n-completions
              (str (or (pen-var-value-maybe 'n-completions)
                       ,n-completions)))

             (subprompts ,subprompts)

             (final-prompt ,prompt)

             (final-max-tokens
              (str (or (pen-var-value-maybe 'max-tokens)
                       ,max-tokens)))

             (final-stop-sequences
              (or (pen-var-value-maybe 'stop-sequences)
                  ',stop-sequences))

             (vals
              ;; If not called interactively then
              ;; manually run interactive expressions
              ;; when they exist.
              (mapcar 'str
                      (if (not (interactive-p))
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

             (var-keyvals (-zip vars vals))
             (var-keyvals-slugged (-zip var-slugs vals))

             ;; template the parameters into the prompt
             (final-prompt
              (pen-expand-template final-prompt vals))
             (final-prompt
              (pen-expand-template-keyvals final-prompt var-keyvals))
             (final-prompt
              (pen-expand-template-keyvals final-prompt var-keyvals-slugged))

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
                    ("PEN_MAX_TOKENS"
                     ,(pen-expand-template final-max-tokens vals))
                    ("PEN_TEMPERATURE" ,(pen-expand-template (str ,temperature) vals))
                    ("PEN_STOP_SEQUENCE"
                     ,(pen-encode-string
                       (str (if (variable-p 'stop-sequence)
                                ;; Make overridable
                                (eval 'stop-sequence)
                              ,stop-sequence))))
                    ("PEN_TOP_P" ,,top-p)
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
                                          (let ((matchpos (string-search stsq r)))
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
          (if (interactive-p)
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
            result))))))

(defun pen-list-to-orglist (l)
  (mapconcat 'identity (mapcar (lambda (s) (concat "- " s)) l)
             "\n"))

(defun test-subprompts ()
  (interactive)
  (let* ((subprompts
          (vector2list
           (ht-get
            (yamlmod-load
             (cat
              (f-join pen-prompts-directory "prompts" "generic-tutor-for-any-topic-and-subtopic.prompt")))
            "subprompts")))
         (keys (type (car (vector2list subprompts)))))

    (etv
     (pps keys))))

;; pdf is prompt description file
;; also, check for a key which specifies that a prompt is only for templating
;; if it doesn't exist, then set not-template
(defun pen-prompt-file-load (fp)
  (let* ((yaml (yamlmod-read-file path))
         (incl-name (ht-get yaml "include")))
    (setq yaml
          (ht-merge (if (sor incl-name)
                        (pen-prompt-file-load incl-name))
                    ;; The last is overriding
                    yaml))
    yaml))

(defun pen-generate-prompt-functions (&optional paths)
  "Generate prompt functions for the files in the prompts directory
Function names are prefixed with pf- for easy searching"
  (interactive)

  (setq pen-prompt-functions nil)
  (setq pen-prompt-filter-functions nil)
  (setq pen-prompt-completion-functions nil)
  (setq pen-prompt-functions-meta nil)

  (noupd
   (let ((paths
          (or paths
              (-non-nil
               (mapcar 'sor (glob (concat pen-prompts-directory "/prompts" "/*.prompt")))))))
     (cl-loop for path in paths do
              (message (concat "pen-mode: Loading .prompt file " path))

              ;; Do a recursive prompt merge from includes
              ;; ht-merge

              ;; results in a hash table
              (let* ((yaml (yamlmod-read-file path))

                     ;; function
                     (title (ht-get yaml "title"))
                     (title-slug (slugify title))
                     (aliases (vector2list (ht-get yaml "aliases")))
                     (alias-slugs (mapcar 'intern (mapcar (lambda (s) (concat pen-prompt-function-prefix s)) (mapcar 'slugify aliases))))

                     ;; lm-complete
                     (cache (pen-yaml-test yaml "cache"))
                     ;; openai-complete.sh is the default LM completion command
                     ;; but the .prompt may specify a different one
                     (lm-command (or
                                  pen-override-lm-command
                                  (ht-get yaml "lm-command")
                                  pen-default-lm-command))

                     (in-development (pen-yaml-test yaml "in-development"))

                     ;; internals
                     (prompt (ht-get yaml "prompt"))
                     (subprompts
                      (let ((subprompts (ht-get yaml "subprompts")))
                        (if subprompts
                            (vector2list subprompts))))
                     (is-info (ht-get yaml "is-info"))
                     (repeater (ht-get yaml "repeater"))
                     (prefer-external (pen-yaml-test yaml "prefer-external"))
                     (conversation-mode (pen-yaml-test yaml "conversation-mode"))
                     (filter (pen-yaml-test yaml "filter"))
                     ;; Don't actually use this.
                     ;; But I can toggle to use the prettifier with a bool
                     (prettifier (ht-get yaml "prettifier"))
                     (collation-postprocessor (ht-get yaml "pen-collation-postprocessor"))
                     (completion (pen-yaml-test yaml "completion"))
                     (insertion (pen-yaml-test yaml "insertion"))
                     (no-trim-start (or (pen-yaml-test yaml "no-trim-start")
                                        (pen-yaml-test yaml "completion")))
                     (no-trim-end (pen-yaml-test yaml "no-trim-end"))
                     (examples (vector2list (ht-get yaml "examples")))
                     (preprocessors (vector2list (ht-get yaml "preprocessors")))
                     (prompt-filter (ht-get yaml "prompt-filter"))
                     (postprocessor (ht-get yaml "postprocessor"))
                     (n-collate (or (ht-get yaml "n-collate")
                                    1))
                     (n-completions (or (ht-get yaml "n-completions")
                                        5))
                     (n-test-runs (ht-get yaml "n-test-runs"))

                     ;; API
                     (engine (ht-get yaml "engine"))
                     (max-tokens (ht-get yaml "max-tokens"))
                     (top-p (ht-get yaml "top-p"))
                     (temperature (ht-get yaml "temperature"))
                     (stop-sequences (or (vector2list (ht-get yaml "stop-sequences"))
                                         (list "\n")))
                     (stop-sequence (if stop-sequences (car stop-sequences)))

                     ;; docs
                     (problems (vector2list (ht-get yaml "problems")))
                     (design-patterns (vector2list (ht-get yaml "design-patterns")))
                     (todo (vector2list (ht-get yaml "todo")))
                     (notes (vector2list (ht-get yaml "notes")))
                     (aims (vector2list (ht-get yaml "aims")))
                     (past-versions (vector2list (ht-get yaml "past-versions")))
                     (external-related (vector2list (ht-get yaml "external-related")))
                     (related-prompts (vector2list (ht-get yaml "related-prompts")))
                     (future-titles (vector2list (ht-get yaml "future-titles")))

                     (var-defaults (vector2list (ht-get yaml "var-defaults")))

                     (doc (mapconcat
                           'identity
                           (-filter-not-empty-string
                            (list
                             title
                             (ht-get yaml "doc")
                             (concat "\npath:\n" (pen-list-to-orglist (list path)))
                             (if design-patterns (concat "\ndesign-patterns:\n" (pen-list-to-orglist design-patterns)))
                             (if todo (concat "\ntodo:" (pen-list-to-orglist todo)))
                             (if aims (concat "\naims:" (pen-list-to-orglist aims)))
                             (if notes (concat "\nnotes:" (pen-list-to-orglist notes)))
                             (if filter (concat "\nfilter: on"))
                             (if completion (concat "\ncompletion: on"))
                             (if past-versions (concat "\npast-versions:\n" (pen-list-to-orglist past-versions)))
                             (if external-related (concat "\nexternal-related\n:" (pen-list-to-orglist external-related)))
                             (if related-prompts (concat "\nrelated-prompts:\n" (pen-list-to-orglist related-prompts)))
                             (if future-titles (concat "\nfuture-titles:\n" (pen-list-to-orglist future-titles)))
                             (if examples (concat "\nexamples:\n" (pen-list-to-orglist examples)))
                             (if preprocessors (concat "\npreprocessors:\n" (pen-list-to-orglist preprocessors)))
                             (if var-defaults (concat "\nvar-defaults:\n" (pen-list-to-orglist var-defaults)))
                             (if prompt-filter (concat "\nprompt-filter:\n" (pen-list-to-orglist (list prompt-filter))))
                             (if postprocessor (concat "\npostprocessor:\n" (pen-list-to-orglist (list postprocessor))))))
                           "\n"))

                     ;; variables
                     (vars (vector2list (ht-get yaml "vars")))
                     (examples (vector2list (ht-get yaml "examples")))
                     (var-slugs (mapcar 'slugify vars))
                     (var-syms
                      (let ((ss (mapcar 'intern var-slugs)))
                        (message (concat "_" prettifier))
                        (if (sor prettifier)
                            ;; Add to the function definition the prettify key if the .prompt file specifies a prettifier
                            (setq ss (append ss '(&key prettify))))
                        ss))
                     (func-name (concat pen-prompt-function-prefix title-slug))
                     (func-sym (intern func-name))
                     (iargs
                      (let ((iteration 0))
                        (cl-loop
                         for tp in (-zip-fill nil var-slugs var-defaults)
                         collect
                         (let ((example (or (sor (nth iteration examples)
                                                 "")
                                            ""))
                               (v (car tp))
                               (d (cdr tp)))
                           (message "%s" (concat "Example " (str iteration) ": " example))
                           (if (and
                                (equal 0 iteration)
                                (not d))
                               ;; The first argument may be captured through selection
                               `(if mark-active
                                    (pen-selected-text)
                                  (read-string-hist ,(concat v ": ") ,example)
                                  ;; TODO Find a way to do multiline entry
                                  ;; (if ,(> (length (s-lines example)) 1)
                                  ;;     (multiline-reader ,example)
                                  ;;   (read-string-hist ,(concat v ": ") ,example))
                                  )
                             ;; `(if ,(> (length (s-lines example)) 1)
                             ;;      (etv ,example)
                             ;;    (if ,d
                             ;;        (eval-string ,(str d))
                             ;;      (read-string-hist ,(concat v ": ") ,example)))
                             `(if ,d
                                  (eval-string ,(str d))
                                (read-string-hist ,(concat v ": ") ,example))))
                         do
                         (progn
                           (setq iteration (+ 1 iteration))
                           (message (str iteration)))))))

                (add-to-list 'pen-prompt-functions-meta yaml)

                ;; var names will have to be slugged, too

                (if alias-slugs
                    (cl-loop for a in alias-slugs do
                             (progn
                               (defalias a func-sym)
                               (add-to-list 'pen-prompt-functions a)
                               (if filter
                                   (add-to-list 'pen-prompt-filter-functions a))
                               (if completion
                                   (add-to-list 'pen-prompt-completion-functions a)))))

                (try
                 (progn
                   (if (and (not in-development)
                            (sor func-name)
                            func-sym
                            (sor title))
                       (let ((funcsym (define-prompt-function)))
                         (add-to-list 'pen-prompt-functions funcsym)
                         (if filter (add-to-list 'pen-prompt-filter-functions funcsym))
                         (if completion (add-to-list 'pen-prompt-completion-functions funcsym))

                         ;; Using memoization here is the more efficient way to memoize.
                         ;; TODO I'll sort it out later. I want an updating mechanism, which exists already using LM_CACHE.
                         ;; (if cache (memoize funcsym))
                         )))
                 (message (concat "pen-mode: Loaded prompt function " func-name))))))))

(defun pen-filter-with-prompt-function ()
  (interactive)
  (let ((f (fz
            (if (>= (prefix-numeric-value current-prefix-arg) 4)
                pen-prompt-functions
              ;; (pen-list-filter-functions)
              pen-prompt-filter-functions)
            nil nil "pen filter: ")))
    (if f
        (let ((filter t))
          (call-interactively (intern f)))
      ;; (filter-selected-region-through-function (intern f))
      )))

(defun pen-run-prompt-function ()
  (interactive)
  (let* ((pen-sh-update (or pen-sh-update (>= (prefix-numeric-value current-global-prefix-arg) 4)))
         (f (fz pen-prompt-functions nil nil "pen run: ")))
    (if f
        (call-interactively (intern f)))))

(defun pen-company-filetype--candidates (prefix)
  (let* ((preceding-text (pen-preceding-text))
         (response
          (cond
           ((>= (prefix-numeric-value current-prefix-arg) 64)
            (pen-words-complete-nongreedy
             (-->
                 preceding-text
               (pen-complete-function it :no-select-result t))))
           ((>= (prefix-numeric-value current-prefix-arg) 16)
            (pen-word-complete-nongreedy
             (-->
                 preceding-text
               (pen-complete-function it :no-select-result t))))
           ((>= (prefix-numeric-value current-prefix-arg) 4)
            (pen-long-complete-nongreedy
             (-->
                 preceding-text
               (pen-complete-function it :no-select-result t))))
           (t
            (pen-line-complete-nongreedy
             (-->
                 preceding-text
               (pen-complete-function it :no-select-result t))))))
         (res
          response))

    (mapcar (lambda (s) (concat (pen-company-filetype--prefix) s))
            res)))

(defun pen-completion-at-point ()
  (interactive)
  (call-interactively 'completion-at-point)
  (if (>= (prefix-numeric-value current-prefix-arg) 4)
      (call-interactively 'pen-company-filetype)
    (call-interactively 'completion-at-point)))

;; This results in 50
;; (let ((alpha 50))
;;   (let ((alpha (or alpha 100)))
;;     (message (str alpha))))

(defmacro pen-update (&rest body)
  "This wraps around pen function calls to make them update the memoization"
  `(eval
    `(let ((do-pen-update t))
       ,',@body)))

(defmacro pen-batch (&rest body)
  "This wraps around pen function calls to make them batch-mode"
  `(eval
    `(let ((do-pen-batch t))
       ,',@body)))

(defmacro pen-single-generation (&rest body)
  "This wraps around pen function calls to make them only create one generation"
  `(eval
    `(let ((pen-single-generation-b t)
           (n-collate 1)
           (n-completions 1))
       ,',@body)))

;; This wasn't sufficient. To make it work from the Host interop and from the minibuffer, I need eval
(comment
 (defmacro pen-long-complete (&rest body)
   "This wraps around pen function calls to make them complete long"
   `(let ((max-tokens 200)
          (stop-sequence "##long complete##")
          (stop-sequences '("##long complete##")))
      ,@body)))

(defmacro pen-words-complete (&rest body)
  "This wraps around pen function calls to make them complete long"
  `(eval
    `(let ((max-tokens 5)
           (stop-sequence "##long complete##")
           (stop-sequences '("##long complete##"))
           (n-collate 1)
           (n-completions 20))
       ,',@body)))

(defmacro pen-words-complete-nongreedy (&rest body)
  "This wraps around pen function calls to make them complete long"
  `(eval
    `(let ((max-tokens 5)
           (stop-sequence (or (and (variable-p 'stop-sequence)
                                   (eval 'stop-sequence))
                              "##long complete##"))
           (stop-sequences (or (and (variable-p 'stop-sequences)
                                    (eval 'stop-sequences))
                               '("##long complete##")))
           (n-collate 1)
           (n-completions 20))
       ,',@body)))

(defmacro pen-word-complete (&rest body)
  "This wraps around pen function calls to make them complete long"
  `(eval
    `(let ((max-tokens 1)
           (stop-sequence "##long complete##")
           (stop-sequences '("##long complete##"))
           (n-collate 1)
           (n-completions 40))
       ,',@body)))

(defmacro pen-word-complete-nongreedy (&rest body)
  "This wraps around pen function calls to make them complete long"
  `(eval
    `(let ((max-tokens 1)
           (stop-sequence (or (and (variable-p 'stop-sequence)
                                   (eval 'stop-sequence))
                              "##long complete##"))
           (stop-sequences (or (and (variable-p 'stop-sequences)
                                    (eval 'stop-sequences))
                               '("##long complete##")))
           (n-collate 1)
           (n-completions 40))
       ,',@body)))

(defmacro pen-long-complete (&rest body)
  "This wraps around pen function calls to make them complete long"
  `(eval
    `(let ((max-tokens 200)
           (stop-sequence "##long complete##")
           (stop-sequences '("##long complete##")))
       ,',@body)))
(defmacro pen-long-complete-nongreedy (&rest body)
  "This wraps around pen function calls to make them complete long"
  `(eval
    `(let ((max-tokens 200)
           (stop-sequence (or (and (variable-p 'stop-sequence)
                                   (eval 'stop-sequence))
                              "##long complete##"))
           (stop-sequences (or (and (variable-p 'stop-sequences)
                                    (eval 'stop-sequences))
                               '("##long complete##"))))
       ,',@body)))

(defmacro pen-line-complete (&rest body)
  "This wraps around pen function calls to make them complete line only"
  `(eval
    `(let ((max-tokens 100)
           (stop-sequence "\n")
           (stop-sequences '("\n")))
       ,',@body)))

(defmacro pen-line-complete-nongreedy (&rest body)
  "This wraps around pen function calls to make them complete line only"
  `(eval
    `(let ((max-tokens 100)
          (stop-sequence (or (and (variable-p 'stop-sequence)
                                  (eval 'stop-sequence))
                             "\n"))
          (stop-sequences (or (and (variable-p 'stop-sequences)
                                   (eval 'stop-sequences))
                              '("\n"))))
      ,',@body)))

(defun pen-complete-function (preceding-text &rest args)
  (if (and (derived-mode-p 'prog-mode)
           (not (string-equal (buffer-name) "*scratch*")))
      (eval `(pf-generic-file-type-completion (pen-detect-language) preceding-text ,@args))
    (eval `(pf-generic-completion-50-tokens preceding-text ,@args))))

(defun pen-complete-long (preceding-text &optional tv)
  "Long-form completion. This will generate lots of text.
May use to generate code from comments."
  (interactive (list (pen-preceding-text) nil))
  (let ((response
         (pen-long-complete
          (pen-complete-function preceding-text))))
    (if tv
        (etv response)
      (insert response))))

(defun pen-cmd-q (&rest args)
  (s-join " " (mapcar 'pen-q (mapcar 'str args))))

(defun pen-compose-cli-command ()
  "This composes a command to run on the CLI"
  (interactive)
  (let* ((f (fz pen-prompt-functions nil nil "pen compose cli command: "))
         (sig (eval-string
               (concat
                "(apply 'pen-cmd-q '"
                (string-replace
                 " &optional" ""
                 (s-replace-regexp
                  " &key.*" ")"
                  (helpful--signature (intern f))))
                ")"))))
    (if f
        (xc (concat "pen " sig)))))

(require 'pen-core)
(require 'pen-openai)
(require 'pen-copilot)
(require 'pen-memoize)
(require 'pen-ivy)
(require 'pen-ink)
(require 'pen-company)
(require 'pen-library)
(require 'pen-selected)
(require 'pen-right-click-menu)
(require 'pen-mouse)
(require 'pen-configure)
(require 'pen-prompt-description)
(require 'pen-completer-description)
(require 'pen-lm-completers)
(require 'pen-emacs)
(require 'pen-acolyte-minor-mode)
(require 'pen-gptprompts)
;; For debugging
(require 'pen-messages)
(require 'pen-yaml)
(require 'pen-glossary)
(require 'pen-diagnostics)
(require 'pen-examplary)

(add-to-list 'auto-mode-alist '("\\.prompt\\'" . prompt-description-mode))

(provide 'pen)
