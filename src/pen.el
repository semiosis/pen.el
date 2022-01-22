;;; pen.el --- Prompt Engineering functions
;;;
;;; Prompt Engineering in Emacs
;;; The Pen of Imagination

(setq large-file-warning-threshold nil)

;; This may have been defined in init,
;; for contrib, etc.
(ignore-errors
  (defvar pen-map (make-sparse-keymap)
    "Keymap for `pen.el'."))

(defmacro lm (&rest body)
  "Interactive lambda with no arguments."
  `(lambda () (interactive) ,@body))

;; builtin
(require 'cl-macs)
(require 'pp)

;; elpa
;; For string-empty-p
(require 'subr-x)
(require 'pen-global-prefix)
(require 'pen-regex)
(require 'pen-support)
(require 'dash)
(require 'projectile)
(require 'transient)
(require 'iedit)
(require 'ht)
(require 'helm)
(require 'memoize)
(require 'ivy)
(require 's)
(require 'company)
(require 'selected)
(require 'pcsv)
(require 'pcre2el)
(require 'f)
(require 'lsp-mode)
(require 'lsp-ui)
(require 'lispy)
(require 'which-key)
(require 'eww-lnum)
(require 'shackle)
(require 'helpful)
(require 'vterm)

;; pen/src
(require 'asoc)
(require 'transducer)
(require 'handle)
(require 'pen-company-lsp)
(require 'pen-nlp)
(require 'pen-which-key)
(require 'pen-elisp)
(require 'pen-custom)
(require 'pen-configure)
(require 'pen-hist)
(require 'pen-eww)
(require 'pen-links)
(require 'pen-handle)
(require 'pen-edit)
(require 'pen-client)
(require 'pen-autosuggest)
(require 'pen-shackle)
(require 'pen-translation-map)
(require 'helm-fzf)
(require 'pen-helm-fzf)
(require 'pen-help)
(require 'pen-eipe)
(require 'pen-textprops)
(require 'pen-faces)
(require 'pen-misc)
(require 'pen-packages)
(require 'pen-pensieve)
(require 'pen-menu-bar)
(require 'pen-daemons)
(require 'pen-source)
(require 'pen-human)
(require 'pen-cterm)
(require 'pen-web)
(require 'pen-esp)
(require 'pen-openwith)
(require 'pen-update)
(require 'pen-keys)
(require 'pen-swipe)
(require 'pen-ilambda)
(require 'pen-demos)

;; Not sure I need the following in pen.el
;; Might be fine to just have them in init.el only
;; (require 'macrostep)
;; (require 'tree-sitter)
;; (require 'tree-sitter-langs)
;; (require 'tree-sitter-indent)

(defvar my-completion-engine 'pen-company-filetype)

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

;; This is a list of useful prompt functions, compound prompt functions, etc.
;; Usually organised under right click menu
(defset pen-editing-functions nil)

(defset pen-prompt-functions nil)
(defset pen-prompt-aliases nil)
(defset pen-prompt-interpreter-functions nil)
(defset pen-prompt-filter-functions nil)
(defset pen-prompt-analyser-functions nil)
(defset pen-prompt-functions-failed nil)
(defset pen-prompts-failed nil)
(defset pen-prompt-completion-functions nil)
(defset pen-prompt-functions-meta nil)

;; (defun pen-ht-get (yaml-ht key)
;;   (pen-try
;;    (ht-get yaml-ht key)))

(defun pen-yaml-test (yaml-ht key)
  (ignore-errors
    (if (and yaml-ht
             (sor key))
        (let ((v (ht-get yaml-ht key)))
          (or (string-equal v "on")
              (string-equal v "true")
              (string-equal v "yes")
              ;; "true" automatically becomes t
              (and (booleanp v)
                   v))))))

(defun pen-yaml-test-off (yaml-ht key)
  (ignore-errors
    (if (and yaml-ht
             (sor key))
        (let ((v (ht-get yaml-ht key)))
          (or (string-equal v "off")
              (string-equal v "false")
              (string-equal v "no")
              ;; "true" automatically becomes t
              (and (booleanp v)
                   (not v)))))))

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
           (subprompts (ht-get yaml-ht "subprompts"))
           (payloads (pen--htlist-to-alist (ht-get yaml-ht "payloads")))
           (title (ht-get yaml-ht "title"))
           (task (ht-get yaml-ht "task"))
           (doc (ht-get yaml-ht "doc"))
           (topic (ht-get yaml-ht "topic"))
           ;; TODO Make vals work, too
           (defs (pen--htlist-to-alist (ht-get yaml-ht "defs")))
           (envs (pen--htlist-to-alist (ht-get yaml-ht "envs")))
           ;; TODO Make vars also use pen--htlist-to-alist
           (vars (pen-vector2list (ht-get yaml-ht "vars")))
           (var-slugs (mapcar 'slugify vars))
           (examples (pen-vector2list (ht-get yaml-ht "examples")))
           (aliases (pen-vector2list (ht-get yaml-ht "aliases")))
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
                 (new-vars (cl-loop for v in vars collect
                                 (translate v)))
                 ;; (new-var-slugs (mapcar 'slugify new-vars))
                 (new-examples
                  (if (vectorp (car examples))
                      (mapcar
                       (lambda (v)
                         (cl-loop for e in (pen-vector2list v) collect
                               (translate e)))
                       examples)
                    (cl-loop for e in examples collect
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
      ;; (ht-get pen-prompts "pf-define-word-for-glossary/1")
      ;; (ht-get pen-prompts 'pf-define-word-for-glossary/1)
      )))

(defun pen-engine-disabled-p (engine)
  (let ((disabled))
    (cl-loop for e in pen-disabled-engines do
          (if (string-match e engine)
              (setq disabled t)))
    disabled))

(defun pen-prompt-disabled-p (prompt)
  (let ((disabled))
    (cl-loop for e in pen-disabled-prompts do
          (if (string-match e prompt)
              (setq disabled t)))
    disabled))

(defun pen-list-filterers ()
  (interactive)
  (let ((funs (-filter (lambda (y) (pen-yaml-test y "filter"))
                       pen-prompt-functions-meta)))
    (if (interactive-p)
        (pen-etv (pps (pen--htlist-to-alist funs)))
      funs)))

(defun pen-list-completers ()
  (interactive)
  (let ((funs (-filter (lambda (y) (pen-yaml-test y "completion"))
                       pen-prompt-functions-meta)))
    (if (interactive-p)
        (pen-etv (pps (pen--htlist-to-alist funs)))
      funs)))

(defun pen-list-inserters ()
  (interactive)
  (let ((funs (-filter (lambda (y) (pen-yaml-test y "insertion"))
                       pen-prompt-functions-meta)))
    (if (interactive-p)
        (pen-etv (pps (pen--htlist-to-alist funs)))
      funs)))

(defun pen-list-infos ()
  (interactive)
  (let ((funs (-filter (lambda (y) (pen-yaml-test y "info"))
                       pen-prompt-functions-meta)))
    (if (interactive-p)
        (pen-etv (pps (pen--htlist-to-alist funs)))
      funs)))

(defun pen-list-interpreters ()
  (interactive)
  (let ((funs (-filter (lambda (y) (pen-yaml-test y "interpreter"))
                       pen-prompt-functions-meta)))
    (if (interactive-p)
        (pen-etv (pps (pen--htlist-to-alist funs)))
      funs)))

(defun pen-encode-string (s &optional newlines)
  (let ((encoded
         (->> s
           ;; (string-replace ";" "<pen-semicolon>")
           (string-replace "\"" "<pen-doublequote>")
           (string-replace ":" "<pen-colon>")
           ;; This breaks it because it encodes slugs. Don't do it
           ;; (string-replace "-" "<pen-dash>")
           (string-replace "'" "<pen-singlequote>")
           (string-replace "`" "<pen-backtick>")
           (string-replace "\\" "<pen-backslash>")
           (string-replace "!" "<pen-bang>")
           (string-replace "\\n" "<pen-notnewline>")
           (string-replace "$" "<pen-dollar>"))))
    (if newlines
        (setq encoded
              (->> encoded
                (string-replace "\n\n" "<pen-dnl>")
                (string-replace "\n" "<pen-newline>"))))
    encoded))

