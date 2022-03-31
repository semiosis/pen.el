;; This was interfering with completion
(setq company-backends '())

;; These bindings will allow you to use Space Cadet keyboard modifiers
;; https://mullikine.github.io/posts/add-super-and-hyper-to-terminal-emacs/
;; C-M-6 = Super (s-)
;; C-M-\ = Hyper (H-)
;; Pen.el will make use of H-
(define-key global-map (kbd "C-M-6") nil)             ;For GUI
(define-key function-key-map (kbd "C-M-6") 'superify) ;For GUI
(define-key function-key-map (kbd "C-M-^") 'superify)
(define-key function-key-map (kbd "C-^") 'superify)
(define-key global-map (kbd "C-M-\\") nil) ;Ensure that this bindings isnt taken
(define-key function-key-map (kbd "C-M-\\") 'hyperify)
(define-key global-map (kbd "M-h") nil)
(define-key function-key-map (kbd "M-h") 'hyperify)
(define-key function-key-map (kbd "M-H") 'hyperify)

(define-key global-map (kbd "M-_") 'irc-find-prev-line-with-diff-char)
(define-key global-map (kbd "M-+") 'irc-find-next-line-with-diff-char)

;; Is this a good idea?
;; (define-key function-key-map (kbd "TAB") 'hyperify)
;; (define-key global-map (kbd "TAB") nil)

(define-key function-key-map (kbd "<backtab>") 'hyperify)

;; Ensure that you have yamlmod

;; https://github.com/perfectayush/emacs-yamlmod
(if module-file-suffix
    (progn
      (module-load (concat (getenv "YAMLMOD_PATH") "/target/release/libyamlmod.so"))
      (add-to-list 'load-path (getenv "YAMLMOD_PATH"))
      (require 'yamlmod)
      (require 'yamlmod-wrapper)))

(require 'pen)
(pen 1)

(let ((d "/root/dump/ubolonton/emacs-tree-sitter/lisp"))
  (if (f-directory-p d)
      (progn
        (add-to-list 'load-path d)
        (require 'tree-sitter))))

;; Camille-complete (because I press SPC to replace)
(defalias 'camille-complete 'pen-run-prompt-function)

(require 'selected)
(define-key selected-keymap (kbd "SPC") 'pen-run-prompt-function)
(define-key selected-keymap (kbd "M-SPC") 'pen-run-prompt-function)
;; (define-key selected-keymap (kbd "A") 'pf-define-word-for-glossary/1)
(define-key selected-keymap (kbd "A") 'pen-add-to-glossary)

;; (define-key pen-map (kbd "H-1") 'pen-company-filetype-word)
;; (define-key pen-map (kbd "H-2") 'pen-company-filetype-words)
;; (define-key pen-map (kbd "H-3") 'pen-company-filetype-line)
;; (define-key pen-map (kbd "H-4") 'pen-company-filetype-long)
(define-key pen-map (kbd "H-1") 'pen-complete-word)
(define-key pen-map (kbd "H-2") 'pen-complete-words)
(define-key pen-map (kbd "H-3") 'pen-complete-line)
(define-key pen-map (kbd "H-4") 'pen-complete-lines)
(define-key pen-map (kbd "H-5") 'pen-complete-long)
(define-key pen-map (kbd "H-S") 'pen-complete-short)
(define-key pen-map (kbd "H-P") 'pen-complete-long)
(define-key pen-map (kbd "H-b") 'pf-generate-the-contents-of-a-new-file/6)
(define-key pen-map (kbd "H-s") 'fz-pen-counsel)
(define-key pen-map (kbd "M-9") 'handle-docs)

(define-key pen-map (kbd "H-n") 'global-pen-acolyte-minor-mode)
(define-key pen-map (kbd "H-.") 'global-pen-acolyte-minor-mode)
(define-key pen-map (kbd "H-:") 'pen-compose-cli-command)
(define-key pen-map (kbd "H-x") 'pen-diagnostics-show-context)

(require 'pen-contrib)
;; from contrib
(require 'pen-org-brain)
(define-key org-brain-visualize-mode-map (kbd "C-c a") 'org-brain-asktutor)
(define-key org-brain-visualize-mode-map (kbd "C-c t") 'org-brain-show-topic)
(define-key org-brain-visualize-mode-map (kbd "C-c d") 'org-brain-describe-topic)

(require 'pen-org-roam)

;; Prompts discovery
;; This is where discovered prompts repositories are placed
(setq pen-prompts-library-directory (f-join user-emacs-directory "prompts-library"))
;; This is how many repositories deep pen will look for new prompts repositories that are linked to eachother
(setq pen-prompt-discovery-recursion-depth 5)

(comment
 (openaidir (f-join user-emacs-directory "openai-api.el"))
 (openaihostdir (f-join user-emacs-directory "host/openai-api.el"))
 (penhostdir (f-join user-emacs-directory "host/pen.el"))
 (contribdir (f-join user-emacs-directory "pen-contrib.el"))
 (contribhostdir (f-join user-emacs-directory "host/pen-contrib.el"))
 (pensievedir (f-join user-emacs-directory "pensieve"))
 (pensievehostdir (f-join user-emacs-directory "host/pensieve"))
 (rhizomedir (f-join user-emacs-directory "rhizome"))
 (rhizomehostdir (f-join user-emacs-directory "host/rhizome"))
 (khaladir (f-join user-emacs-directory "khala"))
 (khalahostdir (f-join user-emacs-directory "host/khala")))

(let ((hostpensievedir (f-join user-emacs-directory "host" "pensieve")))
  (if (f-directory-p (f-join hostpensievedir "src"))
      (setq pen-pensieve-directory hostpensievedir)
    (setq pen-pensieve-directory (f-join user-emacs-directory "pensieve"))))

(let ((hostkhaladir (f-join user-emacs-directory "host" "khala")))
  (if (f-directory-p (f-join hostkhaladir "src"))
      (setq pen-khala-directory hostkhaladir)
    (setq pen-khala-directory (f-join user-emacs-directory "khala"))))

(let ((hostrhizomedir (f-join user-emacs-directory "host" "rhizome")))
  (if (f-directory-p (f-join hostrhizomedir "src"))
      (setq pen-rhizome-directory hostrhizomedir)
    (setq pen-rhizome-directory (f-join user-emacs-directory "rhizome"))))

(let ((hostpeneldir (f-join user-emacs-directory "host" "pen.el")))
  (if (f-directory-p (f-join hostpeneldir "src"))
      (setq pen-penel-directory hostpeneldir)
    (setq pen-penel-directory (f-join user-emacs-directory "pen.el"))))

(let ((hostpromptsdir (f-join user-emacs-directory "host" "prompts")))
  (if (f-directory-p (f-join hostpromptsdir "prompts"))
      (setq pen-prompts-directory hostpromptsdir)
    (setq pen-prompts-directory (f-join user-emacs-directory "prompts"))))

(let ((hostdnidir (f-join user-emacs-directory "host" "dni")))
  (if (f-directory-p (f-join hostdnidir))
      (setq pen-dni-directory hostdnidir)
    (setq pen-dni-directory (f-join user-emacs-directory "dni"))))

(let ((hostcreationdir (f-join user-emacs-directory "host" "creation")))
  (if (f-directory-p (f-join hostcreationdir))
      (setq pen-creation-directory hostcreationdir)
    (setq pen-creation-directory (f-join user-emacs-directory "creation"))))

(let ((hostcontribdir (f-join user-emacs-directory "host" "pen-contrib.el")))
  (if (f-directory-p (f-join hostcontribdir "pen-contrib.el"))
      (setq pen-contrib-directory hostcontribdir)
    (setq pen-contrib-directory (f-join user-emacs-directory "pen-contrib.el"))))

(let ((hostilambdadir (f-join user-emacs-directory "host" "ilambda")))
  (if (f-directory-p (f-join hostilambdadir))
      (setq pen-ilambda-directory hostilambdadir)
    (setq pen-ilambda-directory (f-join user-emacs-directory "ilambda"))))

(let ((hostenginesdir (f-join user-emacs-directory "host" "engines")))
  (if (f-directory-p (f-join hostenginesdir "engines"))
      (setq pen-engines-directory hostenginesdir)
    (setq pen-engines-directory (f-join user-emacs-directory "engines"))))

(let ((hostglossariesdir (f-join user-emacs-directory "host" "glossaries")))
  (if (f-directory-p (f-join hostglossariesdir "glossaries"))
      (setq pen-glossaries-directory hostglossariesdir)
    (setq pen-glossaries-directory (f-join user-emacs-directory "glossaries"))))

;; nlsh
(setq pen-nlsh-histdir (f-join user-emacs-directory "comint-history"))
(f-mkdir pen-nlsh-histdir)

;; Company
(setq company-auto-complete nil)
(setq company-auto-complete-chars '())
(setq company-minimum-prefix-length 0)
(setq company-idle-delay 0)
(setq company-minimum-prefix-length 1)
(setq company-tooltip-limit 20) ; bigger popup window
(setq company-idle-delay 0.3)  ; decrease delay before autocompletion popup shows
(setq company-echo-delay 0)    ; remove annoying blinking
(setq company-begin-commands '(self-insert-command)) ; start autocompletion only after typing
(add-hook 'after-init-hook 'global-company-mode)

(require 'xt-mouse)
(xterm-mouse-mode)
(require 'mouse)
(xterm-mouse-mode t)
;; (defun track-mouse (e))

(setq x-alt-keysym 'meta)

;; Simplify the experience -- Super newb mode


(defun pen-acolyte-scratch ()
  (interactive)
  (switch-to-buffer "*scratch*"))

;; defvar this in your own config and load first to disable
;; (defvar pen-init-with-acolyte-mode t)

;; (if pen-init-with-acolyte-mode
;;     (global-pen-acolyte-minor-mode t))

(package-install 'ivy)
(require 'ivy)
(ivy-mode 1)

(setq message-log-max 20000)

(right-click-context-mode t)
(pen-acolyte-scratch)

(defun pen-default-add-keys (;; frame
                             )
  (interactive)

  (let ((pen-openai-key-file-path (f-join penconfdir "openai_api_key")))
    (if (not (f-file-p pen-openai-key-file-path))
        (let ((envkey (getenv "OPENAI_API_KEY")))
          (if (sor envkey)
              (pen-add-key-openai envkey)
            ;; Automatically check if OpenAI key exists and ask for it otherwise
            (call-interactively 'pen-add-key-openai)))))

  (let ((pen-cohere-key-file-path (f-join penconfdir "cohere_api_key")))
    (if (not (f-file-p pen-cohere-key-file-path))
        (let ((envkey (getenv "COHERE_API_KEY")))
          (if (sor envkey)
              (pen-add-key-cohere envkey)
            ;; Automatically check if Cohere key exists and ask for it otherwise
            (call-interactively 'pen-add-key-cohere)))))

  (let ((pen-goose-key-file-path (f-join penconfdir "goose_api_key")))
    (if (not (f-file-p pen-goose-key-file-path))
        (let ((envkey (getenv "GOOSE_API_KEY")))
          (if (sor envkey)
              (pen-add-key-goose envkey)
            ;; Automatically check if Goose key exists and ask for it otherwise
            (call-interactively 'pen-add-key-goose)))))

  (let ((pen-alephalpha-key-file-path (f-join penconfdir "alephalpha_api_key")))
    (if (not (f-file-p pen-alephalpha-key-file-path))
        (let ((envkey (getenv "ALEPHALPHA_API_KEY")))
          (if (sor envkey)
              (pen-add-key-alephalpha envkey)
            ;; Automatically check if AlephAlpha key exists and ask for it otherwise
            (call-interactively 'pen-add-key-alephalpha)))))

  ;; (let ((pen-aix-key-file-path (f-join penconfdir "aix_api_key")))
  ;;   (if (not (f-file-p pen-aix-key-file-path))
  ;;       (let ((envkey (getenv "AIX_API_KEY")))
  ;;         (if (sor envkey)
  ;;             (pen-add-key-aix envkey)
  ;;           ;; Automatically check if Aix key exists and ask for it otherwise
  ;;           (call-interactively 'pen-add-key-aix)))))

  (let ((pen-hf-key-file-path (f-join penconfdir "hf_api_key")))
    (if (not (f-file-p pen-hf-key-file-path))
        (let ((envkey (getenv "HF_API_KEY")))
          (if (sor envkey)
              (pen-add-key-hf envkey)
            ;; Automatically check if Hf key exists and ask for it otherwise
            (call-interactively 'pen-add-key-hf))))))

(defun pen-delay-add-keys ()
  (interactive)
  (run-with-timer 1 nil 'pen-default-add-keys))

(defun pen-delay-memoise ()
  (interactive)
  (memoize-restore 'pen-prompt-snc)
  (memoize 'pen-prompt-snc))

;; (add-hook 'after-make-frame-functions 'pen-default-add-keys)
(add-hook 'after-init-hook 'pen-delay-add-keys)
(add-hook 'after-init-hook 'pen-acolyte-scratch)
(add-hook 'after-init-hook 'pen-load-config t)
(add-hook 'after-init-hook 'pen-delay-memoise)

(add-hook 'after-init-hook 'pen-load-config t)

(define-key pen-map (kbd "C-c n") #'nbfs)

;; This makes a prefix in the ~/.pen directory for the memoization cache
(setq pen-memo-prefix (pen-get-hostname))

(memoize-restore 'pen-prompt-snc)
(memoize 'pen-prompt-snc)

;; (pen-etv (pen-prompt-snc "rand" 1))

(require 'evil)

;; Multiline fuzzy-finder doesn't work too well with helm
;; Helm breaks each entry up into more lines
;; I should make the magit completions selector anyway
(ivy-mode 1)

;; https://www.emacswiki.org/emacs/TheMysteriousCaseOfShiftedFunctionKeys

(defset pen-fz-commands '(pen-lg-display-page
                          pen-browse-url-for-passage
                          pen-add-to-glossary))

(defun pen-run ()
  (interactive)
  (let ((fun (intern (fz pen-fz-commands nil nil "pen run: "))))
    (call-interactively fun)))

(define-key pen-map (kbd "H-l") 'pen-run)


;; code M-SPC c
;; prose H-"
;; math H-#

;; (defun metaize-keybind (b)
;;   (-cx '("M-" "") (s-split " " b)))

(defmacro pen-define-key-easy (bind fun)
  ""
  (append
   '(progn)
   (flatten-once
    (cl-loop for bind-i in
          (list bind
                (concat "M-" (s-replace-regexp " " " M-" bind)))
          collect
          `((define-key pen-map (kbd ,(concat "H-TAB " bind-i)) ,fun)
            ;; Hyper-Space
            (define-key pen-map (kbd ,(concat "H-SPC " bind-i)) ,fun)
            ;; Can't use M-Q because tmux uses thats
            ;; (define-key pen-map (kbd ,(concat "M-Q " bind-i)) ,fun)
            (define-key pen-map (kbd ,(concat "M-u " bind-i)) ,fun)
            (define-key pen-map (kbd ,(concat "<H-tab> " bind-i)) ,fun)
            (define-key pen-map (kbd ,(concat "M-SPC " bind-i)) ,fun)
            (define-key pen-map (kbd ,(concat "M-SPC TAB " bind-i)) ,fun)
            (define-key pen-map (kbd ,(concat "M-SPC C-M-i " bind-i)) ,fun))))))
(defalias 'pen-dk-easy 'pen-define-key-easy)

(defmacro pen-dk-htab (bind fun)
  ""
  (append
   '(progn)
   (flatten-once
    (cl-loop for bind-i in
          (list bind
                (concat "M-" (s-replace-regexp " " " M-" bind)))
          collect
          `((define-key pen-map (kbd ,(concat "H-TAB " bind-i)) ,fun)
            (define-key pen-map (kbd ,(concat "<H-tab> " bind-i)) ,fun))))))

;; Actually, I want to run prompts this way
;; C-M-i is the same as M-C-i. No such thing as C-M-TAB.
(define-key global-map (kbd "M-SPC") #'indent-for-tab-command)

(defun pen-reload ()
  (interactive)
  (load-library "pen")
  (if (>= (prefix-numeric-value current-prefix-arg) 4)
      (pen-sps "pen-e rla"))
  (pen-generate-prompt-functions)
  (pen-load-config)
  ;; (if (not (pen-container-running-p))
  ;;     (message "Please start the Pen.el server first by running pen in a terminal.")
  ;;   (pen-client-generate-functions))
  (ignore-errors (pen-client-generate-functions)))

;; I could actually use codex to generate DWIM key bindings from function names
(defun pen-define-maps ()
  (interactive)

  ;; Most main pen commands should be under hyperspace
  ;; hyperspace x

  ;; Basic completion functions
  (pen-dk-easy "1" 'pen-complete-word)
  (pen-dk-easy "2" 'pen-complete-words)
  (pen-dk-easy "3" 'pen-complete-line)
  (pen-dk-easy "4" 'pen-complete-lines)
  (pen-dk-easy "5" 'pen-complete-long)

  (pen-dk-easy ";" 'sps-nlsh)
  (pen-dk-easy "A" 'pf-append-to-code/3)
  (pen-dk-easy "N" 'sps-nlsc)
  (pen-dk-easy "S" 'pen-complete-short)
  (pen-dk-easy "P" 'pen-complete-long)
  (pen-dk-easy "^" 'pen-transform)

  ;; c Code
  (pen-dk-easy "c" nil)
  (pen-dk-easy "c b" 'pf-generate-the-contents-of-a-new-file/6)
  (pen-dk-easy "c g g" 'pf-generate-program-from-nl/3)
  (pen-dk-easy "c g r" 'pf-gpt-j-generate-regex/2)
  (pen-dk-easy "c h" 'pf-generic-tutor-for-any-topic/2)
  (pen-dk-easy "c n" 'pen-select-function-from-nl)
  (pen-dk-easy "c p" 'pf-imagine-a-project-template/1)
  (pen-dk-easy "c t" 'pen-transform-code)
  (pen-dk-easy "c l" 'pf-transpile/3)

  ;; apostrophe (chatbots)
  (pen-dk-easy "a" nil)
  (pen-dk-easy "a c" 'apostrophe-start-chatbot-from-selection)

  ;; p Prose
  (pen-dk-easy "p" nil)
  (pen-dk-easy "p t" 'pen-transform-prose)
  (pen-dk-easy "p l" 'pf-translate/3)
  (pen-dk-easy "p v" 'pf-very-witty-pick-up-lines-for-a-topic/1)

  ;; f Fun
  (pen-dk-easy "f" nil)
  (pen-dk-easy "f p" 'pf-very-witty-pick-up-lines-for-a-topic/1)

  ;; g Generate
  (pen-dk-easy "g" nil)
  (pen-dk-easy "G" 'pen-reload)
  (pen-dk-easy "g a" (dff (pen-context 5 (call-interactively 'pf-append-to-code/3))))
  (pen-dk-easy "g n" 'pf-code-snippet-from-natural-language/2)
  (pen-dk-easy "g p" 'pf-generate-perl-command/1)
  (pen-dk-easy "g b" 'pf-write-a-blog-post/2)
  (pen-dk-easy "g e" 'pf-get-an-example-of-the-usage-of-a-function/2)

  ;; e Example
  (pen-dk-easy "e" nil)
  (pen-dk-easy "e f" 'pf-get-an-example-of-the-usage-of-a-function/2)
  ;; e Explain
  (pen-dk-easy "e c" 'pf-explain-some-code/2)
  (pen-dk-easy "e t" 'pf-explain-some-code-with-steps/1)
  (pen-dk-easy "e x" 'pf-explain-the-syntax-of-code/1)
  (pen-dk-easy "e b" 'pf-explain-a-file/4)
  (pen-dk-easy "e y" 'pf-explain-why-this-code-is-needed/2)

  ;; a Ask tutor / Apostrophe
  (pen-dk-easy "a" nil)
  (pen-dk-easy "a t" 'pf-asktutor/3)
  (pen-dk-easy "a q" 'pf-generic-tutor-for-any-topic/2)
  (pen-dk-easy "a s" 'apostrophe-start-chatbot-from-selection)
  (pen-dk-easy "a c" 'apostrophe-start-chatbot-from-selection)
  (pen-dk-easy "a n" 'apostrophe-start-chatbot-from-name)
  (pen-dk-easy "a w" 'apostrophe-chat-about-selection)

  ;; h Help
  (pen-dk-easy "h" nil)
  (pen-dk-easy "h f /" 'pen-select-function-from-nl)
  (pen-dk-easy "h f i" 'pf-given-a-function-name-show-the-import/2)
  (pen-dk-easy "h f u" 'pf-how-to-use-a-function/2)
  (pen-dk-easy "h c" 'pf-explain-some-code/2)
  (pen-dk-easy "i" 'pen-insert-snippet-from-lm)
  (pen-dk-easy "l" nil)
  (pen-dk-easy "l x" 'pen-autofix-lsp-errors)

  ;; m Math
  (pen-dk-easy "m" nil)
  (pen-dk-easy "m e" 'pf-translate-math-into-natural-language/1)
  (pen-dk-easy "m l" 'pf-convert-ascii-to-latex-equation/1)

  ;; d Define
  (pen-dk-easy "d" nil)
  (pen-dk-easy "d 1" 'pf-define-word-for-glossary/1)
  (pen-dk-easy "d d" 'pf-define-word-for-glossary/1)
  (pen-dk-easy "d 2" 'pf-define-word-for-glossary/2)

  ;; n Explain
  (pen-dk-easy "n" nil)
  (pen-dk-easy "n 2" 'pf-explain-some-code/2)
  (pen-dk-easy "n b" 'pf-explain-code-with-bulleted-docstring/1)
  (pen-dk-easy "n x" 'pf-explain-the-syntax-of-code/1)
  (pen-dk-easy "n h" 'pf-explain-haskell-code/1)
  (pen-dk-easy "n s" 'pf-explain-solidity-code/1)
  (pen-dk-easy "n s" 'pf-explain-some-code-with-steps/1)

  ;; t Transform
  (pen-dk-easy "t" nil)
  (pen-dk-easy "t t" 'pen-transform)
  (pen-dk-easy "t c" 'pen-transform-code)
  (pen-dk-easy "t p" 'pen-transform-prose)
  (pen-dk-easy "t r" 'pf-translate/3)
  (pen-dk-easy "t l" 'pf-transpile/3)

  ;; misc
  (pen-dk-easy "w" 'pen-transform)
  (pen-dk-easy "^" 'pen-transform)
  (pen-dk-easy "x" 'pen-diagnostics-show-context)
  ;; (pen-dk-easy "0" 'kill-buffer-and-window)
  (pen-dk-easy "r" 'pf-transpile/3)
  (pen-dk-easy "L" 'pf-translate/3)
  (pen-dk-easy "u" (dff (pen-etv (pf-transpile/3 nil nil (sor pen-fav-programming-language)))))
  (pen-dk-easy "w" (dff (pen-etv (pf-transpile/3 nil nil (sor pen-fav-world-language)))))

  (pen-dk-easy "m" 'pen-complete-medium)
  (pen-dk-easy "s" 'pen-filter-with-prompt-function)
  (pen-dk-easy "y" 'pen-run-analyser-function)
  (pen-dk-easy "d" 'pen-run-editing-function)
  (pen-dk-easy "i" 'pen-start-imaginary-interpreter)
  (pen-dk-easy "j" 'pf-prompt-until-the-language-model-believes-it-has-hit-the-end/1)
  (pen-dk-easy "r" 'pen-run-prompt-function)
  (pen-dk-easy "R" 'pen-run-prompt-alias)
  (pen-dk-easy "h" 'pen-copy-from-hist)
  (pen-dk-easy "k" 'pen-go-to-last-results-dir)
  (pen-dk-easy "o" 'pen-continue-from-hist)
  (pen-dk-easy "n" 'pen-select-function-from-nl)
  (pen-dk-easy "H" 'pf-generic-tutor-for-any-topic/2)
  (pen-dk-easy "b" 'pf-generate-the-contents-of-a-new-file/6)

  ;; templates
  (pen-dk-easy "T" nil)
  (pen-dk-easy "T P" 'pf-imagine-a-project-template/1)

  (pen-dk-htab "c" 'pen-company-complete)
  (pen-dk-htab "f" 'pen-company-complete-choose)
  (pen-dk-htab "a" 'pen-company-complete-add)
  (pen-dk-htab "l" 'pen-complete-long)

  ;; Overrides
  (pen-dk-htab "g" 'pen-reload)
  (pen-dk-htab "e" 'pen-customize)

  (define-key pen-map (kbd "M-1") 'pen-complete-word)
  (define-key pen-map (kbd "M-2") 'pen-complete-words)
  ;; (define-key pen-map (kbd "M-3") 'pen-complete-line)
  (define-key pen-map (kbd "M-3") 'pen-complete-line-maybe)
  (define-key pen-map (kbd "M-4") 'pen-complete-lines)
  (define-key pen-map (kbd "M-5") 'pen-complete-long)

  ;; Treat <S-f9> as a prefix key for pen
  (define-key pen-map (kbd "H-^") 'pen-transform)
  (define-key pen-map (kbd "<S-f9> Y") 'pen-add-to-glossary)
  (define-key pen-map (kbd "<S-f9> G") 'pen-define-general-knowledge)
  (define-key pen-map (kbd "<S-f9> L") 'pen-define-detectlang)
  (define-key pen-map (kbd "<S-f9> T") 'pen-define-word-for-topic)
  (define-key pen-map (kbd "<f12>") nil)
  (define-key pen-map (kbd "<f11>") nil)
  (define-key pen-map (kbd "<f10>") nil)
  (define-key pen-map (kbd "<S-f12>") 'pen-add-to-glossary)
  (define-key pen-map (kbd "<S-f11>") 'pen-define-general-knowledge)
  (define-key pen-map (kbd "<S-f10>") 'pen-define-detectlang)
  (define-key pen-map (kbd "<S-f8>") 'pen-define-word-for-topic)
  (define-key pen-map (kbd "H-@") 'pen-see-pen-command-hist)
  (define-key pen-map (kbd "M-l M-y") 'pen-copy-link-at-point)
  (define-key pen-map (kbd "M-k") 'avy-goto-char))

(pen-define-maps)

;; complex terminal commands
(define-key pen-map (kbd "M-SPC ` n") 'pf-next-terminal-command-from-nl/3)

;; (add-to-list 'pen-editing-functions 'pen-lsp-explain-error)

(setq pen-editing-functions (append pen-editing-functions
                                    '(
                                      pen-lsp-explain-error
                                      pf-explain-error/2
                                      rcm-explain-code
                                      pf-prompt-until-the-language-model-believes-it-has-hit-the-end/1
                                      pf-translate-from-world-language-x-to-y/3
                                      pf-tldr-summarization/1
                                      pf-clean-prose/1
                                      pf-correct-grammar/1
                                      rcm-generate-program
                                      pf-transform-code/3
                                      pf-gpt-j-generate-regex/2
                                      pf-transpile-from-programming-language-x-to-y/3
                                      pen-tutor-mode-assist
                                      pf-thesaurus/1
                                      pf-get-an-example-sentence-for-a-word/1
                                      pf-get-an-example-of-the-usage-of-a-function/2
                                      pen-detect-language-context
                                      pf-get-documentation-for-syntax-given-screen/2
                                      rcm-term
                                      pen-autofix-lsp-errors
                                      pf-explain-why-this-code-is-needed/2
                                      pf-explain-some-code-with-steps/1
                                      pf-explain-some-code/2
                                      pf-explain-some-code/1
                                      pf-explain-solidity-code/1
                                      pf-explain-haskell-code/1
                                      pf-explain-code-with-bulleted-docstring/1)))



(define-key global-map (kbd "M-2") #'company-lsp)

;; (call-interactively 'pen-add-key-booste)

(add-hook 'emacs-lisp-mode-hook '(lambda () (lispy-mode 1)))


(advice-add 'kill-buffer-and-window :around #'ignore-errors-around-advice)

;; (defun pen-kill-ring-save (beg end &optional region)
;;   (interactive (list (mark) (point)
;; 		                 (prefix-numeric-value current-prefix-arg)))
;;   (let ((res (kill-ring-save beg end region)))
;;     (xc (car kill-ring))
;;     res))

(defun kill-ring-save-around-advice (proc &rest args)
  (let ((res (apply proc args)))
    (xc (car kill-ring) t)
    res))

(if (inside-docker-p)
    (progn
      (advice-add 'dired-copy-filename-as-kill :around #'kill-ring-save-around-advice)
      (advice-add 'kill-ring-save :around #'kill-ring-save-around-advice)))

;; swapped <Insert> and C-M-i (reverses tmux's swap)
(define-key key-translation-map (kbd "<insertchar>") (kbd "C-M-i"))
;; (define-key key-translation-map (kbd "C-M-i") (kbd "<insertchar>"))
(define-key key-translation-map (kbd "C-M-i") nil)

;; (advice-remove 'kill-ring-save #'kill-ring-save-around-advice)

(setq pen-fav-programming-language "Emacs Lisp")
(setq pen-fav-world-language "English")

;; C-M-] is the help key, which replaces C-h
;; C-h is used for backspace, like the rest of terminal world.
;; C-M-o is also maped to DEL.
;; C-c h becomes the help-map

(define-key key-translation-map (kbd "C-M-]") (kbd "<help>"))
(global-set-key (kbd "C-M-o") (kbd "DEL"))
(define-key helm-map (kbd "C-h") nil)
(define-key helm-map (kbd "C-h c") nil)
(define-key helm-map (kbd "C-h C-d") nil)
(define-key helm-map (kbd "C-h") (kbd "DEL"))
(define-key isearch-mode-map (kbd "C-h") #'isearch-delete-char)
(define-key global-map (kbd "C-h") (kbd "DEL"))
(global-set-key (kbd "C-c h") help-map)

;; Hyperify is bound to M-h because it's not
;; possible to press M-SPC or C-M-\ while in the
;; web app
(define-key global-map (kbd "M-h") nil)
(define-key function-key-map (kbd "M-h") 'hyperify)

(add-to-list 'default-frame-alist '(set-foreground-color "white"))
;; American flag red background theme was a cool idea, but impractical.
;; (add-to-list 'default-frame-alist '(set-background-color "#660000"))
(add-to-list 'default-frame-alist '(set-background-color "#1e1e1e"))
(remove-from-list 'default-frame-alist '(set-background-color "#660000"))

;; This is still needed for term/cterm, for some reason
(pen-term-set-raw-map)

;; Easily kill comint buffers
(setq kill-buffer-query-functions nil)
;; But ensure that I still avoid killing scratch
(add-hook 'kill-buffer-query-functions #'pen-dont-kill-scratch)

(setq initial-major-mode 'text-mode)

;; The thin client
(require 'pen-client)

;; (imacro generate-fibonacci (n))

;; (idefun
;;  translate-code
;;
;;  (string target-language)
;;  ;; "Translate STRING from its source language into TARGET-LANGUAGE and output it to the echo area."
;;  )
;;
;; (translate "def my_function(alpha, papa):" "python to elisp")

;; For VSCode terminal
;; (define-key pen-map (kbd "M-m") 'right-click-context-menu)

(define-key pen-map (kbd "C-M-e") (kbd "C-e"))
(define-key selected-keymap (kbd "w") 'kill-ring-save)
;; (define-key org-mode-map (kbd "M-h") nil)
(define-key org-mode-map (kbd "M-h") 'org-mark-element)

(if (inside-docker-p)
    (progn
      (define-key pen-map (kbd "M-l s") 'pen-sph)
      (define-key pen-map (kbd "M-l M-s") nil)
      (define-key pen-map (kbd "M-l M-s M-d") 'yas-describe-tables)
      (define-key pen-map (kbd "M-l S") 'pen-spv)
      (define-key pen-map (kbd "M-l M-S") 'pen-spv)
      (define-key pen-map (kbd "M-l n") 'pen-nw)
      (define-key pen-map (kbd "M-l M-n") 'pen-nw)
      (define-key pen-map (kbd "M-l N") 'pen-sps)
      (define-key pen-map (kbd "M-l M-N") 'pen-sps)))

(pen-autosuggest-mode t)

;; Initial load of prompt functions
(pen-reload)

(setq transient-history-file "~/.pen/transient-history.el")
(setq transient-values-file "~/.pen/transient-values.el")

(define-key global-map (kbd "C-x t e") 'toggle-debug-on-error)

(define-key global-map (kbd "M-^") 'pen-cd-vc-cd-top-level)

(define-key pen-map (kbd "M-\"") 'pen-helm-fzf)
(define-key pen-map (kbd "M-U") 'dired-here)

;; Convenience functions for making and editing bindings
(define-key pen-map (kbd "M-l M-r M-f") 'goto-function-from-binding)
(define-key pen-map (kbd "M-l M-r M-o") 'get-map-for-key-binding)
(define-key pen-map (kbd "M-l M-r M-k") 'pen-ead-binding)
(define-key pen-map (kbd "M-l M-r M-M") 'copy-keybinding-as-table-row-or-macro-string)
(define-key pen-map (kbd "M-l M-r M-n") 'yank-function-from-binding)
(define-key pen-map (kbd "M-l M-r M-m") 'record-keyboard-macro-string)

(if (inside-docker-p)
    (define-key pen-map (kbd "<M-f4>") 'pen-revert-kill-buffer-and-window))

;; Perhaps this should also kill the emacsclient
;; (define-key pen-map (kbd "<S-M-f4>") 'pen-save-and-kill-buffer-and-window)
;; (define-key pen-map (kbd "<S-M-f4>") 'pen-revert-and-quit-emacsclient-without-killing-server)

;; Quit Pen
(if (inside-docker-p)
    (define-key pen-map (kbd "<M-f1>") 'pen-kill-buffer-and-frame))

;; Wow, it also works in the web interface
;; I should remember that for future bindings, using Shift-Meta bypasses google chrome Meta bindings
(define-key pen-map (kbd "<S-M-f4>") 'pen-save-and-kill-buffer-window-and-emacsclient)

(require 'eterm-256color)
(set-face-background 'eterm-256color-black nil)
(set-face-foreground 'eterm-256color-black "#000000")
;; This is needed for zsh
(set-face-foreground 'eterm-256color-bright-black "#303030")


(define-key pen-map (kbd "M-l M-.") 'pen-kill-buffer-immediately)

(define-key pen-map (kbd "M-l M-m") 'switch-to-previous-buffer)

(define-key pen-map (kbd "M-l f r") 'helm-mini)
(define-key pen-map (kbd "M-l M-r M-g") 'find-function)

(define-key pen-map (kbd "M-l M-r M-i") 'channel-say-something)
(define-key pen-map (kbd "M-l M-r M-l") 'channel-loop-chat)

(define-key pen-map (kbd "C-c C-o") 'org-open-at-point)

(define-key pen-map (kbd "H-c") 'pf-continue-last)

(define-key pen-map (kbd "M-l M-e") 'pen-revert)

(define-key pen-map (kbd "M-\"") 'pen-helm-fzf)
(define-key pen-map (kbd "M-L") 'helm-buffers-list)
(define-key pen-map (kbd "M-K") 'pen-swipe)
(define-key pen-map (kbd "M-S") 'pen-swipe)

(define-key pen-map (kbd "M-y") nil)
(define-key pen-map (kbd "M-y M-p") #'pen-yank-path)
(define-key pen-map (kbd "M-y M-d") #'pen-yank-dir)
(define-key pen-map (kbd "M-y M-f") #'pen-yank-file)
(define-key pen-map (kbd "M-y M-p") #'pen-yank-path)
(define-key pen-map (kbd "M-y M-g") #'pen-yank-git-path)
(define-key pen-map (kbd "M-y M-o") #'open-git-path-chrome)
(define-key pen-map (kbd "M-y M-m") #'pen-yank-git-path-master)
(define-key pen-map (kbd "M-y M-G") #'pen-yank-git-path-sha)

(require 'counsel)

;; ;; This is too slow
;; (global-set-key (kbd "M-x") 'helm-M-x)

(defun pen-counsel-M-x ()
  (interactive)
  (counsel-M-x ""))

(global-set-key (kbd "M-x") 'pen-counsel-M-x)
(global-set-key (kbd "M-/") 'hippie-expand)
(require 'expand-region)
(global-set-key (kbd "M-r") 'er/expand-region)

(define-key pen-map (kbd "M-m f r") 'helm-mini) ; recent
(define-key pen-map (kbd "M-m f R") 'pen-sps-ranger)

;; (define-key pen-map (kbd "M-\"") nil)
(define-key pen-map (kbd "M-m f z") 'pen-helm-fzf)
(define-key pen-map (kbd "M-m f Z") 'pen-helm-fzf-top)
(define-key pen-map (kbd "M-m f f") 'pen-helm-find-files)
;; This is needed or the combination M-l M-w M-l M-t will cause problems
(define-key pen-map (kbd "M-l M-w") 'pen-save)
(define-key global-map (kbd "C-x ;") 'comment-line)

(defun eval-last-sexp-unknown ()
  (interactive)
  (message "%s" (concat "C-x C-e unbound for " (str major-mode))))
(define-key global-map (kbd "C-x C-e") 'eval-last-sexp-unknown)
(define-key emacs-lisp-mode-map (kbd "C-x C-e") 'eval-last-sexp)

(if (inside-docker-p)
    (progn
      (define-key pen-map (kbd "M-p") #'pen-previous-defun)
      (define-key pen-map (kbd "M-n") #'pen-next-defun)
      (define-key pen-map (kbd "M-C-m") #'pen-enter-edit-emacs)))

(define-key pen-map (kbd "M-[ M-h") #'git-gutter+-previous-hunk)
(define-key pen-map (kbd "M-] M-h") #'git-gutter+-next-hunk)


;; Make paste work in the GUI version
(define-key global-map (kbd "<M-f3>") (kbd "C-y"))

(define-key pen-map (kbd "C-M-k") 'previous-line)
(define-key pen-map (kbd "C-M-j") 'next-line)
;; See: [[$HOME/var/smulliga/source/git/config/emacs/config/my-backspace.el][my-backspace.el]]
(define-key pen-map (kbd "C-M-l") 'right-char)

(define-key global-map (kbd "M-i") 'iedit-mode)

(if (inside-docker-p)
    (progn
      (define-key global-map (kbd "M-q") nil)
      ;; These work in term but nowhere else
      (define-key global-map (kbd "M-q v") #'open-in-vim)
      (define-key global-map (kbd "M-q V") #'e/open-in-vim)
      (define-key global-map (kbd "M-q M-V") #'e/open-in-vim)
      (define-key global-map (kbd "M-q M-v") #'open-in-vim) ;This is like vim's M-q M-m for opening in emacs in the current pane

      ;; These work everywhere except term
      (define-key pen-map (kbd "M-q v") #'open-in-vim)
      (define-key pen-map (kbd "M-q V") #'e/open-in-vim)
      (define-key pen-map (kbd "M-q M-V") #'e/open-in-vim)
      (define-key pen-map (kbd "M-q M-v") #'open-in-vim) ;This is like vim's M-q M-m for opening in emacs in the current pane

      ;; (define-key pen-map (kbd "M-l V") #'e/open-in-vim)
      (define-key pen-map (kbd "M-l M-V") #'e/open-in-vim)))

(provide 'pen-example-config)
