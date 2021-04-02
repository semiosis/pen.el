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
                     (vars (vector2list (ht-get yaml "vars")))
                     (aliases (vector2list (ht-get yaml "aliases")))
                     (alias-slugs (mapcar 'str2sym (mapcar 'slugify aliases)))
                     (examples (vector2list (ht-get yaml "examples")))
                     (preprocessors (vector2list (ht-get yaml "pen-preprocessors")))
                     (var-slugs (mapcar 'slugify vars))
                     ;; (var-syms (append
                     ;;            (mapcar 'str2sym var-slugs)
                     ;;            '(:key ci-update)))
                     (var-syms (mapcar 'str2sym var-slugs))
                     (pen-defaults (vector2list (ht-get yaml "pen-defaults")))
                     (completion (yaml-test yaml "completion"))
                     (func-name (concat "pen-pf-" title-slug))
                     (func-sym (str2sym func-name))
                     (iargs (let ((iteration 0))
                              (cl-loop for v in vars
                                       collect
                                       (let ((example (nth iteration examples)))
                                         (message (concat (str iteration) ": " example))
                                         (if (equal 0 iteration)
                                             ;; The first argument may be captured through selection
                                             `(if (selectionp)
                                                  (my/selected-text)
                                                (progn
                                                  (if ,(> (length (str2lines example)) 1)
                                                      (tvipe ;; ,(concat v ": ")
                                                       ,example)
                                                    (read-string-hist ,(concat v ": ") ,example))))
                                           `(read-string-hist ,(concat v ": ") ,example)))
                                       do
                                       (progn
                                         (setq iteration (+ 1 iteration))
                                         (message (str iteration)))))))

                

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
                                  `(defun ,func-sym ,var-syms
                                     ,(sor doc title)
                                     (interactive ,(cons 'list iargs))
                                     (let* ((sh-update
                                             (or sh-update (>= (prefix-numeric-value current-prefix-arg) 4)))
                                            (result
                                             (chomp
                                              (sn
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
                                                                  (list 'q (str2sym vs)))))))))))
                                       (if (interactive-p)
                                           (if (or ,(not filter)
                                                   (>= (prefix-numeric-value current-prefix-arg) 4)
                                                   (not (selectedp)))
                                               (etv result)
                                             (replace-region result))
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
  (let ((f (fz pen-prompt-functions nil nil "pen run: ")))
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
          (if (>= (prefix-numeric-value current-prefix-arg) 8)
              (list response)
            ;; Just generate a few
            ;; (pen-pf-generic-file-type-completion (detect-language) preceding-text)
            ;; (pen-pf-generic-file-type-completion (detect-language) preceding-text))
            (str2lines (snc "monotonically-increasing-tuple-permutations.py" (car (str2lines response)))))))
    ;; Generate a list
    ;; (setq res '("testing" "testing123"))
    (mapcar (lambda (s) (concat (company-pen-filetype--prefix) s))
            res)))




(defun company-pen-filetype (command &optional arg &rest ignored)
  (interactive (list 'is-interactive))
  (cl-case command
    (is-interactive (company-begin-backend 'company-pen-filetype))
    (prefix (company-pen-filetype--prefix))
    (candidates (company-pen-filetype--candidates arg))
    ;; TODO doc-buffer may contain info on the completion in the future
    ;; (doc-buffer (company-pen-filetype--doc-buffer arg))
    ;; TODO annotation may contain the probability in the future
    ;; (annotation (company-pen-filetype--annotation arg))
    ))



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


(defun pen-complete-long ()
  (interactive)
  (let* ((preceding-text (str (buffer-substring (point) (max 1 (- (point) 1000)))))
         (response (pen-pf-generic-file-type-completion (detect-language) preceding-text)))
    (tv response)))

(define-key global-map (kbd "H-P") 'pen-complete-long)

(my-load "$MYGIT/semiosis/pen.el/pen-core.el")
(require 'pen-core)

(my-load "$MYGIT/semiosis/pen.el/pen-company.el")
(require 'pen-company)

(my-load "$MYGIT/semiosis/pen.el/pen-library.el")
(require 'pen-library)


(define-key org-brain-visualize-mode-map (kbd "C-c a") 'org-brain-asktutor)
(define-key org-brain-visualize-mode-map (kbd "C-c t") 'org-brain-show-topic)
(define-key org-brain-visualize-mode-map (kbd "C-c d") 'org-brain-describe-topic)


(provide 'my-openai)
(provide 'pen)