(use-package hydra
  :ensure t)

;; (require 'pen-utils)
(require 'evil)
(require 'pen-auto-complete)
(require 'selected)
(require 'pen-hydra-window)
(require 'ace-window)

(defmacro sslk (kb &rest body)
  "This lets me write more terse code"
  (let ((f (car body)))
    `(progn
       (let ((spaced
              ;; (sed "s/./& /g" ,kb)
              (s-replace-regexp "\\(.\\)" "\\1 " ,kb)
              )
             (spaced-m
              ;; (sed "s/./M-& /g" ,kb)
              (s-replace-regexp "\\(.\\)" "M-\\1 " ,kb)))

         (ignore-errors (define-key pen-map (kbd (s-replace-regexp "^l" "M-'" (s-replace-regexp " $" "" spaced))) ,f))
         (ignore-errors (define-key global-map (kbd (concat "M-" (s-replace-regexp " $" "" spaced))) ,f))
         (ignore-errors (define-key pen-map (kbd (s-replace-regexp "^l" "M-m" (s-replace-regexp " $" "" spaced))) ,f))
         (ignore-errors (define-key pen-map (kbd (s-replace-regexp "^M-l" "M-m" (s-replace-regexp " $" "" spaced-m))) ,f))
         (ignore-errors (define-key pen-map (kbd (s-replace-regexp "^M-l" "M-'" (s-replace-regexp " $" "" spaced-m))) ,f))
         (ignore-errors (define-key global-map (kbd (s-replace-regexp " $" "" spaced-m)) ,f))))))

(require 'link-hint)

(defvar sel/hydra-stack nil)

(defun sel/hydra-push (expr)
  (push `(lambda () ,expr) sel/hydra-stack))

(defun sel/hydra-pop ()
  (interactive)
  (let ((x (pop sel/hydra-stack)))
    (when x
      (funcall x))))

(defun prehydra ()
  "happens before hydra appears")

(defun posthydra ()
  "happens after hydra appears")

(defun show_hydra ()
  "Start my main hydra."
  (interactive)
  (if (region-active-p)
      (let ((rstart (region-beginning))
            (rend (region-end)))
        (h_x/body))
    (h_nx/body)))

(defun erase_starting_whitespace ()
  "Use sed to erase starting whitespace."
  (pen-region-pipe "sed 's/^\\s\\+//'"))

(defun erase_surrounding_whitespace ()
  "Use sed to erase surrounding whitespace."
  (concat "sed 's/\\s\\+$//'"))

(defun search_code ()
  (interactive)
  (pen-region-pipe "tee >(tm -f -S -tout spv \"searchcode | sp\")"))

(defun google_example ()
  (interactive (list (if (buffer-file-name)
                         (file-name-extension (buffer-file-name))
                       (read-string-hist "egr ext/lang: "))
                     (pen-thing-at-point)))
  (term-sps (concat "cs g " (pen-q ext) " " (pen-q query))))


(defun google_example_literal (ext query)
  (interactive (list (if (buffer-file-name)
                         (file-name-extension (buffer-file-name))
                       (read-string-hist "egr ext/lang: "))
                     (pen-thing-at-point)))
  (term-sps (concat "cs g -l " (pen-q ext) " " (pen-q query))))


;; Make something that optionaly produces a hydra or something else?
;; Nah, forget hydra. Convert the code and move on.
(defmacro mkhydra (name &rest body)
  ""
  `'(defhydra ,name (:exit t
                           :pre (prehydra)
                           :post (posthydra)
                           :color blue
                           :hint nil
                           :columns 4)
      ,@body))

(defmacro convert-hydra-to-sslk (prefix hydra)
  "Generates regular bindings from hydra defintion"
  (cons 'progn
        (let ((result
               (-slice hydra 3)))
          (if (stringp (car result))
              (setq result (cdr result)))

          (setq result
                (mapcar
                 (lambda (l)
                   (-map-indexed
                    (lambda (index item)
                      (if (= index 0) (concat prefix item) item))
                    l))
                 result))

          (cons `(sslk ,prefix nil)
                (mapcar (lambda (l) (cons 'sslk l)) result)))))

(require 'pen-yasnippet)

(global-unset-key "\e'")

;; (require 'pen-syntax-extensions)
;; (pen-load "$MYGIT/config/emacs/config/hydra-org.el")

;; This is very slow to load
;; (pen-load "$MYGIT/config/emacs/config/hydra-elfeed.el")

(defvar norm/hydra-stack nil)

(defun norm/hydra-push (expr)
  (push `(lambda () ,expr) norm/hydra-stack))

(defun norm/hydra-pop ()
  (interactive)
  (let ((x (pop norm/hydra-stack)))
    (when x
      (funcall x))))

(defun prehydra ()
  "Code to execute before hydra appears.")

(defun posthydra ()
  "Code to execute after hydra disappears.")
(require 'helm-config)

(defun helm-copy-to-clipboard ()
  "Copy selection or marked candidates to `helm-current-buffer'.
Note that the real values of candidates are copied and not the
display values."
  (interactive)
  (with-helm-alive-p
    (helm-run-after-exit
     (lambda (cands)
       (with-helm-current-buffer
         (insert (mapconcat (lambda (c)
                              (format "%s" c))
                            cands "\n"))))
     (helm-marked-candidates))))

(defun tmux-kill-other ()
  ""
  (interactive)
  (b pen-tm kill-other))

(defun other-window-1 ()
  ""
  (interactive)
  (other-window 1))

;; This unbinds M-l so it must come first
(convert-hydra-to-sslk "l"
                       (defhydra h_nx (;; "NORMAL"
                                       :exit t
                                       :pre (prehydra)
                                       :post (posthydra)
                                       :color blue
                                       :hint nil
                                       :columns 4

                                       global-map "l"
                                       )
                         "NORMAL"

                         ("*" #'pen-evil-star "evil star")
                         ("(" 'fz-find-dir "fz-find-dir")
                         ("O" 'fz-find-ws "fz-find-ws")
                         (")" 'fz-find-src "fz-find-src")
                         ("T" #'fz-find-file "fz-find-config")
                         ("~" #'lacarte-execute-menu-command "helm menu bar")
                         ("'" #'magit-diff-unstaged-this "vim diff unstaged here")
                         ("\"" #'magit-diff-unstaged "vim diff unstaged")
                         ("J" #'magit-log "magit log")
                         (";" #'other-window-1 "Other window")
                         ("m" #'switch-to-previous-buffer "alternate buffer")
                         ("y" #'link-hint-copy-link "copy link")
                         ("K" #'pen-kill-buffer-and-reopen "Kill buffer and load file")
                         (">" #'rotate-layout "Rotate layout")
                         ("O" #'rotate:even-horizontal "Horizontal")
                         ("u" #'new-buffer-from-tmux-pane-capture "capture pane")
                         ("U" #'new-buffer-from-tmux-main-capture "capture localhost")
                         ("R" #'new-buffer-from-tmux-main-capture-to-english "capture localhost to english")
                         ("1" #'delete-other-windows "only")
                         ("0" #'delete-window "close")
                         ("2" #'split-window-below "hsplit")
                         ("3" #'split-window-right "vsplit")
                         ("S" #'spv "sh v split")
                         ("D" #'pen-swipe "swiper")
                         ("M" #'git-timemachine "git timemachine")
                         ("9" #'describe-foo-at-point "describe")
                         ("h" #'pen-toggle-evil "Toggle Evil")
                         ("l" #'pen-yas-complete "yasnippet menu")
                         ("b" #'list-buffers "List buffers")))

(convert-hydra-to-sslk "lo"
                       (defhydra h_o (:exit t :pre (prehydra) :post (posthydra) :color blue :hint nil :columns 4) ;; "VISUAL: tools"
                         "VISUAL: tools"
                         ("e" (dff (rfilter (lambda (s) (concat "[[egr:" pen-str "]]")))) "egr")
                         ("l" (df h-org-clink (pen-region-pipe "oc")) "oc")
                         ("L" (df h-org-clink-u (pen-region-pipe "org clink -u")) "org clink -u")
                         ("g" (df h-org-clink-g (pen-region-pipe "org clink -g")) "org clink -g")
                         ("u" 'h-org-clink-u "org clink -u")))

(convert-hydra-to-sslk "lf"
                       (defhydra h_f (:exit t :pre (prehydra) :post (posthydra) :color blue :hint nil :columns 4) ;; "VISUAL: filtering"
                         "VISUAL: filtering"
                         ;; ("z" #'filter-selection-with-fzf "apply selected filter from fzf")
                         ("z" #'pen-fwfzf "filter by external filter")
                         ("Z" #'fz-filter-by-elisp-function "filter by elisp function")
                         ("d" #'major-mode-filter "filter by major mode function")
                         ("f" (df fi-with-fzf (pen-region-pipe "pen-tm filter")) "filter with fzf")
                         ("E" (df erase-starting-ws () (pen-sn (concat "sed -i 's/^\\s\\+//' " (pen-q buffer-file-name)))) "erase starting whitespace")
                         ("e" (df efs () (pen-sn (concat "sed -i 's/\\s\\+$//' " (pen-q buffer-file-name)))) "erase free/end whitespace")
                         ("8" (df pep8 () (bash (concat "autopep8 -i \"" buffer-file-name "\""))) "autopep8")
                         ("W" (df fixup-whitespace-line (fixup-whitespace)) "fixup whitespace") ; this only works on a single line
                         ("U" (df fi-uniqnosort (pen-region-pipe "pen-str uniq")) "uniq no sort")
                         ("u" (df fi-uqftln (pen-region-pipe "uq -ftln")) "wrl unquote")
                         (")" (df fi-wrl-parens (pen-region-pipe "wrlp surround '(' ')'")) "wrl parens")
                         ("m" (df fi-mnm (pen-region-pipe "pen-mnm")) "minimise")
                         ("b" (df fi-abbreviate (pen-region-pipe "abbreviate")) "acronymise / abbreviate")
                         ("M" (df fi-umn (pen-region-pipe "pen-umn")) "unminimise")
                         ("o" (df fi-sort-anum (pen-region-pipe "pen-str sort-anum")) "sort anum")
                         ("a" (df fi-ascify (pen-region-pipe "pen-c ascify")) "ascify")
                         ("A" (df fi-anum (pen-region-pipe "pen-c anum")) "[:anum:]")
                         ;; this is save
                         ;; ("s" (df fi-summarize (pen-region-pipe "pen-str summarize")) "summarize")
                         ;; Might as well get the extra bindings by redefining it
                         ;; ("s" 'save-buffer "save-buffer")
                         ("s" 'pen-save "save-buffer")
                         ("S" (df fi-nosymbol (pen-region-pipe "pen-c nosymbol")) "no-symbols")
                         ("q" (df fi-qftln (pen-region-pipe "q -ftln")) "wrl quote")
                         ;; ("q" (df fi-qftln (filter-selection 'qftln)) "wrl quote")
                         ("c" (df fi-upcase (filter-selection 'upcase)) "ucase")
                         ;; ("n" (df fi-uqftln) (pen-region-pipe "uq -ftln") "wrl unquote")
                         ("N" (df fi-qneftln (pen-region-pipe "qne -ftln")) "wrl quote no ends")
                         ;; (","  sel/hydra-pop "exit" :color blue)
                         ("l" #'downcase-region "lcase")
                         ("p" 'pen-pretty-paragraph-selected "Pretty paragraph")
                         ;; ("u" upcase-region "ucase")
                         ("-" (df fi-underline (filter-selection 'udl)) "underline")
                         ("<" (df fi-orgunindent (pen-region-pipe "orgindent -1")) "org unindent")
                         (">" (df fi-orgindent (pen-region-pipe "orgindent")) "org indent")
                         ("," 'fi-unindent "org unindent")
                         ("." 'fi-indent "org indent")
                         ;; ("M--" (filter-selection 'udl) "underline")
                         ;; ("M-u" upcase-region "ucase")
                         ;; ("M-h" (pen-region-pipe "pen-c html-decode") "html-decode")

                         ("t" (df fi-titlecase (pen-region-pipe "pen-c title-case")) "title-case")
                         ;; ("m-,"  sel/hydra-pop "exit" :color blue)
                         ;; Add quoting for the transform hydra too
                         ;; ("q" (pen-region-pipe "q -ftln") "wrl quote")
                         ;; ("M-q" (pen-region-pipe "q -ftln") "wrl quote")
                         ;; ("Q" (pen-region-pipe "uq -ftln") "wrl unquote")
                         ))


(convert-hydra-to-sslk "lg"
                       (defhydra h_ng (:exit t :pre (prehydra) :post (posthydra) :color blue :hint nil :columns 4) ;; "NORMAL: git"
                         "NORMAL: git"
                         ("b" #'pen-magit-blame-toggle "toggle magit blame")
                         ("q" #'magit-blame-quit "quit magit blame")
                         ("a" #'x/git-add-all-below "add all below")
                         ("t" #'sh/git-add-all-below "add all below")
                         ("m" #'sh/git-amend-all-below "amend below")
                         ("'" #'git-d-cached "git d cached")))

(convert-hydra-to-sslk "lX"
                       (defhydra h_nt (:exit t :pre (prehydra) :post (posthydra) :color blue :hint nil :columns 4) ;; "NORMAL: tmux"
                         "NORMAL: tmux"
                         ("a" #'x/git-add-all-below "git add -A .")))

(defmacro unbind-sslk (prefix-chars)
  "Do not return anything."
  ;; body
  `(progn (,@body) nil))

(convert-hydra-to-sslk "le"
                       (defhydra h_ne (:exit t :pre (prehydra) :post (posthydra) :color blue :hint nil :columns 4) ;; "NORMAL: emacs"
                         "NORMAL: emacs"
                         ("e" #'pen-revert "revert")
                         ("x" #'kill-emacs "kill emacs")
                         ("c" #'revert-and-quit-emacsclient-without-killing-server "kill emacsclient")
                         ("m" #'kill-music "kill-music")
                         ("d" (df show-daemonp ()
                                  (let ((d (daemonp)))
                                    (if d
                                        (message d)
                                      (message "not a daemon")
                                      nil))))
                         ("r" #'restart-emacs "restart emacs")
                         ("q" #'pen-quit "quit emacs frame")))

(convert-hydra-to-sslk "lq"
                       (defhydra h_nq (:exit t :pre (prehydra) :post (posthydra) :color blue :hint nil :columns 4) ;; "NORMAL: quoting"
                         "NORMAL: quoting"
                         ;; ("q" (pen-region-pipe "q -ftln") "wrl quote")
                         ("d" #'major-mode-function "run major mode function")
                         ("q" (df fi-wrl-quote (pen-region-pipe "qftln")) "wrl quote")
                         ("l" (df fi-wrl-quote (pen-region-pipe "qftln")) "wrl quote")
                         ("u" (df fi-wrl-unquote (pen-region-pipe "uq -ftln")) "wrl unquote")
                         ("n" (df fi-wrl-quote-ne (pen-region-pipe "qne -ftln")) "wrl quote no ends")))

(convert-hydra-to-sslk "lj"
                       (defhydra h_normal_fuzzy_select (:exit t :pre (prehydra) :post (posthydra) :color blue :hint nil :columns 4) ;; "NORMAL: fuzzy-select"
                         "NORMAL: fuzzy-select"
                         ("i" #'insert-function "select function to insert")
                         ("j" #'helm-switch-major-mode "helm switch major mode")
                         ("d" #'detect-language-set-mode "detect and switch mode")
                         ("a" #'helm-apropos "apropos")))

(defun copy-current-major-mode ()
  (interactive)
  (xc (current-major-mode-string)))

(convert-hydra-to-sslk "lr"
                       (defhydra h_nr (:exit t :pre (prehydra) :post (posthydra) :color blue :hint nil :columns 4) ;; "NORMAL: refactoring"
                         "NORMAL: emacs"
                         ("e" (df efs () (pen-sn (concat "sed -i 's/\\s\\+$//' " (pen-q buffer-file-name)))) "erase free/end whitespace")
                         ("m" #'record-keyboard-macro-string "yank keys")
                         (">" (dff (e "~/.myrc.yaml")) "myrc")
                         ("M" #'copy-keybinding-as-table-row-or-macro-string "yank key binding as table row")
                         ("b" #'copy-keybinding-as-elisp "yank key binding as elisp")
                         ("n" #'yank-function-from-binding "yank function")
                         ("h" #'describe-mode "describe mode")
                         ("k" #'pen-ead-binding "ead binding")
                         ("K" #'pen-ead-binding "ead binding")
                         ;; ("K" #'pen-ead-binding-pen "ead binding pen")
                         ("f" #'goto-function-from-binding "goto function from binding")
                         ("w" #'edit-var-elisp "edit var containing elisp")
                         ("o" #'get-map-for-key-binding "copy the map that provides binding")
                         ("l" #'locate-key-binding "locate key binding binding")
                         ;; ("a" #'annot-edit/add "annotate here")
                         ;; lrr is reserved for a prefix
                         ;; vim +/"lrre" "$EMACSD/config/pen-spacemacs.el"
                         ;; ("r" #'annot-remove "remove annotation")
                         ;; ("-" #'annot-remove "remove annotation")
                         ;; ("]" #'annot-goto-next "next annotation")
                         ;; ("[" #'annot-goto-previous "previous annotation")
                         ("F" #'find-function "find function")
                         ("g" #'find-function "find function")
                         ("j" #'handle-fz-sym "find function")
                         ("v" #'find-variable "find variable")
                         ;; ("t" #'helpful-at-point "helpful thing at point")
                         ("t" 'describe-thing-at-point "describe thing at point")
                         ("." #'helpful-at-point "helpful thing at point")
                         ("p" #'show-map "fz show map")
                         ("P" #'copy-current-major-mode "copy current major mode")
                         ("i" (df sh-interpreter (term "sh-interpreter")))))

(convert-hydra-to-sslk "lW"
                       (defhydra h_nW (:exit t :pre (prehydra) :post (posthydra) :color blue :hint nil :columns 4) ;; "NORMAL: action/appearance"
                         "NORMAL: action/appearance"
                         ("p" (df pen-toggle-prettify (call-interactively 'prettify-symbols-mode)) "Pretty Mode")
                         ("l" (df pen-toggle-linum (call-interactively 'linum-mode)) "Line Numbering")
                         ("i" (df toggle-pen (call-interactively 'pen)) "My minor mode")
                         ("v" #'rotate:even-horizontal "Arrange vertically")
                         ("h" #'rotate:even-vertical "Arrange horizontally")
                         ("t" #'rotate:tiled "Tile windows")
                         ("5" #'rotate:tiled "Tile windows")
                         ("r" #'rotate-layout "Rotate layout")
                         ("b" #'balance-windows "Balance windows")
                         ("f" #'all-over-the-screen "3 columns and follow")))

(convert-hydra-to-sslk "lw"
                       (defhydra h_nw (:exit t :pre (prehydra) :post (posthydra) :color blue :hint nil :columns 4)
                         "NORMAL: windows"
                         ("1" #'delete-other-windows "delete other windows")
                         ("0" #'delete-window "delete window")))

(convert-hydra-to-sslk "lv"
                       (defhydra h_nv (:exit t :pre (prehydra) :post (posthydra) :color blue :hint nil :columns 4) ;; "ANY: version control"
                         "ANY: version control"
                         ("h" #'magit-sps-current-file "Add all and commit")
                         ("m" #'magit-sph "Add all and commit")
                         ("C" #'pen-add-all-commit "Add all and commit")
                         ("M" #'sh/git-amend-all-below "amend below")))

(defun goto-file-and-search (fp pattern)
  (interactive)
  (find-file fp))

(defun gen-elisp-gy ()
  (interactive)
  (let ((sel (pen-thing-at-point))
        (fp (buffer-file-path)))))

(convert-hydra-to-sslk "li"
                       (defhydra h_open-repl (:exit t :pre (prehydra) :post (posthydra) :color blue :hint nil :columns 4) ;; "ANY: repl"
                         "ANY: repl"
                         ("p" #'pen-repl-py "python")
                         ("P" 'xpti-with-package "xpti")
                         ("l" #'pen-repl-lisp "lisp (slime)")
                         ("s" #'pen-repl-lisp "lisp (slime)")
                         ("R" #'run-racket "racket (geiser")
                         ("r" #'racket-repl "racket")
                         ("h" #'haskell-interactive-switch "haskell")
                         ;; ("i" #'ielm "ielm")
                         ("c" (df repl-clisp (term "clisp")) "clisp")
                         ("e" #'ielm "ielm")
                         ("m" #'iman "iman")
                         ("2" (df repl-tcl (et "tclsh")) "tcl")
                         ("M" (df repl-mathematica (et "rlwrap" wolframscript)) "et-mma")
                         ;; ("m" (df tm-repl-mathematica (etm rlwrap wolframscript)) "etm-mma")
                         ("K" (df repl-racket (pen-term-nsfa "racket -iI racket || pen-pak")) "et-racket")
                         ("k" #'ghci "ghci")
                         ("w" (df repl-wolframalpha (et "rlwrap replify waf")) "et-wa")
                         ("L" (df repl-lucene (et "rlwrap replify cl-lucene")) "et-lucene")))

(defun select-repl ()
  "Start the repl select hydra"
  (interactive)
  ;; (sleep-for-for-for 1)
  (tsk "M-l")
  (tsk "M-E"))

(df show-advised
    (tvd (list2string (let ((fns))
                    (ad-do-advised-functions (function)
                      (add-to-list 'fns function))
                    fns)))
    )

(convert-hydra-to-sslk "ld"
                       (defhydra h_advice (:exit t :pre (prehydra) :post (posthydra) :color blue :hint nil :columns 4) ;; "ANY: advice"
                         "ANY: advice"
                         ("e" #'show-advised "show advised functions")))

(defmacro pen-mbind (key &rest h_params)
  (let ((nkey (concat "M-" key)))
    `(,key ,@h_params)
    `(,@h_params)))

(df get-clql-verbose (get-clql t))
(df get-clql-terse (get-clql nil))

(convert-hydra-to-sslk "lk"
                       (defhydra h_nc (:exit t :pre (prehydra) :post (posthydra) :color blue :hint nil :columns 4) ;; "NORMAL: commands"
                         "NORMAL: commands"

                         ("1" #'get-clql-verbose "CLQL for selection")
                         ("2" #'get-clql-terse "CLQL for selection (short)")
                         ("a" #'helm-system-packages "apt / system packages")
                         ("A" #'org-agenda-list "org agenda list")
                         ;; ("b" #'org-brain-visualize "org-brain visualise")
                         ;; ("b" #'org-brain-visualize-goto "org-brain visualise goto")
                         ("b" 'org-brain-go-index "org-brain visualise index/billboard")
                         ("c" #'org-capture "org capture")
                         ("\\" #'pen-columnate-window "fill with columns")
                         ;; ("d" (progn (save-excursion (h_advice/body) (norm/hydra-push '(h_nx/body)))) "advice")
                         ;; ("d" (progn (save-excursion (h_advice/body) (norm/hydra-push '(h_nx/body)))) "advice")
                         ;; ("e" (progn (save-excursion (h_open-repl/body) (norm/hydra-push '(h_nx/body)))) "open repl")
                         ;; ("e" (progn (save-excursion (h_open-repl/body) (norm/hydra-push '(h_nx/body)))) "open repl")
                         ("e" #'change-file-extension "change file extension")
                         ("f" #'helm-do-grep-ag "ag silversercher")
                         ("g" #'evil-insert-digraph "Insert digraph")
                         ("i" #'global-rainbow-identifiers-always-mode "Rainbow identifiers")
                         ("j" #'compile-run "compile-run")
                         ("J" #'compile-run-term "compile-run-term")
                         ("," #'compile-run-compile "compile-run compile")
                         ("<" #'compile-run-tm-ecompile "compile-run pen-tm ecompile")
                         ("M" #'git-timemachine "git timemachine")
                         ("h" #'schema-run "schema-run")
                         (")" (df tmux-kill-other (b pen-tm kill-other)) "Kill other tmux")
                         ("k" #'evil-insert-digraph "insert digraph")
                         ("l" #'copy-current-line-position-to-clipboard "copy line position")
                         ("L" #'helm-show-kill-ring "Show clipboard history")
                         ;; ("'" #'menu-bar-open "Menu bar")
                         ("~" #'menu-bar-open "Menu bar")
                         ;; ("M" #'helm-imenu-anywhere "imenu anywhere")
                         ;; ("m" #'helm-imenu "imenu")
                         ("m" (df switch-to-messages (switch-to-buffer "*Messages*")) "messages")
                         ;; ("m" #'view-echo-area-messages "messages")
                         ;; ("M" #'view-echo-area-messages "messages")
                         ("n" #'helm-buffers-list "Helm Buffers list")
                         ("o" (df h-checkprose (flycheck-compile 'proselint)) "check prose")
                         ("O" #'rotate:even-horizontal "Horizontal")
                         ("p" #'org-plot/gnuplot "GnuPlot")
                         ;; ("p" #'org-plot/gnuplot "GnuPlot") ; projectile, aboove
                         ("P" #'paradox-list-packages "Paradox List Packages")
                         ;; ("p" (progn (save-excursion (hydra-projectile/body) (norm/hydra-push '(h_nx/body)))) "projectile hydra")
                         ("q" #'get-clql-verbose "CLQL for selection")
                         (">" #'rotate-layout "Rotate layout")
                         ("r" #'re-builder "Regex builder")
                         ;; ("s" #'sx-search "StackExchange search")
                         ("s" #'sx-search-quickly "StackExchange search")
                         ("t" #'tvipe "tvipe")
                         ("U" #'term-ranger "term ranger")
                         ("u" #'ranger "ranger")
                         ("v" #'visual-line-mode "Visual Line Mode")
                         ;; ("w" #'correct-word "correct previous word")
                         ("w" #'pen-auto-correct-word "auto correct word")
                         ("W" #'pen-flyspell-add-word "add word to dictionary")
                         ;; ("W" #'wttrin "weather")
                         ("x" #'eval-defun "eval defun")
                         ("y" #'call-graph "Call graph")))

(convert-hydra-to-sslk "ls"
                       (defhydra h_ns (:exit t :pre (prehydra) :post (posthydra) :color blue :hint nil :columns 4) ;; "NORMAL: snippets"
                         "NORMAL: snippets"
                         ("n" #'yas-new-snippet "New snippet")
                         ("l" #'yas-expand "Expand")
                         ("i" #'pen-yas-insert-snippet "Expand")
                         ("d" #'yas-describe-tables "Show snippets")
                         ("r" #'yas/reload-all "Reload snippets")))

(global-set-key
 (kbd "C-x j")
 (defhydra gotoline (:pre (prehydra) :post (posthydra) :columns 4) ;; "goto"
   "goto"
   ("t" (pen-lm (move-to-window-line-top-bottom 0)) "top")
   ("b" (pen-lm (move-to-window-line-top-bottom -1)) "bottom")
   ("m" (pen-lm (move-to-window-line-top-bottom)) "middle")
   ("e" (pen-lm (end-of-buffer)) "end")
   ("c" recenter-top-bottom "recenter")
   ("n" next-line "down")
   ("p" (pen-lm (forward-line -1)) "up")
   ("g" goto-line "goto-line")))
;; Hydra for navigation

;; Maybe add some more hydras
;; https://github.com/abo-abo/hydra/wiki/Org-clock-and-timers

(defhydra hydra-org (:color blue :timeout 12 :columns 4)
  "Org commands"
  ("i" (lambda () (interactive) (org-clock-in '(4))) "Clock in")
  ("o" org-clock-out "Clock out")
  ("q" org-clock-cancel "Cancel a clock")
  ("<f10>" org-clock-in-last "Clock in the last task")
  ("j" (lambda () (interactive) (org-clock-goto '(4))) "Go to a clock")
  ("m" make-this-message-into-an-org-todo-item "Flag and capture this message"))
;; (global-set-key (kbd "<f10>") 'hydra-org/body)

;; Hydra for some org-mode stuff
(global-set-key
 (kbd "C-c t")
 (defhydra hydra-global-org (:color blue :columns 4) ;; "Org"
   "Org"
   ("t" org-timer-start "Start Timer")
   ("s" org-timer-stop "Stop Timer")
   ("r" org-timer-set-timer "Set Timer") ; This one requires you be in an orgmode doc, as it sets the timer for the header
   ("p" org-timer "Print Timer")         ; output timer value to buffer
   ("w" (org-clock-in '(4)) "Clock-In") ; used with (org-clock-persistence-insinuate) (setq org-clock-persist t)
   ("o" org-clock-out "Clock-Out")   ; you might also want (setq org-log-note-clock-out t)
   ("j" org-clock-goto "Clock Goto") ; global visit the clocked task
   ("c" org-capture "Capture") ; Don't forget to define the captures you want http://orgmode.org/manual/Capture.html
   ("l" rg-capture-goto-last-stored "Last Capture")))

(defhydra hydra-undo-tree (:color yellow :hint nil :columns 4)
  "
_p_: undo  _n_: redo _s_: save _l_: load   "
  ("p" undo-tree-undo)
  ("n" undo-tree-redo)
  ("s" undo-tree-save-history)
  ("l" undo-tree-load-history)
  ("u" undo-tree-visualize "visualize" :color blue)
  ("q" nil "quit" :color blue))

(global-set-key (kbd "M-,") 'hydra-undo-tree/undo-tree-undo) ;; or whatever

(define-key global-map (kbd "M-' n") nil)
(define-key pen-map (kbd "M-' n") nil)
(define-key pen-map (kbd "M-l n") nil)
(define-key global-map (kbd "M-l n") nil)

(convert-hydra-to-sslk "ln"
                       (defhydra hydra-projectile (:color blue ;; "Projectile"
                                                          :columns 4)
                         "Projectile"
                         ("a" #'projectile-ag "ag")
                         ("n" #'open-next-file "open-next-file")
                         ("p" #'open-prev-file "open-prev-file")
                         ("j" #'projectile-switch-project "switch")
                         ("b" #'projectile-switch-to-buffer "switch to buffer")
                         ("c" #'projectile-invalidate-cache "cache clear")
                         ("d" #'projectile-find-dir "dir")
                         ("s-f" #'projectile-find-file "file")
                         ("ff" #'projectile-find-file-dwim "file dwim")
                         ("fd" #'projectile-find-file-in-directory "file curr dir")
                         ("g" #'ggtags-update-tags "update gtags")
                         ("i" #'projectile-ibuffer "Ibuffer")
                         ("K" #'projectile-kill-buffers "Kill all buffers")
                         ("o" #'projectile-multi-occur "multi-occur")
                         ("r" #'projectile-recentf "recent file")
                         ("x" #'projectile-remove-known-project "remove known")
                         ("X" #'projectile-cleanup-known-projects "cleanup non-existing")
                         ("z" #'projectile-cache-current-file "cache current")))
                         ;; ("q" nil "cancel"))

(define-key global-map (kbd "M-' /") nil)
(define-key pen-map (kbd "M-' /") nil)
(define-key pen-map (kbd "M-l /") nil)
(define-key global-map (kbd "M-l /") nil)

(convert-hydra-to-sslk "l/"
                       (defhydra h_d (:exit t ;; "VISUAL: codesearch / autocomplete"
                                            :pre (prehydra)
                                            :post (posthydra)
                                            :color blue
                                            :hint nil
                                            :columns 4)
                         "VISUAL: codesearch"
                         ("o" #'all-occur "all-occur")
                         ("n" #'search_code "searchcode")
                         ;; ("e" #'egr "egr")
                         ("d" #'pen-rat-dockerhub-search "dockerhub")
                         ("D" #'gl-find-deb "ubuntu deb")
                         ("k" #'pen-k8s-hub-search "k8s hub")
                         ("j" #'eegr "Google")
                         ("g" #'pen-egr-guru99 "guru99")
                         ("w" 'wiki-summary "wiki summary")
                         ("9" #'pen-egr-guru99 "guru99")
                         ("x" #'google_example "google example")
                         ("a" #'pen-github-awesome-search-and-clone "github awesome search and clone")
                         ("m" #'pen-github-docker-compose-search-and-clone "github docker-compose search and clone")
                         ("E" #'find-repo-by-ext "find repo by extension")
                         ("h" #'pen-github-search-and-clone "github search and clone")
                         ("u" #'gh-search-user-clone-repo "github search repos for user")
                         ("p" #'gh-path-search "github path search")
                         ("H" #'hn "hacker news search")
                         ("r" #'tpb "the pirate bay")
                         ("y" #'search-play-yt "youtube search and play")
                         ("v" 'find-in-video "find in video")
                         ("V" 'find-in-youtube "find in youtube")
                         ("Y" 'ytt "youtube vid search and play")
                         ("i" #'ieee-search "ieee search")
                         ("I" #'Info-search-toc "info search")
                         ("7" #'protocol-search "eww protocol search")
                         ("r" #'pen-github-search-and-clone-cookiecutter "github search and clone cookiecutter")
                         ("q" #'eegr-maybeselected "google")
                         ("t" #'pen-github-search-and-clone-template "github search and clone template")
                         ;; ("T" #'pen-github-search-and-clone-template-lang "github search and clone template lang")
                         ("l" #'google_example_literal "google example literal")
                         ;; ("s" #'tvipe-completions "Show completions in vim.")
                         ;; ("d" #'dack-selection-top "dack top")
                         ;; ("e" #'eack-selection-top "eack top")
                         ("f" #'fz-cq-functions "cq functions")
                         ("R" #'cscope-gen "regen cscope, ctags, etc.")
                         ("s" #'fz-cq-symbols "cq symbols")
                         ("c" #'fz-cq-classes "cq classes")
                         ("/" #'eack-selection-top "eack top")
                         ("?" #'eack-selection "eack selection")
                         ("`" #'eack-selection-top "eack top")))

(define-key global-map (kbd "M-' x") nil)
(define-key pen-map (kbd "M-' x") nil)
(define-key pen-map (kbd "M-l x") nil)
(define-key global-map (kbd "M-l x") nil)

(convert-hydra-to-sslk "lx"
                       (defhydra h_n_normal_x (:exit t :pre (prehydra) :post (posthydra) :color blue :hint nil :columns 4) ;; "NORMAL: x automation"
                         "NORMAL: x automation"
                         ("e" #'x/eack-thing "x eack / thing under cursor")
                         ("s" #'get-arxiv-summary "get arxiv summary for thing under cursor")
                         ("/" #'x/eack-thing-top "x eack / thing under cursor (vc top)")
                         ("`" #'x/eack-thing-top "x eack / thing under cursor (vc top)")
                         ("M-`" #'x/eack-thing-top "x eack / thing under cursor (vc top)")))

(define-key global-map (kbd "M-' @") nil)
(define-key pen-map (kbd "M-' @") nil)
(define-key pen-map (kbd "M-l @") nil)
(define-key global-map (kbd "M-l @") nil)

(convert-hydra-to-sslk "l@"
                       (defhydra h_n_lingo (:exit t :pre (prehydra) :post (posthydra) :color blue :hint nil :columns 4) ;; "NORMAL: lingo"
                         "NORMAL: properties"
                         ("." (df edit-pen-hydra (e "$MYGIT/config/emacs/config/pen-hydra.el")) "edit hydra")
                         ("g" #'clpl-rewrite "Run rewrites on pipeline")
                         ("b" #'clpl-get-rewrite-branches "Get rewrite branches")
                         ("j" #'lingo-simplify-review-dump "simplify review json dump")
                         ("s" #'open-in-sublime "open in sublime")
                         ("i" #'indent-clql-for-yaml "indent clql for yaml")
                         ("a" #'clql-annotate "annotate clql")
                         ("e" #'clql-remove-probable-extraneous-properties "clql rm probable extra properties")
                         ("i" #'paste-clql-in-yaml "paste clql into yaml")
                         ("s" #'lingo-strip-clql-from-yaml "strip clql")
                         ("c" #'lingo-extract-clql-from-yaml "extract clql")
                         ("p" #'lingo-insert-project-name "insert project name")))

(define-key global-map (kbd "M-' p") nil)
(define-key pen-map (kbd "M-' p") nil)
(define-key pen-map (kbd "M-l p") nil)
(define-key global-map (kbd "M-l p") nil)

(convert-hydra-to-sslk "lp"
                       (defhydra h_n_normal_properties (:exit t :pre (prehydra) :post (posthydra) :color blue :hint nil :columns 4) ;; "NORMAL: properties"
                         "NORMAL: properties"
                         ("b" #'pen-etv-buffer-properties-json "tvipe buffer properties")
                         ("o" #'parent-modes "parent modes")
                         ("v" #'pen-etv-buffer-variables-json "tvipe buffer variables")
                         ("g" #'pen-etv-global-variables-json "tvipe global variables")
                         ("e" #'pen-etv-emacs-properties-json "tvipe emacs properties")
                         ("p" #'pen-etv-properties-json "tvipe properties")
                         ("i" #'package-install "Install Package")
                         ("r" #'pen-reload-config-file "reload config file")
                         ("y" #'copy-button-action "copy button action")
                         ("l" #'pen-tvipe-package-list "list packages")
                         ("P" #'paradox-list-packages "Paradox List Packages")
                         ("m" #'list-packages "Package Manager")
                         ;; ("f" #'customize-face "customize face")
                         ("f" #'what-face "what face")
                         ("t" #'pen-etv-textprops "text properties")
                         ("u" #'pen-etv-urls-in-region "selected urls")))

(define-key global-map (kbd "M-' z") nil)
(define-key pen-map (kbd "M-' z") nil)
(define-key pen-map (kbd "M-l z") nil)
(define-key global-map (kbd "M-l z") nil)

(convert-hydra-to-sslk "lz"
                       (defhydra h_n_normal_properties (:exit t :pre (prehydra) :post (posthydra) :color blue :hint nil :columns 4) ;; "NORMAL: fuzzy"
                         ;; Can I start clisp inside of emacs?
                         ("s" (df fz-scriptnames (e (fz (pen-mnm (scriptnames)) nil nil "scriptnames-goto:" t))))
                         ("c" (df fz-tm-config (e (fz (pen-mnm (b tm-list-config)) nil nil "tm-config-goto:" t))))
                         ("b" 'fz-org-tidbits)
                         ("k" 'fz-org-tidbits-tasks)
                         ("d" (df fz-tm-shortcuts (e (fz (pen-mnm (b cd $NOTES\; tm-list-shortcuts)) nil nil "tm-shortcuts-goto:" t))))
                         ("n" (df fz-copy-ns-func (xc (fz-namespaces-func))))
                         ("p" (df fz-go-snippet (e (fz (pen-mnm (b find $HOME/notes/ws/lists/snippets -type f -name "*.txt"))))))
                         ("f" #'fz-insert-function)
                         ("g" #'go-to-glossary)
                         ("t" #'go-to-todo-list)
                         ("r" #'go-to-remember-file)
                         ;; ("r" (df fz-sh-repl (ansi-term "fz-repl")))
                         ("i" (df fz-sh-repl (term "fz-repl"))) ;; TODO make this start an emacs fz-repl instead; interpreter
                         ))

(define-key global-map (kbd "M-8") nil)
(define-key pen-map (kbd "M-8") nil)
(convert-hydra-to-sslk "8"
                       (defhydra hydra-search-thing-at-point (:color blue)
                         "Search"
                         ("1" 'define-it-at-point "define word")
                         ("1" 'define-it-at-point "define word")
                         ;; ("g" engine/search-google "google")
                         ;; ("e" eegr "google")
                         ("e" 'eegr-maybeselected "eegr-maybeselected")
                         ("g" 'eegr "google")
                         ("G" 'egr "google")
                         ("s" 'eegr "google")
                         ("S" 'counsel-gl "google-gl")
                         ("w" 'counsel-gl "google-gl")
                         ("d" 'pen-def-thing-at-point "doc")
                         ("t" 'eegr-thing-at-point "egr thing")
                         ("t" 'eegr-thing-at-point "egr thing")
                         ("T" 'egr-thing-at-point "egr thing (split)")
                         ;; ("e" (call-interactively 'egr) "egr")
                         ("e" 'eegr-maybeselected "eegr-maybeselected")
                         ;; ("E" (call-interactively 'egr-maybeselected) "egr-maybeselected")
                         ("E" 'eegr-maybeselected "eegr-maybeselected")
                         ("i" 'eegr-thing-at-point-imediately "gr thing immediate")
                         ("I" 'egr-thing-at-point-imediately "gr thing immediate (split)")
                         ("8" 'eegr-thing-at-point-lang-imediately "ifl + lang")
                         ;; ("h" 'helm-google-suggest "helm-google-suggest")
                         ("h" 'counsel-google "counsel-google")
                         ("l" 'eegr-thing-at-point-lang "ifl + lang")
                         ("d" 'pen-search "fz")
                         ("L" 'egr-thing-at-point-lang-imediately "ifl + lang")
                         ;; ("g" (call-interactively 'engine/search-grep-app) "grep.app")
                         ("g" 'grep-app "grep.app")
                         ("u" 'egr-thing-at-point-lang "gr + lang ")
                         ("r" 'engine/search-rosindex "rosindex")
                         ;; ("8" 'egr-thing-at-point-lang "egr")
                         ("6" 'ead-thing-at-point "ead")
                         ("7" 'egr-thing-at-point-noquotes "egr")
                         ("9" 'glimpse-thing-at-point "gli")
                         ("0" 'glimpse-thing-at-point-immediate "gli immediately")))
(define-key pen-map (kbd "8") nil)

(defun pen-flycheck-list-errors ()
  (interactive)
  (setq flycheck-check-syntax-automatically '(save idle-change new-line mode-enabled))
  (call-interactively 'flycheck-buffer)
  (call-interactively 'flycheck-list-errors))

(require 'flycheck)

(df fi-text-to-paras-nosegregate (pen-region-pipe "pen-pretty-paragraph"))

(defhydra hydra-apropos (:color blue)
  "Apropos"
  ("a" apropos "apropos")
  ("c" apropos-command "cmd")
  ("d" apropos-documentation "doc")
  ("e" apropos-value "val")
  ("l" apropos-library "lib")
  ("o" apropos-user-option "option")
  ("u" apropos-user-option "option")
  ("v" apropos-variable "var")
  ("i" info-apropos "info")
  ("t" tags-apropos "tags")
  ("z" hydra-customize-apropos/body "customize"))

(defhydra hydra-customize-apropos (:color blue)
  "Apropos (customize)"
  ("a" customize-apropos "apropos")
  ("f" customize-apropos-faces "faces")
  ("g" customize-apropos-groups "groups")
  ("o" customize-apropos-options "options"))

(defmacro hb (name bindings_list))

(defhydra h_ne (:exit t :pre (prehydra) :post (posthydra) :color blue :hint nil :columns 4) ;; "NORMAL: emacs"
  "NORMAL: emacs"
  ("e" #'pen-revert "revert")
  ("x" #'kill-emacs "kill emacs")
  ("c" #'revert-and-quit-emacsclient-without-killing-server "kill emacsclient")
  ("d" (df show-daemonp () (message (daemonp))) "(daemonp)")
  ("r" #'restart-emacs "restart emacs")
  ("q" #'pen-quit "quit emacs frame"))

(use-package hydra
  :defer 2
  :bind ("C-c f" . hydra-flycheck/body))



(defhydra hydra-flycheck (:color blue)
  "
  ^
  ^Flycheck^          ^Errors^            ^Checker^
  ^────────^──────────^──────^────────────^───────^─────
  _q_ quit            _<_ previous        _?_ describe
  _M_ manual          _>_ next            _d_ disable
  _v_ verify setup    _f_ check           _m_ mode
  ^^                  _l_ list            _s_ select
  ^^                  ^^                  ^^
  "
  ("q" nil)
  ("<" flycheck-previous-error :color pink)
  (">" flycheck-next-error :color pink)
  ("?" flycheck-describe-checker)
  ("M" flycheck-manual)
  ("d" flycheck-disable-checker)
  ("f" flycheck-buffer)
  ("l" flycheck-list-errors)
  ("m" flycheck-mode)
  ("s" flycheck-select-checker)
  ("v" flycheck-verify-setup))


;; Language agnostic handle-based hydra
(global-set-key
 (kbd "H-j")
 (defhydra handlenav (:pre (prehydra) :post (posthydra) :columns 4) ;; "handle nav"
   "goto"
   ("j" handle-navdown "down")
   ("k" handle-navup "up")
   ("h" handle-navleft "left")
   ("l" handle-navright "right")
   ("q" nil "quit" :color blue)))

(defmacro dr (&rest body)
  "Define and run"
  `(let ((h (progn ,@body)))
     (call-interactively h)))

(defmacro hydrate (&rest body)
  "Define and run hydra"
  `(dr (defhydra ,@body)))

(defalias 'h 'hydrate)

(defmacro hyn (question ifyes &optional ifno default-yes-predicate)
  (let ((hydrasym (intern (concat "h_yn_" (slugify question))))
        (hydrabodysym (intern (concat "h_yn_" (slugify question) "/body"))))
    (if (not ifno)
        (setq ifno '(progn nil)))
    (if question
        (setq question (concat question " [yn]"))
      (setq question "[yn]"))
    `(progn
       (if ,default-yes-predicate
           ,ifyes
           (progn
             (defhydra ,hydrasym (:exit t)
               ,question
               ("y" ,ifyes)
               ("n" ,ifno))
             (,hydrabodysym))))))

(advice-add 'fit-window-to-buffer :around #'ignore-errors-around-advice)

(provide 'pen-hydra)
