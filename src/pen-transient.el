(defun pen-create-transient (name kvps searchfun kwsearchfun &optional keywordonly)
  (let ((sym (intern (concat name "-transient")))
        (args
         (vconcat (list "Arguments")
                  (append
                   (let ((c 0))
                     (cl-loop for p in kvps do (setq c (1+ c)) collect (list (str c) p (concat "--" p "="))))
                   (let ((c 0))
                     (cl-loop for p in kvps do (setq c (1+ c)) collect (list (concat "-" (str c)) (concat "not" p) (concat "--not-" p "=")))))))
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

(defun github-transient-search (&optional args)
  (interactive
   (list (transient-args 'github-transient)))
  (let ((query (cl-sn (concat "gen-github-query " (mapconcat 'q args " ") " main") :chomp t)))
    (eegh query)))

(defun github-transient-search-with-keywords (&optional args)
  (interactive
   (list (transient-args 'github-transient)))
  (let* ((keywords (read-string-hist "gh keywords:"))
         (query (cl-sn (concat "gen-github-query " (mapconcat 'q args " ") " " (string-or keywords "main")) :chomp t)))
    (eegh query)))

(defset github-key-value-predicates
  ;; prefix with - to invert i.e. -inurl:
  (list ;; "ext"
   "repo"
   "extension"
   "path"
   "filename"
   "followers"
   "language"
   "license"))

(pen-create-transient "github" github-key-value-predicates 'github-transient-search 'github-transient-search-with-keywords t)
(define-key global-map (kbd "H-? h") 'github-transient)

(provide 'pen-transient)