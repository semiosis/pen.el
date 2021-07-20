;; Perspective:
;; Create the language according to speculation and future need.
;; Combine with APIs and LMs according to what they need.

;; TODO It's important to implement single example prompts
;; I can then search for a multi-example prompt

;; TODO examples
;; TODO counterexamples
;; TODO tasks

;; The initial characters of the prompt have more weight than the latter.
;; A 'metaprompt' may be designed which is the initial part of the prompt.
;; It's not a great name as there is no strict part which could be considered.
;; And a metaprompt may be further divided ad infinitum.

(defmacro defprompt (&rest body)
  ""
  `(progn ,@body))

(defmacro defexamples (task examples counterexamples)
  :e "grex"
  "example 1\nexample2" "^example [12]$"
  "example 2\nexample3" "^example [23]$"
  "pi4\npi5" "^pi[45]$")
(defalias 'defex 'defexample)

;; TODO Start with an input/output prompt

;; Convert lines to regex
(defprompt lines regex
  :external "grex"
  ;; The task may also be used as a metaprompt.
  :task "Convert lines to regex"
  :examples '(("example 1\nexample2" "^example [12]$")
              ("example 2\nexample3" "^example [23]$")
              ("pi4\npi5" "^pi[45]$"))
  :counterexamples '())

(provide 'pen-examplary)