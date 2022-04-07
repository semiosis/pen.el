(require 'handle)

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

(defmacro gen-term-command (cmd &optional reuse)
  "Generate an interactive emacs command for a term command"
  (let* ((cmdslug (concat "et-" (slugify cmd)))
         (fsym (intern cmdslug))
         (bufname (concat "*" cmdslug "*")))
    `(defun ,fsym ()
       (interactive)
       (pen-term ,cmd nil nil ,bufname ,reuse))))
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

(handle '(clojure-mode clojurescript-mode cider-repl-mode inf-clojure)
        ;; Re-using may not be good, actually, if I'm working with multiple projects
        :repls (list
                'cider-switch-to-repl-buffer
                'cider-switch-to-repl-buffer-any
                (etc "clj-rebel" t)
                (etc "lein repl" t))
        :formatters '(lsp-format-buffer)
        :docs '(pen-doc-override
                lsp-describe-thing-at-point
                cider-doc-thing-at-point)
        :toggle-test '(projectile-toggle-between-implementation-and-test
                       clojure-open-test)
        :fz-sym '(clojure-fz-symbol
                  ;; clojure-go-to-symbol
                  helm-cider-apropos-symbol)
        :godef '(lsp-find-definition
                 cider-find-var
                 xref-find-definitions-immediately
                 helm-gtags-dwim)
        :errors '(pen-clojure-switch-to-errors)
        :docsearch '(pen-doc)
        :docfun '(pen-cider-docfun)

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

(handle '(go-mode)
        ;; Re-using may not be good, actually, if I'm working with multiple projects
        :repls (list)
        :formatters '(lsp-format-buffer)
        :docs '(pen-doc-override
                lsp-describe-thing-at-point)
        :toggle-test '(projectile-toggle-between-implementation-and-test
                       clojure-open-test)
        :fz-sym '()
        :godef '(lsp-find-definition
                 cider-find-var
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
        :run '()
        :repls '()
        :formatters '()
        :refactor '()
        :debug '()
        :docfun '()
        :docs '(pen-docs-for-thing-given-screen)
        :docsearch '()
        :godec '()
        :godef '()
        :showuml '()
        :nextdef '()
        :prevdef '()
        :nexterr '()
        :preverr '()
        :rc '()
        :errors '()
        :assignments '()
        :references '()
        :definitions '()
        :implementations '())

(handle '(conf-mode feature-mode)
        :run '()
        :repls '()
        :formatters '()
        :docs '(pen-docs-for-thing-given-screen)
        :godef '()
        :docsearch '()
        :nextdef '()
        :prevdef '()
        :nexterr '()
        :preverr '())

(handle '(org-mode)
        :navtree '()
        :run '()
        :docs '(pen-docs-for-thing-given-screen)
        :nexterr '()
        :preverr '()
        :complete '()
        :rc '())

(defun pen-lsp-docs-for-thing-maybe ()
  (interactive)
  (if (>= (prefix-numeric-value current-prefix-arg) 4)
      (let ((current-prefix-arg nil))
        (call-interactively 'pf-get-documentation-for-syntax-given-screen/2))
    (error "Fallthrough")))

(handle '(haskell-mode)
        :navtree '()
        :run '()
        :repls '(dante-repl
                 haskell-repl)
        :docs '(pen-lsp-docs-for-thing-maybe
                haskell-hdc-thing
                hoogle
                pen-docs-for-thing-given-screen)
        :godef '(lsp-find-definition)
        :nexterr '()
        :preverr '()
        :complete '()
        :rc '())

(handle '(text-mode)
        :nexterr '()
        :docs '(pen-docs-for-thing-given-screen)
        :preverr '())

(handle '(fundamental-mode)
        :nexterr '()
        :docs '(pen-docs-for-thing-given-screen)
        :preverr '())

(handle '(special-mode)
        :nexterr '()
        :docs '(pen-docs-for-thing-given-screen)
        :preverr '())

(handle '(comint-mode)
        :nexterr '()
        :docs '(pen-docs-for-thing-given-screen)
        :preverr '())

(handle '(term-mode)
        :nexterr '()
        :docs '(pen-docs-for-thing-given-screen)
        :preverr '())

(handle '(emacs-lisp-mode)
        :repls '(ielm)
        :formatters '(lsp-format-buffer)
        :global-references '(my-helpful--all-references-sym)
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

(provide 'pen-handle)
