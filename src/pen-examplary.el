;; TODO It's important to implement single example prompts
;; I can then search for a multi-example prompt

;; TODO examples
;; TODO counterexamples
;; TODO tasks

(defmacro defprompt (&rest body)
  ""
  `(progn ,@body))

(defmacro defexamples (task examples counterexamples)
  :e "grex"
  "example 1\nexample2" "^example [12]$"
  "example 2\nexample3" "^example [23]$"
  "pi4\npi5" "^pi[45]$")
(defalias 'defex 'defexample)

(defprompt lines->regex (:external "grex")
  (("example 1\nexample2" "^example [12]$")
   ("example 2\nexample3" "^example [23]$")
   ("pi4\npi5" "^pi[45]$"))
  (("example 1\nexample2" "^example [12]$")
   ("example 2\nexample3" "^example [23]$")
   ("pi4\npi5" "^pi[45]$")))

(provide 'examplary)