(require 'f)

(defset pen-ci-cache-dir (f-join penconfdir "ci-cache"))

(f-mkdir pen-ci-cache-dir)

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
        (setq result (pp-to-string (eval exp)))
        (shut-up (write-to-file (str result) fp))))
    (if (or (string-match-p "^[0-9.]+$" result) ; number
            (string-match-p "^(.*)$" result)
            (string-match-p "^nil$" result)
            (string-match-p "^t$" result) ; sexp
            )
        (setq result (read result)))
    `',result))

(provide 'pen-cacheit)