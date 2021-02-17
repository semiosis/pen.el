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


(defun pen-generate ()
  "This function streams text onto the end of the currently selected region accordig to the current prompt settings"
  (interactive)
  (if (region-active-p)
      (let ((r (selected)))
        ;; Send request and replace the text
        )))


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

;; This key will be set
(defcustom pen-openai-key ""
  "OpenAI API key"
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
;; + States
;;   - Off
;;   - Most likely
;;   - Least likely
;;   - Full spectrum

(provide 'prompt-engineer-mode)

(provide 'my-openai)