(require 'handle)

(defun xref-find-definitions-immediately ()
  (interactive)
  (deselect)
  (xref-find-definitions
   (pen-thing-at-point)))

(defun xref-find-definitions-around-advice (proc &rest args)
  (deselect)
  (let ((res (apply proc args)))
    res))
(advice-add 'xref-find-definitions :around #'xref-find-definitions-around-advice)
(advice-add 'lsp-find-references :around #'xref-find-definitions-around-advice)
;; (advice-remove 'xref-find-definitions #'xref-find-definitions-around-advice)

(defset pen-doc-queries
  '(
    "What is '${query}' and what how is it used?"
    "What are some examples of using '${query}'?"
    "What are some alternatives to using '${query}'?"))

;; v:pen-ask-documentation

(defun pen-docs-for-thing-given-screen ()
  (interactive)
  (if (yn "No docfn available. Use Pen?")
      (call-interactively 'pf-get-documentation-for-syntax-given-screen/2)
    (error "Pen declined")))

(defmacro gen-term-command (cmd &optional reuse ask)
  "Generate an interactive emacs command for a term command"
  (let* ((cmdslug (concat "et-" (slugify cmd)))
         (fsym (intern cmdslug))
         (bufname (concat "*" cmdslug "*")))
    `(defun ,fsym ()
       (interactive)
       (if (or (not ,ask)
               (yn (concat "Starting " (q cmd) ". Continue?")))
           (pen-term (pen-nsfa ,cmd) nil nil ,bufname ,reuse)))))
(defalias 'etc 'gen-term-command)

(defun pen-ask-documentation (thing query)
  (interactive
   (let* ((thing (pen-thing-at-point))
          (qs (mapcar (lambda (s) (s-format s 'aget `(("query" . ,thing)))) pen-doc-queries))
          (query
           (fz qs
               nil nil
               "pen-ask-documentation: ")))
     (list
      thing
      query))))

(defun clojure-open-test ()
  "Go to the test. DWIM"
  (interactive)
  (if (major-mode-p 'clojure-mode)
      (let* ((bn (f-basename (buffer-file-name)))
             (mant (f-mant (f-basename (buffer-file-name))))
             (funname
              (if (s-match "_test.clj" bn)
                  (error "You are already in a test file")
                (car (s-split "\\." bn))))
             (topdir (vc-get-top-level))
             (namespace (cider-current-ns))
             (srcdir (cider-current-dir))
             (testdir (s-replace-regexp "/src/" "/test/" (cider-current-dir)))
             (testpath (f-join testdir (concat mant "_test.clj")))
             (top-namespace (car (s-split "\\." namespace))))
        (with-current-buffer
            (find-file testpath)))))

;; (advice-add 'cider-doc-thing-at-point :around #'around-advice-save-excursion)
;; (advice-remove 'cider-doc-thing-at-point #'around-advice-save-excursion)

(handle '(clojure-mode clojurescript-mode cider-repl-mode inf-clojure)
        ;; Re-using may not be good, actually, if I'm working with multiple projects
        :repls (list
                'cider-switch-to-repl-buffer
                'cider-switch-to-repl-buffer-any
                ;; (etc "nvc -f clj-rebel" t)
                ;; (etc "nvt clj-rebel" t)
                ;; (etc "tns clj-rebel" t)
                (etc "tmwr clj-rebel" t t)
                ;; (etc "nvc -f lein repl" t)
                (etc "lein repl" t))
        :copylastresult '(pen-copy-last-clojure-result)
        :formatters '(lsp-format-buffer)
        :docs '(pen-esp-docs-for-thing-if-prefix
                pen-doc-override
                ;; Cider is better, especially for babashka scripts
                cider-doc-thing-at-point
                lsp-describe-thing-at-point
                pen-doc-thing-at-point
                ;; pen-docs-for-thing-given-screen
                )

        ;; Project syms (not general syms)
        :fz-sym '(clojure-fz-symbol
                  ;; clojure-go-to-symbol
                  )
        :godef '(lsp-find-definition
                 cider-find-var
                 xref-find-definitions-immediately
                 helm-gtags-dwim)
        :errors '(pen-clojure-switch-to-errors
                  flycheck-list-errors
                  lsp-ui-flycheck-list)
        :docsearch '(pen-doc)

        :runmain '(cider-run)

        ;; mx
        :runfunc '(pen-cider-run-function)

        :test '(cider-test-run-test)
        :testall '(cider-test-run-ns-tests)
        :testreport '(cider-test-show-report)
        :toggle-test '(projectile-toggle-between-implementation-and-test
                       clojure-open-test)

        ;; <help> f
        ;; Docfun is global symbol search
        :docfun '(helm-cider-apropos-symbol
                  pen-cider-docfun)

        ;; For clj-refactor, see:
        ;; ;; j:pen-clojure-mode-hook
        :refactor '()
        :rename-symbol '(lsp-rename
                         cljr-rename-symbol)
        :references '(lsp-ui-peek-find-references lsp-find-references pen-counsel-ag-thing-at-point)
        :projectfile '(pen-clojure-project-file)
        :preverr '(cider-jump-to-compilation-error)
        :nexterr '(cider-jump-to-compilation-error)

        :nextdef '(pen-prog-next-def
                   lispy-flow)
        :prevdef '(pen-prog-prev-def))

