;; Basic imaginary programming functions
;; Add these to the thesis

;; idefun
;; ieval
;; ilambda
;; ifilter
;; itransform

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


(provide 'imaginary-library)