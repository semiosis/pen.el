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
         (pf-asktutor "emacs" "key bindings" "How do I kill a buffer?" :no-select-result t)))

 (eval `(let ((n-collate 1)
              (n-completions 1))
          (pf-asktutor "emacs" "key bindings" "How do I kill a buffer?" :no-select-result t)))

 ;;  n-completions is set to 1, it breaks
 (eval `(let ((n-completions 1))
          (pf-asktutor "emacs" "key bindings" "How do I kill a buffer?" :no-select-result t))))