(defun repl-or-slime ()
  (interactive)

  (let ((bn "*slime-repl roswell*"))
    (if (buffer-exists bn)
        (switch-to-buffer bn)
      (call-interactively 'slime))))

(handle '(lisp-mode common-lisp-mode slime-repl-mode)
        ;; Re-using may not be good, actually, if I'm working with multiple projects
        :repls (list
                ;; 'sly-mrepl
                ;; 'slime
                'repl-or-slime
                ;; 'slime-repl
                )
        :formatters '(lsp-format-buffer)
        :docs '(pen-doc-override
                lsp-describe-thing-at-point
                slime-documentation

                ;; slime-autodoc-manually
                )

        ;; Not at point - manual entry of symbol, searches web
        :docsearch '(slime-documentation-lookup
                     pen-doc)

        ;; Not at point - manual entry of symbol with fuzzy finder
        :docfun '(slime-documentation-lookup)

        :toggle-test '(projectile-toggle-between-implementation-and-test
                       common-lisp-open-test)
        :fz-sym '(
                  ;; common-lisp-fz-symbol
                  ;; common-lisp-go-to-symbol
                  helm-cider-apropos-symbol)
        :godef '(lsp-find-definition
                 slime-edit-definition
                 pen-slime-godef
                 slime-show-xref
                 xref-find-definitions-immediately
                 helm-gtags-dwim)
        :errors '(pen-common-lisp-switch-to-errors)

        ;; For clj-refactor, see:
        ;; ;; j:pen-common-lisp-mode-hook
        :refactor '()
        :rename-symbol '(lsp-rename
                         ;; cljr-rename-symbol
                         )
        :references '(lsp-ui-peek-find-references lsp-find-references pen-counsel-ag-thing-at-point)
        :projectfile '(
                       ;; pen-common-lisp-project-file
                       )
        :preverr '(cider-jump-to-compilation-error)
        :nexterr '(cider-jump-to-compilation-error)

        :nextdef '(pen-prog-next-def
                   lispy-flow)
        :prevdef '(pen-prog-prev-def))

(handle '(rust-mode rustic-mode rust-ts-mode)
        ;; Re-using may not be good, actually, if I'm working with multiple projects
        :repls (list
                'irust)
        :formatters '(lsp-format-buffer)
        :docs '(pen-doc-override
                lsp-describe-thing-at-point)

        ;; Not at point - manual entry of symbol, searches web
        :docsearch '(pen-doc)

        ;; Not at point - manual entry of symbol with fuzzy finder
        :docfun '()

        :toggle-test '(projectile-toggle-between-implementation-and-test
                       common-lisp-open-test)
        :fz-sym '(
                  ;; This seems to not be the correct one
                  lsp-ivy-global-workspace-symbol)
        :godef '(lsp-find-definition
                 xref-find-definitions-immediately
                 helm-gtags-dwim)
        :errors '(lsp-treemacs-errors-list)

        :refactor '()
        :rename-symbol '(lsp-rename
                         )
        :references '(lsp-ui-peek-find-references lsp-find-references pen-counsel-ag-thing-at-point)
        :projectfile '(
                       ;; pen-common-lisp-project-file
                       )

        ;; Improve this
        :preverr '(lsp-treemacs-errors-list)
        :nexterr '(lsp-treemacs-errors-list)

        :nextdef '(pen-prog-next-def)
        :prevdef '(pen-prog-prev-def))

