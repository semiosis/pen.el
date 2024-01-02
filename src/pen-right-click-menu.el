(require 'popup)
(require 'right-click-context)

;; Not sure if this does anything. Perhaps one of my mods broke this
(setq right-click-context-mouse-set-point-before-open-menu 'not-region)

;; Configure the right click menu to have more height
(defset popup-max-height 30)
(cl-defun popup-menu* (list
                       &key
                       point
                       (around t)
                       (width (popup-preferred-width list))
                       (height popup-max-height)
                       max-width
                       margin
                       margin-left
                       margin-right
                       scroll-bar
                       symbol
                       parent
                       parent-offset
                       cursor
                       (keymap popup-menu-keymap)
                       (fallback 'popup-menu-fallback)
                       help-delay
                       nowait
                       prompt
                       isearch
                       (isearch-filter 'popup-isearch-filter-list)
                       (isearch-cursor-color popup-isearch-cursor-color)
                       (isearch-keymap popup-isearch-keymap)
                       isearch-callback
                       initial-index
                       &aux menu event)
  "Show a popup menu of LIST at POINT. This function returns a
value of the selected item. Almost all arguments are the same as in
`popup-create', except for KEYMAP, FALLBACK, HELP-DELAY, PROMPT,
ISEARCH, ISEARCH-FILTER, ISEARCH-CURSOR-COLOR, ISEARCH-KEYMAP, and
ISEARCH-CALLBACK.

If KEYMAP is a keymap which is used when processing events during
event loop.

If FALLBACK is a function taking two arguments; a key and a
command. FALLBACK is called when no special operation is found on
the key. The default value is `popup-menu-fallback', which does
nothing.

HELP-DELAY is a delay of displaying helps.

If NOWAIT is non-nil, this function immediately returns the menu
instance without entering event loop.

PROMPT is a prompt string when reading events during event loop.

If ISEARCH is non-nil, do isearch as soon as displaying the popup
menu.

ISEARCH-FILTER is a filtering function taking two arguments:
search pattern and list of items. Returns a list of matching items.

ISEARCH-CURSOR-COLOR is a cursor color during isearch. The
default value is `popup-isearch-cursor-color'.

ISEARCH-KEYMAP is a keymap which is used when processing events
during event loop. The default value is `popup-isearch-keymap'.

ISEARCH-CALLBACK is a function taking one argument.  `popup-menu'
calls ISEARCH-CALLBACK, if specified, after isearch finished or
isearch canceled. The arguments is whole filtered list of items.

If `INITIAL-INDEX' is non-nil, this is an initial index value for
`popup-select'. Only positive integer is valid."
  (and (eq margin t) (setq margin 1))
  (or margin-left (setq margin-left margin))
  (or margin-right (setq margin-right margin))
  (if (and scroll-bar
           (integerp margin-right)
           (> margin-right 0))
      ;; Make scroll-bar space as margin-right
      (cl-decf margin-right))
  (setq menu (popup-create point width height
                           :max-width max-width
                           :around around
                           :face 'popup-menu-face
                           :mouse-face 'popup-menu-mouse-face
                           :selection-face 'popup-menu-selection-face
                           :summary-face 'popup-menu-summary-face
                           :margin-left margin-left
                           :margin-right margin-right
                           :scroll-bar scroll-bar
                           :symbol symbol
                           :parent parent
                           :parent-offset parent-offset))
  (unwind-protect
      (progn
        (popup-set-list menu list)
        (if cursor
            (popup-jump menu cursor)
          (popup-draw menu))
        (when initial-index
          (dotimes (_i (min (- (length list) 1) initial-index))
            (popup-next menu)))
        (if nowait
            menu
          (popup-menu-event-loop menu keymap fallback
                                 :prompt prompt
                                 :help-delay help-delay
                                 :isearch isearch
                                 :isearch-filter isearch-filter
                                 :isearch-cursor-color isearch-cursor-color
                                 :isearch-keymap isearch-keymap
                                 :isearch-callback isearch-callback)))
    (unless nowait
      (popup-delete menu))))

(defun pen-translate (&optional phrase)
  (interactive)
  (pen-etv (pf-translate-from-world-language-x-to-y/3 phrase)))

(defun pen-asktutor ()

  )

;; TODO Make this work for the prompt name, too
(defun pen-go-to-prompt-for-ink ()
  (interactive)
  (find-file (lax-plist-get (text-properties-at (point)) 'PEN_PROMPT_PATH)))

(defun pen-go-to-engine-for-ink ()
  (interactive)
  (pen-goto-engine (lax-plist-get (text-properties-at (point)) 'PEN_ENGINE)))

(defun pen-goto-engine (engine)
  (ignore-errors
    (let* ((e (ht-get pen-engines engine))
           (path (ht-get e "engine-path")))
      (find-file path))))

(defun pen-selected-or-preceding-context (&optional max-chars)
  (sor (pen-selected-text t)
       (pen-preceding-text max-chars)))

(defun pen-detect-language-context (&optional max-chars)
  (interactive)
  (message (concat "Detected language: " (pen-ask (pf-get-language/1 (pen-selected-or-preceding-context max-chars))))))

;; TODO Try to detect the appropriate imaginary interpreter to start

(defun pen-detect-imaginary-interpreter ()
  ;; TODO Check for user prompt on current line first
  ;; TODO Then do a language detect
  (-filter (λ (i) (istr-match-p (ht-get i "language") lang)) (pen-list-interpreters))
  (re-match-p "^In \\[[0-9]*\\]: " (current-line-string)))

(defun pen-e-sps (&optional run)
  "`sps` stands for `Split Sensibly`"
  (interactive)
  (split-window-sensibly)
  (other-window 1)
  (if run
      (call-interactively run)))

(defun pen-pwd ()
  "Returns the current directory."
  (pen-snc (pen-cmd "realpath" (pen-umn default-directory))))

(defun pen-tmuxify-cmd (cmd &optional dir window-name)
  (let ((slug (slugify cmd)))
    (setq window-name (or window-name slug))
    (setq dir (or dir (pen-pwd)))
    (concat "TMUX= tmux new -c " (pen-q dir) " -n " (pen-q window-name) " " (pen-q (concat "CWD= " cmd)))))

(defun pen-term-sps (&optional cmd dir)
  "`sps` stands for `Split Sensibly`"
  (interactive)
  (if (not dir)
      (setq dir (cwd)))
  (if (not cmd)
      (progn
        (setq cmd "bash")
        (setq cmd (pen-tmuxify-cmd cmd dir cmd))))
  (pen-e-sps (pen-lm (pen-term-nsfa cmd nil "zsh" nil nil dir))))

(defun pen-start-imaginary-interpreter (lang history)
  (interactive (list (pf-get-language/1 (pen-preceding-text))
                     (pen-preceding-text)))
  (pen-term-sps (pen-cmd "comint" "-E" (pen-cmd "ii" lang history))))

(defun show-suggest-funcs-context-menu ()
  (interactive)

  (eval
   `(def-right-click-menu rcm-suggest-funcs
      (quote ,(mapcar (λ (sym) (list (sym2str sym) :call sym)) (pen-suggest-funcs-collect)))))
  (rcm-suggest-funcs))

(defun ekbd (keys)
  (execute-kbd-macro (kbd keys)))

(defun press-return ()
  (interactive)
  (ekbd "RET"))

(setq right-click-context-global-menu-tree
      `(("Cancel" :call identity-command)
        ("> prompt functions" :call rcm-prompt-functions)
        ("> apps" :call rcm-apps)
        ("> ink"
         :call rcm-ink
         :if (sor (lax-plist-get (text-properties-at (point)) 'PEN_MODEL)
                  (lax-plist-get (text-properties-at (point)) 'PEN_ENGINE)
                  (lax-plist-get (text-properties-at (point)) 'PEN_LM_COMMAND)))
        ("Get value from YAML" :call yaml-get-value-from-this-file :if (major-mode-p 'yaml-mode))
        ("LSP right click menu" :call pen-lsp-mouse-click :if (minor-mode-p lsp-mode))
        ("ebdb right click menu" :call pen-ebdb-mouse-click :if (major-mode-p 'ebdb-mode))
        ("prose"
         ("Cancel" :call identity-command)
         ("pick up line" :call pf-very-witty-pick-up-lines-for-a-topic/1)
         ("translate" :call pf-translate-from-world-language-x-to-y/3 :if (pen-selected-p))
         ("thesaurus" :call pf-thesaurus/1)
         ("paraphrase" :call pf-paraphrase/1 :if (pen-selected-p))
         ("tldr" :call pf-tldr-summarization/1 :if (pen-selected-p))
         ("eli5" :call pf-eli5-explain-like-i-m-five/1 :if (pen-selected-p))
         ("clean prose" :call pf-clean-prose/1 :if (pen-selected-p))
         ("Example of word usage" :call pf-get-an-example-sentence-for-a-word/1)
         ("transform prose" :call pf-transform-prose/2)
         ("correct grammar" :call pf-correct-grammar/1 :if (pen-selected-p))
         ("correct grammar 2" :call pf-correct-grammar-2/1 :if (pen-selected-p))
         ("vexate" :call pf-complicated-explanation-of-how-to-x/1 :if (pen-selected-p))
         ("correct English spelling and grammar" :call pf-correct-english-spelling-and-grammar/1 :if (pen-selected-p))
         ("define term" :call pen-define :if (pen-selected-p))
         ("bullet points -> first-hand account" :call pf-meeting-bullet-points-to-summary/1 :if (pen-selected-p)))
        ("code"
         ("Cancel" :call identity-command)
         ("> generate program" :call rcm-generate-program)
         ("Quick fix syntax" :call pf-quick-fix-code/1)
         ("LSP explain error" :call pen-lsp-explain-error)
         ("explain error" :call pf-explain-error/2)
         ("asktutor" :call pen-tutor-mode-assist :if (derived-mode-p 'prog-mode))
         ("transpile" :call pf-transpile-from-programming-language-x-to-y/3)
         ;; ("add comments" :call pf-annotate-code-with-commentary/2)
         ("guess function name" :call pf-guess-function-name/1)
         ("transform code" :call pf-transform-code/3)
         ("lint awk" :call pen-imagine-awk-linting)
         ("Example of usage" :call pf-get-an-example-of-the-usage-of-a-function/2)
         ("correct the syntax" :call pf-correct-the-syntax/2)
         ("add comments" :call pf-add-comments-to-code/2)
         ("generate from description" :call pf-code-generator-from-description/1)
         ("generate regex for above" :call pf-gpt-j-generate-regex/2))
        ("Press return" :call press-return)
        ("Kill current buffer" :call kill-current-buffer)
        ("Kill current buffer and window" :call kill-buffer-and-window)
        ("(Accept) Save then kill buffer and emacsclient" :call pen-save-and-kill-buffer-window-and-emacsclient)
        ("(Abort) Revert and kill buffer and emacsclient" :call pen-revert-kill-buffer-and-window)
        ("Context functions" :call show-suggest-funcs-context-menu)))

(defmacro def-right-click-menu (name
                                ;; predicates
                                popup)
  "Create a right click menu."
  `(defun ,name ()
     "Open Right Click Context menu."
     (interactive)
     (let ((popup-menu-keymap (copy-sequence popup-menu-keymap)))
       ;; (define-key popup-menu-keymap [mouse-3] #'right-click-context--click-menu-popup)
       (define-key popup-menu-keymap [mouse-3] #'right-click-popup-close)
       (define-key popup-menu-keymap (kbd "C-g") #'right-click-popup-close)
       (let ((value (popup-cascade-menu (right-click-context--build-menu-for-popup-el ,popup nil))))
         (when value
           (if (symbolp value)
               (call-interactively value t)
             (eval value)))))))

;; TODO Generate the right-click menu from the prompt data
;; - The titles should match
;; - I need to figure out organisation
;; - Separate into prose and code, or make tags for categories

(def-right-click-menu rcm-apps
  `(("Cancel" :call identity-command)
    ("start ii" :call pen-start-imaginary-interpreter)
    ("chat to a subject-matter expert about this text" :call apostrophe-chat-about-selection)
    ("chat to a subject-matter expert about this text's broader topics" :call apostrophe-start-chatbot-from-selection)
    ("search the imaginary web" :call pen-browse-url-for-passage)))

(def-right-click-menu rcm-prompt-functions
  `(("Cancel" :call identity-command)
    ("translate" :call pf-translate-from-world-language-x-to-y/3)
    ("transpile" :call pf-transpile/3)

    ("Complete until EOD" :call pf-prompt-until-the-language-model-believes-it-has-hit-the-end/1 :if (pen-selected-p))
    ("> explain code" :call rcm-explain-code)
    ("> cheap" :call rcm-cheap)
    ("> word/term" :call rcm-term :if (pen-word-clickable))
    ("keywords/classify" :call pen-extract-keywords)
    ("get docs" :call pf-get-documentation-for-syntax-given-screen/2)
    ("define for glossary" :call pen-add-to-glossary)
    ("define term (general knowledge)" :call pen-define-general-knowledge)
    ("define term (detect language)" :call pen-define-detectlang)
    ("detect language here" :call pen-detect-language-context)))


(def-right-click-menu rcm-cheap
  '(("Cancel" :call identity-command)
    ("transpile" :call pf-transpile-from-programming-language-x-to-y/3)))

(def-right-click-menu rcm-term
  '(("Cancel" :call identity-command)
    ("pick up line" :call pf-very-witty-pick-up-lines-for-a-topic/1 :if (pen-word-clickable))
    ("define word" :call pen-define :if (pen-word-clickable))))

(def-right-click-menu rcm-generate-program
  '(("Cancel" :call identity-command)
    ("generate program from NL" :call pf-generate-program-from-nl/3)))

(def-right-click-menu rcm-explain-code
  '(("Cancel" :call identity-command)
    ("explain /1" :call pf-explain-some-code/1)
    ("explain (given the language) /2" :call pf-explain-some-code/2)
    ("Why is this code needed?" :call pf-explain-why-this-code-is-needed/2)
    ("explain a shell command" :call pf-explain-a-shell-command/1)
    ("explain a file" :call pf-explain-a-file/4)))

(def-right-click-menu rcm-ink
  '(("Cancel" :call identity-command)
    ("Show pen properties" :call ink-get-properties-here :if (is-ink-p))
    ;; ("Select ink" :call ink-select-full-result-under-point :if (is-ink-p))
    ("go to prompt for text" :call pen-go-to-prompt-for-ink :if (sor (lax-plist-get (text-properties-at (point)) 'PEN_PROMPT_PATH)))
    ("go to engine for text" :call pen-go-to-engine-for-ink :if (sor (lax-plist-get (text-properties-at (point)) 'PEN_ENGINE)))))

;; (define-key pen-map (kbd "H-m") 'right-click-context-menu)
;; (define-key pen-map (kbd "C-M-z") 'right-click-context-menu)

(defun right-click-context-menu-around-advice-remove-overlays (proc &rest args)
  (lsp-ui-sideline--delete-ov)
  (lsp-ui-doc-hide)
  (let ((res (apply proc args)))
    res))
(advice-add 'right-click-context-menu :around #'right-click-context-menu-around-advice-remove-overlays)
;; (advice-remove 'right-click-context-menu #'right-click-context-menu-around-advice-remove-overlays)

(defun identity-command (&optional body)
  (interactive)
  (identity body))

(defun double-click-context-menu ()
  (interactive)
  ;; TODO prevent a cursor position change if double clicking
  ;; The preceding single-click has bindings which change the mark and point
  ;; I'm currently unsure how to do that.

  ;; (call-interactively 'cua-exchange-point-and-mark)
  ;; (if (< (mark) (point))
  ;;     (goto-char (mark)))
  (set-mark (point))
  (call-interactively 'double-click-context-menu-widget)
  ;; (if (eq (mark) (point))
  ;;     (call-interactively 'double-click-context-menu-widget))
  )

(def-right-click-menu double-click-context-menu-widget
  '(("Cancel" :call identity-command)
    ("> Right-click menu" :call right-click-context-menu)
    ("Kill buffer" :call pen-kill-buffer-immediately)
    ("Reopen buffer" :call pen-kill-buffer-and-reopen)
    ("Dired" :call dired-here)
    ("Copy action" :call (copy-widget-action)
     :if (widget-at (point)))
    ("Go to widget function" :call (goto-widadget-action)
     :if (widget-at (point)))
    ("Push widget" :call (push-widget)
     :if (widget-at (point)))
    ("Show widget properties" :call (widget-show-properties-here)
     :if (widget-at (point)))
    ("Context functions" :call show-suggest-funcs-context-menu)))

;; Sometimes I want to triple-click to select a line.
;; Also, the double-mouse click seems to change point and mark.
;; So it's not a good trade.
;; (define-key pen-map (kbd "<double-mouse-1>") 'double-click-context-menu)

(provide 'pen-right-click-menu)
