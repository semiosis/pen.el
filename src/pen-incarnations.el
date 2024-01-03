(define-derived-mode incarnation-description-mode yaml-mode "Incarnation"
  "Incarnation description mode")

(add-to-list 'auto-mode-alist '("\\.incarnation\\'" . incarnation-description-mode))

(defvar pen-incarnations (make-hash-table :test 'equal)
  "Incarnations are chatbots generated from personality prompts")

(defvar pen-incarnations-failed '())

(defun pen-delete-incarnations ()
  (interactive)
  (if (y-or-n-p "Really erase all incarnations?")
      (setq pen-incarnations (make-hash-table :test 'equal))))

(defun pen-list-incarnations ()
  (ht-keys pen-incarnations))

;; (pen-spawn-incarnation "name unknown - a girl who was trafficked")
(defun pen-spawn-incarnation (personality)
  (interactive (list
                (fz (pen-list-personalities)
                    nil nil "Personality: ")))

  (setq pen-incarnations-failed '())
  (let* ((yaml-ht (ht-get pen-personalities personality))
         (full-name (ht-get yaml-ht "full-name"))
         (description (ht-get yaml-ht "description"))
         (bio (ht-get yaml-ht "bio"))
         (personality-path (ht-get yaml-ht "path"))
         (full-name-and-bio (ht-get yaml-ht "full-name-and-bio"))

         ;; load person-defs
         (defs-htlist (pen--htlist-to-alist (ht-get yaml-ht "defs")))
         (def-values)

         (person-defs
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

         (def-slugs (mapcar 'slugify person-defs))

         ;; use the slugs of the keys, so i can use them in further replacements
         (def-keyvals (-zip def-slugs def-values))

         (def-replacement-keyvals)

         (def-keyvals
           (cl-loop
            for atp in def-keyvals
            collect
            (let ((defkey (car atp))
                  (val (str (cdr atp))))
              (cons
               defkey
               ;; First, update the templateeval keyvals
               ;; Second, update the actual vals
               (let* (
                      ;; for each .personality key, create a set of template keys by scaping the string
                      (eval-template-keys
                       (mapcar
                        ;; Remove the angle brackets
                        ;; These keys will be used in the template expansion
                        (lambda (s)
                          ;; This is ugly but $ didnt seem to work
                          (s-replace-regexp "<" "" (s-replace-regexp ">" "" (chomp s))))
                        (append
                         (-filter-not-empty-string
                          (mapcar
                           (lambda (e) (scrape "<\\(.*\\)>" e))
                           (mapcar
                            (lambda (s) (concat s ")>"))
                            (s-split ")>" val))))
                         (-filter-not-empty-string
                          (mapcar
                           (lambda (e) (scrape "<[a-z-]+>" e))
                           (mapcar
                            (lambda (s) (concat s ">"))
                            (s-split ">" val)))))))

                      ;; test this
                      (eval-template-vals
                       (mapcar
                        (lambda (s)
                          (eval
                           `(pen-let-keyvals
                             ',def-replacement-keyvals
                             (eval-string (s-replace-regexp "<\\([^>]*\\)>" "\\1" s)))))
                        eval-template-keys))

                      (eval-template-keyvals (-zip eval-template-keys eval-template-vals))

                      (updated-val
                       (pen-expand-template-keyvals val eval-template-keyvals))
                      (update
                       (setq def-replacement-keyvals
                             (asoc-merge
                              `((,defkey . ,updated-val))
                              def-replacement-keyvals))))
                 ;; for each discovered eval template, i must create a key and value
                 ;; the key is <(...)> inclusive, and the val is (eval-string "(...)")
                 ;; update the vals here
                 updated-val)))))

         (defs-full-name (cdr (assoc "full-name" def-keyvals)))
         (defs-description (cdr (assoc "description" def-keyvals)))
         ;; now i must run
         (full-name
          (cond
           (defs-full-name defs-full-name)
           (full-name full-name)
           (t "unknown person"))
          )
         ;; (full-name (pen-expand-template-keyvals full-name def-replacement-keyvals))
         ;; (description
         ;;  (if (assoc "full-name" description)
         ;;      (assoc "full-name" description)
         ;;    "<description>"))
         (description
          (cond
           (defs-description defs-description)
           (description description)
           (t "unknown bio")))
         ;; (description (pen-expand-template-keyvals description def-replacement-keyvals))
         )

    (setq def-keyvals
          (asoc-merge
           `(("incarnation full name" ,full-name))
           def-keyvals))

    (loop for kv in def-keyvals do
          (ht-set yaml-ht (concat "def-" (car kv)) (cdr kv)))

    (ht-set yaml-ht "full-name" full-name)
    (ht-set yaml-ht "personality-full-name-and-bio" full-name-and-bio)
    (ht-set yaml-ht "description" description)
    (ht-set yaml-ht "personality-path" personality-path)

    (message (concat "pen-mode: Loaded incarnation " full-name))
    (ht-set pen-incarnations full-name yaml-ht)

    (if pen-incarnations-failed
        (progn
          (message "failed:")
          (message (pen-list2str pen-incarnations-failed))
          (message (concat (str (length pen-incarnations-failed)) " failed"))))

    full-name))

(provide 'pen-incarnations)
