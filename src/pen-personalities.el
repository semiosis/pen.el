(define-derived-mode person-description-mode yaml-mode "Person"
  "Person description mode")

(add-to-list 'auto-mode-alist '("\\.person\\'" . person-description-mode))

(defvar pen-personalities (make-hash-table :test 'equal)
  "Personalities are supported personality prompts")

(defvar pen-personalities-failed '())

;; (pen-personality-file-load "/home/shane/source/git/semiosis/personalities/personalities/libertyprime.person")
(defun pen-personality-file-load (fp)
  (let* ((yaml-ht (yamlmod-read-file fp))
         (incl-name (sor (ht-get yaml-ht "include")))
         (incl-fp (if (sor incl-name)
                      (f-join
                       pen-personalities-directory
                       "personalities"
                       (concat (slugify incl-name) ".person"))))
         (incl-yaml (if (and (sor incl-name)
                             (f-file-p incl-fp))
                        (pen-personality-file-load incl-fp))))
    (if incl-yaml
        (setq yaml-ht
              (ht-merge incl-yaml
                        ;; The last is overriding
                        yaml-ht)))
    yaml-ht))

(defun pen-test-personality ()
  (interactive)
  (pen-etv (pps (ht-get pen-personalities "freckled-girl"))))

(defun pen-test-pen-expand-template-keyvals-eval-string ()
  (interactive)

  (pen-expand-template-keyvals val personality-keyvals nil nil 'eval-string))

;; Yes this may prompt to define all the personalities initially.
;; But I can always update them on a one-off basis.
;; This is the way it indeed should work.
(defun pen-load-personalities (&optional paths)
  (interactive)

  (setq pen-personalities (make-hash-table :test 'equal))
  (setq pen-personalities-failed '())
  (noupd
   (eval
    `(let ((paths
            (or ,paths
                (-non-nil
                 (mapcar 'sor (glob (concat pen-personalities-directory "/personalities" "/*.person")))))))
       (cl-loop for path in paths do
                (message (concat "pen-mode: Loading .personalitie file " path))

                ;; pen-try
                (let* ((yaml-ht (pen-personality-file-load path))
                       (full-name (ht-get yaml-ht "full-name"))

                       ;; load defs
                       (defs-htlist (pen--htlist-to-alist (ht-get yaml-ht "defs")))
                       (def-values)

                       ;; an alist
                       (defs
                         ;; It's a key-value
                         ;; generate vals from the values
                         ;; and replace defs
                         (let* ((vars-al defs-htlist)
                                (keys (cl-loop
                                       for atp in vars-al
                                       collect
                                       (car atp)))
                                (values (cl-loop
                                         for atp in vars-al
                                         collect
                                         (cdr atp))))

                           (setq def-values values)
                           keys))

                       (def-slugs (mapcar 'slugify defs))
                       ;; (def-syms (mapcar 'intern def-slugs))

                       ;; use the slugs of the keys, so i can use them in further replacements
                       (def-keyvals (-zip def-slugs def-values))

                       (def-replacement-keyvals)

                       (def-keyvals
                         (let ((personality-keyvals))
                           (cl-loop
                            for atp in def-keyvals
                            collect
                            (let ((key (car atp))
                                  (val (str (cdr atp))))
                              (cons
                               key
                               ;; First, update the templateeval keyvals
                               ;; Second, update the actual vals
                               (let* ((eval-template-keys
                                       (-filter-not-empty-string
                                        (append
                                         (mapcar
                                          (lambda (e) (scrape "<\\(.*\\)>" e))
                                          (mapcar
                                           (lambda (s) (concat s ")>"))
                                           (s-split ")>" val)))
                                         (mapcar
                                          (lambda (e) (scrape "<[a-z-]+>" e))
                                          (mapcar
                                           (lambda (s) (concat s ">"))
                                           (s-split ">" val))))))
                                      ;; (display
                                      ;;  (pen-tv (pps eval-template-keys)))
                                      (eval-template-vals
                                       (mapcar
                                        (lambda (s)
                                          (eval
                                           `(pen-let-keyvals
                                             ',def-replacement-keyvals
                                             (eval-string (s-replace-regexp "<\\([^>]*\\)>" "\\1" s)))))
                                        eval-template-keys))
                                      ;; (display
                                      ;;  (pen-tv (pps eval-template-vals)))
                                      (personality-keyvals (-zip eval-template-keys eval-template-vals))
                                      (updated-val
                                       (pen-expand-template-keyvals val personality-keyvals nil nil 'eval-string))
                                      (update
                                       (setq def-replacement-keyvals
                                             (asoc-merge
                                              `((,key . ,updated-val))
                                              def-replacement-keyvals)))
                                      (display
                                       (pen-tv (pps personality-keyvals))))
                                 ;; for each discovered eval template, i must create a key and value
                                 ;; the key is <(...)> inclusive, and the val is (eval-string "(...)")
                                 ;; update the vals here
                                 updated-val))))))
                       ;; now i must run
                       (full-name (pen-expand-template-keyvals full-name def-keyvals)))
                  (pen-etv (pps
                            (asoc-merge
                             `(("personality full name" ,full-name))
                             def-keyvals)))
                  (ht-set yaml-ht "personality-path" path)
                  (message (concat "pen-mode: Loaded personality " full-name))
                  (ht-set pen-personalities full-name yaml-ht))
                ;; (add-to-list 'pen-personalities-failed path)
                ))
    (if pen-personalities-failed
        (progn
          (message "failed:")
          (message (pen-list2str pen-personalities-failed))
          (message (concat (str (length pen-personalities-failed)) " failed")))))))

(provide 'pen-personalities)