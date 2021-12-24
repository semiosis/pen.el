;; TODO Also have a transient to set

(defun pen-create-transient (name kvps searchfun kwsearchfun)
  (let ((sym (intern (concat name "-transient")))
        (args
         (vconcat (list "Arguments")
                  (append
                   (let ((c 0))
                     (cl-loop for p in kvps do
                              (setq c (1+ c))
                              collect
                              (list (str c) p (concat "--" p "="))))
                   (let ((c 0))
                     (cl-loop for p in kvps do
                              (setq c (1+ c))
                              collect
                              (list
                               (concat "-" (str c))
                               (concat "not" p)
                               (concat "--not-" p "=")))))))
        (actions
         (vconcat
          (list "Actions"
                (list "r" "Run" searchfun)
                (list "d" "Run as filter" kwsearchfun)
                (list "d" "Run as filter" kwsearchfun)))))
    (eval `(define-transient-command ,sym ()
             ,(concat (s-capitalize name) " transient")
             ,args
             ,actions))))

;; (pen-create-transient
;;  "pf initial"
;;  vars
;;  'pen-github-transient-search
;;  'pen-github-transient-search-with-keywords)

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

;; (pen-create-transient "github" pen-github-key-value-predicates 'pen-github-transient-search 'pen-github-transient-search-with-keywords)
(define-key pen-map (kbd "H-? h") 'github-transient)

(provide 'pen-transient)