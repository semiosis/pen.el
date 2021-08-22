;;; pen.el --- Prompt Engineering functions

;; For string-empty-p
(require 'subr-x)
(require 'pen-regex)
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
(require 'asoc)

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
(defset pen-prompt-interpreter-functions nil)
(defset pen-prompt-filter-functions nil)
(defset pen-prompt-functions-failed nil)
(defset pen-prompts-failed nil)
(defset pen-prompt-completion-functions nil)
(defset pen-prompt-functions-meta nil)

(defun pen-yaml-test (yaml-ht key)
  (ignore-errors
    (if (and yaml-ht
             (sor key))
        (ht-get yaml-ht key))))

(defun pen-test-translate-prompt ()
  (interactive)
  (let
      ((from-language "English")
       (to-language "French")
       (topic "Dictionary")
       (prompt "Glossary of terms.\n\nossified\nDefinition: Turn into bone or bony tissue.\n\n<1>\nDefinition:\n"))
    (pen-etv
     (pen-single-generation
      (wrlp
       prompt
       (pf-translate-from-world-language-x-to-y/3
        from-language
        to-language))))))

(defun pen-translate-prompt ()
  "Select a prompt file and translate it.
Reconstruct the entire yaml-ht for a different language."
  (interactive)

  (cl-macrolet ((translate
                 (input)
                 `(eval
                   `(let ((from-language ,from-lang)
                          (to-language ,to-lang)
                          (topic ,topic)
                          (input ,,input))
                      (if input
                          (pen-single-generation ,translator))))))
    (let* ((fname (fz pen-prompt-functions nil nil "pen translate prompt: "))
           (yaml-ht (ht-get pen-prompts fname))
           (prompt (ht-get yaml-ht "prompt"))
           (title (ht-get yaml-ht "title"))
           (task (ht-get yaml-ht "task"))
           (doc (ht-get yaml-ht "doc"))
           (topic (ht-get yaml-ht "topic"))
           (vars (vector2list (ht-get yaml-ht "vars")))
           (var-slugs (mapcar 'slugify vars))
           (examples-list (vector2list (ht-get yaml-ht "examples")))
           (from-lang (ht-get yaml-ht "language"))
           (from-lang (or from-lang (read-string-hist ".prompt Origin Language: ")))
           (to-lang (read-string-hist ".prompt Destination Language: "))
           (translator (let ((tlr (ht-get yaml-ht "translator")))
                         (if (and
                              (sor tlr)
                              (not (string-match "^(" tlr)))
                             ;; if it's a shell script, convert it to elisp
                             (setq tlr
                                   (format
                                    "(pen-sn %s prompt)"
                                    (pen-q
                                     (pen-expand-template-keyvals
                                      tlr
                                      '(("from-language" . (pen-q from-lang))
                                        ("from language" . (pen-q from-lang))
                                        ("to-language" . (pen-q to-lang))
                                        ("to language" . (pen-q to-lang))
                                        ("topic" . (pen-q topic))
                                        ;; It's called 'input' and not 'prompt' because
                                        ;; we could translate other fields, such as variable names
                                        ("input" . (pen-q prompt))))))))
                         tlr))
           (translator (or translator
                           (fz pen-translators nil nil "Select a prompt translator: ")))
           (translator (pen-eval-string
                        (concat "'" translator))))

      (if translator
          (let* ((new-prompt (translate prompt))
                 (new-title (translate title))
                 (new-task (translate task))
                 (new-topic (translate topic))
                 (new-doc (translate doc))
                 ;; is there a mapcar for macros?
                 (new-vars (loop for v in vars collect
                                 (translate v)))
                 ;; (new-var-slugs (mapcar 'slugify new-vars))
                 (new-examples
                  (if (vectorp (car examples-list))
                      (mapcar
                       (lambda (v)
                         (loop for e in (vector2list v) collect
                               (translate e)))
                       examples-list)
                    (loop for e in examples-list collect
                          (translate e))))
                 (new-prompt
                  (pen-expand-template-keyvals
                   new-prompt
                   (-zip vars (mapcar (lambda (s) (format "<%s>" s)) new-vars))))
                 (newht (let ((h (make-hash-table :test 'equal)))
                          (ht-set h "prompt" new-prompt)
                          (ht-set h "title" new-title)
                          (ht-set h "task" new-task)
                          (ht-set h "doc" new-doc)
                          (ht-set h "examples" new-examples)
                          (ht-set h "topic" new-topic)
                          (ht-set h "vars" new-vars)
                          (ht-merge yaml-ht h)))
                 (newyaml (plist2yaml (ht->plist newht))))
            (new-buffer-from-string
             newyaml
             "*new prompt*"
             'prompt-description-mode)))
      ;; (ht-get pen-prompts "pf-define-word/1")
      ;; (ht-get pen-prompts 'pf-define-word-for-glossary/1)
      )))

(defun pen-list-filter-functions ()
  (interactive)
  (let ((funs (-filter (lambda (y) (pen-yaml-test y "filter"))
                       pen-prompt-functions-meta)))
    (if (interactive-p)
        (pen-etv (pps funs))
      funs)))

(defun pen-list-completion-functions ()
  (interactive)
  (let ((funs (-filter (lambda (y) (pen-yaml-test y "completion"))
                       pen-prompt-functions-meta)))
    (if (interactive-p)
        (pen-etv (pps funs))
      funs)))

(defun pen-encode-string (s)
  (->> s
    ;; (string-replace ";" "<pen-semicolon>")
    (string-replace "\"" "<pen-doublequote>")
    (string-replace ":" "<pen-colon>")
    (string-replace "'" "<pen-singlequote>")
    (string-replace "`" "<pen-backtick>")
    (string-replace "!" "<pen-bang>")
    (string-replace "\\n" "<pen-notnewline>")
    (string-replace "$" "<pen-dollar>")))

;; This is necessary because the string-search
;; command is not available in emacs27
(defun pen-string-search (needle haystack &optional start-pos)
  (setq start-pos (or start-pos 0))
  (let ((results (s-matched-positions-all needle haystack)))
    (cl-loop for tp in results
             if (>= (car tp) start-pos)
             return (car tp))))

(defun pen-byte-pos ()
  (position-bytes (point)))

(defun byte-string-search (needle haystack)
  "get byte position or needing in haystack"
  (let ((b (new-buffer-from-string haystack))
        (pos (pen-string-search needle haystack)))
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
  (if vals
      (let ((i 1))
        (chomp
         (progn
           (cl-loop
            for val in vals do
            (setq s (string-replace (format "<%d>" i) (chomp val) s))
            (setq i (+ 1 i)))
           s)))
    s))

(defun pen-test-expand-keyvals ()
  (interactive)
  (pen-etv (pen-expand-template-keyvals " <y> <thing> " '(("thing" . "yo")
                                                          ("y" . "n")))))

(defun pen-test-expand-zip-two-lists ()
  (interactive)
  (pen-etv (pen-expand-template-keyvals " <y> <thing> "
                                        (-zip '("thing" "y") '("yo" "n")))))

(defun pen-expand-template-keyvals (s keyvals)
  "expand template from alist"
  (if keyvals
      (let ((i 1))
        (chomp
         (progn
           (cl-loop
            for kv in keyvals do
            (let ((key (str (car kv)))
                  (val (str (cdr kv))))
              (setq s (string-replace (format "<%s>" key) (chomp val) s))
              ;; (setq s (string-replace (format "<%d>" i) val s))
              (setq i (+ 1 i))))
           s)))
    s))

(defun pen-prompt-snc (cmd resultnumber)
  "This is like pen-snc but it will memoize the function. resultnumber is necessary because we want n unique results per function"
  (if (f-directory-p penconfdir)
      (tee (f-join penconfdir "last-final-command.txt") cmd))
  (pen-snc cmd))

(defun pen-list2cmd (l)
  (pen-snc (concat "cmd-nice-posix " (mapconcat 'pen-q l " "))))

(defun pen-cmd (&rest args)
  (pen-list2cmd args))

(defun tee (fp input)
  (pen-sn (pen-cmd "tee" fp) input))

(defun pen-log-final-prompt (prompt)
  (if (f-directory-p penconfdir)
      (tee (f-join penconfdir "last-final-prompt.txt") prompt))
  prompt)

(defun test-template-newlines ()
  (interactive)
  (--> "\n"
    (pen-onelineify it)
    (pen-expand-template-keyvals it '((:myval "hi")))
    (pen-expand-template it '("a" "bee"))
    (pen-unonelineify it)))

(comment
 (defun test-template ()
   (interactive)
   (pen-etv
    (pps
     (let ((subprompts '((meta . "and")
                         (intra . "and the")))
           (vals '("Something" "upon" "us"))
           (var-keyvals-slugged
            '(("my-name" . "Shane")))
           (var-keyvals
            '(("my name" . "Shane"))))
       (cl-loop for stsq in '("###" "\n"
                              "Alpha <meta> Omega"
                              "First <intra> last"
                              "Once <2> a time, <my name> said...\n")
                collect
                (expand-template stsq)))))))

;; The LM may also send more info to this after the prompt has executed.
;; All this data will go into the Ink properties
(defvar pen-last-prompt-data '())

(defun pen-alist-to-list (al)
  (loop for e in al collect (list (car e) (cdr e))))

(defun pen-test-alist-to-list ()
  (interactive)

  (pen-etv
   (pps
    (pen-alist-to-list
     '(("PEN_PROMPT" . "Once upon a time")
       ("PEN_ENGINE" . "OpenAI Davinci"))))))

(defun pen-test-alist ()
  (interactive)

  (let ((al '(("PEN_PROMPT" . "Once upon a time")
              ("PEN_ENGINE" . "OpenAI Davinci"))))
    (pen-alist-setcdr 'al "PEN_PROMPT" "In a far away land")
    (pen-etv
     (pps
      (cdr
       (assoc "PEN_PROMPT"
              al))))))

;; Use lexical scope. It's more reliable than lots of params.
;; Expected variables:
;; (func-name func-sym var-syms var-defaults doc prompt
;;  iargs prettifier cache path var-slugs n-collate
;;  filter completion lm-command stop-sequences stop-sequence max-tokens
;;  temperature top-p model no-trim-start no-trim-end preprocessors
;;  postprocessor prompt-filter n-completions)
;; (let ((max-tokens 1)) (funcall (cl-defun yo () (pen-etv max-tokens))))
;; (let ((max-tokens 1)) (funcall 'pf-asktutor/3 "emacs" "key bindings" "How do I kill a buffer?" :no-select-result t))
(defun define-prompt-function ()
  (eval
   `(cl-defun ,func-sym ,(append '(&optional) var-syms '(&key no-select-result include-prompt))
      ,doc
      (interactive ,(cons 'list iargs))
      ;; force-custom, unfortunately disables call-interactively
      ;; i guess that it could also disable other values
      (let ((is-interactive (interactive-p)))
        (pen-force-custom
         (cl-macrolet ((expand-template
                        (string-sym)
                        `(--> ,string-sym
                           (pen-onelineify-safe it)
                           (pen-expand-template-keyvals it subprompts-al)
                           (pen-expand-template it vals)
                           (pen-expand-template-keyvals it var-keyvals-slugged)
                           (pen-expand-template-keyvals it var-keyvals)
                           (pen-unonelineify-safe it))))
           (setq pen-last-prompt-data '((face . ink-generated)
                                        ;; This is necessary because most modes
                                        ;; do not allow allow you to change the faces.
                                        ("INK_TYPE" . "generated")))
           (let* (;; Keep in mind this both updates memoization and the bash cache
                  (do-pen-update (pen-var-value-maybe 'do-pen-update))

                  (pen-sh-update (or
                                  (>= (prefix-numeric-value current-global-prefix-arg) 4)
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

                  (final-flags
                   (or (pen-var-value-maybe 'flags)
                       ,flags))

                  (final-flags
                   (if final-flags
                       (mapconcat
                        (lambda (s) (concat "<" s ">"))
                        (vector2list final-flags)
                        " ")))

                  (final-is-info
                   (or (pen-var-value-maybe 'do-etv)
                       (pen-var-value-maybe 'is-info)
                       ,is-info))

                  (final-new-document
                   (or (pen-var-value-maybe 'new-document)
                       ,new-document))

                  (final-include-prompt
                   (or (pen-var-value-maybe 'include-prompt)
                       ,include-prompt))

                  (final-interpreter
                   (or (pen-var-value-maybe 'interpreter)
                       ,interpreter))

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

                  (subprompts-al
                   (if final-subprompts
                       (ht->alist (-reduce 'ht-merge (vector2list final-subprompts)))))

                  (final-prompt ,prompt)

                  (final-prompt (if final-start-yas
                                    (pen-yas-expand-string final-prompt)
                                  final-prompt))

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

                  (vals
                   (cl-loop
                    for tp in (-zip-fill nil vals final-var-defaults)
                    collect
                    (if (and (not (sor (car tp)))
                             (sor (cdr tp)))
                        ;; TODO if a val is empty, apply the default with the subprompts in scope
                        (eval
                         `(pen-let-keyvals
                           ',subprompts-al
                           (eval-string ,(str (cdr tp)))))
                      (car tp))))

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

                  (final-min-tokens
                   (expand-template
                    (str (or (pen-var-value-maybe 'min-tokens)
                             ,min-tokens))))

                  ;; The max tokens may be templated in via variable or even a subprompt
                  (final-max-tokens
                   (expand-template
                    (str (or (pen-var-value-maybe 'max-tokens)
                             ,max-tokens))))

                  (final-temperature
                   (expand-template
                    (str (or (pen-var-value-maybe 'temperature)
                             ,temperature))))

                  (final-validator
                   (expand-template
                    (str (or (pen-var-value-maybe 'validator)
                             ,validator))))

                  (final-mode
                   (expand-template
                    (str (or (pen-var-value-maybe 'mode)
                             ,mode))))

                  (final-model
                   (expand-template
                    (str (or (pen-var-value-maybe 'model)
                             ,model))))

                  (final-top-p
                   (expand-template
                    (str (or (pen-var-value-maybe 'top-p)
                             ,top-p))))

                  (final-top-k
                   (expand-template
                    (str (or (pen-var-value-maybe 'top-k)
                             ,top-k))))

                  (final-postprocessor
                   (expand-template
                    (str (or (pen-var-value-maybe 'postprocessor)
                             ,postprocessor))))

                  (final-postpostprocessor
                   (expand-template
                    (str (or (pen-var-value-maybe 'postpostprocessor)
                             ,postpostprocessor))))

                  (final-stop-sequences
                   (cl-loop for stsq in (or (pen-var-value-maybe 'stop-sequences)
                                            ',stop-sequences)
                            collect
                            (expand-template stsq)))

                  (final-stop-patterns
                   (or (pen-var-value-maybe 'stop-patterns)
                       ',stop-patterns))

                  ;; These happen before the postprocessing
                  (final-split-patterns
                   (or (pen-var-value-maybe 'split-patterns)
                       ',split-patterns))

                  ;; These happen after the postprocessing
                  (final-end-split-patterns
                   (or (pen-var-value-maybe 'end-split-patterns)
                       ',end-split-patterns))

                  (final-stop-sequence
                   (expand-template
                    (str (or (pen-var-value-maybe 'stop-sequence)
                             ,stop-sequence))))

                  (final-translator
                   (expand-template
                    (str (or (pen-var-value-maybe 'translator)
                             ,translator))))

                  (final-prompt
                   (expand-template final-prompt))

                  (final-prompt
                   (if ,prompt-filter
                       (sor (pen-snc ,prompt-filter final-prompt)
                            (concat "prompt-filter " ,prompt-filter " failed."))
                     final-prompt))

                  (final-prompt (if final-end-yas
                                    (pen-yas-expand-string final-prompt)
                                  final-prompt))

                  ;; This is vital. Newlines at the end will break completion
                  (final-prompt (chomp final-prompt))

                  ;; This gives string position, not byte position
                  ;; (string-search "s" "ガムツリshane")

                  (prompt-end-pos (or (byte-string-search "<:pp>" final-prompt)
                                      ;; (length final-prompt)
                                      (string-bytes final-prompt)))

                  (final-prompt (string-replace "<:pp>" "" final-prompt))

                  (final-prompt (pen-log-final-prompt (chomp final-prompt)))

                  ;; Now that all values are loaded, re-template them so I can base values on other values

                  (data
                   (let ((data
                          `(("PEN_PROMPT" . ,(pen-encode-string final-prompt))
                            ("PEN_LM_COMMAND" . ,,lm-command)
                            ("PEN_MODEL" . ,final-model)
                            ("PEN_MIN_TOKENS" . ,final-min-tokens)
                            ("PEN_MAX_TOKENS" . ,final-max-tokens)
                            ("PEN_TEMPERATURE" . ,final-temperature)
                            ("PEN_MODE" . ,final-mode)
                            ("PEN_STOP_SEQUENCE" . ,(pen-encode-string final-stop-sequence))
                            ("PEN_TOP_P" . ,final-top-p)
                            ("PEN_TOP_K" . ,final-top-k)
                            ("PEN_FLAGS" . ,final-flags)
                            ("PEN_CACHE" . ,cache)
                            ("PEN_N_COMPLETIONS" . ,final-n-completions)
                            ("PEN_END_POS" . ,prompt-end-pos))))
                     (setq pen-last-prompt-data
                           (asoc-merge pen-last-prompt-data data))
                     data))

                  ;; construct the full command
                  (shcmd
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
                       (pen-alist-to-list data))
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
                                            (mapcar (lambda (r) (if (and final-postprocessor (sor final-postprocessor))
                                                                    (pen-sn final-postprocessor r)
                                                                  r)))
                                            (mapcar (lambda (r) (if (and (variable-p 'prettify)
                                                                         prettify
                                                                         ,prettifier
                                                                         (sor ,prettifier))
                                                                    (pen-sn ,prettifier r)
                                                                  r)))
                                            (mapcar (lambda (r) (if (not ,no-trim-start) (s-trim-left r) r)))
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
                                                (not final-validator)
                                                (pen-snq final-validator r)))))))
                                    processed-results)
                                (list (message "Try UPDATE=y or debugging")))))))

                  (results (if final-include-prompt
                               (mapcar
                                (lambda (s) (concat final-prompt s))
                                results)
                             results))

                  ;; Avoid using this. Factor it out.
                  (results (if final-postpostprocessor
                               (mapcar
                                (lambda (r) (if (and final-postpostprocessor (sor final-postpostprocessor))
                                                (pen-sn final-postpostprocessor r)
                                              r))
                                results)
                             results))

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
                         final-new-document
                         (>= (prefix-numeric-value current-prefix-arg) 4))
                     (pen-etv (ink-decode (ink-propertise result))))
                    ;; Filter takes priority over insertion
                    ((and ,filter
                          mark-active)
                     ;; (replace-region (concat (pen-selected-text) result))
                     (if (sor result)
                         (replace-region (ink-propertise result))
                       (error "pen filter returned empty string")))
                    ;; Insertion is for prompts for which a new buffer is not necessary
                    ((or ,insertion
                         ,completion)
                     (insert (ink-propertise result)))
                    (t
                     (pen-etv (ink-propertise result))))
                 result)))))))))

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
              (f-join pen-prompts-directory "prompts" "generic-tutor-for-any-topic-and-subtopic-3.prompt")))
            "subprompts")))
         (keys (type (car (vector2list subprompts)))))

    (pen-etv
     (pps keys))))

(defun test-subprompts-2 ()
  (interactive)
  (let ((l (vector2list
            (ht-get
             (yamlmod-load (cat (f-join pen-prompts-directory "prompts" "generic-tutor-for-any-topic-and-subtopic-3.prompt")))
             "subprompts"))))
    (pen-etv
     (pps
      ;; (ht-merge (car l) (second l))
      (ht->alist (-reduce 'ht-merge l))))))

(defun pen-prompt-test-merge ()
  (mu
   (ht-merge
    (pen-prompt-file-load "$PROMPTS/davinci.prompt")
    (pen-prompt-file-load "$PROMPTS/generic-completion-50-tokens.prompt"))))

(defset pen-prompts (make-hash-table :test 'equal)
  "A hash table containing loaded prompts")

(defset pen-translators
  '("(wrlp input (pf-translate-from-world-language-x-to-y/3 from-language to-language))")
  "A list of translators that can be used to translate prompts.
These may be string representations of emacs lisp if beginning with '('.
Otherwise, it will be a shell expression template")

;; pdf is prompt description file
;; also, check for a key which specifies that a prompt is only for templating
;; if it doesn't exist, then set not-template
(defun pen-prompt-file-load (fp)
  (let* ((yaml-ht (yamlmod-read-file fp))
         (incl-name (sor (ht-get yaml-ht "include")))
         (incl-fp (if (sor incl-name)
                      (f-join
                       pen-prompts-directory
                       "prompts"
                       (concat (slugify incl-name) ".prompt"))))
         (incl-yaml (if (and (sor incl-name)
                             (f-file-p incl-fp))
                        (pen-prompt-file-load incl-fp))))
    (if incl-yaml
        (setq yaml-ht
              (ht-merge incl-yaml
                        ;; The last is overriding
                        yaml-ht)))
    yaml-ht))

(defun pen-engine-file-load (fp)
  (let* ((yaml-ht (yamlmod-read-file fp))
         (incl-name (sor (ht-get yaml-ht "include")))
         (incl-fp (if (sor incl-name)
                      (f-join
                       pen-engines-directory
                       "engines"
                       (concat (slugify incl-name) ".engine"))))
         (incl-yaml (if (and (sor incl-name)
                             (f-file-p incl-fp))
                        (pen-engine-file-load incl-fp))))
    (if incl-yaml
        (setq yaml-ht
              (ht-merge incl-yaml
                        ;; The last is overriding
                        yaml-ht)))
    yaml-ht))

(defun pen-prompt-test-examples ()
  (interactive)
  (pen-etv
   (type
    (car
     (vector2list
      (ht-get
       (mu
        (pen-prompt-file-load "$PROMPTS/funny-riddle.prompt"))
       "examples"))))))

;; This is a hash table
(defvar pen-engines (make-hash-table :test 'equal)
  "pen-engines are basically templates which will be merged with the corresponding prompts")

(defvar pen-engines-failed '())

;; (pen-etv (ht-get pen-engines "OpenAI Davinci"))

(defun pen-load-engines (&optional paths)
  (interactive)

  (setq pen-engines (make-hash-table :test 'equal))
  (setq pen-engines-failed '())
  (noupd
   (eval
    `(let ((paths
            (or ,paths
                (-non-nil
                 (mapcar 'sor (glob (concat pen-engines-directory "/engines" "/*.engine")))))))
       (cl-loop for path in paths do
                (message (concat "pen-mode: Loading .engine file " path))

                ;; Do a recursive engine merge from includes
                ;; ht-merge

                ;; results in a hash table
                (try
                 (let* ((yaml-ht (pen-engine-file-load path))

                        ;; function
                        (title (ht-get yaml-ht "title")))
                   (ht-set yaml-ht "path" path)
                   (message (concat "pen-mode: Loaded engine " title))
                   (ht-set pen-engines title yaml-ht))
                 (add-to-list 'pen-engines-failed path)))
       (if pen-engines-failed
           (progn
             (message "failed:")
             (message (pen-list2str pen-engines-failed))
             (message (concat (str (length pen-engines-failed)) " failed"))))))))

;; (ht-get (ht-get pen-prompts "pf-emacs-ielm/1") "path")
(defun pen-organise-prompts ()
  (interactive)
  (cl-loop for yaml-key in (ht-keys pen-prompts) do
           (let* ((yaml-ht (ht-get pen-prompts yaml-key))
                  (path (ht-get yaml-ht "path"))
                  (dn (f-dirname path))
                  (fn (f-basename path))
                  (newfn (s-replace-regexp "^pf-" "" (concat (slugify yaml-key) ".prompt")))
                  (newpath (f-join dn newfn))

                  ;; function
                  (task-ink (ht-get yaml-ht "task"))
                  (task (ink-decode task-ink))
                  (title (ht-get yaml-ht "title"))
                  (title (sor title
                              task))
                  (title-slug (slugify title)))
             (if (and (f-exists-p path)
                      (not (f-exists-p newpath)))
                 (f-move path
                         newpath))
             (message newfn)))
  ;; (let ((paths
  ;;        (-non-nil
  ;;         (mapcar 'sor (glob (concat pen-prompts-directory "/prompts" "/*.prompt"))))))
  ;;      (cl-loop for path in paths do
  ;;               (message (concat "pen-mode: Loading .prompt file " path))))
  )

(defun pen-list-prompt-paths ()
  (-non-nil
   (mapcar 'sor (glob (concat pen-prompts-directory "/prompts" "/*.prompt")))))


(defun pen-generate-prompt-functions (&optional paths)
  "Generate prompt functions for the files in the prompts directory
Function names are prefixed with pf- for easy searching"
  (interactive)

  (setq pen-prompt-functions nil)
  (setq pen-prompts-failed nil)
  (setq pen-prompt-filter-functions nil)
  (setq pen-prompt-completion-functions nil)
  (setq pen-prompt-functions-meta nil)
  (setq pen-prompt-functions-failed nil)
  (setq pen-prompts (make-hash-table :test 'equal))

  (pen-load-engines)

  (noupd
   (eval
    `(let ((paths
            (or ,paths (pen-list-prompt-paths))))
       (cl-loop for path in paths do
                (message (concat "pen-mode: Loading .prompt file " path))

                ;; Do a recursive prompt merge from includes
                ;; ht-merge

                ;; results in a hash table
                (try
                 (let* ((yaml-ht (pen-prompt-file-load path))
                        (path path)

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
                        (title (ht-get yaml-ht "title"))
                        (title (sor title
                                    task))
                        (title-slug (slugify title))

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
                        (flags (ht-get yaml-ht "flags"))
                        (subprompts (ht-get yaml-ht "subprompts"))
                        (is-info (ht-get yaml-ht "is-info"))
                        (new-document (ht-get yaml-ht "new-document"))
                        (start-yas (ht-get yaml-ht "start-yas"))
                        (yas (ht-get yaml-ht "yas"))
                        (end-yas (ht-get yaml-ht "end-yas"))
                        (include-prompt (ht-get yaml-ht "include-prompt"))
                        (repeater (ht-get yaml-ht "repeater"))
                        (prefer-external (pen-yaml-test yaml-ht "prefer-external"))
                        (interpreter (pen-yaml-test yaml-ht "interpreter"))
                        (conversation (pen-yaml-test yaml-ht "conversation"))
                        (filter (pen-yaml-test yaml-ht "filter"))
                        ;; Don't actually use this.
                        ;; But I can toggle to use the prettifier with a bool
                        (prettifier (ht-get yaml-ht "prettifier"))
                        (collation-postprocessor (ht-get yaml-ht "pen-collation-postprocessor"))
                        (completion (pen-yaml-test yaml-ht "completion"))
                        (insertion (pen-yaml-test yaml-ht "insertion"))
                        (no-trim-start (or (pen-yaml-test yaml-ht "no-trim-start")
                                           (pen-yaml-test yaml-ht "completion")))
                        (no-trim-end (pen-yaml-test yaml-ht "no-trim-end"))
                        (examples-list (vector2list (ht-get yaml-ht "examples")))
                        (examples
                         (if (vectorp (car examples-list))
                             (vector2list (car examples-list))
                           examples-list))
                        (preprocessors (vector2list (ht-get yaml-ht "preprocessors")))
                        (validator (ht-get yaml-ht "validator"))
                        (prompt-filter (ht-get yaml-ht "prompt-filter"))
                        (postprocessor (ht-get yaml-ht "postprocessor"))
                        (postpostprocessor (ht-get yaml-ht "postpostprocessor"))
                        (n-collate (or (ht-get yaml-ht "n-collate")
                                       1))
                        (n-completions (or (ht-get yaml-ht "n-completions")
                                           5))
                        (n-test-runs (ht-get yaml-ht "n-test-runs"))

                        ;; API
                        (engine
                         (let* ((engine-title (ht-get yaml-ht "engine"))
                                (engine (if (and
                                             engine-title
                                             pen-engines)
                                            (ht-get pen-engines engine-title))))
                           (if engine
                               (setq yaml-ht (ht-merge yaml-ht engine)))
                           engine-title))
                        (model (ht-get yaml-ht "model"))
                        (min-tokens (ht-get yaml-ht "min-tokens"))
                        (max-tokens (ht-get yaml-ht "max-tokens"))
                        (top-p (ht-get yaml-ht "top-p"))
                        (top-k (ht-get yaml-ht "top-k"))
                        (temperature (ht-get yaml-ht "temperature"))
                        (stop-sequences
                         (or (vector2list (ht-get yaml-ht "stop-sequences"))
                             ;; (list "\n")
                             (list "###<long>###")))
                        (suggest-p
                         (or (vector2list (ht-get yaml-ht "suggest-p"))
                             (list t)))
                        ;; These are automatically turned into prompt functions
                        (nl-suggest-p (vector2list (ht-get yaml-ht "nl-suggest-p")))
                        (stop-sequence
                         (if stop-sequences (car stop-sequences)))

                        (stop-patterns
                         (or (vector2list (ht-get yaml-ht "stop-patterns"))
                             ;; By default, stop when you see ^Input
                             (list "^Input:")))

                        (split-patterns
                         (or (vector2list (ht-get yaml-ht "split-patterns"))
                             nil
                             ;; (list "\n")
                             ))

                        (end-split-patterns
                         (or (vector2list (ht-get yaml-ht "end-split-patterns"))
                             nil
                             ;; (list "\n")
                             ))

                        (translator
                         (let ((tr (ht-get yaml-ht "translator")))
                           (if (sor tr)
                               (add-to-list 'pen-translators tr))
                           tr))

                        ;; docs
                        (problems (vector2list (ht-get yaml-ht "problems")))
                        (design-patterns (vector2list (ht-get yaml-ht "design-patterns")))
                        (todo (vector2list (ht-get yaml-ht "todo")))
                        (notes (vector2list (ht-get yaml-ht "notes")))
                        (aims (vector2list (ht-get yaml-ht "aims")))
                        (past-versions (vector2list (ht-get yaml-ht "past-versions")))
                        (external-related (vector2list (ht-get yaml-ht "external-related")))
                        (related-prompts (vector2list (ht-get yaml-ht "related-prompts")))
                        (future-titles (vector2list (ht-get yaml-ht "future-titles")))

                        (var-defaults (vector2list (ht-get yaml-ht "var-defaults")))

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
                                (if model (concat "\nmodel: " model))
                                (if task (concat "\ntask: " task))
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
                        (vars (vector2list (ht-get yaml-ht "vars")))
                        (var-slugs (mapcar 'slugify vars))
                        (var-syms
                         (let ((ss (mapcar 'intern var-slugs)))
                           (message (concat "_" prettifier))
                           (if (sor prettifier)
                               ;; Add to the function definition the prettify key if the .prompt file specifies a prettifier
                               (setq ss (append ss '(&key prettify))))
                           ss))
                        (func-name (concat pen-prompt-function-prefix title-slug "/" (str (length vars))))
                        (func-sym (intern func-name))
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
                                  `(pen-let-keyvals
                                    ',',(pen-subprompts-to-alist subprompts)
                                    (if ,,default
                                        (eval-string ,,(str default))
                                      (read-string-hist ,,(concat varname ": ") ,,example))))))
                            do
                            (progn
                              (setq iteration (+ 1 iteration))
                              (message (str iteration)))))))

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
                                 (if interpreter (add-to-list 'pen-prompt-interpreter-functions funcsym))
                                 (if filter (add-to-list 'pen-prompt-filter-functions funcsym))
                                 (if completion (add-to-list 'pen-prompt-completion-functions funcsym)))
                             (add-to-list 'pen-prompt-functions-failed func-sym))

                           ;; Using memoization here is the more efficient way to memoize.
                           ;; TODO I'll sort it out later. I want an updating mechanism, which exists already using LM_CACHE.
                           ;; (if cache (memoize funcsym))
                           )))
                   (message (concat "pen-mode: Loaded prompt function " func-name)))
                 (add-to-list 'pen-prompts-failed path)))
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

(defun pen-start-imaginary-interpreter ()
  (interactive)
  (let ((f (fz
            (if (>= (prefix-numeric-value current-prefix-arg) 4)
                pen-prompt-functions
              pen-prompt-interpreter-functions)
            nil nil "pen interpreter: ")))
    (if f
        (let ((filter t))
          (call-interactively (intern f)))
      ;; (filter-selected-region-through-function (intern f))
      )))

(defun pen-run-prompt-function ()
  (interactive)
  (let* ((pen-sh-update
          (or pen-sh-update (>= (prefix-numeric-value current-global-prefix-arg) 4)))
         (f (fz pen-prompt-functions nil nil "pen run: ")))
    (if f
        (call-interactively (intern f)))))

;; This is where I need to propertise company completions
;; Unfortunately, it requires me to duplicate a whole lot of company code
(defun pen-company--insert-candidate (candidate)
  (when (> (length candidate) 0)
    (setq candidate (substring-no-properties candidate))
    ;; XXX: Return value we check here is subject to change.
    (if (eq (company-call-backend 'ignore-case) 'keep-prefix)
        (insert (ink-propertise (company-strip-prefix candidate)))
      (unless (equal company-prefix candidate)
        (delete-region (- (point) (length company-prefix)) (point))
        (insert (ink-propertise candidate))))))

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

    (mapcar (lambda (s)
              (concat (pen-company-filetype--prefix)
                      s))
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

(defmacro pen-force-custom (&rest body)
  "This forces various settings depending on customizations"
  (let ((overrides
         (flatten-once
          (list
           (if pen-force-single-collation
               (list `(pen-single-generation-b t)
                     `(n-collate 1)))
           (if pen-force-few-completions
               (list `(n-completions 3)
                     ;; Also, ensure n-collate = 1 because
                     ;; n-completions may be emulated with collate
                     `(n-collate 1)))
           (if pen-force-gpt-j-aix
               (list `(lm-command "aix-complete.sh")
                     `(model "GPT-J-6B")))
           (if pen-force-openai
               (list `(lm-command "openai-complete.sh")
                     `(model "davinci")))
           (if pen-force-hf
               (list `(lm-command "hf-complete.sh")
                     `(model "gpt2")))))))
    `(eval
      `(let ,',overrides
         ,',@body))))

(defun pen-force-custom-test ()
  (interactive)
  (pen-etv
   (pen-force-custom (message (str (pen-var-value-maybe 'n-collate))))))

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
      ;; Can't put ink-propertise here
      (eval `(pf-generic-file-type-completion/2 (pen-detect-language) preceding-text ,@args))
    (eval `(pf-generic-completion-50-tokens/1 preceding-text ,@args))))

(defun pen-complete-long (preceding-text &optional tv)
  "Long-form completion. This will generate lots of text.
May use to generate code from comments."
  (interactive (list (pen-preceding-text) nil))
  (let ((response
         (pen-long-complete
          (pen-complete-function preceding-text))))
    (if tv
        (pen-etv (ink-propertise response))
      (insert (ink-propertise response)))))

(defun pen-cmd-q (&rest args)
  (s-join " " (mapcar 'pen-q (mapcar 'str args))))

(defun pen-compose-cli-command (funname)
  "This composes a command to run on the CLI"
  (interactive (list (fz pen-prompt-functions nil nil "pen compose cli command: ")))
  (let* ((f funname)
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
(require 'pen-hf)
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
(require 'pen-ii-description)
(require 'pen-engine-description)
(require 'pen-lm-completers)
(require 'pen-emacs)
(require 'pen-acolyte-minor-mode)
(require 'pen-gptprompts)
;; For debugging
(require 'pen-messages)
(require 'pen-yaml)
(require 'pen-glossary)
(require 'pen-localization)
(require 'pen-diagnostics)
(require 'pen-examplary)
(require 'pen-transient)
(require 'pen-engine)
;; Allow Pen.el to use a docker container containing Pen.el as its 'engine'.
(require 'pen-quineserver)
(require 'pen-fun)
(require 'pen-yasnippet)
(require 'pen-filters)

(add-to-list 'auto-mode-alist '("\\.prompt\\'" . prompt-description-mode))

(provide 'pen)
