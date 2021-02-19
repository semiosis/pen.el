;; gy -E "openai api engines.generate -h | pavs"

(defvar prompt-engineer-mode-map (make-sparse-keymap)
  "Keymap for `prompt-engineer-mode'.")
;; (makunbound 'prompt-engineer-mode)
(defvar-local prompt-engineer-mode nil)

(define-minor-mode prompt-engineer-mode
  "Mode for working with language models in your  buffers."
  :global t
  :init-value t
  :lighter " pen"
  :keymap prompt-engineer-mode-map)

;; (define-globalized-mode global-prompt-engineer-mode prompt-engineer-mode prompt-engineer-mode)

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


;; (define-key prompt-engineer-mode-map (kbd "<up>") 'pen-generate)
;; (define-key prompt-engineer-mode-map (kbd "<down>") (lm (tsk "C-n")))
;; (define-key prompt-engineer-mode-map (kbd "<right>") (lm (tsk "M-3")))

(prompt-engineer-mode 1)

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

(setq pen-prompt-directory "/home/shane/source/git/mullikine/prompt-engineer-mode/prompts/")

;; + States
;;   - Off
;;   - Most likely
;;   - Least likely
;;   - Full spectrum

(defun load-prompts ()

  )

(provide 'prompt-engineer-mode)


(defun pen-tweet-sentiment-classifier (input)
  (interactive (list (my/selected-text)))
  (let* ((prompt-fp (umn "$MYGIT/mullikine/prompt-engineer-mode/prompts/tweet-sentiment-classifier.prompt"))
         (output (if input (sor (chomp (sn (concat "openai-complete " (q prompt-fp) " " (q input))))))))
    (if output
        (if (interactive-p)
            (message output)
          output))))

(defun pen-summarise-for-second-grader (input)
  (interactive (list (my/selected-text)))
  (let* ((prompt-fp (umn "$MYGIT/mullikine/prompt-engineer-mode/prompts/summarize-for-2nd-grader.prompt")))
    (region-pipe (concat "openai-complete " (q prompt-fp) " " (q input) " | chomp"))))

(defun pen-obfuscate-language (input)
  (interactive (list (my/selected-text)))
  (let* ((prompt-fp (umn "$MYGIT/mullikine/prompt-engineer-mode/prompts/obfuscate-language.prompt")))
    (region-pipe (concat "openai-complete " (q prompt-fp) " " (q input) " | chomp"))))

(defun pen-make-analogy (former latter)
  (interactive (list (read-string-hist "analogy participant: ")
                     (read-string-hist "analogy participant: ")))
  (let* ((prompt-fp (umn "$MYGIT/mullikine/prompt-engineer-mode/prompts/analogy.prompt")))
    (etv (sn (concat "openai-complete " (q prompt-fp) " " (q former) " "
                     (q latter) " | chomp")))))


(never
 (defset my-prompt-test (yamlmod-read-file (car (glob "$MYGIT/mullikine/prompt-engineer-mode/prompts/*"))))
 (ht-get my-prompt-test "title")
 (cl-loop for v in (vector2list (ht-get my-prompt-test "vars")) collect `(read-string-hist ,(concat v ": ")))
 (mapcar 'slugify (ht-get my-prompt-test "vars"))

 (describe-hash 'my-prompt-test))

(defun pen-interactively-generate-prompt ()
  "A wizard for quickly building a prompt"
  ;; $MYGIT/mullikine/prompt-engineer-mode/prompts/obfuscate-language.prompt
  (interactive)
  (let* ((meta (read-string "Meta description (The human asks the AI to etc.)\":")))))

(defalias 'cll 'cl-loop)


(defun pen-generate-prompt-functions ()
  "Generate prompt functions for the files in the prompts directory"
  (interactive)
  (let ((paths
         (glob "$MYGIT/mullikine/prompt-engineer-mode/prompts/*.prompt")))
    (cl-loop for path in paths do
             ;; results in a hash table
             (let* ((yaml (yamlmod-read-file path))
                    (title (ht-get yaml "title"))
                    (title-slug (slugify title))
                    (vars (vector2list (ht-get yaml "vars")))
                    (var-slugs (mapcar 'slugify vars))
                    (var-syms (mapcar 'str2sym var-slugs))
                    (func-name (concat "pen-" title-slug))
                    (iargs (let ((iteration 0))
                             (cl-loop for v in vars do
                                      (progn
                                        (setq iteration (+ 1 iteration))
                                        (message (str iteration)))
                                      collect
                                      (if (equal 1 iteration)
                                          ;; The first argument may be captured through selection
                                          `(if (selectionp)
                                               (my/selected-text)
                                             (read-string-hist ,(concat v ": ")))
                                        `(read-string-hist ,(concat v ": ")))))))
               ;; var names will have to be slugged, too
               (eval
                `(defun ,(str2sym func-name) ,var-syms
                   (interactive ,(cons 'list iargs))
                   (etv (chomp (sn ,(flatten-once
                                     (list
                                      (list 'concat "openai-complete " (q path))
                                      (flatten-once (cl-loop for vs in var-slugs collect
                                                             (list " "
                                                                   (list 'q (str2sym vs))))))))))))
               (message (concat "pen-mode: Loaded prompt function " func-name))))))


(provide 'my-openai)