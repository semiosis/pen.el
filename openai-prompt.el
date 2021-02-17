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

;; This is definitely a bad solution
;; (define-key openai-prompt-mode-map (kbd "<up>") (lm (tsk "C-p")))
;; (define-key openai-prompt-mode-map (kbd "<down>") (lm (tsk "C-n")))
;; (define-key openai-prompt-mode-map (kbd "<right>") (lm (tsk "M-3")))

(openai-prompt-mode 1)


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

(defvar-local openai-prompt-mode nil)

(provide 'openai-prompt-mode)

(provide 'my-openai)