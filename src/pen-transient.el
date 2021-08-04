(defun create-my-transient (name kvps searchfun kwsearchfun &optional keywordonly)
  (let ((sym (str2sym (concat name "-transient")))
        (args
         (vconcat (list "Arguments")
                  (append
                   ;; (let ((c 0))
                   ;;   (cl-loop for p in google-key-value-predicates do (setq c (1+ c))
                   ;;            collect
                   ;;            (list ;; (concat "-" (str c))
                   ;;             (str c) p (concat "--" p "="))
                   ;;            collect
                   ;;            (list ;; (concat "-" (str c))
                   ;;             (concat "-" (str c)) (concat "not" p) (concat "--not-" p "=")))
                   ;;   (concat "-" (str c)))
                   (let ((c 0))
                     (cl-loop for p in kvps do (setq c (1+ c)) collect (list (str c) p (concat "--" p "="))))
                   (let ((c 0))
                     (cl-loop for p in kvps do (setq c (1+ c)) collect (list (concat "-" (str c)) (concat "not" p) (concat "--not-" p "="))))
                   ;; (list (list "k" "keywords" "--keywords="))
                   )))
        (actions
         (vconcat
          (if keywordonly
              (list "Actions"
                    (list "k" "Search with keywords" kwsearchfun))
            (list "Actions"
                    (list "s" "Search" searchfun)
                    (list "k" "Search with keywords" kwsearchfun))))))
    (eval `(define-transient-command ,sym ()
             ,(concat (s-capitalize name) " transient")
             ,args
             ,actions))))

(provide 'pen-transient)