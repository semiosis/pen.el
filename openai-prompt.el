(defvar openai-prompt-mode-map (make-sparse-keymap)
  "Keymap for `openai-prompt-mode'.")
;; (makunbound 'openai-prompt-mode)
(defvar-local openai-prompt-mode nil)

(define-minor-mode openai-prompt-mode
  "Mode for working with language models in your  buffers."
  :global t
  :init-value t
  :lighter " ai"
  :keymap openai-prompt-mode-map)

;; (define-globalized-mode global-openai-prompt-mode openai-prompt-mode openai-prompt-mode)

;; TODO Make a shell script for querying the OpenAI API
;; $SCRIPTS/openai-curl

;; TODO oai-generate
;; This function streams text onto the end of the currently selected region accordig to the current prompt settings

;; (define-key openai-prompt-mode-map (kbd "<up>") 'oai-generate)
;; (define-key openai-prompt-mode-map (kbd "<down>") (lm (tsk "C-n")))
;; (define-key openai-prompt-mode-map (kbd "<right>") (lm (tsk "M-3")))

(openai-prompt-mode 1)

;; TODO Create a transient mode for quickly setting prompt settings

;; (define-transient-command openai-prompt-configure ()
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
  :group 'openai-prompt
  :initialize #'custom-initialize-default)

(defvar-local oai-prompt-engine nil)

(defvar-local oai-prompt-frequency-penalty nil
  "If your completion is filled with lots of\nrepetition you can increase this setting\nto prevent that from happening.\n\nHow much to penalize new tokens based on\ntheir existing frequency in the text so\nfar.\n\nDecreases the model's likelihood to repeat\nthe same line verbatim (the same text).\n\nThe likelihood of the same/similar lines\nbeing repeated in a completion.\n\nSet it high to avoid repetition.\n\nHowever, it could make sense to lower this\nvalue if writing lyrics for a song's\nchorus.")

(defvar-local oai-prompt-presence-penalty nil)

(defvar-local oai-prompt-best-of nil)

(defvar-local oai-prompt-stop-sequences nil)

(defvar-local oai-prompt-inject-start-text nil)

(defvar-local oai-prompt-inject-restart-text nil)

(defvar-local oai-prompt-show-probabilities nil)
;; + States
;;   - Off
;;   - Most likely
;;   - Least likely
;;   - Full spectrum

(provide 'openai-prompt-mode)

(provide 'my-openai)