;; This is for multiline selection of candidates
;; I need a dynamic collection for openai completion results

;; j:counsel-ag-function

;; The cmd takes a single string which is the search
;; In this case, it may be the first argument to a gpt3 prompt function
(defmacro gen-counsel-generator-function (cmd)
  ""
  (let ((funsym (str2sym (concat "counsel-fz-function-" (slugify cmd))))
        (cmdstr (concat cmd " %s")))
    `(defun ,funsym (string)
       ,(concat "Run " cmd " in the current directory with STRING argument. Do this to generate candidates for ivy.")
       (let* ((command-args (counsel--split-command-args string))
              (search-term (cdr command-args)))
         (or
          (let ((ivy-text search-term))
            (ivy-more-chars))
          (let* ((default-directory (ivy-state-directory ivy-last))
                 (switches (concat (car command-args))))
            (counsel--async-command (counsel--format-ag-command
                                     switches
                                     (funcall (if (listp ,cmdstr) #'identity
                                                #'shell-quote-argument)
                                              string)))
            nil))))))

(never
 (ivy-read "testing:"
           (counsel-fz-function-openai-complete-very-witty-pick-up-lines-prompt "tea")
           ;; :initial-input initial-input
           :dynamic-collection t
           :keymap counsel-ag-map
           ;; :history histvar
           :action 'etv
           :require-match t
           ;; :caller (or caller 'counsel-ag)
           ))


(defun counsel-ag-function (string)
  "Grep in the current directory for STRING."
  (let* ((command-args (counsel--split-command-args string))
         (search-term (cdr command-args)))
    (or
     (let ((ivy-text search-term))
       (ivy-more-chars))
     (let* ((default-directory (ivy-state-directory ivy-last))
            ;; (regex (counsel--grep-regex search-term))
            (switches (concat (car command-args)
                              ;; (counsel--ag-extra-switches regex)

                              ;; Don't add extra arguments or generic programs other than ag will have problems

                              ;; (if (ivy--case-fold-p string)
                              ;;     " -i "
                              ;;   " -s ")
                              )))
       (counsel--async-command (counsel--format-ag-command
                                switches
                                (funcall (if (listp counsel-ag-command) #'identity
                                           #'shell-quote-argument)
                                         ;; regex
                                         string
                                         )))
       nil))))



(provide 'pen-ivy)