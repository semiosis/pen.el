;; gy -E "openai api engines.generate -h | pavs"

(defvar pen.el-map (make-sparse-keymap)
  "Keymap for `pen.el'.")
;; (makunbound 'pen.el)
(defvar-local pen.el nil)

(define-minor-mode pen.el
  "Mode for working with language models in your  buffers."
  :global t
  :init-value t
  :lighter " pen"
  :keymap pen.el-map)

;; (define-globalized-mode global-pen.el pen.el pen.el)

;; TODO Make a shell script for querying the OpenAI API
;; $SCRIPTS/openai-curl

;; TODO pen-generate
;; This function streams text onto the end of the currently selected region accordig to the current prompt settings


;; (defun pen-generate ()
;;   "This function streams text onto the end of the currently selected region accordig to the current prompt settings"
;;   (interactive)
;;   (if (region-active-p)
;;       (let ((r (selected)))
;;         ;; Send request and replace the text
;;         )))


;; (define-key pen.el-map (kbd "<up>") 'pen-generate)
;; (define-key pen.el-map (kbd "<down>") (lm (tsk "C-n")))
;; (define-key pen.el-map (kbd "<right>") (lm (tsk "M-3")))

(pen.el 1)

;; TODO Create a transient mode for quickly setting prompt settings

;; (define-transient-command prompt-engineer-configure ()
;;   "Transient for configuring the current openai prompt fuction."
;;   :man-page "docker-image-pull"
;;   ["Arguments"
;;    ("-a" "All" "-a")]
;;   [:description docker-utils-generic-actions-heading
;;    ("F" "Pull selection" docker-utils-generic-action)
;;    ("T" "Pull specific tag (sps)" my-docker-pull-specific-tag)
;;    ("N" "Pull a new image" dockerage-pull-one)])

;; This key will be set upon setting pen-openai-key-location
(defcustom pen-openai-key ""
  "OpenAI API key"
  :type 'string
  :group 'prompt-engineer
  :initialize #'custom-initialize-default)

;; This location will be set upon setting pen-openai-key
(defcustom pen-openai-key-location ""
  "OpenAI API key"
  :type 'string
  :group 'prompt-engineer
  :initialize #'custom-initialize-default)

(defcustom pen-prompt-directory ""
  "Directory where .prompt files are located"
  :type 'string
  :group 'prompt-engineer
  :initialize #'custom-initialize-default)

(defvar-local pen-engine nil)

(defvar-local pen-frequency-penalty nil
  "If your completion is filled with lots of\nrepetition you can increase this setting\nto prevent that from happening.\n\nHow much to penalize new tokens based on\ntheir existing frequency in the text so\nfar.\n\nDecreases the model's likelihood to repeat\nthe same line verbatim (the same text).\n\nThe likelihood of the same/similar lines\nbeing repeated in a completion.\n\nSet it high to avoid repetition.\n\nHowever, it could make sense to lower this\nvalue if writing lyrics for a song's\nchorus.")

(defvar-local pen-presence-penalty nil)

(defvar-local pen-best-of nil)

(defvar-local pen-stop-sequences nil)

(defvar-local pen-inject-start-text nil)

(defvar-local pen-inject-restart-text nil)

(defvar-local pen-show-probabilities nil)

(setq pen-prompt-directory "/home/shane/source/git/semiosis/prompts/prompts")

;; + States
;;   - Off
;;   - Most likely
;;   - Least likely
;;   - Full spectrum





(never
 (defset my-prompt-test (yamlmod-read-file (car (glob "$MYGIT/mullikine/pen.el/prompts/*"))))
 (ht-get my-prompt-test "title")
 (cl-loop for v in (vector2list (ht-get my-prompt-test "vars")) collect `(read-string-hist ,(concat v ": ")))
 (mapcar 'slugify (ht-get my-prompt-test "vars"))

 (describe-hash 'my-prompt-test))

(defun pen-interactively-generate-prompt ()
  "A wizard for quickly building a prompt"
  ;; $MYGIT/mullikine/pen.el/prompts/obfuscate-language.prompt
  (interactive)
  (let* ((meta (read-string "Meta description (The human asks the AI to etc.)\":")))))

(defalias 'cll 'cl-loop)


(defset pen-prompt-functions nil)
;; Metadata about prompt functions -- save the hash table here 
(defset pen-prompt-functions-meta nil)


(defun yaml-test (yaml key)
  (if (and yaml
           (sor key))
      (let ((c (ht-get yaml key)))
        (and (sor c)
             (string-equal c "on")))))


;; Bools return a string
;; (ht-get (yamlmod-read-file "/home/shane/var/smulliga/source/git/semiosis/prompts/prompts/subtopic-generation.prompt") "cache")

(transient-define-argument magit:--gpg-sign ()
  :description "Sign using gpg"
  :class 'transient-option
  :shortarg "-S"
  :argument "--gpg-sign="
  :allow-empty t
  :reader 'magit-read-gpg-signing-key)

(transient-define-argument magit:--author ()
  :description "Limit to author"
  :class 'transient-option
  :key "-A"
  :argument "--author="
  :reader 'magit-transient-read-person)

(defun magit-commit-reshelve (date update-author &optional args)
  "Change the committer date and possibly the author date of `HEAD'.

The current time is used as the initial minibuffer input and the
original author or committer date is available as the previous
history element.

Both the author and the committer dates are changes, unless one
of the following is true, in which case only the committer date
is updated:
- You are not the author of the commit that is being reshelved.
- The command was invoked with a prefix argument.
- Non-interactively if UPDATE-AUTHOR is nil."
  (interactive
   (let ((update-author (and (magit-rev-author-p "HEAD")
                             (not current-prefix-arg))))
     (push (magit-rev-format (if update-author "%ad" "%cd") "HEAD"
                             (concat "--date=format:%F %T %z"))
           magit--reshelve-history)
     (list (read-string (if update-author
                            "Change author and committer dates to: "
                          "Change committer date to: ")
                        (cons (format-time-string "%F %T %z") 17)
                        'magit--reshelve-history)
           update-author
           (magit-commit-arguments))))
  (let ((process-environment process-environment))
    (push (concat "GIT_COMMITTER_DATE=" date) process-environment)
    (magit-run-git "commit" "--amend" "--no-edit"
                   (and update-author (concat "--date=" date))
                   args)))


;; Here are some infix commands which let you specify values
(transient-define-argument magit-log:-n ()
  :description "Limit number of commits"
  :class 'transient-option
  ;; For historic reasons (and because it easy to guess what "-n"
  ;; stands for) this is the only argument where we do not use the
  ;; long argument ("--max-count").
  :shortarg "-n"
  :argument "-n"
  :reader 'transient-read-number-N+)

(transient-define-argument magit:--author ()
  :description "Limit to author"
  :class 'transient-option
  :key "-A"
  :argument "--author="
  :reader 'magit-transient-read-person)

(defun pen-edit-function-prompt ()
  (interactive))


;; prefix with - to invert i.e. -inurl:
(defset prompt-function-params
  (list
   "repo"
   "extension"
   "path"
   "filename"
   "followers"
   "language"
   "license"))

(defun prompt-function-transient-search (&optional args)
  (interactive
   (list (transient-args 'prompt-function)))
  (etv args))

(create-my-transient "prompt-function" prompt-function-params 'prompt-function-transient-search '-search-with-keywords)


;; Base on create-my-transient
(defun transient-configurator (name kvps searchfun kwsearchfun &optional keywordonly)
  (let ((sym (str2sym (concat name "-transient")))
        (args
         (vconcat (list "Arguments")
                  (append
                   ;; (let ((c 0))
                   ;;   (cl-loop for p in google-key-value-predicates do (setq c (1+ c))
                   ;;            collect
                   ;;            (list ;; (concat "-" (str c))
                   ;;             (str c) p (concat "--" p "="))
                   ;;            collect
                   ;;            (list ;; (concat "-" (str c))
                   ;;             (concat "-" (str c)) (concat "not" p) (concat "--not-" p "=")))
                   ;;   (concat "-" (str c)))
                   (let ((c 0))
                     (cl-loop for p in kvps do (setq c (1+ c)) collect (list (str c) p (concat "--" p "="))))
                   (let ((c 0))
                     (cl-loop for p in kvps do (setq c (1+ c)) collect (list (concat "-" (str c)) (concat "not" p) (concat "--not-" p "="))))
                   ;; (list (list "k" "keywords" "--keywords="))
                   )))
        (actions
         (vconcat
          (if keywordonly
              (list "Actions"
                    (list "k" "Search with keywords" kwsearchfun))
            (list "Actions"
                  (list "s" "Search" searchfun)
                  (list "k" "Search with keywords" kwsearchfun))))))
    (eval `(define-transient-command ,sym ()
             ,(concat (s-capitalize name) " transient")
             ,args
             ,actions))))


;; Make it automatic and only work with strings.

;; It is a macro which I place inside a
;; function as a call and expands into code.
;; That code checks to see if transient
;; variables fro this function are defined and if
;; so it applies/sets the names in the current
;; scope to those values.
;; It can't just be a call because the called function must exist.
;; That is, unless I create an error. Don't do that.
;; It's too complicated. I can't build this right now.
;; Manually make it first.
;; Abandon this for the moment. It's too complex. 


;; (defun test-configurable-function ()
;;   (interactive)

;;   (transient-let
;;    ;; Call test-configurable-function
;;    'test-configurable-function
;;    ))

(defun configure-prompt-function-show-arguments ()
  (interactive)
  (etv (pps (transient-args 'configure-prompt-function))))


;; I've already streamlined tranient quite a lot.
;; I should just use this.
;; j:create-my-transient


;; This should let me reconfigure the parameters of a prompt function.
;; This should be persistent.
;; Therefore, a prompt function should have some persistent state.
;; Used my serialised hash tables for persistent state.
;; Make this appear when I run a prompt function after pressing H-u
(define-transient-command configure-prompt-function ()
  "Configure the parameters of a prompt function."
  ;; :info-manual "(magit)Initiating a Commit"
  ;; :man-page "git-commit"
  ["Arguments"
   ("-l" "n-collate"   ("-a" "--all"))
   ("-h" "cache"                     "--cache")
   ("-v" "Show diff of changes to be committed"   ("-v" "--verbose"))
   ("-n" "Disable hooks"                          ("-n" "--no-verify"))
   ("-R" "Claim authorship and reset author date" "--reset-author")
   ;; (magit:--author :description "Override the author")
   ;; (7 "-D" "Override the author date" "--date=" transient-read-date)
   ("-s" "Add Signed-off-by line"                 ("-s" "--signoff"))

   ;; What is the leading number for? - It may be the prefix
   ;; (5 magit:--gpg-sign)
   ;; (magit-commit:--reuse-message)
   ]
  [["Run"
    ;; ("r" "Run"         pen-transient-run)
    ("r" "Run"         a/beep)
    ("s" "Show arguments" configure-prompt-function-show-arguments)]
   ["Edit"
    ("e" "edit prompt"         pen-edit-function-prompt)
    ;; (6 "n" "Reshelve"     magit-commit-reshelve)
    ]
   ;; [""
   ;;  ("F" "Instant fixup"  magit-commit-instant-fixup)
   ;;  ("S" "Instant squash" magit-commit-instant-squash)]
   ]

  ;; If I specify the body (below), then I
  ;; need to call transient-setup with the name
  ;; of this transient.
  ;; If I do not specify the body below, then
  ;; the transient can be called but non-
  ;; interactively only.
  (interactive)
  (transient-setup 'configure-prompt-function)

  ;; Conditional logic may be placed here

  ;; (if-let ((buffer (magit-commit-message-buffer)))
  ;;     (switch-to-buffer buffer)
  ;;   ;; this must be the name of the define-transient-command I am defining
  ;;   (transient-setup 'configure-prompt-function))
  )


;; (define-transient-command magit-commit ()
;;   "Create a new commit or replace an existing commit."
;;   :info-manual "(magit)Initiating a Commit"
;;   :man-page "git-commit"
;;   ["Arguments"
;;    ("-a" "Stage all modified and deleted files"   ("-a" "--all"))
;;    ("-e" "Allow empty commit"                     "--allow-empty")
;;    ("-v" "Show diff of changes to be committed"   ("-v" "--verbose"))
;;    ("-n" "Disable hooks"                          ("-n" "--no-verify"))
;;    ("-R" "Claim authorship and reset author date" "--reset-author")
;;    (magit:--author :description "Override the author")
;;    (7 "-D" "Override the author date" "--date=" transient-read-date)
;;    ("-s" "Add Signed-off-by line"                 ("-s" "--signoff"))
;;    (5 magit:--gpg-sign)
;;    (magit-commit:--reuse-message)]
;;   [["Create"
;;     ("c" "Commit"         magit-commit-create)
;;     ("i" "Instant commit" magit-commit-instant)
;;     ("t" "Instant add commit" magit-commit-instant)]
;;    ["Edit HEAD"
;;     ("e" "Extend"         magit-commit-extend)
;;     ("w" "Reword"         magit-commit-reword)
;;     ("a" "Amend"          magit-commit-amend)
;;     (6 "n" "Reshelve"     magit-commit-reshelve)]
;;    ["Edit"
;;     ("f" "Fixup"          magit-commit-fixup)
;;     ("s" "Squash"         magit-commit-squash)
;;     ("A" "Augment"        magit-commit-augment)
;;     (6 "x" "Absorb changes" magit-commit-absorb)]
;;    [""
;;     ("F" "Instant fixup"  magit-commit-instant-fixup)
;;     ("S" "Instant squash" magit-commit-instant-squash)]]

;;   ;; If I specify the body (below), then I
;;   ;; need to call transient-setup with the name
;;   ;; of this transient
;;   (interactive)
;;   (if-let ((buffer (magit-commit-message-buffer)))
;;       (switch-to-buffer buffer)
;;     (transient-setup 'magit-commit)))


;; Put it inside a function, like an interactive.
;; It should only run when the function has been called interactively.
;; It would be extremely tricky to get transient to work synchronously.
;; So I can't do that.

;; (pen-pf-define-word-for-glossary "glum" :prettify t)
(defun pen-generate-prompt-functions ()
  "Generate prompt functions for the files in the prompts directory
Function names are prefixed with pen-pf- for easy searching"
  (interactive)
  (noupd
   (let ((paths
          (-non-nil (mapcar 'sor (glob (concat pen-prompt-directory "/*.prompt"))))))
     (cl-loop for path in paths do
              (message (concat "pen-mode: Loading .prompt file " path))

              ;; results in a hash table
              (let* ((yaml (yamlmod-read-file path))
                     (title (ht-get yaml "title"))
                     (title-slug (slugify title))
                     (doc (ht-get yaml "doc"))
                     (cache (yaml-test yaml "cache"))
                     (needs-work (yaml-test yaml "needs-work"))
                     (disabled (yaml-test yaml "disabled"))
                     (prefer-external (yaml-test yaml "prefer-external"))
                     (filter (yaml-test yaml "filter"))
                     ;; Don't actually use this. But I can toggle to use the prettifier with a bool
                     (prettifier (ht-get yaml "prettifier"))
                     (completion (yaml-test yaml "completion"))
                     (n-collate (ht-get yaml "n-collate"))
                     (vars (vector2list (ht-get yaml "vars")))
                     (aliases (vector2list (ht-get yaml "aliases")))
                     (alias-slugs (mapcar 'str2sym (mapcar (lambda (s) (concat "pen-pf-" s)) (mapcar 'slugify aliases))))
                     (examples (vector2list (ht-get yaml "examples")))
                     (preprocessors (vector2list (ht-get yaml "pen-preprocessors")))
                     (var-slugs (mapcar 'slugify vars))
                     ;; (var-syms (append
                     ;;            (mapcar 'str2sym var-slugs)
                     ;;            '(:key ci-update)))
                     (var-syms
                      (let ((ss (mapcar 'str2sym var-slugs)))
                        (message (concat "_" prettifier))
                        (if (sor prettifier)
                            (setq ss (append ss '(&key prettify))))
                        ;; (setq ss (append ss '(:key prettify)))
                        ss))
                     (pen-defaults (vector2list (ht-get yaml "pen-defaults")))
                     (completion (yaml-test yaml "completion"))
                     (func-name (concat "pen-pf-" title-slug))
                     (func-sym (str2sym func-name))
                     (iargs (let ((iteration 0))
                              (cl-loop for v in vars
                                       collect
                                       (let ((example (or (sor (nth iteration examples)
                                                               "")
                                                          "")))
                                         (message "%s" (concat "Example " (str iteration) ": " example))
                                         (if (equal 0 iteration)
                                             ;; The first argument may be captured through selection
                                             `(if (selectionp)
                                                  (my/selected-text)
                                                (if ,(> (length (str2lines example)) 1)
                                                    (tvipe ;; ,(concat v ": ")
                                                     ,example)
                                                  (read-string-hist ,(concat v ": ") ,example)))
                                           `(if ,(> (length (str2lines example)) 1)
                                                (tvipe ;; ,(concat v ": ")
                                                 ,example)
                                              (read-string-hist ,(concat v ": ") ,example))))
                                       do
                                       (progn
                                         (setq iteration (+ 1 iteration))
                                         (message (str iteration)))))))

                (setq n-collate (or n-collate 1))

                (add-to-list 'pen-prompt-functions-meta yaml)

                ;; var names will have to be slugged, too

                (if alias-slugs
                    (cl-loop for a in alias-slugs do
                             (progn
                               (defalias a func-sym)
                               (add-to-list 'pen-prompt-functions a))))

                (if (not needs-work)
                    (add-to-list 'pen-prompt-functions
                                 ;; These are getting added to a list
                                 (eval
                                  `(cl-defun ,func-sym ,var-syms
                                     ,(sor doc title)
                                     (interactive ,(cons 'list iargs))
                                     (let* ((sh-update
                                             (or sh-update (>= (prefix-numeric-value current-global-prefix-arg) 4)))
                                            (shcmd (concat
                                                    ,(if (sor prettifier)
                                                         '(if prettify
                                                              "PRETTY_PRINT=y "
                                                            ""))
                                                    ,(flatten-once
                                                      (list
                                                       (list 'concat
                                                             (if cache
                                                                 "oci "
                                                               "")
                                                             "openai-complete "
                                                             (q path))
                                                       (flatten-once
                                                        (cl-loop for vs in var-slugs collect
                                                                 (list " "
                                                                       (list 'q (str2sym vs)))))))))
                                            (result
                                             (chomp
                                              (mapconcat 'identity
                                                         (cl-loop for i in (number-sequence ,n-collate)
                                                                  collect
                                                                  (progn
                                                                    ;; (ns (concat "update? " (str sh-update)))
                                                                    (message (concat ,func-name " query " (int-to-string i)))
                                                                    (sn shcmd)
                                                                    (message (concat ,func-name " done " (int-to-string i)))))
                                                         ""))))
                                       (if (interactive-p)
                                           (cond
                                            ((and ,filter
                                                  (selectedp))
                                             (replace-region (concat (selection) result)))
                                            (,completion
                                             (etv result))
                                            ((or ,(not filter)
                                                 (>= (prefix-numeric-value current-prefix-arg) 4)
                                                 (not (selectedp)))
                                             (etv result))
                                            (t
                                             (replace-region result)))
                                         result))))))
                (message (concat "pen-mode: Loaded prompt function " func-name)))))))
(pen-generate-prompt-functions)


(define-derived-mode prompt-description-mode yaml-mode "Prompt"
  "Prompt description mode")


;; (define-key global-map (kbd "H-TAB") nil)
(define-key global-map (kbd "H-TAB g") 'pen-generate-prompt-functions)



(defun pen-filter-with-prompt-function ()
  (interactive)
  (let ((f (fz pen-prompt-functions nil nil "pen filter: ")))
    (if f
        (filter-selected-region-through-function (str2sym f)))))
(define-key global-map (kbd "H-TAB s") 'pen-filter-with-prompt-function)

(defun pen-run-prompt-function ()
  (interactive)
  (let* ((sh-update (or sh-update (>= (prefix-numeric-value current-global-prefix-arg) 4)))
         (f (fz pen-prompt-functions nil nil "pen run: ")))
    ;; (ns (concat "sh-update: " (str sh-update)))
    (if f
        (call-interactively (str2sym f)))))
(defalias 'camille-complete 'pen-run-prompt-function)
(define-key global-map (kbd "H-TAB r") 'pen-run-prompt-function)

;; Camille-complete (because I press SPC to replace
(define-key selected-keymap (kbd "SPC") 'pen-run-prompt-function)
(define-key selected-keymap (kbd "M-SPC") 'pen-run-prompt-function)

;; TODO Make a function for permuting the tuples of monotonically increasing length all starting with the first element

;; TODO Generate a list of completion symbols
;; This should be a permutation of n-nmax tokens of a single response from openai
;; TODO In future, suggest alternative completions from openai
;; Make this into 2 functions


(defun company-pen-filetype--candidates (prefix)
  (let* ((preceding-text (pen-preceding-text))
         ;; (trailing_ws_pat "[ \t\n]*\\'")
         ;; (original_whitespace (regex-match-string trailing_ws_pat preceding-text))
         ;; (endspace)
         ;; (preceding-text-endspaceremoved)
         (response
          (->>
           preceding-text
           (pen-pf-generic-file-type-completion (detect-language))))
         ;; Take only the first line for starters
         ;; Do not only take the first line. That's kinda useless.
         ;; (line (car (str2lines response)))
         ;; (line response)
         (res
          ;; (cl-loop
          ;;  for i from 1 to 3 collect
          ;;  (->>
          ;;   preceding-text
          ;;   (pen-pf-generic-file-type-completion (detect-language))))
          (list response)
          ;; j:monotonically-increasing-tuple-permutations
          ;; (if (>= (prefix-numeric-value current-prefix-arg) 8)
          ;;     (list response)
          ;;   ;; Just generate a few
          ;;   ;; (pen-pf-generic-file-type-completion (detect-language) preceding-text)
          ;;   ;; (pen-pf-generic-file-type-completion (detect-language) preceding-text))
          ;;   (str2lines (snc "monotonically-increasing-tuple-permutations.py" (car (str2lines response)))))
          ))
    ;; Generate a list
    ;; (setq res '("testing" "testing123"))
    (mapcar (lambda (s) (concat (company-pen-filetype--prefix) s))
            res)))




;; TODO Generate arbitrarily many company completion functions 

;; Go over all the pen functions and automatically create completion functions
;; From the ones that have "completion: on"

(defvar my-completion-engine 'company-pen-filetype)

;; (defvar my-completion-engines `(company-pen-filetype
;;                                 completion-at-point
;;                                 ,(defcompletion-engine
;;                                    'pen-pf-tldr-summarization)))

(never
 (ht-keys (car pen-prompt-functions-meta))
 (ht-get (car pen-prompt-functions-meta) "title")


 (cl-loop for pf-ht in pen-prompt-functions-meta do
          (message (ht-get pf-ht "title")))

 (cl-loop for pf-ht in pen-prompt-functions-meta do
          (if ;; (string-equal "Generic file type completion" (ht-get pf-ht "title"))
              (yaml-test pf-ht "completion" )
              (message (ht-get pf-ht "title"))
            ;; (message (ht-get pf-ht "title"))
            )))

(require 'company)
(defun my-completion-at-point ()
  (interactive)
  (call-interactively 'completion-at-point)
  (if (>= (prefix-numeric-value current-prefix-arg) 4)
      (call-interactively 'company-pen-filetype)
    (call-interactively 'completion-at-point)))

;; (define-key global-map (kbd "M-1") #'my-completion-at-point)
(define-key global-map (kbd "M-1") #'company-pen-filetype)


(defun pen-complete-long (preceding-text &optional tv)
  (interactive (list (str (buffer-substring (point) (max 1 (- (point) 1000))))
                     t))
  (let* ((response (pen-pf-generic-file-type-completion (detect-language) preceding-text)))
    (if tv
        (tv response)
      response)))


;; This should have many options and return a list of completions
;; It should be used in company-mode
;; j_company-pen-filetype
(defun pen-company-complete-generate (preceding-text))


(defun pen-completions-line (preceding-text &optional tv)
  (interactive (list (pen-preceding-text-line)
                     t))
  (let* ((response (pen-pf-generic-file-type-completion (detect-language) preceding-text)))
    (if tv
        (tv response)
      response)))

(define-key global-map (kbd "H-P") 'pen-complete-long)

(my-load "$MYGIT/semiosis/pen.el/pen-core.el")
(require 'pen-core)

(my-load "$MYGIT/semiosis/pen.el/pen-ivy.el")
(require 'pen-ivy)

(my-load "$MYGIT/semiosis/pen.el/pen-company.el")
(require 'pen-company)

(my-load "$MYGIT/semiosis/pen.el/pen-library.el")
(require 'pen-library)

(load (concat emacsdir "/config/examplary.el"))
(require 'examplary)

(my-load "$MYGIT/semiosis/pen.el/imaginary.el")
(require 'imaginary)

(my-load "$MYGIT/semiosis/pen.el/pen-contrib.el")
(require 'pen-contrib)

(define-key org-brain-visualize-mode-map (kbd "C-c a") 'org-brain-asktutor)
(define-key org-brain-visualize-mode-map (kbd "C-c t") 'org-brain-show-topic)
(define-key org-brain-visualize-mode-map (kbd "C-c d") 'org-brain-describe-topic)

(provide 'my-openai)
(provide 'pen)