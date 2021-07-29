(defun pen-test-closure ()
  (etv (if (variable-p 'n-collate)
           (eval 'n-collate)
         5)))
;; It works in code
(defun pen-test-closure2 ()
  (let ((n-collate 1)) (pen-test-closure)))
;; But not in the M-: minibuffer
(comment
 (let ((n-collate 1)) (pen-test-closure)))
;; But if I eval, then it DOES work in the minibuffer
(comment
 (eval `(let ((n-collate 1)) (pen-test-closure))))