(handle '(racket-mode)
        :repls (list 'pen-racket-run
                     (dff (sps "racket"))
                     (etc "racket" t)
                     ;; racket-run
                     'racket-repl)
        ;; This is for running the program
        :runmain '(pen-racket-run-main)
        :formatters '(lsp-format-buffer)
        :docfun '(racket-describe-search)
        :docs '(;; pen-esp-docs-for-thing-if-prefix
                pen-doc-override
                racket-lsp-describe-thing-at-point
                pen-doc-thing-at-point
                ;; prog-mode handles this
                ;; pen-docs-for-thing-given-screen
                )
        :references '(lsp-ui-peek-find-references
                      ;; lsp-find-references
                      pen-counsel-ag-thing-at-point)
        :docsearch '(pen-doc-ask)
        :godef '(lsp-find-definition
                 racket-visit-definition
                 xref-find-definitions-immediately
                 helm-gtags-dwim)
        :docsearch '(pen-doc)
        :nextdef '(pen-prog-next-def
                   lispy-flow))

(handle '(ess-r-mode)
        :repls '()
        ;; This is for running the program
        :runmain '()
        :formatters '(lsp-format-buffer)
        :docs '(pen-esp-docs-for-thing-if-prefix
                pen-doc-override
                lsp-describe-thing-at-point
                pen-doc-thing-at-point
                ;; prog-mode handles this
                ;; pen-docs-for-thing-given-screen
                )
        :references '(lsp-ui-peek-find-references
                      ;; lsp-find-references
                      pen-counsel-ag-thing-at-point)
        :docsearch '(pen-doc-ask)
        :godef '(lsp-find-definition
                 xref-find-definitions-immediately
                 helm-gtags-dwim)
        :docsearch '(pen-doc)
        :nextdef '(pen-prog-next-def
                   lispy-flow))

(handle '(bible-mode bible-search-mode)
        ;; Re-using may not be good, actually, if I'm working with multiple projects
        :repls (list)
        :formatters '(lsp-format-buffer)
        :docs '(bible-mode-show-definition
                lookup-thing-glossary-definition
                dict-word
                ;; wordnut-lookup-current-word
                helm-wordnet-suggest
                lsp-describe-thing-at-point)
        :toggle-test '(projectile-toggle-between-implementation-and-test
                       clojure-open-test)
        :fz-sym '()
        :godef '(lsp-find-definition
                 xref-find-definitions-immediately
                 helm-gtags-dwim)
        :errors '()
        :docsearch '(pen-doc)
        :docfun '()

        :refactor '()
        :rename-symbol '(lsp-rename cljr-rename-symbol)
        :references '(lsp-ui-peek-find-references lsp-find-references pen-counsel-ag-thing-at-point)
        :projectfile '()
        :preverr '()
        :nexterr '()

        :nextdef '(pen-prog-next-def)
        :prevdef '(pen-prog-prev-def))

(defun gore-repl ()
  (interactive)
  (sps "nvt gore"))

(handle '(go-mode go-ts-mode)
        ;; Re-using may not be good, actually, if I'm working with multiple projects
        :repls '(gore-repl)
        :formatters '(lsp-format-buffer)
        :docs '(pen-esp-docs-for-thing-if-prefix
                pen-doc-override
                lsp-describe-thing-at-point
                pen-doc-thing-at-point
                ;; prog-mode handles this
                ;; pen-docs-for-thing-given-screen
                )
        :toggle-test '(projectile-toggle-between-implementation-and-test
                       clojure-open-test)
        :fz-sym '()
        :godef '(lsp-find-definition
                 xref-find-definitions-immediately
                 helm-gtags-dwim)
        :errors '()
        :docsearch '(pen-doc)
        :docfun '()

        :refactor '()
        :rename-symbol '(lsp-rename cljr-rename-symbol)
        :references '(lsp-ui-peek-find-references lsp-find-references pen-counsel-ag-thing-at-point)
        :projectfile '()
        :preverr '()
        :nexterr '()

        :nextdef '(pen-prog-next-def)
        :prevdef '(pen-prog-prev-def))

