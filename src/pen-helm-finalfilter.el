;; This should allow me to have another final filter of the candidates using some kind of additional fuzzyfinder
;; query notation the end of the regular query.

;; TODO Set the value of 

(comment
 ;; nadvice - proc is the original function, passed in. do not modify
 (defun helm-get-candidates-around-advice (proc &rest args)
   (message "helm-get-candidates called with args %S" args)
   (let ((res (apply proc args)))
     (message "helm-get-candidates returned %S" res)
     res))
 (advice-add 'helm-get-candidates :around #'helm-get-candidates-around-advice)
 (advice-remove 'helm-get-candidates #'helm-get-candidates-around-advice))

(provide 'pen-helm-finalfilter)
