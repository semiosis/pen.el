;; This should allow me to have another final filter of the candidates using some kind of additional fuzzyfinder
;; query notation the end of the regular query.

;; TODO Set the value of

(comment
 ;; Sigh... this just transforms the results - it doesn't "filter" them
 ;; v +/"\"  A transformer function that treat candidates one by one." "$EMACSD_BUILTIN/elpa/helm-core-20210804.1141/helm-source.el"
 (defun helm-global-candidate-filter (candidate)
   (message "Candidate: %s" candidate)
   candidate
   ;; (if (re-match-p "foundation" candidate)
   ;;     candidate
   ;;   nil)
   )

 (comment
  (load-library "helm"))

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
                       do
                       (progn (setq ,candidate (funcall f real))
                              (setq ,candidate (funcall 'helm-global-candidate-filter ,candidate)))
                       finally return ,candidate)
            (progn
              (setq ,candidate (funcall it real))
              (setq ,candidate (funcall 'helm-global-candidate-filter ,candidate)))))

      (progn
        (setq ,candidate (funcall 'helm-global-candidate-filter ,candidate))
        ,candidate)))

 ;; It's needed to redefine all the functions and macros which depend on the changed macro

 (defun helm--initialize-one-by-one-candidates (candidates source)
   "Process CANDIDATES with the `filter-one-by-one' function in SOURCE.
Return CANDIDATES unchanged when pattern is not empty."
   (helm-aif (and (string= helm-pattern "")
                  (assoc-default 'filter-one-by-one source))
       (cl-loop for cand in candidates collect
                (helm--maybe-process-filter-one-by-one-candidate cand source))
     candidates))

 (defun helm-match-from-candidates (cands matchfns match-part-fn limit source)
   (when cands                          ; nil in async sources.
     (condition-case-unless-debug err
         (cl-loop with hash = (make-hash-table :test 'equal)
                  with allow-dups = (assq 'allow-dups source)
                  with case-fold-search = (helm-set-case-fold-search)
                  with count = 0
                  for iter from 1
                  for fn in matchfns
                  when (< count limit) nconc
                  (cl-loop for c in cands
                           for dup = (gethash c hash)
                           for disp = (helm-candidate-get-display c)
                           while (< count limit)
                           for target = (if (helm-get-attr 'match-on-real source)
                                            ;; Let's fails on error in
                                            ;; case next block returns nil.
                                            (or (cdr-safe c)
                                                (get-text-property 0 'helm-realvalue disp))
                                          disp)
                           for prop-part = (get-text-property 0 'match-part target)
                           for part = (and match-part-fn
                                           (or prop-part
                                               (funcall match-part-fn target)))
                           ;; When allowing dups check if DUP
                           ;; have been already found in previous loop
                           ;; by comparing its value with ITER.
                           when (and (or (and allow-dups dup (= dup iter))
                                         (null dup))
                                     (condition-case nil
                                         (funcall fn (or part target))
                                       (invalid-regexp nil)))
                           do
                           (progn
                             ;; Give as value the iteration number of
                             ;; inner loop to be able to check if
                             ;; the duplicate have not been found in previous loop.
                             (puthash c iter hash)
                             (helm--maybe-process-filter-one-by-one-candidate c source)
                             (cl-incf count))
                           ;; Filter out nil candidates maybe returned by
                           ;; `helm--maybe-process-filter-one-by-one-candidate'.
                           and when c collect
                           (if (and part (not prop-part))
                               (if (consp c)
                                   (cons (propertize target 'match-part part) (cdr c))
                                 (propertize c 'match-part part))
                             c)))
       (error (unless (eq (car err) 'invalid-regexp) ; Always ignore regexps errors.
                (helm-log-error "helm-match-from-candidates in source `%s': %s %s"
                                (assoc-default 'name source) (car err) (cdr err)))
              nil))))

 (defun helm-output-filter--process-source (process output-string source limit)
   (cl-dolist (candidate (helm-transform-candidates
                          (helm-output-filter--collect-candidates
                           (split-string output-string "\n")
                           (assq 'incomplete-line source))
                          source t))
     (setq candidate
           (helm--maybe-process-filter-one-by-one-candidate candidate source))
     (if (assq 'multiline source)
         (let ((start (point)))
           (helm-insert-candidate-separator)
           (helm-insert-match candidate 'insert-before-markers
                              (1+ (cdr (assq 'item-count source)))
                              source)
           (put-text-property start (point) 'helm-multiline t))
       (helm-insert-match candidate 'insert-before-markers
                          (1+ (cdr (assq 'item-count source)))
                          source))
     (cl-incf (cdr (assq 'item-count source)))
     (when (>= (assoc-default 'item-count source) limit)
       (helm-kill-async-process process)
       (helm-log-run-hook 'helm-async-outer-limit-hook)
       (cl-return))))

 (defun helm-search-from-candidate-buffer (pattern get-line-fn search-fns
                                                   limit start-point match-part-fn source)
   (let ((inhibit-read-only t))
     (helm--search-from-candidate-buffer-1
      (lambda ()
        (cl-loop with hash = (make-hash-table :test 'equal)
                 with allow-dups = (assq 'allow-dups source)
                 with case-fold-search = (helm-set-case-fold-search)
                 with count = 0
                 for iter from 1
                 for searcher in search-fns
                 do (progn
                      (goto-char start-point)
                      ;; The character at start-point is a newline,
                      ;; if pattern match it that's mean we are
                      ;; searching for newline in buffer, in this
                      ;; case skip this false line.
                      ;; See comment >>>[1] in
                      ;; `helm--search-from-candidate-buffer-1'.
                      (and (condition-case nil
                               (looking-at pattern)
                             (invalid-regexp nil))
                           (forward-line 1)))
                 nconc
                 (cl-loop with pos-lst
                          ;; POS-LST is used as a flag to decide if we
                          ;; run `helm-search-match-part' even if
                          ;; MATCH-PART isn't specified on source. This
                          ;; happen when fuzzy matching or using a
                          ;; negation (!) in one of the patterns, in
                          ;; these case the searcher returns a list
                          ;; '(BEG END) instead of an integer like
                          ;; `re-search-forward'.
                          while (and (setq pos-lst (funcall searcher pattern))
                                     (not (eobp))
                                     (< count limit))
                          for cand = (apply get-line-fn
                                            (if (and pos-lst (listp pos-lst))
                                                pos-lst
                                              (list (point-at-bol) (point-at-eol))))
                          when (and match-part-fn
                                    (not (get-text-property 0 'match-part cand)))
                          do (setq cand
                                   (propertize cand 'match-part (funcall match-part-fn cand)))
                          for dup = (gethash cand hash)
                          when (and (or (and allow-dups dup (= dup iter))
                                        (null dup))
                                    (or
                                     ;; Always collect when cand is matched
                                     ;; by searcher funcs and match-part attr
                                     ;; is not present.
                                     (and (not match-part-fn)
                                          (not (consp pos-lst)))
                                     ;; If match-part attr is present, or if SEARCHER fn
                                     ;; returns a cons cell, collect PATTERN only if it
                                     ;; match the part of CAND specified by
                                     ;; the match-part func.
                                     (helm-search-match-part cand pattern)))
                          do (progn
                               (puthash cand iter hash)
                               (helm--maybe-process-filter-one-by-one-candidate cand source)
                               (cl-incf count))
                          and collect cand))))))

 (comment
  ;; nadvice - proc is the original function, passed in. do not modify
  (defun helm-get-candidates-around-advice (proc &rest args)
    (message "helm-get-candidates called with args %S" args)
    (let ((res (apply proc args)))
      (message "helm-get-candidates returned %S" res)
      res))
  (advice-add 'helm-get-candidates :around #'helm-get-candidates-around-advice)
  (advice-remove 'helm-get-candidates #'helm-get-candidates-around-advice)))

(provide 'pen-helm-finalfilter)
