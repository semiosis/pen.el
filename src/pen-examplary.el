(require 'pen-yaml)

(comment (require 'pen-ilambda))

;; xl can be the prefix for examplary

;; TODO Create data for fine-tuning. This is just generating training examples.
;; Recommend having at least a couple hundred examples. In general,
;; we've found that each doubling of the dataset size leads to a linear increase in model quality.

;; TODO
;; - Resort to =yq= to generate =yaml= since nothing exists yet for =yamlmod=

;; xl-defprompt should generate a yaml file
;; The entire YAML file.

;; n-generate:
;; Number of examples to generate by default from
;; The input to the output if the prompt has an arity of 2 (i.e. conversion)
(defvar n-generate 5)

;; (pen-get-one-example-of "car manufacturer")
(defun pen-get-one-example-of (thing-type)
  (car (pf-list-of/2 "1" thing-type :no-select-result t)))

(defun pen-save-prompt (prompt-plist)
  ;; (json-encode-alist)
  ;; (json2yaml (json-encode-plist '(:task "my task" :gen "my gen")))
  (let ((fp (slugify (plist-get prompt-plist :task))))
    (plist2yaml prompt-plist)))

;; TODO Steps
;; - eenerate a plist
;; - export the plist to yaml

;; (pen-unonelineify (pen-onelineify "hello\nshane"))

(defvar pen-language-models '())

(defmacro defprompt (language-model-id)
  ""
  `(progn ,@body))

(defmacro xl-defprompt (args &rest data)
  "xl-defprompt
This macro generates a yaml and returns its prompt function.

If args has an arity of 1, it is a generation
If args has an arity of 2, it is a conversion/transformation

args is a lot like haskell args
It's a list of the arguments.
The last element in the list is the output/return value"
  (setq args (mapcar 'str args))

  (let* ((task (plist-get data :task))
         (orig-gen (plist-get data :gen))
         (gen orig-gen)
         (orig-filter (plist-get data :filter))
         (filter orig-filter)
         (examples (plist-get data :examples))
         (lm-command (plist-get data :lm-command))
         (model (plist-get data :model))
         (orig-prompt (plist-get data :prompt))
         (prompt orig-prompt))

    ;; If task (metaprompt) doesn't exist, infer it
    (if (not task)
        (setq task
              (cond
               ((eq 1 (length args))
                (concat "generate " (car args)))
               ((eq 2 (length args))
                (concat "convert "
                        (car args)
                        " to "
                        (cadr args)))
               (t nil))))

    ;; If gen is a shell script, convert it to an elisp function
    (if (stringp gen)
        (setq gen (eval
                   `(λ (initial n)
                      (pen-str2list
                       (pen-snc
                        (concat
                         (pen-cmd ,gen initial)
                         "| head -n "
                         (str n))))))))

    ;; If gen is a shell pipeline string, convert it to an elisp function
    (if (stringp filter)
        (setq filter (eval
                      `(λ (in)
                         (pen-snc ,filter in)))))

    ;; Generate examples if none
    (if (not examples)
        (if gen
            (setq examples
                  (mapcar 'list (apply
                                 gen
                                 (pen-get-one-example-of (car args))
                                 n-generate)))
          (setq examples
                (mapcar 'list (pf-list-of/2 "1" (car args) :no-select-result t)))))

    ;; (pen-etv (pps examples))
    ;; Add outputs to examples if there is a filter
    (if (and filter
             examples)
        (setq examples
              (cl-loop for ex in examples
                    collect
                    (cond
                     ((and (eq 1 (length ex))
                           filter)
                      (list (car ex)
                            (apply filter (list (car ex)))))
                     ;; (t
                     ;;  (list (str (length ex)) (pps filter)))
                     ))))

    (if task (plist-put data :task task))

    (if (and gen (not orig-gen)) (plist-put data :gen gen))
    (if (and filter (not orig-filter)) (plist-put data :filter filter))

    ;; Rules to build the prompt
    (plist-put
     data :prompt
     (if (and task
              examples
              (eq 2 (length (car examples))))
         (progn
           ;; Firstly, ensure that the prompt function un-onelinerises the output
           (plist-put data :task nil)
           (plist-put data :examples examples)
           (plist-put data :stop-sequences '("Input:"))
           (concat
            task "\n\n"
            (list2str
             (mapcar
              (λ (ex)
                (list2str (list (concat "Input:" (pen-onelineify (car ex)))
                                (concat "Output:" (pen-onelineify (cadr ex))))))
              examples))
            "Input:<1>"
            "Output:")
           "")))

    ;; Examples is used for something else in the prompt
    (if examples (plist-put data :examples examples))
    ;;    (plist-put data :lm-command lm-command)
    ;;    (plist-put data :model model)
    )

  (pen-etv (plist2yaml data))
  nil)

;; https://github.com/pemistahl/grex
(defun grex (in)
  (pen-snc "grex" in))

;; A gen function must take an initial value and a number for how many to generate
(defun examplary-edit-generator (initial n)
  (pen-str2list (pen-snc (concat (pen-cmd "examplary-edit-generator" "shane") "| head -n " (str n)))))

(comment
 ;; so this is a prompt that takes a single input, which is a multiline string
 ;; and prodduces a regex for it
 ;; "short lines of code" will generate the first column
 ;; and filter runs over that to generate the 2nd column
 ;; then because it's binary, it will create a task which says "convert short lines of code into regex"
 ;; I think my goal is to make it so that designing prompts is always a simple binary function
 ;; with minimal inputs
 ;; i think i can do this by encoding all the design patterns into examplary
 ;; and inferring fields that arent present
 (xl-defprompt ("short lines of code" regex) :filter "grex")

 ;; Convert lines to regex
 ;; This is a macro so no need to escape things, yet
 (xl-defprompt ("lines of code" regex)
               ;; :task "Convert lines to regex"
               ;; Generate input with this
               ;; :gen "examplary-edit-generator shane"
               :gen examplary-edit-generator
               :filter "grex"
               ;; The third argument (if supplied) should be incorrect output (a counterexample).
               ;; If the 2nd argument is left out, it will be generated by the command specified by :external
               :examples (("example 1\nexample2")
                          ("example 2\nexample3" "^example [23]$")
                          ("pi4\npi5" "^pi[45]$" "pi4\npi5"))
               :lm-command "openai-complete.sh"))

(provide 'pen-examplary)