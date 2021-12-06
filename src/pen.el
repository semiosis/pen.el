;;; pen.el --- Prompt Engineering functions

(setq large-file-warning-threshold nil)

(defvar pen-map (make-sparse-keymap)
  "Keymap for `pen.el'.")

(defmacro lm (&rest body)
  "Interactive lambda with no arguments."
  `(lambda () (interactive) ,@body))

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
(require 'pp)
(require 's)
(require 'cl-macs)
(require 'company)
(require 'selected)
(require 'pcsv)
(require 'pcre2el)
(require 'asoc)
(require 'transducer)
(require 'lsp-mode)
(require 'lsp-ui)
(require 'lispy)
(require 'pen-company-lsp)
(require 'pen-nlp)
(require 'pen-which-key)
(require 'pen-elisp)
(require 'pen-custom)
(require 'pen-configure)
(require 'pen-hist)
(require 'pen-eww)
(require 'eww-lnum)
(require 'pen-edit)
(require 'pen-client)
(require 'pen-autosuggest)

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
                                                             override-prompt
                                                             force-interactive
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
             (intern client-fn-name)))
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
                                          ("PEN_GEN_TIME" . ,(time-to-seconds))))

             (pen-append-to-file
              (concat
               "\n'"
               (pen-snc "tr -d '\\n'" (pps pen-last-prompt-data)))
              (f-join penconfdir "prompt-hist-preselect.el"))

             ;; Many a  transformation pipeline here could benefit from transducers
             ;; https://dev.solita.fi/2021/10/14/grokking-clojure-transducers.html
             ;; https://github.com/FrancisMurillo/transducer.el
             (let* (;; Keep in mind this both updates memoization and the bash cache

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
                           ,force-engine
                           pen-force-engine
                           (pen-var-value-maybe 'engine)
                           ,engine)))

                    (final-temperature)
                    (final-lm-command)
                    (final-model)

                    ;; Actually, only override model, temperature and lm-command again if force-engine is set.
                    ;; And with final-force-engine, only override final-model, final-temperature and final-lm-command.
                    ;; Don't override final-'force'-model, etc.
                    (final-engine
                     (progn
                       (if (and
                            (not pen-prompt-force-engine-disabled)
                            (sor ,force-engine))
                           (progn
                             (pen-log ".prompt Forcing engine:")
                             (pen-log ".prompt Forcing engine n-completions")
                             (pen-log ".prompt Forcing engine model")
                             (pen-log ".prompt Forcing engine all keys etc.")
                             (let* ((engine (ht-get pen-engines ,force-engine))
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
                               (if engine
                                   (setq final-engine engine))
                               (if model
                                   (setq final-model model))
                               (if lm-command
                                   (setq final-lm-command lm-command))
                               (if api-endpoint
                                   (setq final-api-endpoint api-endpoint)))))
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

                    (final-include-prompt
                     (or (pen-var-value-maybe 'include-prompt)
                         ,include-prompt))

                    ;; What was this?
                    (final-no-gen
                     (or (pen-var-value-maybe 'no-gen)
                         ,no-gen))

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

                    (final-api-endpoint
                     (or (pen-var-value-maybe 'api-endpoint)
                         ,api-endpoint))

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

                    (final-inject-gen-start
                     (expand-template
                      (or
                       inject-gen-start
                       (pen-var-value-maybe 'inject-gen-start)
                       ,inject-gen-start)))

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
                            final-temperature ;At this stage, could only have been set by force-engine
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

                    ;; pretext is useful for examples for the generation
                    (final-prompt (concat pretext final-prompt))

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

                    (collect-from-pos (or (byte-string-search "<:pp>" final-prompt)
                                          ;; (length final-prompt)
                                          (string-bytes final-prompt)))

                    ;; Maybe just use <:pp> instead
                    ;; (query-pos (or (byte-string-search "<:qp>" final-prompt)
                    ;;                ""))

                    (final-prompt
                     (if (sor final-inject-gen-start)
                         (if (re-match-p "<:pp>" final-prompt)
                             (concat final-prompt final-inject-gen-start)
                           (concat final-prompt "<:pp>" final-inject-gen-start))
                       final-prompt))
                    ;; This is where to start collecting from

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
                     (if final-no-gen
                         (progn
                           (message "Prompting function aborted")
                           '(""))
                       ;; (list (message "Try UPDATE=y or debugging"))
                       (pen-maybe-uniq
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
                                    (list (message "Try UPDATE=y or debugging"))))))))

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
                       result)))

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
                   result))))))))))

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
                         (pen-unonelineify-safe it))))

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

                        ;; variables
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
                                          (eval-string ,,(str default))
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

(defmacro pen-force-custom (&rest body)
  "This forces various settings depending on customizations"
  (let ((overrides
         (flatten-once
          (list
           ;; (if (sor pen-force-engine)
           ;;     (progn
           ;;       (pen-log (concat "Custom forcing engine: " pen-force-engine))
           ;;       (pen-log "Custom forcing engine n-completions")
           ;;       (pen-log "Custom forcing engine model")
           ;;       (pen-log "Custom orcing engine all keys etc.")
           ;;       (let* ((engine (ht-get pen-engines pen-force-engine))
           ;;              (keys (mapcar 'intern (mapcar 'slugify (ht-keys engine))))
           ;;              (vals (ht-values engine))
           ;;              (tups (-zip-lists keys vals)))
           ;;         (append
           ;;          `((engine ,pen-force-engine))
           ;;          tups))))

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
 (idefun sha-hash-string (s))

 (pen-force
  ((temperature 0.0))
  (sha-hash-string "sugar shane"))

 (pen-force
  ((temperature 0.9))
  (sha-hash-string "ceiling"))

 (pen-force
  ((temperature 0.0))
  (sha-hash-string "ceiling")))

(defun pen-force-custom-test ()
  (interactive)
  (pen-etv (pen-force-custom (message (str (pen-var-value-maybe 'n-collate))))))

;; TODO I absolutely need to be using iλ functions everywhere
(defmacro pen-one (&rest body)
  `(eval
    `(let ((pen-single-generation-b t)
           (n-collate 1)
           (n-completions 1)
           ;; This is needed because the engine can also force n-completions
           (force-n-completions 1)
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
            (pen-no-select-result t)
            (pen-select-only-match t))
        ,',@body))))

(defmacro pen-single-generation (&rest body)
  "This wraps around pen function calls to make them only create one generation"
  `(eval
    `(let ((pen-single-generation-b t)
           (n-collate 1)
           (n-completions 1)
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
  "This wraps around pen function calls to make them complete line only"
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
(require 'pen-scratch)

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

(provide 'pen)