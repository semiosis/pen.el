;; e:/root/notes/ws/emacs/com/notes.org

;; (defmacro defcomcmd (&rest body)
;;   ""
;;   `(progn ,@body))

;; Make a getopt elisp function?
;; e:/usr/share/doc/util-linux/examples/getopt-parse.bash

(defun getopt (&rest args)
  (let ((output
         (str2lines (snc (concat
                          (apply 'cmd (append (list "getopt") args))
                          " | xargs pl")))))
    (if (not (string-equal b_exit_code "0"))
        (error "getopt failed")
      output)))

;; getopts.sh "h:vs:z:" -h yo -v -s hi -z yo
(defun getopts (optstring &rest args)
  (let ((output
         (-partition-in-steps 2 2 (str2lines (s-remove-trailing-newline (sn (apply 'cmd (append (list "getopts.sh" optstring) args))))))))
    (if (not (string-equal b_exit_code "0"))
        (error "getopts failed")
      output)))

(comment
 (getopts "a:b:c" "-a" "A")
 (getopts "a:b:c" "-a" "A" "-c" "-b" "B")
 (getopts "a:b:c" "-a" "A" "-c" )
 (getopt "-o" "ab:c::" "--long" "a-long,b-long:,c-long::" "-n" "example.bash" "--" "-b" "yo ")
 (ignore-errors (getopt "-o" "ab:c::" "--long" "a-long,b-long:,c-long::" "-n" "example.bash" "--" "-z" "yo ")))

(defun com/run (filter-script &rest args)
  (let ((filter-script-sym (str2sym (concat "com/" filter-script))))
    (if (functionp filter-script-sym)
        (apply filter-script-sym args)
      (snc filter-script args))))

(defun com/apply-pipe (filter-script &rest args)
  (let ((filter-script-sym
         (and (stringp filter-script)
              (str2sym (concat "filter/" filter-script))))
        (input (apply 'com/run args)))
    (cond
     ;; ((listp filter-script)
     ;;  (let ((com-filter-sym (str2sym (concat "com/" (str (car filter-script))))))
     ;;    ;; (macrop com-filter-sym)
     ;;    (eval `(append ,filter-script ,(list input)))))
     ((functionp filter-script-sym)
      (apply filter-script-sym (list input)))
     (t (snc filter-script input)))))

(comment
 ;; Think more about how I'd use mac/join
 ;; (com/run "apply-pipe" '(join -d "-" -d "=") "apply-pipe" "q" "apply-pipe" "split-space" "current-line-string")
 (com/apply-pipe "q" "current-line-string")
 (com/apply-pipe "split-space" "current-line-string")
 (filter/split-space (com/current-line-string))
 (com/run "join" :d "-" "split" :d " " "current-line-string")
 (pipeline-rl replace-line join :d "-" split :d " " current-line-string))

(defun com/current-line-string (&rest args)
  (current-line-string))

;; split-space is 
(defun filter/split-space (input)
  (s-join "\n" (s-split " " input)))

(defun filter/join-dash (input)
  (s-join "-" (str2lines input)))

(defun filter/q (input)
  (e/q input))

(comment
 (defmacro mac/join (&rest args)
   (let ((results (getopts "d:" args)))
     results)))

(comment
 ;; I don't think this has to be a macro
 (defmacro mac/join (&rest args)
   (let ((input (-last-item args))
         (args (-drop-last 1 args)))
     (setq args (append (list "d:") (mapcar 'str args)))
     (let* ((results ;; (apply 'getopts `,@args)
             (eval `(funcall 'getopts ,@args)))
            (results (mapcar (lambda (e)
                               (list (str2sym (car e))
                                     (cadr e)))
                             results)))

       `(let* ,(append '((d ","))
                       `,results)
          (s-join d (s-split "\n" ,input)))))))

;; I might not even need parentheses
;; pipeline-rl replace-line join :d "-" split :d " " current-line-string
;; It shouldn't be that merely the last item is the input.
;; But rather, the arguments not used by getopts are the input command.
(defun com/join (&rest args)
  (let ((input (-last-item args))
        (args (-drop-last 1 args)))
    (setq args (append (list "d:") (mapcar
                                    (lambda (e)
                                      (if (keywordp e)
                                          (s-replace ":" "-" (str e))
                                        (str e)))
                                    args)))
    (let* ((results ;; (apply 'getopts `,@args)
            (eval `(funcall 'getopts ,@args)))
           (results (mapcar (lambda (e)
                              (list (str2sym (car e))
                                    (cadr e)))
                            results)))

      (eval
       `(let* ,(append '((d ","))
                       `,results)
          (s-join d (s-split "\n" ,input)))))))

(comment
 (com/join :d "-" :d "=" "input\nyo"))

;; (apply 'getopts '("a:b:c" "-a" "A"))

(comment
 (apply 'getopts '("a:b:c" "-a" "A"))
 (getopts "a:b:c" "-a" "A")
 (getopts "a:b:c" "-a" "A"))

(provide 'pen-com)
