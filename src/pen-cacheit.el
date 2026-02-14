(require 'f)

(defset pen-ci-cache-dir (f-join penconfdir "ci-cache"))

(ignore-errors
  (f-mkdir pen-ci-cache-dir))

(defun serialize (exp)
  (s-chomp (if (or (listp exp)
                   (consp exp))
               (concat "'" (pp-to-string exp))
             (pp-to-string exp))))

(comment
 (mesg (pps (let ((m "yo")) (cache `(progn (sleep 1) ,m) t))))
 (mesg (pps (let ((m "yo")) (cache `(progn (sleep 1) ,m)))))

 ;; TODO Stabilise; Ensure these both work
 (! mesg.pps.car.eval
  (let ((m '(a "dfksjl" c)))
    (cache `(progn (sleep 1) ',m))))
 (! mesg.pps.car.eval
  (let ((m '(a "dfksjl" c)))
    (cache
     `(progn (sleep 1) ',m)
     t)))
 (mesg (pps (car (eval (let ((m '(a "dfksjl" c))) (cache `(progn (sleep 1) ',m)))))))
 (mesg (pps (car (eval (let ((m '(a "dfksjl" c))) (cache `(progn (sleep 1) ',m) t))))))
 
 ;; Or both of these
 (! mesg.pps.car
  (let ((m '(a "dfksjl" c)))
    (cache `(progn (sleep 1) ',m))))
 (! mesg.pps.car
  (let ((m '(a "dfksjl" c)))
    (cache
     `(progn (sleep 1) ',m)
     t)))
 (mesg (pps (car (let ((m '(a "dfksjl" c))) (cache `(progn (sleep 1) ',m))))))
 (mesg (pps (car (let ((m '(a "dfksjl" c))) (cache `(progn (sleep 1) ',m) t)))))
 
 (! mesg.pps
  (let ((m '(a "dfksjl" c)))
    (cache `(progn (sleep 1) ',m))))
 (! mesg.pps
  (let ((m '(a "dfksjl" c)))
    (cache
     `(progn (sleep 1) ',m)
     t)))
 (mesg (pps (let ((m '(a "dfksjl" c))) (cache `(progn (sleep 1) ',m)))))
 (mesg (pps (let ((m '(a "dfksjl" c))) (cache `(progn (sleep 1) ',m) t))))
 (tv (let ((m '(a "test" c))) (cache `(progn (sleep 1) ',m)))))

(defmacro pen-ci (exp &optional b_update)
  "Caches something. Saves an expression."
  (let* ((name (str exp))
         (result nil)
         (b_update
          (or
           (pen-var-value-maybe 'pen-sh-update)
           (pen-var-value-maybe 'pen-sh-update)
           b_update
           (>= (prefix-numeric-value current-prefix-arg) 4)))
         (fp (f-join pen-ci-cache-dir (slugify name))))
    (if (and (file-exists-p fp)
             (not b_update))
        (progn
          (setq result (shut-up (e/cat fp))))
      (progn
        (let ((exp (eval exp)))
          (if (listp exp)
              (setq result (concat "'" (pp-to-string exp)))
            (setq result (pp-to-string exp))))
        (shut-up (write-to-file (str result)
                                fp))))
    (if (or (string-match-p "^[0-9.]+$" result) ; number
            (string-match-p "^(.*)$" result)
            (string-match-p "^nil$" result)
            (string-match-p "^t$" result) ; sexp
            )
        (setq result (read result)))
    `',result))

(defun cache (exp &optional b_update)
  ;; (eval exp)

  (let* ((name (str exp))
         (result nil)

         (b_update
          (or
           (pen-var-value-maybe 'pen-sh-update)
           (pen-var-value-maybe 'pen-sh-update)
           b_update
           (>= (prefix-numeric-value current-prefix-arg) 4)))
         (fp (f-join pen-ci-cache-dir (shortened-string-with-hash name)))

         (using-cached
          (and (file-exists-p (tv fp))
               (not b_update))))

    (if using-cached
        (progn
          ;; Read from cache into result
          (setq result (! shut-up·e/cat fp))
          ;; (eval-string (read result))
          (read result)
          ;; (if (or (string-match-p "^[0-9.]+$" result) ; number
          ;;         (string-match-p "^(.*)$" result)
          ;;         (string-match-p "^'(.*)$" result)
          ;;         (string-match-p "^nil$" result)
          ;;         (string-match-p "^t$" result) ; sexp
          ;;         )
          ;;     (setq result (eval-string (read result))))
          )

      ;; If not using cache, then evaluate and write to cache
      ;; Also set result
      (let ((result (eval exp)))
        ;; (shut-up (write-to-file (! tv·serialize result) fp))
        (delete-file fp)
        ;; (shut-up (write-to-file result (tv fp)))
        (write-to-file (serialize result) (tv fp))
        result))))

(provide 'pen-cacheit)