(handle '(python-mode python-ts-mode)
        ;; Re-using may not be pythonod, actually, if I'm working with multiple projects
        :repls (list)
        :formatters '(lsp-format-buffer)
        :docs '(pen-esp-docs-for-thing-if-prefix
                pen-doc-override
                lsp-describe-thing-at-point
                pen-doc-thing-at-point

                ;; prog-mode handles this
                ;; pen-docs-for-thing-given-screen
                )
        :toggle-test '(projectile-toggle-between-implementation-and-test
                       clojure-open-test)
        :fz-sym '()
        :pythondef '(lsp-find-definition
                 xref-find-definitions-immediately
                 helm-gtags-dwim)
        :errors '()
        :docsearch '(pen-doc)
        :docfun '()

        :refactor '()
        :rename-symbol '(lsp-rename cljr-rename-symbol)
        :references '(lsp-ui-peek-find-references lsp-find-references pen-counsel-ag-thing-at-point)
        :projectfile '()
        :preverr '()
        :nexterr '()

        :nextdef '(pen-prog-next-def)
        :prevdef '(pen-prog-prev-def))

(handle '(prog-mode)
        :complete '()
        ;; This is for running the program
        :runmain '()
        :repls '()
        :formatters '()
        :refactor '()
        :debug '()
        :docfun '()
        :docs '(pen-esp-docs-for-thing-if-prefix
                pen-doc-override
                lsp-describe-thing-at-point
                pen-docs-for-thing-given-screen)
        :docsearch '()
        :godef '(lsp-find-definition)
        :showuml '()
        :nextdef '()
        :prevdef '()
        :nexterr '()
        :preverr '()
        :global-references '(
                             pen-counsel-ag-thing-at-point
                             ;; fall back to godef
                             handle-godef)
        :rc '()
        :errors '(lsp-ui-flycheck-list
                  ;; pen-lsp-error-list
                  )
        :assignments '()
        :references '()
        :definitions '()
        :implementations '()
        :readme '(find-readme-here))

(handle '(conf-mode feature-mode)
        :runmain '()
        :repls '()
        :formatters '()
        :docs '(pen-docs-for-thing-given-screen)
        :godef '()
        :docsearch '()
        :nextdef '()
        :prevdef '()
        :nexterr '()
        :preverr '())

(handle '(sh-base-mode bash-ts-mode)
        :runmain '()
        :repls '()
        :formatters '()
        :docs '(man-thing-at-point
                pen-lsp-get-hover-docs
                ladicle/toggle-lsp-ui-doc)
        :godef '(lsp-find-definition
                 bash-goto-excutable-on-path-at-point)
        :docsearch '()
        :nextdef '()
        :prevdef '()
        :nexterr '()
        :preverr '())

