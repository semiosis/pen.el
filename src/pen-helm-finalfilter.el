;; This should allow me to have another final filter of the candidates using some kind of additional fuzzyfinder
;; query notation the end of the regular query.

;; TODO Set the value of

(defun helm-global-candidate-filter (candidate)
  candidate)

;; Make this do an extra filtration
(defmacro helm--maybe-process-filter-one-by-one-candidate (candidate source)
  "Execute `filter-one-by-one' function(s) on real value of CANDIDATE in SOURCE."
  `(helm-aif (assoc-default 'filter-one-by-one ,source)
       (let ((real (if (consp ,candidate)
                       (cdr ,candidate)
                     ,candidate)))
         (if (and (listp it)
                  (not (functionp it))) ;; Don't treat lambda's as list.
             (cl-loop for f in it
                      do (setq ,candidate (funcall f real))
                      finally return ,candidate)
           (setq ,candidate (funcall it real))))

     (setq ,candidate (funcall 'helm-global-candidate-filter real))
     ,candidate))

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
