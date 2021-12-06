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