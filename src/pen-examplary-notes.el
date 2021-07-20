;; TODO Start with an input/output prompt
;; TODO Ensure I can generate simple lists without filters

;; If :gen or :filter is a string then it refers to an external shell script
;; If :gen or :filter is a symbol then it refers to a function.

;; :gen (An elisp function or external command to generate input examples)
;; :filter (An elisp function or external command to filter input examples and generate output examples)
;; :task (may also be used as a metaprompt. also used to define a function)



;; (etv (plist-get (expand-macro '(defprompt lines regex
;;                                  :external "grex"
;;                                  ;; The task may also be used as a metaprompt.
;;                                  :task "Convert lines to regex"
;;                                  :examples '(("example 1\nexample2" "^example [12]$")
;;                                              ("example 2\nexample3" "^example [23]$")
;;                                              ("pi4\npi5" "^pi[45]$"))
;;                                  :counterexamples '())) :external))

;; Only use as many examples as required by the model

(defmodel gpt3
  :n-examples 3)

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

;; (defmacro defprompt (inputtype outputtype &rest data)
;;   ""
;;   `(,@data))