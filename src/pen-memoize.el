(require 'memoize)
(require 'pen-configure)

;; These changes are required to allow persistent caching on disk

(defset pen-ht-cache-dir (f-join penconfdir "ht-cache"))

(f-mkdir pen-ht-cache-dir)

(defun pen-ht-cache-slug-fp (name)
  (concat pen-ht-cache-dir "/" "persistent-hash-"
          (or (sor pen-memo-prefix
                   "global"))
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



(defun memoize-update-call (func args)
  (let* ((funcpps (pps func))
         (funcslugdata (if (< 150 (length funcpps))
                           (md5 funcpps)
                         funcpps))
         (funcslug (slugify (s-join "-" (pen-str2list funcslugdata))))
         (tablename (concat "table-" funcslug))
         (table (make-or-load-hash-table tablename '(:test equal)))))
  (remhash args table))


(defun memoize--wrap (func timeout)
  "Return the memoized version of FUNC.
TIMEOUT specifies how long the values last from last access. A
nil timeout will cause the values to never expire, which will
cause a memory leak as memoize is use, so use the nil value with
care."
  (let* (;;This also works for lambdas
         (funcpps (pps func))
         (funcslugdata (if (< 150 (length funcpps))
                           (md5 funcpps)
                         funcpps))
         (funcslug (slugify (s-join "-" (pen-str2list funcslugdata))))
         (tablename (concat "table-" funcslug))
         (timeoutsname (concat "timeouts-" funcslug))
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
                                         ;; (try (remhash args ,table)
                                         ;;      (message ,(concat "timer for memoized " funcslug " failed")))
                                         ))) ,,timeouts)))))))))

(defun ignore-errors-around-advice (proc &rest args)
  (ignore-errors
    (let ((res (apply proc args)))
      res)))

(advice-add 'memoize-restore :around #'ignore-errors-around-advice)
(advice-add 'memoize :around #'ignore-errors-around-advice)

(memoize-restore 'lg-url-is-404)
(memoize 'lg-url-is-404)
(memoize-restore 'url-cache-is-404)
(memoize 'url-cache-is-404)

(defun test-memo ()
  (interactive)
  (let ((result
         (ilist 10 "tree species")))
    (etv result)))

(provide 'pen-memoize)
