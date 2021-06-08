;; This is for everything outside of core pen stuff
;; i.e. applications built on pen.el

(defvar pen-tutor-common-questions
  '("What is <1:q> used for?"
    "What are some good learning materials"))

(defun pen-tutor-mode-assist (query)
  (interactive (let* ((bl (buffer-language t t)))
                 (list
                  (read-string-hist
                   (concat "asktutor (" bl "): ")
                   (my/thing-at-point)))))
  (pen-pf-asktutor bl bl query))


(defset pen-doc-queries
  '(
    "What is '${query}' and what how is it used?"
    "What are some examples of using '${query}'?"
    "What are some alternatives to using '${query}'?"))

;; v:pen-ask-documentation 
(defun pen-ask-documentation (thing query)
  (interactive
   (let* ((thing (my/thing-at-point))
          (qs (mapcar (lambda (s) (s-format s `(("query" . ,thing)))) pen-doc-queries))
          (query
           (fz pen-doc-queries
               nil nil
               "pen-ask-documentation: ")))
     (list
      thing
      query))))
;; (s-format "hello ${query}" 'aget '(query . "thereE"))

;; (s-format "hello ${query}" 'aget '(("query" . "thereE")))

(provide 'pen-contrib)