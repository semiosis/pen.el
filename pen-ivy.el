;; This is for multiline selection of candidates
;; I need a dynamic collection for openai completion results

;; j:counsel-ag-function

(defun my-counsel--format-command (cmd extra-args needle)
  "Construct a complete `counsel-ag-command' as a string.
EXTRA-ARGS is a string of the additional arguments.
NEEDLE is the search string."
  (counsel--format cmd
                   (if (listp cmd)
                       (if (string-match " \\(--\\) " extra-args)
                           (counsel--format
                            (split-string (replace-match "%s" t t extra-args 1))
                            needle)
                         (nconc (split-string extra-args) needle))
                     (if (string-match " \\(--\\) " extra-args)
                         (replace-match needle t t extra-args 1)
                       (concat extra-args " " needle)))))

;; The cmd takes a single string which is the search
;; In this case, it may be the first argument to a gpt3 prompt function
(defmacro gen-counsel-generator-function (cmd)
  ""
  (let ((funsym (str2sym (concat "counsel-generator-function-" (slugify cmd))))
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
            (counsel--async-command (concat
                                     (my-counsel--format-command ,cmdstr
                                                                 switches
                                                                 (funcall (if (listp ,cmdstr) #'identity
                                                                            #'shell-quote-argument)
                                                                          string))
                                     " | cat"))
            nil))))))

;; (never
;;  (ivy-read "testing:"
;;            (counsel-fz-function-openai-complete-very-witty-pick-up-lines-prompt "tea")
;;            ;; :initial-input initial-input
;;            :dynamic-collection t
;;            :keymap counsel-ag-map
;;            ;; :history histvar
;;            :action 'etv
;;            :require-match t
;;            ;; :caller (or caller 'counsel-ag)
;;            ))

(defmacro gen-counsel-function (cmd action)
  ""
  (let ((funsym (str2sym (concat "counsel-generated-" (slugify cmd))))
        (histvarsym (str2sym (concat "counsel-generated-" (slugify cmd) "-histvar")))
        (cmdstr (concat cmd " %s")))
    (eval `(defvar ,histvarsym nil))
    `(cl-defun ,funsym (&optional initial-input initial-directory extra-ag-args ag-prompt
                                  &key caller &key histvar)
       "Run an arbitrary external shell command in the current directory. Select from the results.

INITIAL-INPUT can be given as the initial minibuffer input.
INITIAL-DIRECTORY, if non-nil, is used as the root directory for search.
EXTRA-AG-ARGS, if non-nil, is appended to `counsel-ag-base-command'.
AG-PROMPT, if non-nil, is passed as `ivy-read' prompt argument.
CALLER is passed to `ivy-read'.

With a `\\[universal-argument]' prefix argument, prompt for INITIAL-DIRECTORY.
With a `\\[universal-argument] \\[universal-argument]' prefix argument, \
prompt additionally for EXTRA-AG-ARGS."
       (interactive)

       (if (not histvar)
           (setq histvar ',histvarsym))

       (setq counsel--regex-look-around nil)

       (let ((default-directory (or initial-directory
                                    (counsel--git-root)
                                    default-directory)))
         (ivy-read (concat ,cmd ": ")
                   ;; ,(macro-expand `(gen-counsel-generator-function ,,cmd))
                   (gen-counsel-generator-function ,cmd)
                   :initial-input initial-input
                   :dynamic-collection t
                   :keymap counsel-ag-map
                   :history histvar
                   :action ,action
                   :require-match t
                   :caller (or caller ',funsym))))))

;; (gen-counsel-generator-function "counsel-ag-cmd")
;; (gen-counsel-function "counsel-ag-cmd" 'etv)

(gen-counsel-generator-function "openai-complete pick-up-line.prompt")
(gen-counsel-generator-function "openai-complete pick-up-line.prompt")
(gen-counsel-function "loop openai-complete pick-up-line.prompt" 'etv)


(provide 'pen-ivy)