(handle '(gnu-apl-mode)
        :runmain '()
        :repls '(gnu-apl)
        :formatters '()
        :docs '(man-thing-at-point)
        :godef '()
        :docsearch '()
        :nextdef '()
        :prevdef '()
        :nexterr '()
        :preverr '())

(handle '(bible-term-greek-mode)
        :runmain '()
        :repls '()
        :formatters '()
        :docs '(pen-esp-docs-for-thing-if-prefix
                lookup-thing-glossary-definition
                dict-word
                wordnut-lookup-current-word
                helm-wordnet-suggest
                pen-docs-for-thing-given-screen)
        :godef '()
        :docsearch '()
        :nextdef '()
        :prevdef '()
        :nexterr '()
        :preverr '())

(handle '(org-mode)
        :navtree '()
        :runmain '()
        :docs '(pen-esp-docs-for-thing-if-prefix
                lookup-thing-glossary-definition
                dict-word
                wordnut-lookup-current-word
                helm-wordnet-suggest
                pen-docs-for-thing-given-screen)
        :nexterr '()
        :preverr '()
        :complete '()
        :rc '())

(handle '(help-mode)
        :navtree '()
        :runmain '()
        :docs '(lookup-thing-glossary-definition
                dict-word
                wordnut-lookup-current-word
                helm-wordnet-suggest
                pen-docs-for-thing-given-screen)
        :nexterr '()
        :preverr '()
        :complete '()
        :rc '())

(defun pen-esp-docs-for-thing-if-prefix ()
  "This does `pen-docs-for-thing-given-screen` if prefix is set."
  (interactive)
  (if (>= (prefix-numeric-value current-prefix-arg) 4)
      (let ((current-prefix-arg nil))
        (call-interactively 'pf-get-documentation-for-syntax-given-screen/2))
    (error "Fallthrough")))

(handle '(haskell-mode)
        :navtree '()
        :runmain '()
        :projectfile '(pen-haskell-project-file)
        :repls '(dante-repl
                 haskell-repl)
        :docs '(pen-esp-docs-for-thing-if-prefix
                pen-lsp-get-hover-docs
                haskell-hdc-thing
                hoogle
                pen-docs-for-thing-given-screen)
        :references '(lsp-ui-peek-find-references lsp-find-references pen-counsel-ag-thing-at-point)
        :godef '(lsp-find-definition)
        :nexterr '()
        :preverr '()
        :complete '()
        :compile '(compile-run-compile)
        :rc '())

(handle '(text-mode)
        :nexterr '()
        :docs '(lookup-thing-glossary-definition
                dict-word
                wordnut-lookup-current-word
                helm-wordnet-suggest
                pen-docs-for-thing-given-screen)
        :preverr '())

(handle '(fundamental-mode)
        :nexterr '()
        :docs '(lookup-thing-glossary-definition
                dict-word
                wordnut-lookup-current-word
                helm-wordnet-suggest
                pen-docs-for-thing-given-screen)
        :preverr '())

(handle '(special-mode)
        :nexterr '()
        :docs '(pen-docs-for-thing-given-screen)
        :preverr '())

(handle '(comint-mode)
        :nexterr '()
        :docs '(pen-docs-for-thing-given-screen)
        :preverr '())

(defun swipl-playground ()
  (interactive)
  (sps (cmd "swipl-playground" (get-path nil t))))

(handle '(prolog-mode)
        :complete '(indent-for-tab-command)
        ;; This is for running the program
        :run '(compile-run)
        :repls '(
                 prolog-consult-buffer
                 ;; run-prolog
                 swipl-playground)
        :formatters '(lsp-format)
        :refactor '()
        :debug '(dap-debug-and-hydra)
        :docfun '(helpful-symbol)
        :docs '(
                pen-esp-docs-for-thing-if-prefix
                pen-doc-override
                ;; lsp-ui-doc-show
                pen-doc-thing-at-point
                ;; use prolog help before lsp docs
                prolog-help-on-predicate
                pen-lsp-get-hover-docs
                pen-docs-for-thing-given-screen)
        :docsearch '(pen-doc-ask)
        :godec '(lsp-find-declaration
                 google-for-docs
                 )
        :godef '(lsp-find-definition
                 helm-gtags-dwim
                 xref-find-definitions-immediately
                 fz-cq-symbols
                 google-for-def)
        :showuml (list 'show-uml)
        :nextdef '(pen-prog-next-def)
        :prevdef '(pen-prog-prev-def)
        :nexterr '(fly-next-error)
        :preverr '(fly-prev-error)
        :rc '(pen-goto-rc)
        ;; select from multiple
        :errors '(lsp-ui-flycheck-list flycheck-buffer)
        :assignments '()
        :references '(lsp-ui-peek-find-references
                      ;; lsp-find-references
                      pen-counsel-ag-thing-at-point
                      ;; pen-counsel-ag
                      )
        :definitions '(lsp-ui-peek-find-definitions)
        :implementations '(lsp-ui-peek-find-implementation))

(handle '(problog-mode)
        :complete '(indent-for-tab-command)
        ;; This is for running the program
        :run '(compile-run)
        :repls '()
        :formatters '()
        :refactor '()
        :debug '()
        :docfun '()
        :docs '(
                pen-esp-docs-for-thing-if-prefix
                pen-doc-override
                ;; lsp-ui-doc-show
                pen-lsp-get-hover-docs
                pen-doc-thing-at-point
                prolog-help-on-predicate
                pen-docs-for-thing-given-screen)
        :docsearch '(pen-doc-ask)
        :godec '()
        :godef '(lsp-find-definition
                 helm-gtags-dwim
                 xref-find-definitions-immediately
                 fz-cq-symbols
                 google-for-def)
        :showuml (list 'show-uml)
        :nextdef '(pen-prog-next-def)
        :prevdef '(pen-prog-prev-def)
        :nexterr '(fly-next-error)
        :preverr '(fly-prev-error)
        :rc '(pen-goto-rc)
        ;; select from multiple
        :errors '()
        :assignments '()
        :references '(lsp-ui-peek-find-references
                      ;; lsp-find-references
                      pen-counsel-ag-thing-at-point
                      ;; pen-counsel-ag
                      )
        :definitions '(lsp-ui-peek-find-definitions)
        :implementations '(lsp-ui-peek-find-implementation))

