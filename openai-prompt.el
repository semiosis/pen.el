(defvar prompt-engineer-mode-map (make-sparse-keymap)
  "Keymap for `prompt-engineer-mode'.")
;; (makunbound 'prompt-engineer-mode)
(defvar-local prompt-engineer-mode nil)

(define-minor-mode prompt-engineer-mode
  "Mode for working with language models in your  buffers."
  :global t
  :init-value t
  :lighter " ai"
  :keymap prompt-engineer-mode-map)

;; (define-globalized-mode global-prompt-engineer-mode prompt-engineer-mode prompt-engineer-mode)

;; TODO Make a shell script for querying the OpenAI API
;; $SCRIPTS/openai-curl

;; TODO oai-generate
;; This function streams text onto the end of the currently selected region accordig to the current prompt settings



;; (define-key prompt-engineer-mode-map (kbd "<up>") 'oai-generate)
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

(defcustom openai-key ""
  "OpenAI API key"
  :type 'string
  :group 'prompt-engineer
  :initialize #'custom-initialize-default)

(defvar-local pem-engine nil)

(defvar-local pem-frequency-penalty nil
  "If your completion is filled with lots of\nrepetition you can increase this setting\nto prevent that from happening.\n\nHow much to penalize new tokens based on\ntheir existing frequency in the text so\nfar.\n\nDecreases the model's likelihood to repeat\nthe same line verbatim (the same text).\n\nThe likelihood of the same/similar lines\nbeing repeated in a completion.\n\nSet it high to avoid repetition.\n\nHowever, it could make sense to lower this\nvalue if writing lyrics for a song's\nchorus.")

(defvar-local pem-presence-penalty nil)

(defvar-local pem-best-of nil)

(defvar-local pem-stop-sequences nil)

(defvar-local pem-inject-start-text nil)

(defvar-local pem-inject-restart-text nil)

(defvar-local pem-show-probabilities nil)
;; + States
;;   - Off
;;   - Most likely
;;   - Least likely
;;   - Full spectrum

(provide 'prompt-engineer-mode)

(provide 'my-openai)