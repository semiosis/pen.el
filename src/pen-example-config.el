;; This was interfering with completion
(setq company-backends '())

(let ((pendir (f-join user-emacs-directory "pen.el"))
      (contribdir (f-join user-emacs-directory "pen-contrib.el")))
  (add-to-list 'load-path (f-join pendir "src"))
  (add-to-list 'load-path (f-join contribdir "src"))
  (add-to-list 'load-path (f-join pendir "src/in-development")))

;; Add Hyper and Super
(defun add-event-modifier (string e)
  (let ((symbol (if (symbolp e) e (car e))))
    (setq symbol (intern (concat string
                                 (symbol-name symbol))))
    (if (symbolp e)
        symbol
      (cons symbol (cdr e)))))

(defun superify (prompt)
  (let ((e (read-event)))
    (vector (if (numberp e)
                (logior (lsh 1 23) e)
              (if (memq 'super (event-modifiers e))
                  e
                (add-event-modifier "s-" e))))))

(defun hyperify (prompt)
  (let ((e (read-event)))
    (vector (if (numberp e)
                (logior (lsh 1 24) e)
              (if (memq 'hyper (event-modifiers e))
                  e
                (add-event-modifier "H-" e))))))

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

;; Camille-complete (because I press SPC to replace)
(defalias 'camille-complete 'pen-run-prompt-function)

(require 'selected)
(define-key selected-keymap (kbd "SPC") 'pen-run-prompt-function)
(define-key selected-keymap (kbd "M-SPC") 'pen-run-prompt-function)
;; (define-key selected-keymap (kbd "A") 'pf-define-word-for-glossary/1)
(define-key selected-keymap (kbd "A") 'pen-add-to-glossary)

(pen-define-key pen-map (kbd "H-TAB j") 'pf-prompt-until-the-language-model-believes-it-has-hit-the-end/1)
(pen-define-key pen-map (kbd "H-TAB r") 'pen-run-prompt-function)
(pen-define-key pen-map (kbd "H-TAB R") 'pen-run-prompt-alias)
;; (define-key pen-map (kbd "H-1") 'pen-company-filetype-word)
;; (define-key pen-map (kbd "H-2") 'pen-company-filetype-words)
;; (define-key pen-map (kbd "H-3") 'pen-company-filetype-line)
;; (define-key pen-map (kbd "H-4") 'pen-company-filetype-long)
(define-key pen-map (kbd "H-1") 'pen-complete-word)
(define-key pen-map (kbd "H-2") 'pen-complete-words)
(define-key pen-map (kbd "H-3") 'pen-complete-line)
(define-key pen-map (kbd "H-4") 'pen-complete-lines)
(define-key pen-map (kbd "H-5") 'pen-complete-long)
(define-key pen-map (kbd "H-P") 'pen-complete-long)
(define-key pen-map (kbd "H-b") 'pf-generate-the-contents-of-a-new-file/6)
(define-key pen-map (kbd "H-TAB m") 'pen-complete-medium)
(pen-define-key pen-map (kbd "H-TAB g") 'pen-generate-prompt-functions)
(define-key pen-map (kbd "H-s") 'fz-pen-counsel)
(pen-define-key pen-map (kbd "H-TAB s") 'pen-filter-with-prompt-function)
(pen-define-key pen-map (kbd "H-TAB y") 'pen-run-analyser-function)
(pen-define-key pen-map (kbd "H-TAB d") 'pen-run-editing-function)
(pen-define-key pen-map (kbd "H-TAB i") 'pen-start-imaginary-interpreter)
(define-key pen-map (kbd "H-n") 'global-pen-acolyte-minor-mode)
(define-key pen-map (kbd "H-.") 'global-pen-acolyte-minor-mode)
(define-key pen-map (kbd "H-:") 'pen-compose-cli-command)
(define-key pen-map (kbd "H-x") 'pen-diagnostics-show-context)
(pen-define-key pen-map (kbd "H-TAB e") 'pen-customize)

;; Most main pen commands should be under hyperspace
;; hyperspace x
(pen-define-key pen-map (kbd "H-SPC x") 'pen-diagnostics-show-context)

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
 (contribhostdir (f-join user-emacs-directory "host/pen-contrib.el")))

;; Personal pen.el repository
(let ((hostpeneldir (f-join user-emacs-directory "host" "pen.el")))
  (if (f-directory-p (f-join hostpeneldir "pen.el"))
      (setq pen-penel-directory hostpeneldir)
    (setq pen-penel-directory (f-join user-emacs-directory "pen.el"))))

;; Personal prompts repository
(let ((hostpromptsdir (f-join user-emacs-directory "host" "prompts")))
  (if (f-directory-p (f-join hostpromptsdir "prompts"))
      (setq pen-prompts-directory hostpromptsdir)
    (setq pen-prompts-directory (f-join user-emacs-directory "prompts"))))

;; Personal engines repository
(let ((hostenginesdir (f-join user-emacs-directory "host" "engines")))
  (if (f-directory-p (f-join hostenginesdir "engines"))
      (setq pen-engines-directory hostenginesdir)
    (setq pen-engines-directory (f-join user-emacs-directory "engines"))))

;; Personal glossaries repository
(let ((hostglossariesdir (f-join user-emacs-directory "host" "glossaries")))
  (if (f-directory-p (f-join hostglossariesdir "glossaries"))
      (setq pen-glossaries-directory hostglossariesdir)
    (setq pen-glossaries-directory (f-join user-emacs-directory "glossaries"))))

;; nlsh
(setq pen-nlsh-histdir (f-join user-emacs-directory "comint-history"))

;; Initial load of prompt functions
(pen-generate-prompt-functions)

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
(defun pen-acolyte-dired-prompts ()
  (interactive)
  (dired pen-prompts-directory))

(defun pen-acolyte-scratch ()
  (interactive)
  (switch-to-buffer "*scratch*"))

;; defvar this in your own config and load first to disable
(defvar pen-init-with-acolyte-mode t)

(if pen-init-with-acolyte-mode
    (global-pen-acolyte-minor-mode t))

(package-install 'ivy)
(require 'ivy)
(ivy-mode 1)

(setq message-log-max 20000)

(right-click-context-mode t)
(pen-acolyte-scratch)

(let ((pen-openai-key-file-path (f-join penconfdir "openai_api_key")))
  (if (not (f-file-p pen-openai-key-file-path))
      (let ((envkey (getenv "OPENAI_API_KEY")))
        (if (sor envkey)
            (pen-add-key-openai envkey)
          ;; Automatically check if OpenAI key exists and ask for it otherwise
          (call-interactively 'pen-add-key-openai)))))

(let ((pen-aix-key-file-path (f-join penconfdir "aix_api_key")))
  (if (not (f-file-p pen-aix-key-file-path))
      (let ((envkey (getenv "AIX_API_KEY")))
        (if (sor envkey)
            (pen-add-key-aix envkey)
          ;; Automatically check if Aix key exists and ask for it otherwise
          (call-interactively 'pen-add-key-aix)))))

(let ((pen-hf-key-file-path (f-join penconfdir "hf_api_key")))
  (if (not (f-file-p pen-hf-key-file-path))
      (let ((envkey (getenv "HF_API_KEY")))
        (if (sor envkey)
            (pen-add-key-hf envkey)
          ;; Automatically check if Hf key exists and ask for it otherwise
          (call-interactively 'pen-add-key-hf)))))

(add-hook 'after-init-hook 'pen-acolyte-scratch)

(setq pen-memo-prefix (pen-get-hostname))

(memoize-restore 'pen-prompt-snc)
(memoize 'pen-prompt-snc)

;; (etv (pen-prompt-snc "rand" 1))

(define-key pen-map (kbd "H-TAB n") 'pen-select-function-from-nl)
(define-key pen-map (kbd "H-TAB h") 'pf-generic-tutor-for-any-topic/2)
(define-key pen-map (kbd "H-TAB p") 'pf-imagine-a-project-template/1)
(define-key pen-map (kbd "H-TAB b") 'pf-generate-the-contents-of-a-new-file/6)

(require 'evil)

;; Multiline fuzzy-finder doesn't work too well with helm
;; Helm breaks each entry up into more lines
;; I should make the magit completions selector anyway
(ivy-mode 1)

;; https://www.emacswiki.org/emacs/TheMysteriousCaseOfShiftedFunctionKeys

;; Treat <S-f9> as a prefix key for pen
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

(defset pen-fz-commands '(pen-lg-display-page
                          pen-browse-url-for-passage
                          pen-add-to-glossary))

(defun pen-run ()
  (interactive)
  (let ((fun (intern (fz pen-fz-commands nil nil "pen run: "))))
    (call-interactively fun)))

(define-key pen-map (kbd "H-l") 'pen-run)

(defun sps-nlsc (os)
  (interactive (list (pen-detect-language-ask)))
  (sps (cmd "eterm" "nlsc" os)))

(defun sps-nlsh (os)
  (interactive (list (fz (ilist 20 "distinctive linux distributions including nixos")
                         nil nil "sps-nlsh OS: ")))
  (sps (cmd "eterm" "nlsh" os)))


;; code M-SPC c
;; prose H-"
;; math H-#

(setq pen-fav-programming-language "Emacs Lisp")
(setq pen-fav-world-language "English")

;; Actually, I want to run prompts this way
;; C-M-i is the same as M-C-i. No such thing as C-M-TAB.
(define-key global-map (kbd "M-SPC") #'indent-for-tab-command)

;; g is for generation
(define-key pen-map (kbd "M-SPC g b") 'pf-write-a-blog-post/2)
;; U is for understand
(define-key pen-map (kbd "M-SPC r") 'pf-transpile/3)
(define-key pen-map (kbd "M-SPC t") 'pen-transform-prose)
(define-key pen-map (kbd "M-SPC u") (dff (etv (pf-transpile/3 nil nil (sor pen-fav-programming-language)))))
(define-key pen-map (kbd "M-SPC w") (dff (etv (pf-transpile/3 nil nil (sor pen-fav-world-language)))))

(define-key pen-map (kbd "H-^") 'pen-transform)
(define-key pen-map (kbd "M-SPC ^") 'pen-transform)
(define-key pen-map (kbd "M-SPC w") 'pen-transform)
(define-key pen-map (kbd "M-SPC t") nil)
(define-key pen-map (kbd "M-SPC t") 'pen-transform)
(define-key pen-map (kbd "M-SPC i") 'pen-insert-snippet-from-lm)
(define-key pen-map (kbd "M-SPC h") nil)
(define-key pen-map (kbd "M-SPC h f u") 'pf-how-to-use-a-function/2)
(define-key pen-map (kbd "M-SPC h f i") 'pf-given-a-function-name-show-the-import/2)
(define-key pen-map (kbd "M-SPC e c") 'pf-explain-some-code/2)
(define-key pen-map (kbd "M-SPC e") nil)
(define-key pen-map (kbd "M-SPC e f") 'pf-get-an-example-of-the-usage-of-a-function/2)
(define-key pen-map (kbd "M-SPC a") nil)
(define-key pen-map (kbd "M-SPC g a") (dff (pen-context 5 (call-interactively 'pf-append-to-code/3))))
(define-key pen-map (kbd "M-SPC A") 'pf-append-to-code/3)
(define-key pen-map (kbd "M-SPC h f /") 'pen-select-function-from-nl)
(define-key pen-map (kbd "M-SPC N") 'sps-nlsc)
(define-key pen-map (kbd "M-SPC ;") 'sps-nlsh)
(define-key pen-map (kbd "M-SPC f") nil)
(define-key pen-map (kbd "M-SPC l") nil)
(define-key pen-map (kbd "M-SPC l x") 'pen-autofix-lsp-errors)
(define-key pen-map (kbd "M-SPC 1") 'pen-complete-word)
(define-key pen-map (kbd "M-SPC 2") 'pen-complete-words)
(define-key pen-map (kbd "M-SPC 3") 'pen-complete-line)
(define-key pen-map (kbd "M-SPC 4") 'pen-complete-lines)
(define-key pen-map (kbd "M-SPC 5") 'pen-complete-long)
(define-key pen-map (kbd "M-SPC P") 'pen-complete-long)
(define-key pen-map (kbd "M-SPC c") nil)
(define-key pen-map (kbd "M-SPC c t") 'pen-transform-code)
(define-key pen-map (kbd "M-SPC g p") 'pf-generate-perl-command/1)
(define-key pen-map (kbd "M-SPC c g r") 'pf-gpt-j-generate-regex/2)
(define-key pen-map (kbd "M-SPC c g g") 'pf-generate-program-from-nl/3)
(define-key pen-map (kbd "H-SPC m e") 'pf-translate-math-into-natural-language/1)
(define-key pen-map (kbd "H-SPC m l") 'pf-convert-ascii-to-latex-equation/1)
(define-key pen-map (kbd "H-SPC c n") 'pen-select-function-from-nl)
(define-key pen-map (kbd "H-SPC c h") 'pf-generic-tutor-for-any-topic/2)
(define-key pen-map (kbd "H-SPC c p") 'pf-imagine-a-project-template/1)
(define-key pen-map (kbd "H-SPC c b") 'pf-generate-the-contents-of-a-new-file/6)

(add-to-list 'pen-editing-functions 'pen-lsp-explain-error)
(add-to-list 'pen-editing-functions 'pf-explain-error/2)
(add-to-list 'pen-editing-functions 'rcm-explain-code)
(add-to-list 'pen-editing-functions 'pf-prompt-until-the-language-model-believes-it-has-hit-the-end/1)
(add-to-list 'pen-editing-functions 'pf-translate-from-world-language-x-to-y/3)
(add-to-list 'pen-editing-functions 'pf-tldr-summarization/1)
(add-to-list 'pen-editing-functions 'pf-clean-prose/1)
(add-to-list 'pen-editing-functions 'pf-correct-grammar/1)
(add-to-list 'pen-editing-functions 'rcm-generate-program)
(add-to-list 'pen-editing-functions 'pf-transform-code/3)
(add-to-list 'pen-editing-functions 'pf-gpt-j-generate-regex/2)
(add-to-list 'pen-editing-functions 'pf-transpile-from-programming-language-x-to-y/3)
(add-to-list 'pen-editing-functions 'pen-tutor-mode-assist)
(add-to-list 'pen-editing-functions 'pf-thesaurus/1)
(add-to-list 'pen-editing-functions 'pf-get-an-example-sentence-for-a-word/1)
(add-to-list 'pen-editing-functions 'pf-get-an-example-of-the-usage-of-a-function/2)
(add-to-list 'pen-editing-functions 'pen-detect-language-context)
(add-to-list 'pen-editing-functions 'pf-get-documentation-for-syntax-given-screen/2)
(add-to-list 'pen-editing-functions 'rcm-term)
(add-to-list 'pen-editing-functions 'pen-autofix-lsp-errors)

(define-key global-map (kbd "M-2") #'company-lsp)

(define-key pen-map (kbd "H-@") 'pen-see-pen-command-hist)

;; (call-interactively 'pen-add-key-booste)
