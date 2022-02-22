(define-derived-mode dni-description-mode yaml-mode "dni"
  "D'ni script mode")

(add-to-list 'auto-mode-alist '("\\.dni\\'" . dni-description-mode))

;; TODO Make this into dni-let macro
(defmacro dni-let (yaml &rest body)
  ;; yaml can be a string to a yaml path or a yaml-ht
  (let* ((yaml-ht (if (stringp yaml)
                      (yamlmod-read-file yaml)
                    yaml))

         ;; load yaml-defs
         (defs-htlist (ht-to-alist yaml-ht))
         (dni-values)

         (yaml-defs
          (let* ((vars-al defs-htlist)
                 (keys (cl-loop
                        for atp in vars-al
                        collect
                        (car atp)))
                 (values (cl-loop
                          for atp in vars-al
                          collect
                          (cdr atp))))

            (setq dni-values values)
            keys))

         (dni-slugs (mapcar 'slugify yaml-defs))

         ;; use the slugs of the keys, so i can use them in further replacements
         (dni-keyvals (-zip dni-slugs dni-values))

         (dni-replacement-keyvals)

         (dni-keyvals
           (cl-loop
            for atp in dni-keyvals
            collect
            (let ((defkey (car atp))
                  (val (str (cdr atp))))
              (cons
               defkey
               (let* (
                      (eval-template-keys
                       (mapcar
                        (lambda (s)
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

                      (eval-template-vals
                       (mapcar
                        (lambda (s)
                          (eval
                           `(pen-let-keyvals
                             ',dni-replacement-keyvals
                             (eval-string (s-replace-regexp "<\\([^>]*\\)>" "\\1" s)))))
                        eval-template-keys))

                      (eval-template-keyvals (-zip eval-template-keys eval-template-vals))

                      (updated-val
                       (pen-expand-template-keyvals val eval-template-keyvals))
                      (update
                       (setq dni-replacement-keyvals
                             (asoc-merge
                              `((,defkey . ,updated-val))
                              dni-replacement-keyvals))))
                 ;; for each discovered eval template, i must create a key and value
                 ;; the key is <(...)> inclusive, and the val is (eval-string "(...)")
                 ;; update the vals here
                 updated-val))))))

    `(pen-let-keyvals
      ,dni-keyvals
      ,@body)))

(defun pen-test-dni-let ()
  (interactive)
  (dni-let "/home/shane/source/git/semiosis/dni/parchment/trafficked-girl.dni"
           (pen-etv description)))

(provide 'pen-dni)