(handle '(c-mode c-ts-base-mode c++-ts-mode)
        ;; Re-using may not be good, actually, if I'm working with multiple projects
        :repls (list
                'sps-top
                ;; 'slime-repl
                )
        :formatters '(lsp-format-buffer)
        :docs '(pen-doc-override
                lsp-describe-thing-at-point
                man-thing-at-point-cpp

                ;; This is automatically done because it's a prog mode I think
                ;; pen-docs-for-thing-given-screen
                )

        ;; Not at point - manual entry of symbol, searches web
        :docsearch '(pen-doc)

        ;; Not at point - manual entry of symbol with fuzzy finder
        :docfun '()

        :toggle-test '(projectile-toggle-between-implementation-and-test
                       common-lisp-open-test)
        :fz-sym '(
                  ;; This seems to not be the correct one
                  lsp-ivy-global-workspace-symbol)
        :godef '(lsp-find-definition
                 xref-find-definitions-immediately
                 helm-gtags-dwim)
        :errors '(lsp-treemacs-errors-list)

        :refactor '()
        :rename-symbol '(lsp-rename
                         )
        :references '(lsp-ui-peek-find-references lsp-find-references pen-counsel-ag-thing-at-point)
        :projectfile '(
                       ;; pen-common-lisp-project-file
                       )

        ;; Improve this
        :preverr '(lsp-treemacs-errors-list)
        :nexterr '(lsp-treemacs-errors-list)

        :nextdef '(pen-prog-next-def)
        :prevdef '(pen-prog-prev-def))

(handle '(term-mode)
        :nexterr '()
        :docs '(pen-docs-for-thing-given-screen)
        :preverr '())

(handle '(emacs-lisp-mode)
        :repls '(ielm)
        :formatters '(lsp-format-buffer)
        :global-references '(pen-helpful--all-references-sym)
        :fz-sym '(find-function)
        :docs '(my-doc-override
                describe-thing-at-point
                helpful-symbol-at-point)
        :godef '(lispy-goto-symbol
                 elisp-slime-nav-find-elisp-thing-at-point
                 lsp-find-definition
                 xref-find-definitions-immediately
                 helm-gtags-dwim)
        :jumpto '(lispy-goto)
        :docsearch '(my/doc)
        :docfun '(helpful-symbol)
        :nextdef '(my-prog-next-def
                   lispy-flow)
        :prevdef '(my-prog-prev-def))

(defun fz-run-handle ()
  (interactive)
  (let ((sym
         (str2sym
          (fz
           (mapcar 'str2sym
                   (mapcar
                    (lambda (e)
                      (replace-regexp-in-string "^:" "handle-"
                                                (str e)))
                    handle-keywords))
           nil nil "Handle Run"))))
    (if sym
        (call-interactively sym))))

(defun handle--command-execute (commands arg)
  "Run COMMANDS with `command-execute'.
Try next command on `error', passing ARG as `prefix-arg'."
  (when commands
    (if (>= (prefix-numeric-value current-global-prefix-arg) 4)
        (let
            ((cmd (fz commands nil nil "Handle select command: ")))
          ;; (tv (type cmd))
          (command-execute (str2sym cmd) 'record))
      (let ((first (car commands))
            (rest (cdr commands)))
        (condition-case nil
            (cond
             ((let ((prefix-arg arg))
                ;; (message "`handle' running `%s'." first)
                (command-execute first 'record)) t)
             ((not (handle--nice-function-p first)) t)
             (t (progn
                  ;; (message "`handle' ran `%s' unsuccessfully." first)
                  (handle--command-execute rest arg))))
          (error ;; (message "`handle' failed to run `%s'." first)
           (format "`handle' failed to run `%s'." first)
           (handle--command-execute rest arg)))))))

(provide 'pen-handle)
