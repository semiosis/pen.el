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

(provide 'pen-ivy)