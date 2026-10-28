(defun eww-open-this-file ()
  (interactive)
  (eww-open-file (buffer-file-path)))

(defun w3m-open-this-file ()
  (interactive)
  (let ((path (buffer-file-path)))
    (if (f-exists-p path)
        (w3m-find-file (buffer-file-path))
      (w3m (buffer-file-path)))))

(defun chrome-this-file ()
  (interactive)
  (chrome (buffer-file-path) t nil))

(defun firefox-this-file ()
  (interactive)
  (snc (cmd "firefox" (buffer-file-path))))

(defun elinks-dump-this-file ()
  (interactive)
  (let ((fp (buffer-file-path)))
    (if (not (f-file-p fp))
        (error "Not buffer associated with this file")
      (if (>= (prefix-numeric-value current-prefix-arg) 4)
          (etv (snc (cmd "elinks-dump" fp)))
        (nw (cmd "elinks-dump" fp))))))

(defun elinks-open-this-file ()
  (interactive)
  (nw (cmd "elinks" (buffer-file-path))))

(defun elinks-dump-open-this-file ()
  (interactive)
  (new-buffer-from-string (pen-sn (concat "elinks-dump " (pen-q (buffer-file-fpath))))))

;; TODO Add a hook for the major mode to provide the list of functions.
;; For comint mode, the list of functions

;; To do it in this way is not an ideal system
;; because they're not simply key lookups, rather a lot of predicates may need to run
;; before getting to the functions for the major mode.

;; But perhaps I could run 

