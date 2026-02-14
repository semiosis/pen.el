(comment
 (cmd-cip "-5" 5 "hello" "=h")
 (pen-cip-string "yo -5 =yo yo")
 (pen-ex-to-elisp "yo -5 =yo yo")
 ;; Compound function names cant take multiple args (perhaps I should change that,
 ;; so the first one takes all the args and remaining functions can only take the result of previous function):
 ;; (pen-ex-to-elisp "mesg.pps.list yo -5 =yo yo")
 )


(comment
 (pen-ex-to-elisp "mesg.pps yo")
 (pen-ex-to-elisp "list yo -5 -yo yo =route-program"))
(defun pen-ex-to-elisp (s)
  ;; First argument is the function name / compound function name
  (let ((form (pen-cip-string (concat "=" s))))
    (if (= (length form) 2)
        (eval (cons '! (pen-cip-string (concat "=" s))))
      (eval form))))

;; (pen-ex-to-elisp mesg.pps.list yo -5 =yo yo)

(provide 'pen-ex)
