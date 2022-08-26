(defun eww-open-this-file ()
  (interactive)
  (eww-open-file (buffer-file-path)))

(defun elinks-dump-open-this-file ()
  (interactive)
  (new-buffer-from-string (pen-sn (concat "elinks-dump " (pen-q (buffer-file-path))))))

(defset prog-mode-funcs '(pen-lsp-get-hover-docs
                          run-file-with-interpreter
                          handle-projectfile
                          handle-rename-symbol
                          magit-log-buffer-file))
(defset yaml-mode-funcs
  (list
   'yaml-get-value-from-this-file
   'lsp-yaml-select-buffer-schema
   'lsp-yaml-download-schema-store-db
   (df yaml-multiline-chrome (chrome "https://yaml-multiline.info/"))
   (dff (chrome "https://lzone.de/cheat-sheet/YAML"))))
(defset dired-mode-funcs '(tramp-mount-sshfs
                           dired-narrow
                           deer-from-dired
                           dired-narrow-fuzzy
                           open-main
                           dired-toggle-read-only
                           show-extensions-below
                           run-fs-search-function
                           dired-toggle-dumpd-dir
                           pen-sps-ranger))
(defset ranger-mode-funcs '(open-main
                            ranger-hacky-fix
                            pen-sps-ranger))
(defset haskell-interactive-mode-funcs `(haskell-process-restart
                                         ,(dff (customize-variable 'haskell-process-log))
                                         ,(dff (customize-variable 'haskell-process-show-debug-tips))
                                         customize-mode))

(defset prolog-mode-funcs '(ediprolog-consult
                            ediprolog-dwim))

(defset term-mode-funcs '(term-restart-process))

(defset proced-mode-funcs '(proced-get-pwd))

(defset Info-mode-funcs '(info-buttons-imenu))

(defset web-mode-funcs '(eww-open-this-file))

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
(defset emacs-lisp-mode-funcs '(reload-library-here))

(defset csv-mode-funcs '(csv-open
                         csv-open-in-numpy
                         csv-open-in-pandas
                         csv-open-in-fpvd))

(defset tabulated-list-mode-funcs '(tablist-export-csv
                                    tablist-open-in-fpvd))

(defset subed-mode-funcs '(show-clean-subs))

(defset context-functions '(org-in-src-block-p org-babel-change-block-type))

(defset grep-mode-funcs (list 'grep-ead-on-results 'grep-output-get-paths))
;; (defset grep-mode-funcs '(grep-ead-on-results))

(defset Custom-mode-funcs (list
                           'configure-chrome-permissions))

(defset racket-mode-funcs (list ))
(defset org-mode-funcs ;; (list 'org-latex-export-to-pdf 'tvipe-org-table-export)
  (list
   'org-ascii-convert-region-to-utf8
   'poly-org-mode
   'pen-lsp-open-hover-docs-url
   'idify-org-file
   'unidify-org-file
   'idify-org-files-here
   'unidify-org-files-here
   'generate-glossary-buttons-over-buffer-force-on
   'org-latex-export-to-pdf
   'org-latex-export-to-pdf
   'org-sidebar-tree-toggle
   'org-ql-search
   'helm-org-rifle
   'tvipe-org-table-export-tsv
   'etv-org-table-export-tsv
   'fpvd-org-table-export
   'efpvd-org-table-export))

(defset kubernetes-overview-mode-funcs
  (list
   (df kube-get-pods
       (pen-term-nsfa "kubectl -n kube-system get pods"))
   (df kube-get-pods-buffer
       (new-buffer-from-string (pen-sn "kubectl -n kube-system get pods")))))

;; (defun new-buffer-from-string-filter (s))

(defset python-mode-funcs (append '(python-version
                                    python-pytest-popup
                                    py-detect-libraries
                                    importmagic-fix-imports
                                    pyimport-insert-missing
                                    pyimport-remove-unused)
                                  (list ;; (df ag-init (pen-counsel-ag "__init__"))
                                   (lk (pen-counsel-ag "__init__"))
                                   (lk (lint "py-mypy")))))

(defset c++-mode-funcs (append '()
                               (list
                                (lk (lint "cpplint"))
                                (lk (lint "d-thompsonja-cpplint-1-4-5")))))

;; Any way to combine these?
(defset rust-mode-funcs (list
                         'rust-test
                         'rustic-cargo-current-test))

(defset go-mode-funcs '())
(defset clojure-mode-filters (list
                              (defshellfilter cljfmt)
                              (defshellfilter-new-buffer clojure2json)))
(defset clojure-mode-funcs (list
                            'cider-restart
                            'clj-rebel-doc
                            'cider-jack-in
                            'cider-repl-set-ns
                            'clojure-find-deps
                            'pen-clojure-lein-run
                            'clojure-select-copy-dependency
                            'helm-cider-spec
                            'helm-cider-spec-ns
                            'helm-cider-history
                            'helm-cider-apropos
                            'helm-cider-cheatsheet
                            'helm-cider-apropos-ns
                            'helm-cider-spec-symbol
                            'helm-cider-repl-history
                            'helm-cider-apropos-symbol
                            'helm-cider-apropos-symbol-doc
                            'clojure-open-test
                            'projectile-toggle-between-implementation-and-test))
(defset clojurec-mode-funcs '(cider-jack-in))

(defset web-mode-funcs '(eww-open-this-file elinks-dump-open-this-file))

(defset haskell-mode-funcs '(ghcid
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

                             hs-download-packages-with-function-type))

(defset haskell-cabal-mode-funcs '(haskell-cabal-add-dependency))

(defset eww-mode-funcs '(eww-open-in-chrome
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
                         google-this-url-in-this-domain
                         pen-eww-save-image
                         pen-eww-save-image-auto))
(defset magit-mode-funcs '(magit-eww-releases))
(defset crontab-mode-funcs '(crontab-guru))

(defun org-brain-edit-hist ()
  (interactive)
  (edit-var-elisp 'org-brain--vis-history))

(defset graphviz-dot-mode-funcs
  '(dot-digraph
    neato-digraph))

(defset org-brain-visualize-mode-funcs
  (list
     'org-brain-to-dot-associates
   'org-brain-to-dot-children
   'pp-org-brain-tree
   'org-brain-show-recursive-children
   'org-brain-show-recursive-children-names
   'org-brain-describe-topic
   'org-brain-headline-to-file
   'org-brain-headline-to-file-this
   'org-brain-asktutor
   'org-brain-current-topic
   'org-brain-google-here
   'org-brain-suggest-subtopics
   'org-brain-edit-hist
   'org-brain-set-title
   'org-brain-open-resource
   'org-id-update-id-locations
   'revert-buffer
   'org-brain-switch-brain
   (dff (edit-var-elisp 'org-brain-mind-map-child-level))
   (dff (edit-var-elisp 'org-brain-mind-map-parent-level))))

(defset magit-status-mode-funcs '(magit-eww-releases))
(defset magit-log-mode-funcs '(magit-eww-releases))
(defset mermaid-mode-funcs '(mermaid-compile))

(defset markdown-mode-funcs '(markdown-get-mode-here
                              markdown-preview
                              md-org-export-to-org
                              md-glow-vs
                              markdown-get-lang-here
                              poly-markdown-mode))

(defset lisp-mode-funcs '(sly))

(defset Man-mode-funcs '(Man-follow-manual-reference
                         Man-goto-section))

(defset rustic-mode-funcs (list
                           'rust-test
                           'rustic-cargo-current-test))

;; TODO Make a macro to generate these functions
(defset docker-image-mode-funcs '(docker-image-copy-entrypoint-and-cmd docker-image-copy-cmd docker-image-copy-entrypoint ff-dockerhub ff-dockerfile))
(defset docker-container-mode-funcs (list
                                     (defun docker-container-copy-cmd ()
                                       (interactive)
                                       (let ((sel (docker-select-one)))
                                         (xc (pen-sn (concat "docker-get-cmd " sel)))))
                                     (defun docker-container-export-nspawn ()
                                       (interactive)
                                       (let ((sel (docker-select-one)))
                                         (pen-sn (concat "docker-export-nspawn -r  " sel))))))
(defset docker-machine-mode-funcs (list
                                     (defun regen-cert ()
                                       (interactive)
                                       (let ((sel (docker-select-one)))
                                         (pen-term-nsfa (concat "set -xv; docker-machine regenerate-certs " sel " ; pen-pak"))))))

(defun emacs-which (cmd)
  (str2list (chomp (pen-sn (concat "PATH=" (pen-q (getenv "PATH")) " which -a " cmd)))))

;; (emacs-which "grex")

(defset graphviz-dot-mode-filters (list (defshellfilter gen-qdot)))

(defset hcl-mode-filters (list
                                (defshellfilter-new-buffer hcl2json)))
(defset terraform-mode-filters (list
                                (defshellfilter-new-buffer hcl2json)))
(defset terraform-mode-funcs (list
                              (lk (lint "tflint"))))
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

(defun major-mode-function (&optional mode)
  (interactive)
  (if (not mode)
      (setq mode major-mode))
  (let* ((lsym (intern (concat (symbol-name mode) "-funcs")))
         (progsym (intern "prog-mode-funcs"))
         (func-list (if (variable-p lsym)
                        (symbol-value lsym)
                      nil))
         (pl (if (variable-p progsym)
                 (symbol-value progsym)
               nil))
         (finallist (if (and (derived-mode-p 'prog-mode)
                             pl)
                        (append '() func-list pl)
                      func-list)))
    (if finallist
        (call-interactively (intern (fz finallist nil nil "major-mode-function: ")))
      (message (concat (symbol-name finallist) " is empty")))))

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