;; Do it like this, with a top value key for the mode, so instant lookup there
;; together with subpredicates along with corresponding functions.
(defset funclist-tuples `((org-agenda-mode
                           ((true)
                            (agenda-fix-questionmarks
                             cfw:open-org-calendar
                             notmuch-search-agenda)))
                          (prog-mode
                           ((true)
                            (pen-lsp-get-hover-docs
                             run-file-with-interpreter
                             switch-to-org-for-this-file
                             handle-projectfile
                             handle-rename-symbol
                             magit-patch-save-to-clipboard
                             magit-patch-apply-from-clipboard
                             magit-log-buffer-file)))
                          (comint-mode
                           ((true)
                            (comint-history-isearch-backward-regexp))
                           ((pen-sidecar-match-current-buffer-name "battlestar")
                            (pen-comint--battlestar--save
                             pen-comint--battlestar--inven
                             pen-comint--battlestar--drop
                             pen-comint--battlestar--score
                             edit-battlestar-command-history))
                           ((pen-sidecar-match-current-buffer-name "bsdgames-adventure")
                            (pen-comint--bsdgames-adventure--info
                             pen-comint--bsdgames-adventure--score
                             edit-bsdgames-adventure-command-history)))
                          (yaml-mode
                           ((true)
                            (yaml-get-value-from-this-file
                             lsp-yaml-select-buffer-schema
                             lsp-yaml-download-schema-store-db
                             ,(df yaml-multiline-chrome (chrome "https://yaml-multiline.info/"))
                             ,(dff (chrome "https://lzone.de/cheat-sheet/YAML")))))
                          (dired-mode
                           ((true)
                            (tramp-mount-sshfs
                             dired-find-alternate-file
                             dired-narrow
                             directory-listing-to-csv
                             deer-from-dired
                             dired-narrow-fuzzy
                             open-main
                             dired-toggle-read-only
                             find-ci-here
                             find-src-here
                             find-doc-here
                             show-extensions-below
                             run-fs-search-function
                             todayfile
                             dired-toggle-dumpd-dir
                             pen-sps-ranger
                             pen-sps-ncdu)))
                          (notmuch-show-mode
                           ((true)
                            (notmuch-open-mail-html-in-browser)))
                          (magit-status-mode
                           ((true)
                            (magit-section-cycle-diffs
                             magit-dired-jump)))
                          (vimrc-mode
                           ((true)
                            (vimhelp)))
                          (bible-mode
                           ((true)
                            (apropos-variable
                             bible-mode-fast-toggle
                             bible-mode-cross-references
                             bible-mode-cross-references-ext
                             bible-mode-split-display
                             bible-random-verse-ref
                             nicene-creed
                             bible-mode-read-chapter-aloud-kjv
                             bible-mode-fuzzy-search
                             bible-open-interlinear
                             syriac-digraph-select
                             aramaic-digraph-select
                             greek-digraph-select
                             hebrew-digraph-select
                             arabic-digraph-select
                             commandments-of-Jesus
                             bible-fz-chapter-titles-go
                             bible-fz-passage-outlines-go
                             prophesies-fortelling-Jesus-fulfilled)))
                          (bible-search-mode
                           ((true)
                            (apropos-variable
                             bible-mode-fast-toggle
                             bible-mode-cross-references
                             bible-mode-split-display
                             bible-random-verse-ref
                             bible-mode-fuzzy-search
                             bible-open-interlinear
                             bible-fz-chapter-titles-go
                             bible-fz-passage-outlines-go)))
                          (w3m-mode
                           ((true)
                            (w3m-enable-display-html-for-fontify
                             w3m-disable-display-html-for-fontify
                             eww-summarize-this-page
                             reopen-in
                             reopen-in-eww
                             reopen-in-browsh
                             reopen-in-carbonyl
                             reopen-in-elinks
                             reopen-in-elinks-dump-chrome
                             reopen-in-rdrview
                             reopen-in-pen-emacs-web-browse
                             rdrview)))
                          (eshell-mode
                           ((true)
                            (ranger
                             counsel-esh-history
                             eshell-backward-matching-input
                             eshell-forward-matching-input
                             eshell-previous-matching-input
                             eshell-next-matching-input
                             pcomplete-expand-and-complete
                             pen-start-term-visual-cmd
                             eshell-quit-process)))
                          (shell-mode
                           ((true)
                            (ranger
                             pen-start-term-visual-cmd)))
                          (calc-mode
                           ((true)
                            (pen-calc-clear-stack)))
                          (ranger-mode
                           ((true)
                            (open-main
                             ranger-hacky-fix
                             pen-sps-ranger)))
                          (problog-mode
                           ((true)
                            (compile-run-compile)))
                          (html-mode
                           ((true)
                            (w3m-open-this-file
                             eww-open-this-file
                             ;; chrome-this-file
                             firefox-this-file
                             elinks-dump-this-file
                             elinks-open-this-file)))
                          (solidity-mode
                           ((true)
                            (find-file-at-point)))
                          (haskell-interactive-mode
                           ((true)
                            (haskell-process-restart
                             ,(dff (customize-variable 'haskell-process-log))
                             ,(dff (customize-variable 'haskell-process-show-debug-tips))
                             customize-mode)))
                          (prolog-mode
                           ((true)
                            (ediprolog-consult
                             ediprolog-dwim)))
                          (term-mode
                           ((true)
                            (term-restart-process)))
                          (proced-mode
                           ((true)
                            (proced-get-pwd)))
                          (Info-mode
                           ((true)
                            (info-buttons-imenu
                             info-apropos
                             pen-Info-get-text-contents)))
                          (web-mode
                           ((true)
                            (eww-open-this-file
                             elinks-dump-open-this-file)))
                          (emacs-lisp-mode
                           ((true)
                            (reload-library-here)))
                          (csv-mode
                           ((true)
                            (csv-open
                             csv-open-in-numpy
                             csv-open-in-pandas
                             csv-open-in-fpvd
                             csv-open-in-tabulated-list)))
                          (gnu-apl-mode
                           ((true)
                            (gnu-apl
                             gnu-apl-show-keyboard
                             gnu-apl-finnapl-list
                             pen-visor-apl-show-pronounciation
                             pen-visor-apl-show-functionality
                             pen-visor-apl-show-keys
                             pen-pronounce-apl)))
                          (tabulated-list-mode
                           ((true)
                            (tablist-export-csv
                             pen-tablist-copy-marked
                             tablist-to-org-table
                             tablist-open-in-fpvd)))
                          (subed-mode
                           ((true)
                            (show-clean-subs)))
                          (notmuch-search-mode
                           ((true)
                            (helm-notmuch)))
                          (notmuch-show-mode
                           ((true)
                            (helm-notmuch
                             notmuch-show-save-attachments
                             notmuch-search-agenda)))
                          (grep-mode
                           ((true)
                            (grep-ead-on-results
                             grep-output-get-paths)))
                          (Custom-mode
                           ((true)
                            (configure-chrome-permissions)))
                          (racket-mode
                           ((true)
                            (,(df drracket (pen-sn (cmd "drracket" (get-path nil t)) nil nil nil t))
                             racket-xp-next-definition
                             racket-xp-previous-definition
                             racket-xp-next-use
                             racket-xp-previous-use
                             racket-xp-next-error
                             racket-xp-previous-error
                             racket-xp-tail-next-sibling
                             racket-xp-tail-previous-sibling)))
                          (org-mode
                           ((true)
                            (pen-org-add-tag
                             org-toggle-link-display
                             org-kill-note-or-show-branches
                             org-ascii-convert-region-to-utf8
                             org-html-export-to-html
                             org-latex-export-to-pdf
                             poly-org-mode
                             pen-reopen-literally
                             insert-figlet-org
                             pen-lsp-open-hover-docs-url
                             idify-org-file
                             unidify-org-file
                             idify-org-files-here
                             unidify-org-files-here
                             org-copy-thing-here
                             generate-glossary-buttons-over-buffer-force-on
                             org-md-export-to-markdown
                             org-latex-export-to-pdf
                             org-latex-export-to-pdf
                             org-sidebar-tree-toggle
                             org-ql-search
                             helm-org-rifle
                             tvipe-org-table-export-tsv
                             etv-org-table-export-tsv
                             fpvd-org-table-edit
                             fpvd-org-table-export
                             efpvd-org-table-export)))
                          (kubernetes-overview-mode
                           ((true)
                            (,(df kube-get-pods
                                  (pen-term-nsfa "kubectl -n kube-system get pods"))
                             ,(df kube-get-pods-buffer
                                  (new-buffer-from-string (pen-sn "kubectl -n kube-system get pods"))))))
                          (python-mode
                           ((true)
                            ,(append '(python-version
                                       python-pytest-popup
                                       py-detect-libraries
                                       importmagic-fix-imports
                                       pyimport-insert-missing
                                       pyimport-remove-unused)
                                     (list ;; (df ag-init (pen-counsel-ag "__init__"))
                                      (lk (pen-counsel-ag "__init__"))
                                      (lk (lint "py-mypy"))))))
                          (c++-mode
                           ((true)
                            ,(append '()
                                     (list
                                      (lk (lint "cpplint"))
                                      (lk (lint "d-thompsonja-cpplint-1-4-5"))))))
                          (rust-mode
                           ((true)
                            (rust-test
                             rustic-cargo-current-test
                             lsp-avy-lens)))
                          (clojure-mode
                           ((true)
                            (cider-restart
                             cider-apropos-select
                             clj-rebel-doc
                             cider-jack-in
                             cider-repl-set-ns
                             clojure-find-deps
                             pen-clojure-lein-run
                             clojure-select-copy-dependency
                             helm-cider-spec
                             helm-cider-spec-ns
                             helm-cider-history
                             helm-cider-apropos
                             helm-cider-cheatsheet
                             helm-cider-apropos-ns
                             helm-cider-spec-symbol
                             helm-cider-repl-history
                             helm-cider-apropos-symbol
                             helm-cider-apropos-symbol-doc
                             clojure-open-test
                             projectile-toggle-between-implementation-and-test)))
                          (clojurec-mode
                           ((true)
                            (cider-jack-in)))
                          (haskell-mode
                           ((true)
                            (ghcid
                             hoogle
                             ghcd-info
                             ;; pen-intero-get-type
                             ;; pen-haskell-get-import-for-package
                             pen-haskell-get-import
                             pen-haskell-hoogle-type
                             pen-haskell-fill-hole
                             pen-interpreter-import
                             haskell-show-hdc-readme
                             dante-repl
                             sps-dante-ghcid
                             esps-dante-ghcid
                             haskell-hdc-thing

                             pen-haskell-get-type
                             haskell-extend-language
                             pen-src-thing-at-point

                             ;; uses stack
                             ;; hs-install-module-under-cursor

                             hs-download-packages-with-function-type)))
                          (haskell-cabal-mode
                           ((true)
                            (haskell-cabal-add-dependency)))
                          (eww-mode
                           ((true)
                            (eww-open-in-chrome
                             eww-dump-vim
                             eww-reopen-in-chrome
                             reopen-in-w3m
                             reopen-in-browsh
                             reopen-in-carbonyl
                             select-font-lock-face-region
                             w3m-open-this-file
                             elinks-open-this-file
                             elinks-dump-this-file
                             pen-url-cache-delete
                             eww-add-domain-to-chrome-dom-matches
                             pen-lg-display-page
                             toggle-cached-version
                             eww-open-all-links
                             eww-next-image
                             eww-select-wayback-for-url
                             eww-mirror-url
                             toggle-use-chrome-locally
                             eww-open-medium
                             eww-open-huggingface
                             eww-open-spacy
                             eww-reader
                             eww-reload-cache-for-page
                             eww-open-browsh
                             eww-summarize-this-page
                             rdrview
                             google-this-url-in-this-domain
                             pen-eww-save-image
                             pen-eww-save-image-auto)))
                          (magit-mode
                           ((true)
                            (magit-eww-releases
                             magit-toggle-margin)))
                          (crontab-mode
                           ((true)
                            (crontab-guru)))
                          (graphviz-dot-mode
                           ((true)
                            (dot-digraph
                             neato-digraph)))
                          (org-brain-visualize-mode
                           ((true)
                            (apropos-variable
                             notmuch-search-agenda
                             org-brain-to-dot-associates
                             org-brain-to-dot-children
                             pp-org-brain-tree
                             org-brain-clear-metadata
                             org-brain-edit-metadata
                             org-brain-show-recursive-children
                             org-brain-show-recursive-children-names
                             org-brain-describe-topic
                             org-brain-headline-to-file
                             org-brain-headline-to-file-this
                             org-brain-asktutor
                             org-brain-current-topic
                             org-brain-google-here
                             org-brain-suggest-subtopics
                             org-brain-edit-hist
                             org-brain-clear-hist
                             org-brain-set-title
                             org-brain-open-resource
                             org-id-update-id-locations
                             revert-buffer
                             org-brain-switch-brain
                             ,(dff (edit-var-elisp 'org-brain-mind-map-child-level))
                             ,(dff (edit-var-elisp 'org-brain-mind-map-parent-level)))))
                          (magit-status-mode
                           ((true)
                            (magit-eww-releases)))
                          (magit-log-mode
                           ((true)
                            (magit-eww-releases)))
                          (mermaid-mode
                           ((true)
                            (mermaid-compile)))
                          (markdown-mode
                           ((true)
                            (markdown-get-mode-here
                             markdown-preview
                             slides
                             md-org-export-to-org
                             md-glow-this-buffer
                             md-tidytext-this-buffer
                             markdown-insert-image
                             markdown-get-lang-here
                             poly-markdown-mode)))
                          (lisp-mode
                           ((true)
                            (slime-edit-uses
                             sbcl-web-docs)))
                          (Man-mode
                           ((true)
                            (Man-follow-manual-reference
                             Man-goto-section)))
                          (chess-display-mode
                           ((true)
                            (chess-display-move-first
                             chess-display-move-last)))
                          (rustic-mode
                           ((true)
                            (rust-test
                             rustic-cargo-current-test)))
                          (docker-image-mode
                           ((true)
                            (docker-image-copy-entrypoint-and-cmd
                             docker-image-copy-cmd
                             docker-image-copy-entrypoint
                             ff-dockerhub
                             ff-dockerfile)))
                          (docker-container-mode
                           ((true)
                            (
                             ;; TODO Make a macro to generate these functions
                             ,(defun docker-container-copy-cmd ()
                                (interactive)
                                (let ((sel (docker-select-one)))
                                  (xc (pen-sn (concat "docker-get-cmd " sel)))))
                             ,(defun docker-container-export-nspawn ()
                                (interactive)
                                (let ((sel (docker-select-one)))
                                  (pen-sn (concat "docker-export-nspawn -r  " sel)))))))
                          (docker-machine-mode
                           ((true)
                            (,(defun regen-cert ()
                                (interactive)
                                (let ((sel (docker-select-one)))
                                  (pen-term-nsfa (concat "set -xv; docker-machine regenerate-certs " sel " ; pen-pak")))))))
                          (terraform-mode
                           ((true)
                            (,(lk (lint "tflint")))))
                          (text-mode
                           ((true)
                            (insert-figlet)))))
(add-to-list 'funclist-tuples `(yaml-ts-mode
                                ,(cadr (assoc 'yaml-mode funclist-tuples))))
(add-to-list 'funclist-tuples `(gnu-apl-interactive-mode
                                ,(cadr (assoc 'gnu-apl-mode funclist-tuples))))
(add-to-list 'funclist-tuples `(org-strippeddown-mode
                                ,(cadr (assoc 'org-mode funclist-tuples))))

(defun reload-library-here ()
  (interactive)
  (let* ((libs (string2list
                (pen-snc "\"pen-scrape\" \"\\(provide '[a-z-]+\\)\" | sed -e \"s/.*'//\" -e 's/)$//'" (buffer-string))))
         (lib
          (if (> (length libs) 1)
              (fz libs nil nil "library")
            (car libs))))
    (if (sor lib)
        (load-library lib))))

;; (defset context-functions '(org-in-src-block-p org-babel-change-block-type))

;; (defun new-buffer-from-string-filter (s))

;; (defset lisp-mode-funcs '(sly))


(defset clojure-mode-filters (list
                              (defshellfilter cljfmt)
                              (defshellfilter-new-buffer clojure2json)))

(defset graphviz-dot-mode-filters (list (defshellfilter gen-qdot)))

(defset hcl-mode-filters (list
                                (defshellfilter-new-buffer hcl2json)))
(defset terraform-mode-filters (list
                                (defshellfilter-new-buffer hcl2json)))

(defset text-mode-filters (list
                           (defshellfilter grex)
                           (defshellfilter-new-buffer-mode 'text-mode ner)
                           (defshellfilter-new-buffer-mode 'text-mode extract-keyphrases)
                           (defshellfilter-new-buffer-mode 'text-mode deplacy)
                           (defshellfilter split-commas-multiline)))
(defset prompt-description-mode-filters (list
                                         (defshellfilter tidy-prompt)))
(defset eww-mode-filters (list
                           (defshellfilter-new-buffer-mode 'text-mode ner)
                           (defshellfilter-new-buffer-mode 'text-mode extract-keyphrases)
                           (defshellfilter-new-buffer-mode 'text-mode deplacy)))
(defset csv-mode-filters (list
                          (defshellfilter-new-buffer csv2org-table)
                          (defshellfilter-new-buffer tsv2org-table)))

(defset dockerfile-mode-filters (list
                                 (defshellfilter docker-listify-arguments)))

(defset sh-mode-filters (list (defshellfilter split-pipe-multiline)
                              (defshellfilter dvate)
                              (defshellfilter python-listify-arguments)
                              (defshellfilter join-cmd-args)
                              (defshellfilter bash-onelinerise-line-continuations)
                              (defshellfilter split-options-multiline)
                              (defshellfilter sh-split-statement-multiline)
                              (defshellfilter split-args-multiline)))
(defset clql-mode-filters (list (defshellfilter extract-yaml-from-clql)))
(defset snippet-mode-filters (list (defshellfilter escape-for-yasnippet)))
(defset yaml-mode-filters (list
                           (defshellfilter compile-yaml)
                           (eval `(defshellfilter ,(intern (pen-nsfa "yq ."))))))
(defset hy-mode-filters (list (defshellfilter-new-buffer hy2py)))
(defset racket-mode-filters (list))

(defset python-mode-filters (list (defshellfilter python2to3)
                                  (defshellfilter autopep8)
                                  (defshellfilter-new-buffer python-scrape-imports)
                                  (defshellfilter python-listify-arguments)
                                  (defshellfilter autopep8 --aggressive)
                                  (defshellfilter py-split-array-multiline)
                                  (defshellfilter-new-buffer py2hy)))

(defshellfilter-new-buffer md2org)

(defset markdown-mode-filters (list 'sh/nb/md2org
                                    (defshellfilter-new-buffer md2txt)
                                    (defshellfilter-new-buffer mermaid-show)
                                    (defshellfilter-new-buffer translate-to-english)
                                    (defshellfilter translate-to-english)
                                    (defshellfilter md-checklistify)
                                    (defshellfilter-new-buffer plantuml)))

(defshellfilter-new-buffer org2md)

(defset org-mode-filters (list
                          (defshellfilter-new-buffer translate-to-english)
                          (defshellfilter-new-buffer org2txt)
                          (defshellfilter translate-to-english)
                          (defshellfilter org-listify)
                          (defshellfilter org-reformat)
                          (defshellfilter org-checklistify)
                          (defshellfilter mnm-presentation)
                          (defshellfilter-new-buffer-mode 'text-mode ner)
                          (defshellfilter-new-buffer-mode 'text-mode deplacy)
                          (defshellfilter grex)
                          'sh/nb/org2md
                          (defshellfilter python-listify-arguments)
                          (defshellfilter split-commas-multiline)
                          (defshellfilter spaces-to-org-table)
                          (defshellfilter tsv2org-table)
                          (defshellfilter space-to-org-table)
                          (defshellfilter org-capitalise-headings)
                          (defshellfilter-new-buffer mermaid-show)
                          (defshellfilter-new-buffer plantuml)))

(comment
 (flatten-once
  (loop for tp in (cdr (assoc 'yaml-mode funclist-tuples))
        if (eval (car tp))
        collect (cadr tp)
        else
        collect nil)))

(defun major-mode-function (&optional mode)
  (interactive)
  ;; TODO Go through all parent modes
  (if (not mode)
      (setq mode major-mode))
  (let* ((tups (cdr (assoc mode funclist-tuples)))
         (func-list (flatten-once
                     (loop for tp in tups
                           if (eval (car tp))
                           collect (cadr tp)
                           else
                           collect nil)))

         ;; (lsym (intern (concat (symbol-name mode) "-funcs")))
         ;; (progsym (intern "prog-mode-funcs"))
         ;; (func-list (if (variable-p lsym)
         ;;                (symbol-value lsym)
         ;;              nil))
         )
    (if (interactive-p)
        (if func-list
            (call-interactively (intern (fz func-list nil nil "major-mode-function: ")))
          ;; (message (concat (symbol-name func-list) " is empty"))
          (message (concat "Func list for " (str mode) " is empty")))
      func-list)))

;; Using j:get-helm-descbinds-as-string to sort binded commands to the top
;; would slow things down.
;; mx:get-helm-descbinds-as-string
;; Oh, I don't even need to do that, because I only need to extend
;; j:get-major-mode-functions.
;; Oh, I don't ever need to extend j:get-major-mode-functions because
;; j:get-major-mode-functions only returns commands with bindings
;; Ah, I see, so the reason why some commands display without their binding
;; is that the binding is overshadowed by a binding in a different mode, such as pen-mode.
(defun major-mode-functions (&optional mode)
  (interactive)

  ;; If 'fundamental-mode', then check the file extension

  (let* ((mode major-mode)
         (mode (if (and (equal major-mode 'fundamental-mode)
                        (f-file-p (buffer-file-name)))
                   (get-mode-for-file (buffer-file-name))
                 mode))
         (modes (parent-mode-list mode))
         (modestr (sym2str mode))
         (modesym (intern modestr))
         (mapsym (intern (concat modestr "-map")))
         (funs
          (cond
           ((>= (prefix-numeric-value current-prefix-arg) 64)
            (progn
              (setq current-prefix-arg nil)
              (flatten-list
               (loop for m in modes collect
                     (major-mode-function m)))))
           ((>= (prefix-numeric-value current-prefix-arg) 16)
            (j 'funclist-tuples))
           ;; I want to be able to run functions with a basic C-u
           ((or (>= (prefix-numeric-value current-prefix-arg) 4)
                t)
            (flatten-list
             (append (get-major-mode-functions mapsym)
                     (flatten-list
                      (loop for m in modes collect
                            (major-mode-function m)))))))))

    ;; ess-mode-map

    (if (interactive-p)
        (if funs
            (if (>= (prefix-numeric-value current-prefix-arg) 4)
                (call-interactively (intern (fz funs nil nil "C-u major-mode-function: ")))
              (call-interactively (intern (fz funs nil nil "major-mode-function: "))))
          (message (concat (symbol-name funs) " is empty")))
      funs)))

(defun major-mode-filter (&optional mode)
  (interactive)
  (if (not mode)
      (setq mode major-mode))
  (let ((lsym (intern (concat (symbol-name mode) "-filters"))))
    (if (variable-p lsym)
        (let* ((funname (fz (eval lsym) nil nil "major-mode-filter: "))
               (f (intern funname)))
          (if (not (string-empty-p funname))
              (filter-selected-region-through-function (intern funname))))
      (message (concat (symbol-name lsym) " is not defined")))))

(provide 'pen-func-lists)
