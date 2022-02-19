(require 'handle)

(defset pen-doc-queries
  '(
    "What is '${query}' and what how is it used?"
    "What are some examples of using '${query}'?"
    "What are some alternatives to using '${query}'?"))

;; v:pen-ask-documentation 

(defmacro gen-term-command (cmd &optional reuse)
  "Generate an interactive emacs command for a term command"
  (let* ((cmdslug (concat "et-" (slugify cmd)))
         (fsym (str2sym cmdslug))
         (bufname (concat "*" cmdslug "*")))
    `(defun ,fsym ()
       (interactive)
       (et ,cmd nil nil ,bufname ,reuse))))
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

(handle '(clojure-mode clojurescript-mode cider-repl-mode inf-clojure)
        ;; Re-using may not be good, actually, if I'm working with multiple projects
        :repls (list
                'cider-switch-to-repl-buffer
                'cider-switch-to-repl-buffer-any
                (etc "clj-rebel" t)
                (etc "lein repl" t))
        :formatters '(lsp-format-buffer)
        :docs '(my-doc-override
                lsp-describe-thing-at-point
                cider-doc-thing-at-point)
        :godef '(lsp-find-definition
                 cider-find-var
                 xref-find-definitions-immediately
                 helm-gtags-dwim)
        :errors '(my-clojure-switch-to-errors)
        :docsearch '(my/doc)
        :docfun '(my/cider-docfun)

        ;; For clj-refactor, see:
        ;; ;; j:my-clojure-mode-hook
        :refactor '()
        :references '(lsp-ui-peek-find-references lsp-find-references my-counsel-ag-thing-at-point)
        :projectfile '(my-clojure-project-file)
        :nextdef '(my-prog-next-def
                   lispy-flow))

(handle '(prog-mode)
        :complete '()
        ;; This is for running the program
        :run '()
        :repls '()
        :formatters '()
        :refactor '()
        :debug '()
        :docfun '()
        :docs '(pf-get-documentation-for-syntax-given-screen/2)
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
        :docs '(pf-get-documentation-for-syntax-given-screen/2)
        :godef '()
        :docsearch '()
        :nextdef '()
        :prevdef '()
        :nexterr '()
        :preverr '())

(handle '(org-mode)
        :navtree '()
        :run '()
        :docs '(pf-get-documentation-for-syntax-given-screen/2)
        :nexterr '()
        :preverr '()
        :complete '()
        :rc '())

(handle '(text-mode)
        :nexterr '()
        :docs '(pf-get-documentation-for-syntax-given-screen/2)
        :preverr '())

(handle '(fundamental-mode)
        :nexterr '()
        :docs '(pf-get-documentation-for-syntax-given-screen/2)
        :preverr '())

(handle '(special-mode)
        :nexterr '()
        :docs '(pf-get-documentation-for-syntax-given-screen/2)
        :preverr '())

(handle '(comint-mode)
        :nexterr '()
        :docs '(pf-get-documentation-for-syntax-given-screen/2)
        :preverr '())

(handle '(term-mode)
        :nexterr '()
        :docs '(pf-get-documentation-for-syntax-given-screen/2)
        :preverr '())

(provide 'pen-handle)