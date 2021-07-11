;;; pen.el --- Prompt Engineering functions

;; For string-empty-p
(require 'subr-x)
(require 'pen-support)
(require 'pen-global-prefix)
(require 'dash)
(require 'projectile)
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

(defvar my-completion-engine 'company-pen-filetype)

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
(defset pen-prompt-functions-meta nil)

(defun pen-yaml-test (yaml key)
  (ignore-errors
    (if (and yaml
             (sor key))
        (let ((c (ht-get yaml key)))
          (and (sor c)
               (string-equal c "on"))))))

;; This is just so I get syntax highlighting for defpf in emacs
(defmacro defpf (&rest body)
  `(define-prompt-function
     ,@body))

(defun define-prompt-function (func-name func-sym var-syms doc prompt iargs prettifier cache path var-slugs n-collate filter completion
                                         lm-command stop-sequences stop-sequence max-tokens temperature top-p engine
                                         no-trim-start no-trim-end
                                         preprocessors postprocessor
                                         n-completions)
  (eval
   `(cl-defun ,func-sym ,var-syms
      ,doc
      (interactive ,(cons 'list iargs))
      (let* ((final-prompt ,prompt)

             ;; preprocess the values of the parameters
             (vals
              (cl-loop
               for tp in
               (-zip-fill nil ',var-syms ',preprocessors)
               collect
               (let* ((sym (car tp))
                      (pp (cdr tp))
                      (initval (eval sym)))
                 (if pp
                     (sn pp initval)
                   initval))))

             ;; template the parameters into the prompt
             (i 1)
             (final-prompt
              (chomp
               (progn
                 (cl-loop
                  for val in vals do
                  (setq final-prompt (string-replace (format "<%d>" i) val final-prompt))
                  (setq i (+ 1 i)))
                 final-prompt)))

             (prompt-end-pos (or (string-search "<:pp>" ,prompt)
                                 (length final-prompt)))

             (final-prompt (string-replace "<:pp>" "" final-prompt))

             ;; check for cache update
             (pen-sh-update
              (or pen-sh-update (>= (prefix-numeric-value current-global-prefix-arg) 4)))

             ;; construct the full command
             (shcmd
              (concat
               ;; All parameters are sent as environment variables
               (sh-construct-envs
                ;; This is a bit of a hack for \n in prompts
                `(("PEN_PROMPT" ,(tv (string-replace "\\n" "<pen-notnewline>" final-prompt)))
                  ("PEN_LM_COMMAND" ,,lm-command)
                  ("PEN_ENGINE" ,,engine)
                  ("PEN_MAX_TOKENS" ,,max-tokens)
                  ("PEN_TEMPERATURE" ,,temperature)
                  ("PEN_STOP_SEQUENCE" ,,stop-sequence)
                  ("PEN_TOP_P" ,,top-p)
                  ("PEN_CACHE" ,,cache)
                  ("PEN_N_COMPLETIONS" ,,n-completions)
                  ("PEN_END_POS" ,prompt-end-pos)))
               " "
               "lm-complete"))
             ;; http://cl-cookbook.sourceforge.net/loop.html
             ;; (var-vals
             ;;  (cl-loop
             ;;   for vs in ',var-syms
             ;;   collect
             ;;   ))

             ;; run the completion command and collect the result
             (resultsdirs
              (cl-loop
               for i in (number-sequence 1 ,n-collate)
               collect
               (progn
                 (message (concat ,func-name " query " (int-to-string i) "..."))
                 ;; TODO Also handle PEN_N_COMPLETIONS
                 (let ((ret (pen-snc shcmd)))
                   (message (concat ,func-name " done " (int-to-string i)))
                   ret))))

             (results
              (-uniq
               (flatten-once
                (cl-loop for rd in resultsdirs
                         collect
                         (->> (glob (concat rd "/*"))
                           (mapcar 'e/cat)
                           (mapcar (lambda (r) (if (not ,no-trim-start) (s-trim-left r) r)))
                           (mapcar (lambda (r) (if (not ,no-trim-end) (s-trim-right r) r)))
                           (mapcar (lambda (r) (if (and ,postprocessor (sor ,postprocessor)) (pen-sn ,postprocessor r) r)))
                           (mapcar (lambda (r) (if (and (variable-p 'prettify)
                                                        prettify
                                                        ,prettifier
                                                        (sor ,prettifier))
                                                   (pen-sn ,prettifier r)
                                                 r))))))))

             ;; (result
             ;;  (progn
             ;;    (cl-loop
             ;;     for stsq in ,stop-sequences do
             ;;     (let ((matchpos (string-search stsq result)))
             ;;       (if matchpos
             ;;           (setq stsq (s-truncate matchpos result "")))))
             ;;    result))

             (result (cl-fz results :prompt (concat ,func-name ": ") :select-only-match t)))
        (if (interactive-p)
            (cond
             ((and ,filter
                   mark-active)
              (replace-region (concat (pen-selected-text) result)))
             (,completion
              (etv result))
             ((or ,(not filter)
                  (>= (prefix-numeric-value current-prefix-arg) 4)
                  (not mark-active))
              (etv result))
             (t
              (replace-region result)))
          result)))))

(defun pen-list-to-orglist (l)
  (mapconcat 'identity (mapcar (lambda (s) (concat "- " s)) l)
             "\n"))

(defun pen-generate-prompt-functions ()
  "Generate prompt functions for the files in the prompts directory
Function names are prefixed with pen-pf- for easy searching"
  (interactive)
  (noupd
   (let ((paths
          (-non-nil (mapcar 'sor (glob (concat pen-prompt-directory "/*.prompt"))))))
     (cl-loop for path in paths do
              (message (concat "pen-mode: Loading .prompt file " path))

              ;; results in a hash table
              (let* ((yaml (yamlmod-read-file path))

                     ;; function
                     (title (ht-get yaml "title"))
                     (title-slug (slugify title))
                     (aliases (vector2list (ht-get yaml "aliases")))
                     (alias-slugs (mapcar 'intern (mapcar (lambda (s) (concat "pen-pf-" s)) (mapcar 'slugify aliases))))

                     ;; lm-complete
                     (cache (pen-yaml-test yaml "cache"))
                     ;; openai-complete.sh is the default LM completion command
                     ;; but the .prompt may specify a different one
                     (lm-command (or (ht-get yaml "lm-command")
                                     "openai-complete.sh"))

                     (in-development (pen-yaml-test yaml "in-development"))

                     ;; internals
                     (prompt (ht-get yaml "prompt"))
                     (prefer-external (pen-yaml-test yaml "prefer-external"))
                     (conversation-mode (pen-yaml-test yaml "conversation-mode"))
                     (filter (pen-yaml-test yaml "filter"))
                     ;; Don't actually use this.
                     ;; But I can toggle to use the prettifier with a bool
                     (prettifier (ht-get yaml "prettifier"))
                     (collation-postprocessor (ht-get yaml "pen-collation-postprocessor"))
                     (completion (pen-yaml-test yaml "completion"))
                     (no-trim-start (pen-yaml-test yaml "no-trim-start"))
                     (no-trim-end (pen-yaml-test yaml "no-trim-end"))
                     (preprocessors (vector2list (ht-get yaml "preprocessors")))
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
                     (doc (mapconcat
                           'identity
                           (-filter-not-empty-string
                            (list
                             title
                             (ht-get yaml "doc")
                             (if design-patterns (concat "\ndesign-patterns:\n" (pen-list-to-orglist design-patterns)))
                             (if todo (concat "\ntodo:" (pen-list-to-orglist todo)))
                             (if aims (concat "\naims:" (pen-list-to-orglist aims)))
                             (if notes (concat "\nnotes:" (pen-list-to-orglist notes)))
                             (if past-versions (concat "\npast-versions:\n" (pen-list-to-orglist past-versions)))
                             (if external-related (concat "\nexternal-related\n:" (pen-list-to-orglist external-related)))
                             (if related-prompts (concat "\nrelated-prompts:\n" (pen-list-to-orglist related-prompts)))
                             (if future-titles (concat "\nfuture-titles:\n" (pen-list-to-orglist future-titles)))
                             (if preprocessors (concat "\npreprocessors:\n" (pen-list-to-orglist preprocessors)))
                             (if postprocessor (concat "\npostprocessor:\n" (pen-list-to-orglist (list postprocessor))))))
                           "\n"))

                     ;; variables
                     (vars (vector2list (ht-get yaml "vars")))
                     (examples (vector2list (ht-get yaml "examples")))
                     (preprocessors (vector2list (ht-get yaml "pen-preprocessors")))
                     (var-slugs (mapcar 'slugify vars))
                     (var-syms
                      (let ((ss (mapcar 'intern var-slugs)))
                        (message (concat "_" prettifier))
                        (if (sor prettifier)
                            ;; Add to the function definition the prettify key if the .prompt file specifies a prettifier
                            (setq ss (append ss '(&key prettify))))
                        ss))
                     (var-defaults (vector2list (ht-get yaml "var-defaults")))
                     (func-name (concat "pen-pf-" title-slug))
                     (func-sym (intern func-name))
                     (iargs
                      (let ((iteration 0))
                        (cl-loop for v in vars
                                 collect
                                 (let ((example (or (sor (nth iteration examples)
                                                         "")
                                                    "")))
                                   (message "%s" (concat "Example " (str iteration) ": " example))
                                   (if (equal 0 iteration)
                                       ;; The first argument may be captured through selection
                                       `(if mark-active
                                            (pen-selected-text)
                                          (if ,(> (length (s-lines example)) 1)
                                              (etv ,example)
                                            (read-string-hist ,(concat v ": ") ,example)))
                                     `(if ,(> (length (s-lines example)) 1)
                                          (etv ,example)
                                        (read-string-hist ,(concat v ": ") ,example))))
                                 do
                                 (progn
                                   (setq iteration (+ 1 iteration))
                                   (message (str iteration)))))))

                (add-to-list 'pen-prompt-functions-meta yaml)

                (if completion
                    nil
                  ;; TODO Add to company-mode completion functions
                  )

                ;; var names will have to be slugged, too

                (if alias-slugs
                    (cl-loop for a in alias-slugs do
                             (progn
                               (defalias a func-sym)
                               (add-to-list 'pen-prompt-functions a))))

                (if (and (not in-development)
                         (sor func-name)
                         func-sym
                         (sor title))
                    (let ((funcsym (defpf
                                     func-name func-sym var-syms doc
                                     prompt iargs prettifier
                                     cache path var-slugs n-collate
                                     filter completion lm-command
                                     stop-sequences stop-sequence
                                     max-tokens temperature top-p engine
                                     no-trim-start no-trim-end
                                     preprocessors postprocessor
                                     n-completions)))
                      (add-to-list 'pen-prompt-functions funcsym)
                      ;; Using memoization here is the more efficient way to memoize.
                      ;; TODO I'll sort it out later. I want an updating mechanism, which exists already using LM_CACHE.
                      ;; (if cache (memoize funcsym))
                      ))
                (message (concat "pen-mode: Loaded prompt function " func-name)))))))

(defun pen-filter-with-prompt-function ()
  (interactive)
  (let ((f (fz pen-prompt-functions nil nil "pen filter: ")))
    (if f
        (filter-selected-region-through-function (intern f)))))

(defun pen-run-prompt-function ()
  (interactive)
  (let* ((pen-sh-update (or pen-sh-update (>= (prefix-numeric-value current-global-prefix-arg) 4)))
         (f (fz pen-prompt-functions nil nil "pen run: ")))
    (if f
        (call-interactively (intern f)))))

(defun company-pen-filetype--candidates (prefix)
  (let* ((preceding-text (pen-preceding-text))
         (response
          (->>
              preceding-text
            (pen-pf-generic-file-type-completion (detect-language))))
         (res
          (list response)))
    (mapcar (lambda (s) (concat (company-pen-filetype--prefix) s))
            res)))

(defun my-completion-at-point ()
  (interactive)
  (call-interactively 'completion-at-point)
  (if (>= (prefix-numeric-value current-prefix-arg) 4)
      (call-interactively 'company-pen-filetype)
    (call-interactively 'completion-at-point)))

(defun pen-complete-long (preceding-text &optional tv)
  "Long-form completion. This will generate lots of text.
May use to generate code from comments."
  (interactive (list (str (buffer-substring (point) (max 1 (- (point) 1000))))
                     t))
  (let* ((response (pen-pf-generic-file-type-completion (detect-language) preceding-text)))
    (if tv
        (etv response)
      response)))

;; http://github.com/semiosis/pen.el/blob/master/pen-core.el
(require 'pen-core)

;; http://github.com/semiosis/pen.el/blob/master/pen-ivy.el
(require 'pen-ivy)

;; http://github.com/semiosis/pen.el/blob/master/pen-company.el
(require 'pen-company)

;; http://github.com/semiosis/pen.el/blob/master/pen-library.el
(require 'pen-library)

;; http://github.com/semiosis/pen.el/blob/master/pen-contrib.el
(require 'pen-contrib)

;; http://github.com/semiosis/pen.el/blob/master/pen-prompt-description.el
(require 'pen-prompt-description)

;; TODO
(require 'pen-openai)
(require 'pen-ocean)
(require 'pen-huggingface)

(provide 'pen)