(defun pen-decode-string (s)
  (comment (let ((decoded
                  (->> s
                    ;; (string-replace ";" "<pen-semicolon>")
                    (string-replace "<pen-doublequote>" "\"")
                    (string-replace "<pen-colon>" ":")
                    ;; This breaks it because it encodes slugs. Don't do it
                    ;; (string-replace "-" "<pen-dash>")
                    (string-replace "<pen-singlequote>" "'")
                    (string-replace "<pen-backslash>" "\\")
                    (string-replace "<pen-backtick>" "`")
                    (string-replace "<pen-bang>" "!")
                    (string-replace "<pen-notnewline>" "\\n")
                    (string-replace "<pen-dollar>" "$")
                    (string-replace "<pen-dnl>" "\n\n")
                    (string-replace "<pen-newline>" "\n"))))
             decoded))
  (pen-snc "pen-decode-string" s))

;; This is necessary because the string-search
;; command is not available in emacs27
(defun pen-string-search (needle haystack &optional start-pos)
  (setq start-pos (or start-pos 0))
  (let ((results (s-matched-positions-all needle haystack)))
    (cl-loop for tp in results
             if (>= (car tp) start-pos)
             return (car tp))))

(defun pen-position-bytes (pos)
  (if (= 0 pos)
      0
    (position-bytes pos)))

(defun pen-byte-pos ()
  (pen-position-bytes (point)))

(defun byte-string-search (needle haystack)
  "get byte position or needing in haystack"
  (let ((b (new-buffer-from-string haystack))
        (pos (pen-string-search needle haystack)))
    (if pos
        (with-current-buffer b
          (let ((y (pen-position-bytes pos)))
            (kill-buffer b)
            y))
      (progn
        (kill-buffer b)
        nil))))

(defun pen-boxify (s)
  "This is useful to force spelling in prompts"
  (pen-snc "sed 's/./\\[\\U&\\]/g'" s))

(defun pen-expand-template (s vals &optional encode pipelines)
  "expand template from list"
  (if vals
      (let ((i 1))
        (chomp
         (progn
           (cl-loop
            for val in vals do
            (if encode (setq val (pen-encode-string val)))

            (cl-loop for pl
                  in pipelines
                  do
                  (let ((plf (format "<%s:%i>" (car pl) i))
                        (plf2 (format "<%s<pen-colon>%i>" (car pl) i)))

                    (cond-all
                     ((re-match-p (pen-unregexify plf) s)
                      (setq s (string-replace plf (pen-snc (cdr pl) (chomp val)) s)))
                     ((re-match-p (pen-unregexify plf2) s)
                      (setq s (string-replace plf2 (pen-snc (cdr pl) (chomp val)) s))))))

            (let ((unquoted (format "<%d>" i))
                  (unquoted2 (format "<:%d>" i))
                  (unquoted3 (format "<<pen-colon>%d>" i))
                  (unchomped (format "<::%d>" i))
                  (unchomped2 (format "<<pen-colon><pen-colon>%d>" i)))
              (cond-all
               ((re-match-p (pen-unregexify unquoted) s)
                (setq s (string-replace unquoted (chomp val) s)))
               ((re-match-p (pen-unregexify unquoted2) s)
                (setq s (string-replace unquoted2 (chomp val) s)))
               ((re-match-p (pen-unregexify unquoted3) s)
                (setq s (string-replace unquoted3 (chomp val) s)))
               ((re-match-p (pen-unregexify unchomped) s)
                (setq s (string-replace unchomped val s)))
               ((re-match-p (pen-unregexify unchomped2) s)
                (setq s (string-replace unchomped2 val s)))))

            (cl-loop for pl
                  in '(("q" . pen-q)
                       ("sl" . slugify)
                       ("bx" . pen-boxify)
                       ("bs" . pen-backslashed))
                  do
                  (let ((plf (format "<%s:%d>" (car pl) i))
                        (plf2 (format "<%s<pen-colon>%d>" (car pl) i))
                        (plfu (format "<%s::%d>" (car pl) i))
                        (plf2u (format "<%s<pen-colon><pen-colon>%d>" (car pl) i)))

                    (cond-all
                     ((re-match-p (pen-unregexify plf) s)
                      (setq s (string-replace plf (apply (cdr pl) (list (chomp val))) s)))
                     ((re-match-p (pen-unregexify plf2) s)
                      (setq s (string-replace plf2 (apply (cdr pl) (list (chomp val))) s)))
                     ((re-match-p (pen-unregexify plf) s)
                      (setq s (string-replace plfu (apply (cdr pl) (list val)) s)))
                     ((re-match-p (pen-unregexify plf2) s)
                      (setq s (string-replace plf2u (apply (cdr pl) (list val)) s))))))

            (setq i (+ 1 i)))
           s)))
    s))

(defun pen-test-expand-keyvals ()
  (interactive)
  (pen-etv (pen-expand-template-keyvals " <q:y> <thing> " '(("thing" . "yo")
                                                            ("y" . "n")))))

(defun pen-test-expand-zip-two-lists ()
  (interactive)
  (pen-etv (pen-expand-template-keyvals " <y> <q:thing hi> "
                                        (-zip '("thing hi" "y") '("yo" "n")))))

(defun scrape-all (re input)
  (pen-str2list (pen-snc (pen-cmd "pen-scrape" re) input)))

(defun pen-expand-macros (s)
  (let ((scs (-filter-not-empty-string (scrape-all "<m:\\([^)]*\\)>" s))))
    (shut-up
      (cl-loop for sc in scs do
               (let* ((inner sc)
                      (inner (s-replace-regexp "^<m:" "" inner))
                      (inner (s-replace-regexp ">$" "" inner)))
                 (setq s (string-replace
                          sc
                          (pp-oneline
                           (macroexpand
                            (eval-string
                             (concat "'" inner))))
                          s))))))
  s
  ;; (scrape "<m:([^)]*)>" s)
  )

(defun test-pen-expand-macros ()
  (interactive)
  (pen-expand-macros "This is my string <m:(pen-n-words->n-tokens/m)> This is it"))

