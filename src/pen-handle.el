(require 'handle)

(defset pen-doc-queries
  '(
    "What is '${query}' and what how is it used?"
    "What are some examples of using '${query}'?"
    "What are some alternatives to using '${query}'?"))

;; v:pen-ask-documentation 
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