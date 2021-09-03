;; Basic imaginary programming functions
;; Add these to the thesis

;; idefun
;; ieval
;; ilambda
;; ifilter
;; itransform
;; imacro

;; idefun vs imacro

;; imacro should take

;; i macro-expand?

;; Well, I could inject a macro with a value which is actually sent to the LM?

;; Make a legit imaginary programming library for emacs

;; Do an (ignore-errors (eval-string result)) on the result
(defmacro ieval (&rest body)
  "imaginary eval")

;; TODO Make an elisp code evaluator based on prompting

;; TODO Make an elisp code generator based on prompting
;; This should create a function, which may not necessarily work
;; But can be imaginarily evaluated

;; if any of these arguments are not available, infer them via prompt
;; The macro can be expanded to create an instance of the function
(defmacro idefun (name args docstring &rest body)
  ""
  (let )
  `(progn ,@body))

(idefun double (a)
        "this function doubles its input")

(defun ilist (n type-of-thing)
  (interactive (list (read-string-hist "ilist n: ")
                     (read-string-hist "ilist type-of-thing: ")))
  (pen-single-generation (pf-list-of/2 (str n) (str type-of-thing) :no-select-result t)))

(defun test-ilist ()
  (interactive)
  (etv (pps (ilist 10 "tennis players"))))

(provide 'imaginary-library)