(defmacro cond-all (&rest body)
  "Like cond, but runs all of them"
  (let ((whens
         (cl-loop for c in body
                  collect
                  `(when ,(car c)
                     ,@(cdr c)))))
    `(progn
       ,@whens)))

;; Discovering the keys is a separate issue (when generating the .prompt files)
(defun pen-jinja-expand (s keyvals)
  (if keyvals
      (let ((i 1))
        (chomp
         (progn
           (cl-loop
            for kv in keyvals do
            (let* ((key (str (car kv)))
                   (val (str (cdr kv)))
                   (val (if encode
                            (pen-encode-string val)
                          val)))

              ;; oci bigscience-get-prompts | jq . | scrape "{{[^}]*}}" | v
              (cl-loop for pl
                    in pipelines
                    do
                    (let ((plf (format "<%s:%s>" (car pl) key))
                          (plf2 (format "<%s<pen-colon>%s>" (car pl) key)))

                      (cond-all
                       ((re-match-p (pen-unregexify plf) s)
                        (setq s (string-replace plf (pen-snc (cdr pl) (chomp val)) s)))
                       ((re-match-p (pen-unregexify plf2) s)
                        (setq s (string-replace plf2 (pen-snc (cdr pl) (chomp val)) s))))))

              ;; (comment
              ;;  (pen-cartesian-product '("foo" "bar" "baz") '("einie" "mienie" "meinie" "mo"))
              ;;  ;; (mapcar 'car '(("hello" . "there") ("about" . "time")))
              ;;  (mapcar 'car pipelines)
              ;;  (car (assoc "uc" '(("uc" . "pen-str uc")))))

              (cl-loop for pl
                    in '(("q" . pen-q)
                         ("sl" . slugify)
                         ("bx" . pen-boxify)
                         ("bs" . pen-backslashed))
                    do
                    (let ((plf (format "<%s:%s>" (car pl) key))
                          (plf2 (format "<%s<pen-colon>%s>" (car pl) key))
                          (plfu (format "<%s::%s>" (car pl) key))
                          (plf2u (format "<%s<pen-colon><pen-colon>%s>" (car pl) key)))

                      (cond-all
                       ((re-match-p (pen-unregexify plf) s)
                        (setq s (string-replace plf (apply (cdr pl) (list (chomp val))) s)))
                       ((re-match-p (pen-unregexify plf2) s)
                        (setq s (string-replace plf2 (apply (cdr pl) (list (chomp val))) s)))
                       ((re-match-p (pen-unregexify plf) s)
                        (setq s (string-replace plfu (apply (cdr pl) (list val)) s)))
                       ((re-match-p (pen-unregexify plf2) s)
                        (setq s (string-replace plf2u (apply (cdr pl) (list val)) s))))))

              ;; (setq s (string-replace (format "<%d>" i) val s))
              (setq i (+ 1 i))))
           s)))
    s))

(defun pen-backslashed (val)
  (pen-sn "sed 's=.=\\\\&=g'" val))

(defun pen-expand-template-keyvals (s keyvals &optional encode pipelines)
  "expand template from alist"
  (if keyvals
      (let ((i 1))
        (chomp
         (progn
           (cl-loop
            for kv in keyvals do
            (let* ((key (str (car kv)))
                   (val (str (cdr kv)))
                   (val (if encode
                            (pen-encode-string val)
                          val)))

              (cl-loop for pl
                    in pipelines
                    do
                    (let ((plf (format "<%s:%s>" (car pl) key))
                          (plf2 (format "<%s<pen-colon>%s>" (car pl) key))
                          (plf2u (format "<%s<pen-colon><pen-colon>%s>" (car pl) key)))

                      (cond-all
                       ((re-match-p (pen-unregexify plf) s)
                        (setq s (string-replace plf (pen-snc (cdr pl) (chomp val)) s)))
                       ((re-match-p (pen-unregexify plf2) s)
                        (setq s (string-replace plf2 (pen-snc (cdr pl) (chomp val)) s)))
                       ((re-match-p (pen-unregexify plf2u) s)
                        (setq s (string-replace plf2u (pen-sn (cdr pl) val) s))))))

              ;; (comment
              ;;  (pen-cartesian-product '("foo" "bar" "baz") '("einie" "mienie" "meinie" "mo"))
              ;;  ;; (mapcar 'car '(("hello" . "there") ("about" . "time")))
              ;;  (mapcar 'car pipelines)
              ;;  (car (assoc "uc" '(("uc" . "pen-str uc")))))

              (let ((unquoted (format "<%s>" key))
                    (unquoted2 (format "<:%s>" key))
                    (unquoted3 (format "<<pen-colon>%s>" key))
                    (unchomped (format "<::%s>" key))
                    (unchomped2 (format "<<pen-colon><pen-colon>%s>" key)))
                (cond-all
                 ((re-match-p (pen-unregexify unquoted) s)
                  (setq s (string-replace unquoted (chomp val) s)))
                 ((re-match-p (pen-unregexify unquoted2) s)
                  (setq s (string-replace unquoted2 (chomp val) s)))
                 ((re-match-p (pen-unregexify unquoted3) s)
                  (setq s (string-replace unquoted3 (chomp val) s)))
                 ((re-match-p (pen-unregexify unchomped) s)
                  (setq s (string-replace unchomped val s)))
                 ((re-match-p (pen-unregexify unchomped2) s)
                  (setq s (string-replace unchomped2 val s)))))

              (cl-loop for pl
                    in '(("q" . pen-q)
                         ("sl" . slugify)
                         ("bx" . pen-boxify)
                         ("bs" . pen-backslashed))
                    do
                    (let ((plf (format "<%s:%s>" (car pl) key))
                          (plf2 (format "<%s<pen-colon>%s>" (car pl) key))
                          (plfu (format "<%s::%s>" (car pl) key))
                          (plf2u (format "<%s<pen-colon><pen-colon>%s>" (car pl) key)))

                      (cond-all
                       ((re-match-p (pen-unregexify plf) s)
                        (setq s (string-replace plf (apply (cdr pl) (list (chomp val))) s)))
                       ((re-match-p (pen-unregexify plf2) s)
                        (setq s (string-replace plf2 (apply (cdr pl) (list (chomp val))) s)))
                       ((re-match-p (pen-unregexify plf) s)
                        (setq s (string-replace plfu (apply (cdr pl) (list val)) s)))
                       ((re-match-p (pen-unregexify plf2) s)
                        (setq s (string-replace plf2u (apply (cdr pl) (list val)) s))))))

              ;; Then scrape the prompt for remaining template patterns and check for existing functions that match the pattern

              (setq i (+ 1 i))))
           s)))
    s))

;; This function is also memoized
(defun pen-prompt-snc (cmd resultnumber
                           ;; &optional docache update
                           )
  "This is like pen-snc but it will memoize the function. resultnumber is necessary because we want n unique results per function"
  ;; (tv cmd)

  (setq cmd (concat pen-snc-ignored-envs " " cmd))

  (if (f-directory-p penconfdir)
      (tee (f-join penconfdir "last-final-command.txt") cmd))

  ;; These extra envs can slip into the function without affecting the memoisation
  ;; (pen-snc (tv (concat (sh-construct-envs (pen-var-value-maybe 'ignored-envs)) " " cmd)))
  (pen-snc (concat pen-snc-ignored-envs " " cmd))

  ;; (if docache
  ;;     (pen-ci (pen-snc cmd) t)
  ;;   (pen-snc cmd))
  )

(defmacro pen-quote-args (&rest body)
  "Join all the arguments in a sexp into a single string.
Be mindful of quoting arguments correctly."
  `(mapconcat (lambda (input)
                (pen-shellquote (str input))) ',body " "))
(defalias 'e-cmd 'pen-quote-args)

(defun pen-shellquote (input)
  "If string contains spaces or backslashes, put quotes around it, but only if it is not surrounded by ''."
  (if (or (string-match "\\\\" input)
          (string-match " " input)
          (string-match "*" input)
          (string-match "?" input)
          (string-match "\"" input))
      (e/q input)
    input))

(defun pen-list2cmd (l)
  (pen-snc (concat "cmd-nice-posix " (mapconcat 'pen-q l " "))))

(defun pen-cmd (&rest args)
  (pen-list2cmd args))

(defun tee (fp input)
  (pen-sn (pen-cmd "tee" fp) input))

(defun awk1 (s)
  (pen-sn "awk 1" s))

(defun tee-a (fp input)
  (pen-sn (pen-cmd "tee" "-a" fp) (awk1 (concat "\n" input))))

(defun pen-log-final-prompt (prompt)
  (if (f-directory-p penconfdir)
      (tee (f-join penconfdir "last-final-prompt.txt") prompt))
  prompt)

(defun test-template-newlines ()
  (interactive)
  (let ((ret (--> "<a>\n"
               (pen-onelineify it)
               (pen-expand-template-keyvals it '((:myval "hi")))
               (pen-expand-template it '("a" "bee"))
               (pen-unonelineify it))))
    (if (interactive-p)
        (pen-etv ret)
      ret)))

(defun test-template ()
  (interactive)
  (cl-macrolet ((expand-template
                 (string-sym)
                 `(--> ,string-sym
                    (pen-onelineify-safe it)
                    ;; (pen-expand-template-keyvals it subprompts-al)
                    (pen-expand-template it vals t)
                    (pen-expand-template-keyvals it var-keyvals-slugged t)
                    (pen-expand-template-keyvals it var-keyvals t)
                    (pen-unonelineify-safe it))))
    (let* ((subprompts '((meta . "and")
                         (intra . "and the")))
           (vals `("Something" "upon" "us"
                   ;; "   import python\n\n   from Function f\n   where f.getName().matches(\"get%\") and f.isMethod()\n   select f, \"This is a method called get...\"\n"
                   ,(pen-snc "pen-str onelineify" "   import python\n\n   from Function f\n   where f.getName().matches(\"get%\") and f.isMethod()\n   select f, \"This is a method called get...\"\n")))
           (var-keyvals-slugged
            '(("my-name" . "Shane")
              ("output" . "OUTPUT")))
           (var-keyvals
            '(("my name" . "Shane")))
           (ret
            (cl-loop for stsq in '("###" "\n"
                                   "Alpha <meta> Omega"
                                   "First <intra> last"
                                   "Once <2> a time <output>, <my name> said <4>...\n")
                     collect
                     ;; stsq
                     (expand-template stsq))))
      (if (interactive-p)
          (pen-etv (car (last ret)))
        ret))))

;; The LM may also send more info to this after the prompt has executed.
;; All this data will go into the Ink properties
(defvar pen-last-prompt-data '())

(defun pen-alist-to-list (al)
  (cl-loop for e in al collect (list (car e) (cdr e))))

;; (defun pen-list-to-alist (l)
;;   (cl-loop for e in l collect (cons (car e) (second e))))

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

(defun pen-str2num (s)
  "Returns nil if nil"
  (if (and s (stringp s))
      (string-to-number (str s))
    s))

(defun pen-hard-bound (val min max)
  (setq val (sor (str val)))
  (setq min (sor (str min)))
  (setq max (sor (str max)))

  (if val (setq val (string-to-number val)))
  (if min (setq min (string-to-number min)))
  (if max (setq max (string-to-number max)))

  (if (and val min (< val min))
      (setq val min))

  (if (and val max (> val max))
      (setq val max))

  val)

(defun pen-maybe-uniq (no-uniq lst)
  (if no-uniq
      lst
    (-uniq lst)))

(defvar pen-default-approximate-token-length-divisor 2.5)

(defun pen-num (val)
  (cond
   ((stringp val)
    (string-to-number val))
   (t val)))

(defun pen-approximate-token-length (text &optional divisor)
  (interactive (list (pen-selected-text)))
  (let ((len
         (round (+ (/ (length text)
                      (or
                       (pen-num divisor)
                       pen-default-approximate-token-length-divisor)) 5))))
    (if (interactive-p)
        (message "%s %d" "approximate-length: " len)
      len)))

(defun to-integer (n)
  ;; truncate
  ;; floor
  (cond
   ((stringp n) (round (string-to-number n)))
   ((numberp n) (round n))
   (t 0)))

(defun pen-n-words->n-tokens (n-words &optional chars-per-tok chars-per-word)
  (setq chars-per-word (or chars-per-word
                           (pen-get-average-word-length)))

  (to-integer (/ (* n-words chars-per-word) chars-per-tok)))

(defmacro pen-n-words->n-tokens/m (n-words)
  `(pen-n-words->n-tokens ,n-words (pen-num token-char-length)))

(defun pen-find-file (path)
  "Create directories and edit file"
  (pen-snc (pen-cmd "mkdir" "-p" (f-dirname path)))
  (if (re-match-p "/$" path)
      (progn
        (pen-snc (pen-cmd "mkdir" "-p" path))
        (find-file path))
    (progn
      (f-touch path)
      (find-file path))))

(defun pen-open-all-files (file-list)
  (interactive (read-string-hist "pen-open-all-files: "))
  (cl-loop for path in (pen-str2list file-list)
        do
        (ignore-errors
          (with-current-buffer
              (pen-find-file path)
            (kill-buffer)))))

(defun pen-touch-file (path)
  "Create directories and edit file"
  (pen-snc (pen-cmd "mkdir" "-p" (f-dirname path)))
  (if (re-match-p "/$" path)
      (progn
        (pen-snc (pen-cmd "mkdir" "-p" path)))
    (progn
      (f-touch path))))

(defun pen-touch-all-files (file-list)
  (interactive (read-string-hist "pen-touch-all-files: "))
  (cl-loop for path in (pen-str2list file-list)
        do
        (progn
          (message "%s" (concat "touching " path))
          (pen-touch-file path))))

(comment
 (pen-etv (pps (tuplist-to-alist '((a b) (c d))))))
(defun tuplist-to-alist (tuplist)
  (mapcar (lambda (tup)
            (cons (car tup) (second tup)))
          tuplist))
(defalias 'pen-list2alist 'tuplist-to-alist)
(defalias 'pen-list-to-alist 'tuplist-to-alist)

;; Use lexical scope with dynamic scope for overriding.
;; That way is more reliable than having lots of params.
;; Expected variables:
;; (func-name func-sym var-syms var-defaults doc prompt
;;  iargs prettifier cache path var-slugs n-collate
;;  filter completion lm-command stop-sequences stop-sequence max-tokens
;;  temperature top-p model no-trim-start no-trim-end preprocessors
;;  postprocessor prompt-filter n-completions)
;; (let ((max-tokens 1)) (funcall (cl-defun yo () (pen-etv max-tokens))))
;; (let ((max-tokens 1)) (funcall 'pf-asktutor/3 "emacs" "key bindings" "How do I kill a buffer?" :no-select-result t))

;; I don't think cl-defun passes on the current-global-prefix-arg
;; I have to extend cl-defun
;; Actually, I think it's the interactive functions which are doing it
;; That's correct, it is. Not possible to fix without modifying emacs c code.
;; Instead, use C-u 0 to update cache, instead of H-u

(require 'pen-define-prompt-function)

(defun pen-list-to-orglist (l)
  (mapconcat 'identity (mapcar (lambda (s) (concat "- " s)) l)
             "\n"))

(defun test-subprompts ()
  (interactive)
  (let* ((subprompts
          (pen-vector2list
           (ht-get
            (yamlmod-load
             (cat
              (f-join pen-prompts-directory "prompts" "generic-tutor-for-any-topic-and-subtopic-3.prompt")))
            "subprompts")))
         (keys (type (car (pen-vector2list subprompts)))))

    (pen-etv
     (pps keys))))

(defun test-subprompts-2 ()
  (interactive)
  (let ((l (pen-vector2list
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
    (pen-try
     (if (and (sor incl-name)
              (not (f-file-p incl-fp)))
         (error (concat "Missing include file for " fp))))
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
     (pen-vector2list
      (ht-get
       (mu
        (pen-prompt-file-load "$PROMPTS/generate-transformative-code.prompt"))
       "examples")))))
  (pen-etv
   (type
    (car
     (pen-vector2list
      (ht-get
       (mu
        (pen-prompt-file-load "$PROMPTS/generate-transformative-code.prompt"))
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
                        (engine-title (ht-get yaml-ht "engine-title")))
                   (ht-set yaml-ht "engine-path" path)
                   (message (concat "pen-mode: Loaded engine " engine-title))
                   (ht-set pen-engines engine-title yaml-ht))
                 (add-to-list 'pen-engines-failed path)))
       (if pen-engines-failed
           (progn
             (message "failed:")
             (message (pen-list2str pen-engines-failed))
             (message (concat (str (length pen-engines-failed)) " failed")))))))

  ;; Redefine this because we have updated options
  (defcustom pen-force-engine ""
    "Force using this engine"
    :type 'string
    :group 'pen
    :options (ht-keys pen-engines)
    :set (lambda (_sym value)
           (set _sym value))
    :get (lambda (_sym)
           (eval (sor _sym nil)))
    :initialize #'custom-initialize-default))

;; (ht-get (ht-get pen-prompts "pf-emacs-ielm/1") "path")
(defun pen-organise-prompts ()
  (interactive)
  (cl-loop for yaml-key in (ht-keys pen-prompts) do
           (let* ((yaml-ht (ht-get pen-prompts yaml-key))
                  (path (ht-get yaml-ht "path"))
                  (dn (f-dirname path))
                  (fn (pen-f-basename path))
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

(defun pen--htlist-to-alist (htlist)
  (if (vectorp htlist)
      (setq htlist (pen-vector2list htlist)))
  (mapcar
   (lambda (e)
     (if (ht-p e)
         (let ((key (car (ht-keys e))))
           (cons key
                 (ht-get e key)))
       e))
   htlist))

(defun pen--test-resolve-engine ()
  (interactive)
  (mu
   (let* ((engine-ht (yamlmod-read-file "$MYGIT/semiosis/engines/engines/reasonable-defaults.engine"))
          (defers (pen-vector2list (ht-get engine-ht "defer"))))
     (pen-etv (pps (pen--htlist-to-alist defers))))))

(defun pen-resolve-engine (starting-engine &optional requirements)
  "This should resolve the engine and may run recursively to do so."

  ;; Now that we have both engine and requirements, re-evaluate the engine.
  ;; Select the first from engine family.
  ;; following defers

  ;; pen-libre-only

  (comment
   (let* ((engine-ht (ht-get pen-engines starting-engine))
          (local (ht-get engine-ht "local"))
          (libre-model (ht-get engine-ht "libre-model"))
          (libre-dataset (ht-get engine-ht "libre-dataset"))
          (defers (pen-vector2list (ht-get engine-ht "defer")))
          (family (pen-vector2list (ht-get engine-ht "engine-family")))
          ;; This is a list of htables. convert to alist
          (fallbacks (pen-vector2list (ht-get engine-ht "fallback")))

          ;; Start with the defers.
          ;; If a defer exists with those exact requirements, then defer.
          ;; Choose the first that satisfies
          ;; it (has all the requirements in the
          ;; defer key).

          (defer-suggestions
            (-filter
             'identity
             (cl-loop for d in (pen--htlist-to-alist defers) collect
                      (let* ((defer-provisions (s-split "+" (car d)))
                             (newengine (cdr d))
                             ;; (newengine-ht (ht-get pen-engines newengine))
                             (satisfies (-reduce-from
                                         (lambda (a r)
                                           (and a (-contains-p defer-provisions r)))
                                         t
                                         requirements)))
                        (if satisfies
                            newengine)))))

          ;; Simply run this function recursively on these and collect the results
          (family-suggestions
           (-filter
            'identity
            (-flatten
             (cl-loop for e in family
                      collect
                      (pen-resolve-engine
                       e
                       requirements))))))

     ;; If this engine solves the requirements and has all the data, stop here
     ;; - if it has the appropriate speciality then select it
     ;; - otherwise

     (-reduce (lambda (c e)))

     ;; Select the first from family which satisfies the requirements

     (cl-loop for child in family collect
              (let ((child-engine-ht (ht-get pen-engines child))
                    (layers (ht-get child-engine-ht "layers")))))

     (if defers)))

  ;; If the current model isn't available, try
  ;; engines descended from or lighter engines

  ;; I actually shouldn't merely use the default engine.
  ;; That is because the model may be a different mode.
  ;; Then I should have default engines that are mode specific.
  (comment
   (let ((selected-engine starting-engine))
     (if (pen-engine-disabled-p selected-engine)
         (setq selected-engine pen-default-engine))

     selected-engine))

  starting-engine)

(defun pen-filter-with-prompt-function ()
  (interactive)
  (let ((f (fz
            (if (>= (prefix-numeric-value current-prefix-arg) 4)
                pen-prompt-functions
              ;; (pen-list-filterers)
              pen-prompt-filter-functions)
            nil nil "pen filter: ")))
    (if f
        (pen-filter
         (call-interactively (intern f)))
      ;; (filter-selected-region-through-function (intern f))
      )))

(defun pen-run-analyser-function ()
  "Run a prompt function which also has a results analyser. e.g. fact checker.
But use the results-analyser."
  (interactive)
  (let* ((pen-sh-update
          (or pen-sh-update (>= (prefix-numeric-value current-global-prefix-arg) 4))))
    (let ((f (fz
              pen-prompt-analyser-functions
              nil nil "pen analyser: ")))
      (if f
          (let ((analyse t))
            (call-interactively (intern f)))))))

(defun pen-run-editing-function ()
  (interactive)
  (let ((f (fz
            pen-editing-functions
            nil nil "pen editing function: ")))
    (if f
        (let ((analyse t))
          (call-interactively (intern f))))))

(defun pen-run-prompt-function ()
  (interactive)
  (let* ((pen-sh-update
          (or pen-sh-update (>= (prefix-numeric-value current-global-prefix-arg) 4)))
         (f (fz pen-prompt-functions nil nil "pen run: ")))
    (if f
        (call-interactively (intern f)))))

(defun pen-run-prompt-alias ()
  (interactive)
  (let* ((pen-sh-update
          (or pen-sh-update (>= (prefix-numeric-value current-global-prefix-arg) 4)))
         (f (fz pen-prompt-aliases nil nil "pen run (aliases): ")))
    (if f
        (call-interactively (intern f)))))

;; This is where I need to propertise company completions
;; Unfortunately, it requires me to duplicate a whole lot of company code
(defun pen-company--insert-candidate (candidate)
  (when (> (length candidate) 0)
    (setq candidate (substring-no-properties candidate))
    ;; XXX: Return value we check here is subject to change.
    (if (eq (company-call-backend 'ignore-case) 'keep-prefix)
        (pen-insert (ink-propertise (company-strip-prefix candidate)))
      (unless (equal company-prefix candidate)
        (delete-region (- (point) (length company-prefix)) (point))
        (pen-insert (ink-propertise candidate))))))

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

(defmacro pen-context (n-lines &rest body)
  "This wraps around pen function calls to only allow them n lines of context"
  `(eval
    `(let ((n-lines-context ,,n-lines))
       ,',@body)))

(defmacro pen-engine (engine-name &rest body)
  "This wraps around pen function calls to force the engine"
  (if (sor engine-name)
      `(eval
        `(let ((engine ,,engine-name)
               (force-engine ,,engine-name))
           ,',@body))
    `(progn ,@body)))

(defmacro pen-force-custom (&rest body)
  "This forces various settings depending on customizations"
  (let ((overrides
         (flatten-once
          (list
           (if pen-force-temperature
               (list `(temperature pen-force-temperature)))

           (if pen-force-single-collation
               (list `(pen-single-generation-b t)
                     `(n-collate 1)))

           (if pen-force-one
               (list `(n-collate 1)
                     `(n-completions 1)))

           (if pen-force-no-uniq-results
               (list `(no-uniq-results t)))

           (if pen-force-n-collate
               (list `(n-collate pen-force-n-collations)))

           (if pen-force-n-completions
               (list `(n-completions pen-force-n-completions)))

           (if pen-force-few-completions
               (list `(n-completions 3)
                     ;; Also, ensure n-collate = 1 because
                     ;; n-completions may be emulated with collate
                     `(n-collate 1)))))))
    `(eval
      `(let ,',overrides
         ,',@body))))

(defmacro pen-force (tups &rest body)
  "This forces prompt function parameters through dynamic scope"
  (let ((overrides tups))
    `(eval
      `(let ,',overrides
         ,',@body))))

(comment
 (idefun sha1 (s))

 (pen-force
  ((temperature 0.0))
  (sha1 "sugar shane"))

 (pen-force
  ((temperature 0.9))
  (sha1 "ceiling"))

 (pen-human
  (pen-force
   ((temperature 0.0))
   (sha1 "ceiling"))))

(defun pen-force-custom-test ()
  (interactive)
  (pen-etv (pen-force-custom (message (str (pen-var-value-maybe 'n-collate))))))

;; TODO I absolutely need to be using iλ functions everywhere
(defmacro pen-one (&rest body)
  "Just generate one completion, and do not select"
  `(eval
    `(let ((pen-single-generation-b t)
           (n-collate 1)
           (n-completions 1)
           ;; This is needed because the engine can also force n-completions
           (force-n-completions 1)
           (force-n-jobs 1)
           (pen-no-select-result t)
           (pen-select-only-match t))
       ,',@body)))

(defmacro pen-car (&rest body)
  `(eval
    `(car
      (let ((pen-single-generation-b t)
            (n-collate 1)
            (n-completions 1)
            ;; This is needed because the engine can also force n-completions
            (force-n-completions 1)
            (force-n-jobs 1)
            (pen-no-select-result t)
            (pen-select-only-match t))
        ,',@body))))

(defmacro pen-get-prompt (&rest body)
  `(eval
    `(car
      (let ((pen-single-generation-b t)
            (n-collate 1)
            (n-completions 1)
            ;; This is needed because the engine can also force n-completions
            (force-n-completions 1)
            (pen-no-select-result t)
            (pen-select-only-match t)
            (pen-no-gen t)
            (pen-include-prompt t))
        ,',@body))))

;; This is not the same as pen-train-model, which doesn't exist yet.
;; When you train a function, you need to invoke the function as you would but also give it  expected possible outputs.
(defmacro pen-train-function (invocation examples)
  ;; This has to work via the docker container, somehow.
  ;; Run and save results to the history.
  ;; But run with desired result(s), along with a pen-train-function boolean.

  ;; Don't use pen-get prompt. That's too slow.
  ;; (pen-get-prompt)

  ;; Run the function several times with different parameters to generate full prompts
  ;; Then create a list of (prompt+result)s and include them when prompting in future
  ;; I could add to a list of such function-result strings and take n from them.
  `(eval
    `(car
      (let ((pen-single-generation-b t)
            (n-collate 1)
            (n-completions 1)
            ;; This is needed because the engine can also force n-completions
            (force-n-completions 1)
            (pen-no-select-result t)
            (pen-select-only-match t)
            (pen-no-gen t)
            (pen-include-prompt t)
            (pen-train-function t)
            (pen-force-results ,',examples))
        ,',invocation))))

(defmacro pen-single-generation (&rest body)
  "This wraps around pen function calls to make them only create one generation"
  `(eval
    `(let ((pen-single-generation-b t)
           (n-collate 1)
           (n-completions 1)
           (n-jobs 1)
           ;; This is needed because the engine can also force n-completions
           (force-n-completions 1))
       ,',@body)))

(defmacro pen-single-batch (&rest body)
  ""
  `(eval
    `(let ((do-pen-batch t)
           (pen-single-generation-b t)
           (n-collate 1)
           (n-completions 1)
           (n-jobs 1)
           ;; This is needed because the engine can also force n-completions
           (force-n-completions 1))
       ,',@body)))

(defmacro pen-no-select (&rest body)
  ""
  `(eval
    `(let ((do-pen-batch t)
           (pen-no-select-result t))
       ,',@body)))

(defmacro pen-filter (&rest body)
  ""
  `(eval
    `(let ((filter t)
           ;; (insertion nil)
           (no-insertion t)
           ;; (new-document nil)
           (no-new-document t)
           ;; (info nil)
           (no-info t)
           ;; (completion nil)
           (no-completion t))
       ,',@body)))

;; This wasn't sufficient. To make it work from the Host interop and from the minibuffer, I need eval
(comment
 (defmacro pen-long-complete (&rest body)
   "This wraps around pen function calls to make them complete long"

   ;; force-completion is just a hint as to what this function is doing
   ;; if force-completion is specified and the engine (i.e. AIx) strips the starting whitespace
   ;; then pen will be hinted to add some whitespace.
   `(let ((force-completion t)
          (max-generated-tokens 200)
          (stop-sequence "##long complete##")
          (stop-sequences '("##long complete##")))
      ,@body)))

(defmacro pen-words-complete (&rest body)
  "This wraps around pen function calls to make them complete long"
  ;; force-completion is just a hint as to what this function is doing
  ;; if force-completion is specified and the engine (i.e. AIx) strips the starting whitespace
  ;; then pen will be hinted to add some whitespace.
  `(eval
    `(let ((force-completion t)
           (max-generated-tokens 5)
           (stop-sequence "##long complete##")
           (stop-sequences '("##long complete##"))
           (n-collate 1)
           (n-completions 20))
       ,',@body)))

(defmacro pen-words-complete-nongreedy (&rest body)
  "This wraps around pen function calls to make them complete words"
  `(eval
    `(let ((force-completion t)
           (max-generated-tokens 5)
           (stop-sequence (or (and (variable-p 'stop-sequence)
                                   (eval 'stop-sequence))
                              "##long complete##"))
           (stop-sequences (or (and (variable-p 'stop-sequences)
                                    (eval 'stop-sequences))
                               '("##long complete##")))
           (n-collate 1)
           (n-completions 20))
       ,',@body)))

(defmacro pen-n-complete (n &rest body)
  "This wraps around pen function calls to make them complete a single word"
  `(eval
    `(let ((force-completion t)
           (max-generated-tokens ,,n)
           (stop-sequence "##long complete##")
           (stop-sequences '("##long complete##"))
           (n-collate 1)
           (n-completions 3))
       ,',@body)))

(defmacro pen-word-complete (&rest body)
  "This wraps around pen function calls to make them complete a single word"
  `(eval
    `(let ((force-completion t)
           (max-generated-tokens 1)
           (stop-sequence "##long complete##")
           (stop-sequences '("##long complete##"))
           (n-collate 1)
           (n-completions 40))
       ,',@body)))

(defmacro pen-word-complete-nongreedy (&rest body)
  "This wraps around pen function calls to make them complete a singel word"
  `(eval
    `(let ((force-completion t)
           (max-generated-tokens 1)
           (stop-sequence (or (and (variable-p 'stop-sequence)
                                   (eval 'stop-sequence))
                              "##long complete##"))
           (stop-sequences (or (and (variable-p 'stop-sequences)
                                    (eval 'stop-sequences))
                               '("##long complete##")))
           (n-collate 1)
           (n-completions 40))
       ,',@body)))

(defmacro pen-short-complete (&rest body)
  "This wraps around pen function calls to make them complete long"
  `(eval
    `(let ((force-completion t)
           (max-generated-tokens 100)
           (stop-sequence "##long complete##")
           (stop-sequences '("##long complete##")))
       ,',@body)))

(defmacro pen-long-complete (&rest body)
  "This wraps around pen function calls to make them complete long"
  `(eval
    `(let ((force-completion t)
           (max-generated-tokens 200)
           (stop-sequence "##long complete##")
           (stop-sequences '("##long complete##")))
       ,',@body)))

(defmacro pen-medium-complete (&rest body)
  "This wraps around pen function calls to make them complete long"
  `(eval
    `(let ((force-completion t)
           (max-generated-tokens 100)
           (stop-sequence "##long complete##")
           (stop-sequences '("##long complete##")))
       ,',@body)))

(defmacro pen-long-complete-nongreedy (&rest body)
  "This wraps around pen function calls to make them complete long"
  `(eval
    `(let ((force-completion t)
           (max-generated-tokens 200)
           (stop-sequence (or (and (variable-p 'stop-sequence)
                                   (eval 'stop-sequence))
                              "##long complete##"))
           (stop-sequences (or (and (variable-p 'stop-sequences)
                                    (eval 'stop-sequences))
                               '("##long complete##"))))
       ,',@body)))

(defmacro pen-desirable-line-complete (&rest body)
  "This wraps around pen function calls to make them complete line only"
  ;; TODO set a filter for results.
  ;; This should be pf-textual-semantic-search-filter/3 with a query and counterquery
  `(eval
    `(let ((force-completion t)
           (max-generated-tokens 100)
           (n-completions 20)
           (n-collate 2)
           (stop-sequence "\n")
           (stop-sequences '("\n")))
       ,',@body)))

(defmacro pen-line-complete (&rest body)
  "This wraps around pen function calls to make them complete line only"
  `(eval
    `(let ((force-completion t)
           (max-generated-tokens 100)
           (n-completions 20)
           (n-collate 2)
           (stop-sequence "\n")
           (stop-sequences '("\n")))
       ,',@body)))

(defmacro pen-lines-complete (&rest body)
  "This wraps around pen function calls to make them complete line only"
  `(eval
    `(let ((force-completion t)
           (max-generated-tokens 50)
           (n-completions 2)
           (n-collate 1)
           ;; (no-utilise-code t)
           (inject-gen-start "\n")
           (stop-sequence "##long complete##")
           (stop-sequences '("##long complete##"))
           ;; Delete the last line. But only if more than 1?
           (postprocessor "pen-str maybe-delete-last-line"))
       ,',@body)))

(defmacro pen-line-complete-nongreedy (&rest body)
  "This wraps around pen function calls to make them complete line only"
  `(eval
    `(let ((force-completion t)
           (max-generated-tokens 100)
           (n-completions 20)
           (n-collate 2)
           (stop-sequence (or (and (variable-p 'stop-sequence)
                                   (eval 'stop-sequence))
                              "\n"))
           (stop-sequences (or (and (variable-p 'stop-sequences)
                                    (eval 'stop-sequences))
                               '("\n"))))
       ,',@body)))

(defmacro pen-less-repetition (&rest body)
  "This wraps around pen function calls to give them a repetition penalty"
  `(eval
    `(let ((frequency-penalty 0.3))
       ,',@body)))

(defun pen-complete-function (preceding-text &rest args)
  ;; (pf-generic-completion-50-tokens/1 preceding-text)

  ;; TODO Ensure privacy - pen-avoid-divulging
  (pen-less-repetition
   (if (string-empty-p (s-chompall (buffer-string)))
       (eval `(pf-generate-the-contents-of-a-new-file/6
               preceding-text
               nil nil nil nil nil
               ,@args))
     (if (and (or (derived-mode-p 'prog-mode)
                  (derived-mode-p 'term-mode)
                  (derived-mode-p 'text-mode))
              (not (string-equal (buffer-name) "*scratch*")))
         ;; Can't put ink-propertise here
         (eval `(let ((engine "OpenAI Codex"))
                  ;; (pf-generic-file-type-completion/3 (pen-detect-language) preceding-text (pen-surrounding-proceeding-text) ,@args)
                  (if (pen-var-value-maybe 'no-utilise-code)
                      (pf-generic-file-type-completion-nocode/2 (pen-detect-language) preceding-text ,@args)
                    (if pen-cost-efficient
                        (pf-generic-file-type-completion/2 (pen-detect-language) preceding-text ,@args)
                      (pf-generic-file-type-completion/3 (pen-detect-language) preceding-text (pen-snc "sed 1d" (pen-proceeding-text)) ,@args)))))
       (eval `(pf-generic-completion-50-tokens/1 preceding-text ,@args))))))

(defun ekm (binding)
  (let ((fun (key-binding (kbd binding))))
    (if fun
        (call-interactively fun)
      (execute-kbd-macro (kbd binding)))))

(defun pen-complete-insert (s)
  "This is a completely useless function ,currently"
  (pen-insert s))

(defun pen-complete-word (preceding-text &optional tv)
  "Word completion"
  (interactive (list (pen-preceding-text) nil))
  (let ((response
         (pen-word-complete
          (pen-complete-function preceding-text))))
    (if tv
        (pen-etv (ink-propertise response))
      (pen-complete-insert (ink-propertise response)))))

(defun pen-complete-words (preceding-text &optional tv)
  "Words completion"
  (interactive (list (pen-preceding-text) nil))

  (let ((response
         (if (> (prefix-numeric-value current-prefix-arg) 1)
             ;; Complete this many words -- fudge it. Use tokens per word in future
             (pen-n-complete (prefix-numeric-value current-prefix-arg)
                             (pen-complete-function preceding-text))
           (pen-words-complete
            (pen-complete-function preceding-text)))))
    (if tv
        (pen-etv (ink-propertise response))
      (pen-complete-insert (ink-propertise response)))))

(defun pen-complete-desirable-line (preceding-text &optional tv)
  "Desirable line completion"
  (interactive (list (pen-preceding-text) nil))
  (let ((response
         (pen-desirable-line-complete
          (pen-complete-function preceding-text))))
    (if tv
        (pen-etv (ink-propertise response))
      (pen-complete-insert (ink-propertise response)))))

(defun pen-complete-line (preceding-text &optional tv)
  "Line completion"
  (interactive (list (pen-preceding-text) nil))
  (let ((response
         (pen-line-complete
          (pen-complete-function preceding-text))))
    (if tv
        (pen-etv (ink-propertise response))
      (pen-complete-insert (ink-propertise response)))))

(defun pen-complete-line-maybe (preceding-text &optional tv)
  (interactive (list (pen-preceding-text) nil))
  (if mark-active
      ;; Disabled pen-mode temporarily
      (let* ((pen nil)
             (fun (key-binding (kbd "M-3"))))
        (call-interactively fun))
    (pen-complete-line preceding-text tv)))

(defun pen-complete-medium (preceding-text &optional tv)
  "Long-form completion (medium length). This will generate lots of text.
May use to generate code from comments."
  (interactive (list (pen-preceding-text) nil))
  (let ((response
         (pen-medium-complete
          (pen-complete-function preceding-text))))
    (if tv
        (pen-etv (ink-propertise response))
      (pen-complete-insert (ink-propertise response)))))

(defun pen-complete-short (preceding-text &optional tv)
  "Short-form completion."
  (interactive (list (pen-preceding-text) nil))
  (let ((response
         (pen-short-complete
          (pen-complete-function preceding-text))))
    (if tv
        (pen-etv (ink-propertise response))
      (pen-complete-insert (ink-propertise response)))))

(defun pen-complete-long (preceding-text &optional tv)
  "Long-form completion. This will generate lots of text.
May use to generate code from comments."
  (interactive (list (pen-preceding-text) nil))
  (let ((response
         (pen-long-complete
          (pen-complete-function preceding-text))))
    (if tv
        (pen-etv (ink-propertise response))
      (pen-complete-insert (ink-propertise response)))))

(defun pen-complete-lines (preceding-text &optional tv)
  "Lines-form completion. This will generate lots of text.
May use to generate code from comments."
  (interactive (list (pen-preceding-text) nil))
  (let ((response
         (pen-lines-complete
          (pen-complete-function preceding-text))))
    (if tv
        (pen-etv (ink-propertise response))
      (pen-complete-insert (ink-propertise response)))))

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

;; I need access to the existing completions.
;; I may need to actually keep track of the inputs I have made.
;; I need a database for this.

(defun pen-continue-prompt ())

(require 'pen-borrowed)
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
(require 'pen-yasnippet)
(require 'pen-filters)
(require 'pen-term)
(require 'pen-lsp-client)
(require 'ilambda)
(require 'pen-cacheit)
(require 'pen-ii)
(require 'pen-comint)
(require 'pen-tty)
(require 'pen-tmux)
(require 'pen-looking-glass)
(require 'pen-buffer-state)
(require 'pen-apostrophe)
(require 'pen-melee)
(require 'pen-channel)
(require 'pen-scratch)
(require 'pen-minor-modes)
(require 'pen-modeline)
(require 'pen-hide-minor-modes)
(require 'pen-dired)
(require 'pen-semiosis-protocol)
(require 'pen-mad-teaparty)
(require 'pen-documents)
(require 'pen-helm)
(require 'pen-media)

(defun pen-lsp-explain-error ()
  (interactive)
  (let ((error (lsp-ui-pen-diagnostics)))
    (if (sor error)
        (pen-etv
         (pf-explain-error/3
          (pen-detect-language-ask)
          error
          ;; (pen-surrounding-context)
          (rx/chomp (current-line-string)))))))

(add-to-list 'auto-mode-alist '("\\.prompt\\'" . prompt-description-mode))

(defun pen-copy-from-hist ()
  (interactive)
  (let* ((fp (f-join penconfdir "prompt-hist.el"))
         (sel (fz (pen-sn "tac" (s/awk1 (e/cat fp))) nil nil "pen-copy-from-hist: "))
         (al (eval-string sel))
         (vals (apply 'pen-cmd (eval-string (concat "'" (cdr (assoc "PEN_VALS" al)))))))
    (xc
     (concat
      (cdr (assoc "PEN_FUNCTION_NAME" al))
      " "
      vals))))

(defun pen-vector2list (v)
  (append v nil))

;; TODO Make this work properly
(cl-defun pf-continue-last (&key no-select-result include-prompt no-gen select-only-match variadic-var inject-gen-start force-interactive)
  (interactive)
  (pen-continue-from-hist t force-interactive))

(defun pen-continue-from-hist (&optional last force-interactive)
  (interactive)
  (let* ((fp (f-join penconfdir "prompt-hist.el"))
         (hist-list (pen-str2list (pen-sn "tac" (s/awk1 (e/cat fp)))))
         (sel
          (if last
              (car hist-list)
            (fz hist-list nil nil "pen-continue-from-hist: ")))
         (al (eval-string sel))
         (vals (eval-string (concat "'" (cdr (assoc "PEN_VALS" al)))))
         (orig-inject-text (pen-decode-string (cdr (assoc "PEN_INJECT_GEN_START" al))))
         ;; string-bytes was tricky to find
         (orig-inject-len (string-bytes orig-inject-text))
         (prompt (pen-decode-string (cdr (assoc "PEN_PROMPT" al))))
         (prompt-length (length prompt))
         (result (cdr (assoc "PEN_RESULT" al)))
         (results (cdr (assoc "PEN_RESULTS" al)))
         ;; This is the :pp pos of full prompt (i.e. just before url)
         (collect-from-pos (or (pen-num (cdr (assoc "PEN_COLLECT_FROM_POS" al))) 0))
         (end-pos (or (pen-num (cdr (assoc "PEN_END_POS" al))) 0))
         ;; end-pos-original is the pos of full prompt just after the url
         ;; end-pos is a few chars too large sometimes
         ;; prompt-length is a few chars too short
         (end-pos-original
          (- end-pos orig-inject-len))

         ;; The URL in imagine website
         (pp-inject-length
          (- end-pos-original collect-from-pos))

         (fun (intern (cdr (assoc "PEN_FUNCTION_NAME" al)))))

    (if (sor results)
        (setq results (pen-vector2list (json-parse-string results))))

    (let* ((result
            (cond
             ((and (stringp result)
                   (re-match-p "\\`[0-9]+\\'" result))
              (fz results nil nil "pen-continue-from-hist result: "))
             ((stringp result) result)
             (results
              (fz results nil nil "pen-continue-from-hist result: "))))
           (the-increase (- (length result)
                            orig-inject-len)))

      (apply
       fun
       (append vals
               `(:inject-gen-start
                 ,(s-right
                   (- (length result)
                      pp-inject-length)
                   result)
                 :force-interactive
                 (or (interactive-p)
                     force-interactive)))))))

(defun pen-final-loads ()
  (load-library "pen-custom")
  (load-library "pen-ii")
  (load-library "pen-company-lsp")
  (load-library "pen-tty")
  (pen-load-config))

(add-hook 'window-setup-hook ;; 'emacs-startup-hook ;; 'after-init-hook
          'pen-final-loads t)

(defun test-stop-validator ()
  (pen-snq "sed -z 's/\\n/<newline>/g' | grep -vq \"<newline>\"" "dlf\nkjsdf"))

(defun pen-see-pen-command-hist ()
  (interactive)
  (find-file (f-join penconfdir "all-pen-commands.txt")))

;; (comment
;;            (setq final-prompt (concat (replace-regexp-in-string "\\(<:fz-eol>\\).*\\'" "" final-prompt nil nil 1) completion)))

(defun pen-test-fzeof ()
  (interactive)
  (let* ((final-prompt "Once upon a time there <:fz-eol> yo")
         (func-sym 'pf-generic-completion-50-tokens/1)
         (pos))

    (while (setq pos (byte-string-search "<:fz-eol>" final-prompt))

      (let* ((completions
              (eval
               `(let* ((force-prompt ,(s-left pos final-prompt))
                       (stop-sequence "\n")
                       (stop-sequences '("\n"))
                       (max-tokens 50)
                       (do-pen-batch t)
                       (pen-no-select-result t))
                  (,func-sym))))
             (completion (fz completions nil nil "select part:")))

        (setq final-prompt (concat
                            (replace-regexp-in-string "\\(<:fz-eol>\\).*\\'" completion final-prompt nil nil 1)
                            ""))))
    (pen-etv final-prompt)))

(defun pen-test-batch-mode ()
  (interactive)
  (eval `(pen-list2str (pen-batch (pen-single-generation (pf-imagine-a-infocom-game-interpreter/2 nil nil :no-select-result t :temperature nil :prompt-hist-id nil :include-prompt nil :no-gen nil :variadic-var nil :override-prompt nil :inject-gen-start nil))))))

;; (imacro define-function-with-ignore-errors (&body))
;; (imacro/2 generate-fibonacci (n))
;; (imacro/1 generate-fibonacci)

(defmacro pen-human (&rest body)
  "Run prompt functions below with the human engine"
  `(eval
    `(let ((pen-force-engine "Human"))
       ,',@body)))

(provide 'pen)
