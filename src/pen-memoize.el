(require 'memoize)
(require 'pen-configure)

;; These changes are required to allow persistent caching on disk

(defset pen-ht-cache-dir (f-join penconfdir "ht-cache"))
;; (defset pen-ht-cache-dir (f-join "/dev/shm" "ht-cache"))

(f-mkdir pen-ht-cache-dir)

(defun pen-ht-cache-slug-fp (name)
  (concat pen-ht-cache-dir "/" "memo-"
          (or (sor pen-memo-prefix
                   "global"))
          "-"
          (slugify name) ".elht"))

(defun ht-cache (name &optional ht)
  (let* ((n (pen-ht-cache-slug-fp name))
         (nswap (concat n ".swap")))
    (if ht
        (progn (shut-up (pen-write-to-file (prin1-to-string ht) nswap))
               (rename-file nswap n t))
      ;; This is the place to ensure that the file is owned by the user
      (if (f-exists-p n)
          (let ((r (find-file-literally n)))
            (if r
                (let ((ret (read r)))
                  (kill-buffer r)
                  ret)))))))

(defun ht-cache-delete (name)
  (f-delete (pen-ht-cache-slug-fp name) t))

(defun make-or-load-hash-table (name args)
  (progn
    (or (ht-cache name)
        (apply 'make-hash-table args))))


(defun memoize (func &optional timeout)
  "Memoize FUNC: a closure, lambda, or symbol.

If argument is a symbol then install the memoized function over
the original function. The TIMEOUT value, a timeout string as
used by `run-at-time' will determine when the value expires, and
will apply after the last access (unless another access
happens)."
  (cl-typecase func
    (symbol
     (when (get func :memoize-original-function)
       (user-error "%s is already memoized" func))
     (put func :memoize-original-documentation (documentation func))
     (put func 'function-documentation
          (concat (documentation func) " (memoized)"))
     (put func :memoize-original-function (symbol-function func))
     (fset func (memoize--wrap (symbol-function func) timeout func))
     func)
    (function (memoize--wrap func timeout funcsym))))


;; (defun memoize-update-call (func args)
;;   (let* ((funcpps (pps func))
;;          (func_slug_data (md5 (substring funcpps 0 100)))
;;          (func_slug (substring
;;                     (concat (str funcsym) "-" func_slug_data
;;                             ;; "-" funcpps
;;                             )
;;                     0 100))
;;          ;; (func_slug (slugify (s-join "-" (pen-str2list func_slug_data))))
;;          (tablename (concat "table-" func_slug))
;;          (table (make-or-load-hash-table tablename '(:test equal)))))
;;   (remhash args table))


;; Process:
(comment
 (let ((tn "table-dff-let-nil-let-info-a-about-a-nstory-book-info-b-about-a-nmystery-tv-firstrun-snc-tr-s-a-a-car-str2"))
   (ht-cache tn)

   ;; this loads from the file or makes an empty hash table
   (make-or-load-hash-table tn '(:test equal))
   
   ;; Puts the maybe empty hash table here (saves it):
   ;; $PEN/ht-cache
   (ht-cache tn (make-or-load-hash-table tn '(:test equal)))

   ;; Then delete it again
   (ht-cache-delete tn)))

(comment
 (memoize 'dff-let-nil-let-info-a-about-a-nstory-book-info-b-about-a-nmystery-tv-firstrun-snc-tr-s-a-a-car-str2lines-concat-info-a-info-b-)
 (memoize-restore 'dff-let-nil-let-info-a-about-a-nstory-book-info-b-about-a-nmystery-tv-firstrun-snc-tr-s-a-a-car-str2lines-concat-info-a-info-b-)
 (memoize-delete 'dff-let-nil-let-info-a-about-a-nstory-book-info-b-about-a-nmystery-tv-firstrun-snc-tr-s-a-a-car-str2lines-concat-info-a-info-b-)
 ;; $PEN/ht-cache/memo-pen-agia-table-dff-let-nil-let-info-a-about-a-nstory-book-info-b-about-a-nmystery-tv-firstrun-snc-tr-s-a-a-car-str2.elht
 (dff-let-nil-let-info-a-about-a-nstory-book-info-b-about-a-nmystery-tv-firstrun-snc-tr-s-a-a-car-str2lines-concat-info-a-info-b-))

(defun memoize-restore-around-advice (proc &rest args)
  (let ((res (apply proc args)))
    ;; Also delete when I restore
    (apply 'memoize-delete args)
    res))
(advice-add 'memoize-restore :around #'memoize-restore-around-advice)
;; (advice-remove 'memoize-restore #'memoize-restore-around-advice)


;; This was broken
(comment
 (defun memoize--wrap (func timeout)
   "Return the memoized version of FUNC.
TIMEOUT specifies how long the values last from last access. A
nil timeout will cause the values to never expire, which will
cause a memory leak as memoize is use, so use the nil value with
care."
   (let* (;;This also works for lambdas
          (funcpps (pps func))
          (func_slug_data (if (< 150 (length funcpps))
                            (md5 funcpps)
                          funcpps))
          (func_slug (slugify (s-join "-" (pen-str2list func_slug_data))))
          (tablename (concat "table-" func_slug))
          (timeoutsname (concat "timeouts-" func_slug))
          (table (make-or-load-hash-table tablename '(:test equal)))
          (timeouts (make-or-load-hash-table timeoutsname '(:test equal))))
     (eval
      `(lambda (&rest args)
         (let ((value (gethash args ,table)))
           (unwind-protect
               ;; (or value (puthash args (apply ,func args) ,table))
               (let ((ret (or
                           (and
                            (not (pen-var-value-maybe 'pen-sh-update))
                            (not (pen-var-value-maybe 'do-pen-update))
                            (not (>= (prefix-numeric-value current-global-prefix-arg) 4))
                            (not (>= (prefix-numeric-value current-prefix-arg) 4))
                            value)
                           ;; Add to the hash table and save the hash table
                           (let ((newret (puthash args
                                                  (or (apply ,func args)
                                                      'MEMOIZE_NIL)
                                                  ,table)))
                             (if (featurep 'hashtable-print-readable)
                                 (ht-cache ,tablename ,table))
                             newret))))
                 (if (equal ret 'MEMOIZE_NIL)
                     (setq ret nil))
                 ret)
             (let ((existing-timer (gethash args ,timeouts))
                   (timeout-to-use (or
                                    ;; timeout comes from the calling 'memoize' function
                                    (and (variable-p 'timeout)
                                         timeout)
                                    memoize-default-timeout)))
               (when existing-timer
                 (cancel-timer existing-timer))
               (when timeout-to-use
                 (puthash args
                          (run-at-time timeout-to-use nil
                                       (eval
                                        `(lambda ()
                                           (remhash ,args ,,table)
                                           ;; It would probably be better to alert and ignore
                                           n ;; (try (remhash args ,table)
                                           ;;      (message ,(concat "timer for memoized " func_slug " failed")))
                                           ))) ,,timeouts))))))))))

;; Theses do very similar things
(defun memoize-exists-p (func_sym)
  "Check if memo function exists in memory"
  (get func_sym :memoize-original-function))

(defun memoize-file-exists-p (func_sym)
  "Check if memo function exists in storage"
  
  ;; Checks for t
  (let* (;;This also works for lambdas
         (func_body (symbol-function func_sym))
         (funcpps (pps func_body))
         (func_slug_data (md5 (substring funcpps 0 100)))
         (func_slug (message "%s" (substring
                                   (concat (str func_sym) "-" func_slug_data
                                           "-" (slugify funcpps t 100))
                                   0 100)))
         (tablename (concat "table-" func_slug))
         (timeoutsname (concat "timeouts-" func_slug))
         (table_fp (pen-ht-cache-slug-fp tablename))
         (timeouts_fp (pen-ht-cache-slug-fp timeoutsname)))
    (f-exists-p (pen-ht-cache-slug-fp tablename))))

(defun memoize-delete (func_sym)
  (let* (;;This also works for lambdas
         (func_body (symbol-function func_sym))
         (funcpps (pps func_body))
         (func_slug_data (md5 (substring funcpps 0 100)))
         (func_slug (message "%s" (substring
                                   (concat (str func_sym) "-" func_slug_data
                                           "-" (slugify funcpps t 100))
                                   0 100)))
         (tablename (concat "table-" func_slug))
         (timeoutsname (concat "timeouts-" func_slug))
         (table_fp (pen-ht-cache-slug-fp tablename))
         (timeouts_fp (pen-ht-cache-slug-fp timeoutsname)))
    (ignore-errors (f-delete table_fp))
    (ignore-errors (f-delete timeouts_fp))))

;; This fixed it
;; also, i added funcsym so I don't have to sha the function body
(defun memoize--wrap (func timeout funcsym)
  "Return the memoized version of FUNC.
TIMEOUT specifies how long the values last from last access. A
nil timeout will cause the values to never expire, which will
cause a memory leak as memoize is use, so use the nil value with
care."
  (let* (;;This also works for lambdas
         (funcpps (pps func))
         (func_slug_data (md5 (substring funcpps 0 100)))
         (func_slug (message "%s" (substring
                                   (concat (str funcsym) "-" func_slug_data
                                           "-" (slugify funcpps t 100))
                                   0 100)))
         (tablename (concat "table-" func_slug))
         (timeoutsname (concat "timeouts-" func_slug))
         ;; (table (eval `(make-or-load-hash-table ,tablename :test 'equal)))
         ;; (timeouts (eval `(make-or-load-hash-table ,timeoutsname :test 'equal)))
         (table (make-or-load-hash-table tablename '(:test equal)))
         (timeouts (make-or-load-hash-table timeoutsname '(:test equal))))
    (eval
     `(lambda (&rest args)
        (let ((value (gethash args ,table)))
          (unwind-protect
              ;; (or value (puthash args (apply ,func args) ,table))
              (let ((ret (or (and
                              (not (pen-var-value-maybe 'pen-sh-update))
                              (not (pen-var-value-maybe 'do-pen-update))
                              (not (>= (prefix-numeric-value current-global-prefix-arg) 4))
                              (not (>= (prefix-numeric-value current-prefix-arg) 4))
                              value)
                             ;; Add to the hash table and save the hash table
                             (let ((newret (puthash args
                                                    (or (apply ,func args)
                                                        'MEMOIZE_NIL)
                                                    ,table)))
                               (if (featurep 'hashtable-print-readable)
                                   (ht-cache ,tablename ,table))
                               newret))))
                (if (equal ret 'MEMOIZE_NIL)
                    (setq ret nil))
                ret)
            (let ((existing-timer (gethash args ,timeouts))
                  (timeout-to-use (or
                                   ;; timeout comes from the calling 'memoize' function
                                   (and (variable-p 'timeout)
                                        timeout)
                                   memoize-default-timeout)))
              (when existing-timer
                (cancel-timer existing-timer))
              (when timeout-to-use
                (puthash args
                         (run-at-time timeout-to-use nil
                                      (lambda ()
                                        ;; It would probably be better to alert and ignore
                                        (try (remhash args ,table)
                                             ;; (message ,(concat "timer for memoized " func_slug " failed"))
                                             t)))
                         ,timeouts)))))))))

(defun ignore-errors-around-advice (proc &rest args)
  (ignore-errors
    (let ((res (apply proc args)))
      res)))

(advice-add 'memoize-restore :around #'ignore-errors-around-advice)
(advice-add 'memoize :around #'ignore-errors-around-advice)

;; (advice-remove 'memoize-restore #'ignore-errors-around-advice)
;; (advice-remove 'memoize #'ignore-errors-around-advice)

(ignore-errors (memoize-restore 'lg-url-is-404))
(memoize 'lg-url-is-404)
(ignore-errors (memoize-restore 'url-cache-is-404))
(memoize 'url-cache-is-404)

(defun test-memo ()
  (interactive)
  (let ((result
         (ilist 10 "tree species")))
    (etv result)))

(defun pen-rememoize ()
  (interactive)  
  (memoize-restore 'pen-prompt-snc)
  (memoize 'pen-prompt-snc))

(provide 'pen-memoize)
