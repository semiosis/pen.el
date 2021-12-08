(defun pen-test-closure ()
  (pen-etv (if (variable-p 'n-collate)
           (eval 'n-collate)
         5)))
;; It works in code
(defun pen-test-closure2 ()
  (interactive)
  (let ((n-collate 1)) (pen-test-closure)))
;; But not in the M-: minibuffer
(comment
 (let ((n-collate 1)) (pen-test-closure)))
;; But if I eval, then it DOES work in the minibuffer
(comment
 (eval `(let ((n-collate 1)) (pen-test-closure))))

(comment
 (eval `(pen-single-generation
         (pf-asktutor/3 "emacs" "key bindings" "How do I kill a buffer?" :no-select-result t)))

 (eval `(let ((n-collate 1)
              (n-completions 1))
          (pf-asktutor/3 "emacs" "key bindings" "How do I kill a buffer?" :no-select-result t)))

 ;;  n-completions is set to 1, it breaks
 (eval `(let ((n-completions 1))
          (pf-asktutor/3 "emacs" "key bindings" "How do I kill a buffer?" :no-select-result t))))

(defun pen-load-defs ()
  (interactive)
  (let* ((fp "/home/shane/source/git/semiosis/prompts/prompts/guess-function-name-1.prompt")
         (yaml-ht (yamlmod-read-file fp))
         (defs (pen--htlist-to-alist (ht-get yaml-ht "defs"))))
    (pen-etv (pps defs))))

;; https://github.com/volrath/treepy.el
;; Use this
(defun pen-load-paths ()
  (interactive)
  (let* ((fp "/home/shane/var/smulliga/source/git/semiosis/prompts/prompts/negate-sentence-1.prompt")
         (yaml-ht (yamlmod-read-file fp))
         ;; (paths (pen--htlist-to-alist (ht-get yaml-ht "paths")))
         (paths (ht-get yaml-ht "paths")))
    (pen-etv (pps paths))))

(defun pen-load-vars ()
  (interactive)
  (let* ((fp "/home/shane/source/git/semiosis/prompts/prompts/append-to-code-3.prompt")
         (yaml-ht (yamlmod-read-file fp))
         (vars (pen--htlist-to-alist (ht-get yaml-ht "vars")))

         (vals
          (cl-loop
           for atp in vars
           collect
           (car (pen-vector2list (cdr atp)))))

         (keys (cl-loop
                for atp in vars
                collect
                (car atp)))

         (als (cl-loop
               for atp in vars
               collect
               (pen--htlist-to-alist (pen-vector2list (cdr atp)))))

         (defaults
           (cl-loop
            for atp in als
            collect
            (cdr (assoc "default" atp))))

         (examples
          (cl-loop
           for atp in als
           collect
           (cdr (assoc "example" atp))))

         (preprocessors
          (cl-loop
           for atp in als
           collect
           (cdr (assoc "preprocessor" atp)))))
    (pen-etv (pps vals))))

(defun pen-load-test ()
  (interactive)
  (let* (
         ;; (fp "/home/shane/source/git/spacemacs/prompts/prompts/test-imaginary-equivalence-2.prompt")
         ;; (fp "/home/shane/var/smulliga/source/git/semiosis/prompts/prompts/correct-english-spelling-and-grammar-1.prompt")
         (fp "/home/shane/var/smulliga/source/git/semiosis/prompts/prompts/describe-image.prompt")
         (yaml-ht (yamlmod-read-file fp))
         ;; (defs (pen--htlist-to-alist (ht-get yaml-ht "defs")))
         ;; (var (ht-get yaml-ht "n-completions"))
         ;; (var (pen--htlist-to-alist (ht-get yaml-ht "pipelines")))
         (var (pen--htlist-to-alist (ht-get yaml-ht "payloads")))
         (var
          (cl-loop for pl in var
                   collect
                   (let ((v (if (re-match-p "^(" (cdr pl))
                                (eval-string (cdr pl))
                              pl)))
                     (cons (car pl) v)))))
    ;; (var (pen-yaml-test yaml-ht "filter"))
    ;; (var (ht-get yaml-ht "filter")))
    ;; (pen-etv (json--encode-alist var))
    (pen-etv (pps var))))

;; (idefun add-5-to-x (x))

;; (idefun colour-of-thing (thing)
;;         "Given the name of a thing, provide the hash colour")

;; (alchemy_getTokenAllowance "0xE41d2489571d322189246DaFA5ebDe1F4699F498")

;; TODO I could, when generating prompting functions, also provide examples, or set them/a context for functions.
;; Consider generating examples for functions and then providing them as a parameter.
;; To generate examples, I would need to force-generate prompts

;; (iassert 55 add-5-to-x 50)

(defun test-pen-train-function ()
  (interactive)

  (pen-etv
   (eval
    `(pen-train-function
      (pf-transpile/3 "5 + 5" "Python" "Lisp")
      '("(+ 5 5)")))))

;; (etv
;;  (pen-get-prompt (pf-transpile/3 "5 + 5" "Python" "Lisp")))

;; TODO I could, when generating prompting functions, also provide examples, or set them/a context for functions.
;; Consider generating examples for functions and then providing them as a parameter.
;; To generate examples, I would need to force-generate prompts

;; (iassert 55 add-5-to-x 50)