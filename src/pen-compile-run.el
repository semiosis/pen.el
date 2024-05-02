(defun compile-run ()
  "This is used to compile and run a source file."
  (interactive)
  (cond ((bound-and-true-p go-playground-mode)
         (call-interactively 'go-playground-exec))
        ;; Unfortunately, cant use ~tm sps~ because the command can't find the LINES and COLUMNS, even with eval resize
        ;; sps works now

        ;; TODO use the current directory?
        ;; (get-temp-fp)

        (t ;; (pen-snc (concat "unbuffer pen-tm -f -te -d sps -x -pak -args pen-cr " crstr))

         ;; crstr is the filetype and the path
         ;; Handle this better. Sometimes the buffer does not have a path.
         ;; If it doesn't have a path.
         ;; get-path-ext-from-mode-alist
         (let* ((ext
                 (if (buffer-file-name)
                     (f-ext (buffer-file-name))))
                (ext (or ext
                         (get-ext-for-mode)
                         ""))
                (crstr
                 (cond ((sor ext) (concat "-ft " ext " " (pen-q (str (buffer-file-name)))))
                       (t (pen-q (str (buffer-file-name)))))))

           ;; (save-temp-if-no-file)
           (if (not (buffer-file-name))
               ;; (pen-sn (concat "pen-tm -f -S -i -tout sps -x -pak -args pen-cr " crstr) (awk1 (buffer-string)))
               (tpop (concat "pen-cr " crstr)
                     (awk1 (s-replace-regexp
                            "^ \\+"
                            ""
                            (buffer-string))))
             ;; (pen-snc (concat "unbuffer pen-tm -f -te -d sps -x -pak -args pen-cr " crstr))
             (tpop (concat "pen-cr " crstr)))))))

(defun compile-run-term ()
  "This is used to compile and run a source file."
  (interactive)
  (cond ((bound-and-true-p go-playground-mode) (call-interactively 'go-playground-exec))
        ;; Unfortunately, cant use ~tm sps~ because the command can't find the LINES and COLUMNS, even with eval resize
        ;; sps works now
        (t ;; (pen-snc (concat "unbuffer pen-tm -f -te -d sps -x -pak -args pen-cr " crstr))
         (let ((crstr
                (cond ((derived-mode-p 'json-mode) (concat "-ft json " (pen-q (str (buffer-file-name)))))
                      ((derived-mode-p 'csv-mode) (concat "-ft csv " (pen-q (str (buffer-file-name)))))
                      (t (pen-q (str (buffer-file-name))))
                      )
                ))
           (if (not (buffer-file-name))
               (pen-term-nsfa (concat "pen-cr " crstr ) (awk1 (buffer-string)))
             (pen-term-nsfa (concat "pen-cr " crstr )))))))

;; (defun compile-run-term ()
;;   "This is used to compile and run a source file inside term."
;;   (interactive)
;;   (cond ((bound-and-true-p go-playground-mode) (call-interactively 'go-playground-exec))
;;         ;; Unfortunately, cant use ~tm sps~ because the command can't find the LINES and COLUMNS, even with eval resize
;;         ;; sps works now
;;         (t (pen-term-nsfa (concat "pen-cr " (pen-q (str (buffer-file-name))) "; pen-pak")))))

(defun compile-run-tm-ecompile ()
  "This is used to compile and run a source file."
  (interactive)
  (cond ((bound-and-true-p go-playground-mode) (call-interactively 'go-playground-exec))
        ;; Unfortunately, cant use ~tm sps~ because the command can't find the LINES and COLUMNS, even with eval resize
        ;; sps works now
        (t (pen-snc (concat "unbuffer pen-tm -f -te -d sps -x -pak -args compile pen-cr " (pen-q (str (buffer-file-name))))))))

(defun compile-run-compile ()
  "This is used to compile and run a source file inside term."
  (interactive)
  (cond ((bound-and-true-p go-playground-mode) (call-interactively 'go-playground-exec))
        ;; Unfortunately, cant use ~tm sps~ because the command can't find the LINES and COLUMNS, even with eval resize
        ;; sps works now
        (t (compile (concat "pen-cr " (pen-q (str (buffer-file-name))) " | cat")))))

(defun schema-run ()
  "This is used to get the paths through file."
  (interactive)
  (cond ((bound-and-true-p go-playground-mode) (call-interactively 'go-playground-exec))
        ;; Unfortunately, cant use ~tm sps~ because the command can't find the LINES and COLUMNS, even with eval resize
        ;; sps works now
        (t (pen-snc (concat "unbuffer pen-tm -f -te -d sps -x -args zh " (pen-q (str (buffer-file-name))))))))

(provide 'pen-compile-run)
