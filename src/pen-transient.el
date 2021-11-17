(defun pen-create-transient (name kvps searchfun kwsearchfun &optional keywordonly)
  (let ((sym (intern (concat name "-transient")))
        (args
         (vconcat (list "Arguments")
                  (append
                   (let ((c 0))
                     (loop for p in kvps do (setq c (1+ c)) collect (list (str c) p (concat "--" p "="))))
                   (let ((c 0))
                     (loop for p in kvps do (setq c (1+ c)) collect (list (concat "-" (str c)) (concat "not" p) (concat "--not-" p "=")))))))
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

(defun pen-github-transient-search (&optional args)
  (interactive
   (list (transient-args 'github-transient)))
  (let ((query (pen-cl-sn (concat "gen-github-query " (mapconcat 'pen-q args " ") " main") :chomp t)))
    (eegh query)))

(defun pen-github-transient-search-with-keywords (&optional args)
  (interactive
   (list (transient-args 'github-transient)))
  (let* ((keywords (read-string-hist "gh keywords:"))
         (query (pen-cl-sn (concat "gen-github-query " (mapconcat 'pen-q args " ") " " (sor keywords "main")) :chomp t)))
    (eegh query)))

(defset pen-github-key-value-predicates
  ;; prefix with - to invert i.e. -inurl:
  (list ;; "ext"
   "repo"
   "extension"
   "path"
   "filename"
   "followers"
   "language"
   "license"))

(pen-create-transient "github" pen-github-key-value-predicates 'pen-github-transient-search 'pen-github-transient-search-with-keywords t)
(define-key pen-map (kbd "H-? h") 'github-transient)

(provide 'pen-transient)