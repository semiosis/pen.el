;; TODO Make the keybindings map to pen-mode-map
;; TODO Rename pen-mode to pen-mode -- it's far more convenient

;; gy -E "openai api engines.generate -h | pavs"

(defvar pen-mode-map (make-sparse-keymap)
  "Keymap for `pen-mode'.")
;; (makunbound 'pen-mode)
(defvar-local pen-mode nil)

(define-minor-mode pen-mode
  "Mode for working with language models in your  buffers."
  :global t
  :init-value t
  :lighter " pen"
  :keymap pen-mode-map)

;; (define-globalized-mode global-pen-mode pen-mode pen-mode)

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


;; (define-key pen-mode-map (kbd "<up>") 'pen-generate)
;; (define-key pen-mode-map (kbd "<down>") (lm (tsk "C-n")))
;; (define-key pen-mode-map (kbd "<right>") (lm (tsk "M-3")))

(pen-mode 1)

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

(setq pen-prompt-directory "/home/shane/source/git/mullikine/prompts/prompts")

;; + States
;;   - Off
;;   - Most likely
;;   - Least likely
;;   - Full spectrum

(defun load-prompts ()

  )

(provide 'pen-mode)


;; (defun pen-tweet-sentiment-classifier (input)
;;   (interactive (list (my/selected-text)))
;;   (let* ((prompt-fp (umn "$MYGIT/mullikine/pen-mode/prompts/tweet-sentiment-classifier.prompt"))
;;          (output (if input (sor (chomp (sn (concat "openai-complete " (q prompt-fp) " " (q input))))))))
;;     (if output
;;         (if (interactive-p)
;;             (message output)
;;           output))))

;; (defun pen-summarise-for-second-grader (input)
;;   (interactive (list (my/selected-text)))
;;   (let* ((prompt-fp (umn "$MYGIT/mullikine/pen-mode/prompts/summarize-for-2nd-grader.prompt")))
;;     (region-pipe (concat "openai-complete " (q prompt-fp) " " (q input) " | chomp"))))

;; (defun pen-obfuscate-language (input)
;;   (interactive (list (my/selected-text)))
;;   (let* ((prompt-fp (umn "$MYGIT/mullikine/pen-mode/prompts/obfuscate-language.prompt")))
;;     (region-pipe (concat "openai-complete " (q prompt-fp) " " (q input) " | chomp"))))

;; (defun pen-make-analogy (former latter)
;;   (interactive (list (read-string-hist "analogy participant: ")
;;                      (read-string-hist "analogy participant: ")))
;;   (let* ((prompt-fp (umn "$MYGIT/mullikine/pen-mode/prompts/analogy.prompt")))
;;     (etv (sn (concat "openai-complete " (q prompt-fp) " " (q former) " "
;;                      (q latter) " | chomp")))))


(never
 (defset my-prompt-test (yamlmod-read-file (car (glob "$MYGIT/mullikine/pen-mode/prompts/*"))))
 (ht-get my-prompt-test "title")
 (cl-loop for v in (vector2list (ht-get my-prompt-test "vars")) collect `(read-string-hist ,(concat v ": ")))
 (mapcar 'slugify (ht-get my-prompt-test "vars"))

 (describe-hash 'my-prompt-test))

(defun pen-interactively-generate-prompt ()
  "A wizard for quickly building a prompt"
  ;; $MYGIT/mullikine/pen-mode/prompts/obfuscate-language.prompt
  (interactive)
  (let* ((meta (read-string "Meta description (The human asks the AI to etc.)\":")))))

(defalias 'cll 'cl-loop)


(defvar pen-prompt-functions nil)


(defun pen-generate-prompt-functions ()
  "Generate prompt functions for the files in the prompts directory"
  (interactive)
  (let ((paths
         (-non-nil (mapcar 'sor (glob (concat pen-prompt-directory "/*.prompt"))))))
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
               (add-to-list 'pen-prompt-functions
                            (eval
                             `(defun ,(str2sym func-name) ,var-syms
                                (interactive ,(cons 'list iargs))
                                (etv (chomp (sn ,(flatten-once
                                                  (list
                                                   (list 'concat "openai-complete " (q path))
                                                   (flatten-once (cl-loop for vs in var-slugs collect
                                                                          (list " "
                                                                                (list 'q (str2sym vs)))))))))))))
               (message (concat "pen-mode: Loaded prompt function " func-name))))))
(pen-generate-prompt-functions)


(define-derived-mode prompt-description-mode yaml-mode "Prompt"
  "Prompt description mode")


;; (define-key global-map (kbd "H-TAB") nil)
(define-key global-map (kbd "H-TAB g") 'pen-generate-prompt-functions)
(define-key global-map (kbd "H-TAB r") 'pen-run-prompt-function)


(defun pen-run-prompt-function ()
  (interactive)
  (let ((f (fz pen-prompt-functions)))
    (if f
        (call-interactively (str2sym f)))))
(defalias 'camille-complete 'pen-run-prompt-function)

;; Camille-complete (because I press SPC to replace
(define-key selected-keymap (kbd "SPC") 'pen-run-prompt-function)
(define-key selected-keymap (kbd "M-SPC") 'pen-run-prompt-function)

(provide 'my-openai)