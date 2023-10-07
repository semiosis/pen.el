(require 'lsp-mode)
(require 'el-patch)
(require 'lsp-haskell)
(require 'pen-lsp-racket)
(require 'lsp-go)
(require 'lsp-clojure)
(require 'ccls)
(require 'lsp-ui)
(require 'rust-mode)
(require 'helm-lsp)
(require 'lsp-headerline)
(require 'pen-lsp-common-lisp)

(el-patch-feature lsp-mode)
(el-patch-defun lsp (&optional arg)
  "Entry point for the server startup.
When ARG is t the lsp mode will start new language server even if
there is language server which can handle current language. When
ARG is nil current file will be opened in multi folder language
server if there is such. When `lsp' is called with prefix
argument ask the user to select which language server to start."
  (interactive "P")

  (lsp--require-packages)

  (when (buffer-file-name)
    (let (clients
          (matching-clients (lsp--filter-clients
                             (-andfn #'lsp--matching-clients?
                                     #'lsp--server-binary-present?))))
      (cond
       (matching-clients
        (when (setq lsp--buffer-workspaces
                    (or (and
                         ;; Don't open as library file if file is part of a project.
                         (not (lsp-find-session-folder (lsp-session) (buffer-file-name)))
                         (lsp--try-open-in-library-workspace))
                        (lsp--try-project-root-workspaces (equal arg '(4))
                                                          (and arg (not (equal arg 1))))))
          (lsp-mode 1)
          (when lsp-auto-configure (lsp--auto-configure))
          (setq lsp-buffer-uri (lsp--buffer-uri))
          (lsp--info "Connected to %s."
                     (apply 'concat (--map (format "[%s]" (lsp--workspace-print it))
                                           lsp--buffer-workspaces)))))
       ;; look for servers which are currently being downloaded.
       ((setq clients (lsp--filter-clients (-andfn #'lsp--matching-clients?
                                                   #'lsp--client-download-in-progress?)))
        (lsp--info "There are language server(%s) installation in progress.
The server(s) will be started in the buffer when it has finished."
                   (-map #'lsp--client-server-id clients))
        (seq-do (λ (client)
                  (cl-pushnew (current-buffer) (lsp--client-buffers client)))
                clients))
       ;; look for servers to install
       ((setq clients (lsp--filter-clients (-andfn #'lsp--matching-clients?
                                                   #'lsp--client-download-server-fn
                                                   (-not #'lsp--client-download-in-progress?))))
        (let ((client (lsp--completing-read
                       (concat "Unable to find installed server supporting this file. "
                               "The following servers could be installed automatically: ")
                       clients
                       (-compose #'symbol-name #'lsp--client-server-id)
                       nil
                       t)))
          (cl-pushnew (current-buffer) (lsp--client-buffers client))
          (lsp--install-server-internal client)))
       ;; no clients present
       ((setq clients (unless matching-clients
                        (lsp--filter-clients (-andfn #'lsp--matching-clients?
                                                     (-not #'lsp--server-binary-present?)))))
        (lsp--warn "The following servers support current file but do not have automatic installation configuration: %s
You may find the installation instructions at https://emacs-lsp.github.io/lsp-mode/page/languages.
(If you have already installed the server check *lsp-log*)."
                   (mapconcat (λ (client)
                                (symbol-name (lsp--client-server-id client)))
                              clients
                              " ")))
       ;; no matches
       ;; If there are no matches, I should run ESP
       ((-> #'lsp--matching-clients? lsp--filter-clients not)
        (progn
          ;; 
          (never
           (lsp--error
            (el-patch-swap
              "There are no language servers supporting current mode `%s' registered with `lsp-mode'.
This issue might be caused by:
1. The language you are trying to use does not have built-in support in `lsp-mode'. You must install the required support manually. Examples of this are `lsp-java' or `lsp-metals'.
2. The language server that you expect to run is not configured to run for major mode `%s'. You may check that by checking the `:major-modes' that are passed to `lsp-register-client'.
3. `lsp-mode' doesn't have any integration for the language behind `%s'. Refer to https://emacs-lsp.github.io/lsp-mode/page/languages and https://langserver.org/ ."
              "No LSP server for current mode")
            major-mode major-mode major-mode))))))))

(defun lsp--get-document-symbols-around-advice (proc &rest args)
  ;; This greatly speeds up lsp-mode.
  ;; e:$HOME/source/git/emacs-mirror/emacs/src/process.c

  ;; (pen-concat-imenu-init cc-imenu-c-generic-expression 'imenu-default-create-index-function)
  ;; e:$HOME/local/emacs28/share/emacs/28.0.50/lisp/progmodes/cc-menus.el.gz
  ;; (setq imenu-create-index-function 'imenu-default-create-index-function)
  (if (not (derived-mode-p 'c-mode))
      (let ((res (apply proc args)))
        res)))
(advice-add 'lsp--get-document-symbols :around #'lsp--get-document-symbols-around-advice)

(use-package lsp-mode
  :ensure t
  :commands lsp-register-client
  :init (setq lsp-gopls-server-args '("--debug=localhost:6060"))
  :config
  (setq lsp-prefer-flymake :none)
  (lsp-register-custom-settings
   '(("gopls.completeUnimported" t t))))

(setq lsp-gopls-staticcheck t)
(setq lsp-eldoc-render-all t)
(setq lsp-gopls-complete-unimported t)

(use-package lsp-ui
  :ensure t
  :config
  (setq lsp-ui-sideline-ignore-duplicate t)
  (add-hook 'lsp-mode-hook 'lsp-ui-mode)
  (require 'lsp-ui-imenu))

(add-hook 'lsp-after-open-hook 'lsp-enable-imenu)

(use-package lsp-mode
  :ensure t
  :commands (lsp lsp-deferred)
  ;; :hook (go-mode . lsp-deferred)
  :hook ((go-mode . lsp-deferred)
         (go-ts-mode . lsp-deferred)))

(remove-hook 'before-save-hook 'gofmt-before-save)
(defun lsp-go-install-save-hooks ()
  (add-hook 'before-save-hook #'lsp-format-buffer t t)
  (add-hook 'before-save-hook #'lsp-organize-imports t t))
(add-hook 'go-mode-hook #'lsp-go-install-save-hooks)
(add-hook 'go-ts-mode-hook #'lsp-go-install-save-hooks)

(comment
 (use-package lsp-haskell
   :ensure t
   :config
   (setq lsp-haskell-process-path-hie "haskell-language-server-wrapper")))

(progn
  (require 'julia-mode)
  (require 'lsp-julia)
  (require 'lsp-mode)
  (add-hook 'julia-mode-hook #'lsp-mode)
  (add-hook 'julia-mode-hook #'lsp))

;; (add-to-list 'load-path (concat emacsdir "/manual-packages/lsp-solidity-el"))
;; (require 'lsp-solidity)

(with-eval-after-load 'lsp-mode
  (add-hook 'rust-mode-hook #'lsp))

(with-eval-after-load 'lsp-ui
  (add-hook 'lsp-mode-hook 'lsp-ui-mode))

;; I don't want the doc overlays to appear automatically
;; To turn back on:
;; (define-key lsp-mode-map (kbd "C-c d") 'ladicle/toggle-lsp-ui-doc)
(defun pen-hide-lsp-ui-doc-mode ()
  (interactive)
  (lsp-ui-doc-mode -1))
(add-hook 'lsp-ui-mode-hook 'pen-hide-lsp-ui-doc-mode)

(add-hook 'c++-mode-hook 'maybe-lsp)
(add-hook 'c-mode-hook #'maybe-lsp)
(add-hook 'python-mode-hook 'maybe-lsp)
(add-hook 'python-ts-mode-hook 'maybe-lsp)
(add-hook 'perl-mode-hook 'maybe-lsp)
;; (remove-hook 'perl-mode-hook 'maybe-lsp)
(add-hook 'dockerfile-mode-hook 'maybe-lsp)
(add-hook 'java-mode-hook 'maybe-lsp)
(add-hook 'kotlin-mode-hook 'maybe-lsp)
(add-hook 'yaml-mode-hook #'maybe-lsp)
(add-hook 'sql-mode-hook 'maybe-lsp)
(add-hook 'php-mode-hook 'maybe-lsp)
(add-hook 'clojure-mode-hook 'maybe-lsp)
(add-hook 'clojurescript-mode-hook 'maybe-lsp)
(add-hook 'julia-mode-hook 'maybe-lsp)
(add-hook 'ess-julia-mode-hook 'maybe-lsp)
(add-hook 'go-mode-hook 'maybe-lsp)
(add-hook 'go-ts-mode-hook 'maybe-lsp)
(add-hook 'cmake-mode-hook 'maybe-lsp)
(add-hook 'ruby-mode-hook 'maybe-lsp)
(add-hook 'gitlab-ci-mode-hook 'maybe-lsp)
(add-hook 'sh-mode-hook 'maybe-lsp)
(add-hook 'rust-mode-hook 'maybe-lsp)
(add-hook 'rust-ts-mode-hook 'maybe-lsp)
(add-hook 'vimrc-mode-hook 'maybe-lsp)
(add-hook 'racket-mode-hook 'maybe-lsp)
(add-hook 'lisp-mode-hook 'maybe-lsp)
(add-hook 'solidity-mode-hook 'maybe-lsp)
(add-hook 'rustic-mode-hook 'maybe-lsp)
(add-hook 'nix-mode-hook 'maybe-lsp)
(add-hook 'js-mode-hook 'maybe-lsp)
(add-hook 'typescript-mode-hook 'maybe-lsp)
(add-hook 'haskell-mode-hook #'maybe-lsp)
(add-hook 'prolog-mode-hook #'maybe-lsp)
(add-hook 'purescript-mode-hook 'maybe-lsp)

;; These modes are "clojure"
(dolist (m '(clojure-mode
             clojurec-mode
             clojurescript-mode
             clojurex-mode))
  (add-to-list 'lsp-language-id-configuration `(,m . "clojure")))

;; (dolist (m '(rustic-mode rust-ts-mode))
;;   (add-to-list 'lsp-language-id-configuration `(,m . "rust")))

(setq lsp-enable-indentation nil)

(if (not (inside-docker-p))
    (setq lsp-clojure-server-command '("bash" "-c" "clojure-lsp")))
;; Up to here is ok

(setq ccls-executable (executable-find "ccls"))

(use-package lsp-ui-peek
  :config)

(defun lsp-set-cfg ()
  (let ((lsp-cfg `(:pyls (:configurationSources ("flake8")))))
    (lsp--set-configuration lsp-cfg)))

;; https://www.mortens.dev/blog/emacs-and-the-language-server-protocol/
(setq lsp-clients-clangd-args '("-j=4" "-background-index" "-log=error"))

(use-package lsp-mode
  :hook
  ((go-mode c-mode c++-mode) . lsp)
  :bind
  (:map lsp-mode-map
        ("C-c r" . lsp-rename))
  :config

  (use-package lsp-ui
    :preface
    (defun ladicle/toggle-lsp-ui-doc ()
      (interactive)
      (if lsp-ui-doc-mode
          (progn
            (lsp-ui-doc-mode -1)
            (lsp-ui-doc--hide-frame))
        (lsp-ui-doc-mode 1)))
    :bind
    (:map lsp-mode-map
          ("C-c C-r" . lsp-ui-peek-find-references)
          ("C-c C-j" . lsp-ui-peek-find-definitions)
          ("C-c i" . lsp-ui-peek-find-implementation)
          ("C-c m" . lsp-ui-imenu)
          ("C-c s" . lsp-ui-sideline-mode)
          ("C-c d" . ladicle/toggle-lsp-ui-doc))
    :hook
    (lsp-mode . lsp-ui-mode))

  ;; DAP
  (use-package dap-mode
    :custom
    (dap-go-debug-program `("node" "$HOME/.extensions/go/out/src/debugAdapter/goDebug.js"))
    :config
    (dap-mode 1)
    (require 'dap-hydra)
    (require 'dap-gdb-lldb) ; download and expand lldb-vscode to the =$HOME/.extensions/webfreak.debug=
    (require 'dap-go) ; download and expand vscode-go-extenstion to the =$HOME/.extensions/go=
    (use-package dap-ui
      :ensure nil
      :config
      (dap-ui-mode 1))))

(setq lsp-inhibit-message t)

(defun pen-lsp--managed-mode-hook-body ()
  (interactive)
  (remove-hook 'post-self-insert-hook 'lsp--on-self-insert t)
  (setq-local indent-region-function (function handle-formatters)))

(add-hook 'lsp--managed-mode-hook #'pen-lsp--managed-mode-hook-body)

(defun lsp-ui-flycheck-list ()
  "List all the diagnostics in the whole workspace."
  (interactive)
  (let ((buffer (get-buffer-create "*lsp-diagnostics*"))
        (workspace lsp--cur-workspace)
        (window (selected-window)))
    (with-current-buffer buffer
      (lsp-ui-flycheck-list--update window workspace))
    (add-hook 'lsp-after-diagnostics-hook 'lsp-ui-flycheck-list--refresh nil t)
    (setq lsp-ui-flycheck-list--buffer buffer)
    (display-buffer
     buffer)))

(setq dap-python-executable "python-for-lsp")

(defun dap-python-debug-and-hydra (&optional cmd pyver)
  (interactive)
  (if cmd
      (progn
        (if pyver
            (pen-sn (concat "cd $HOME/scripts; ln -sf `which " pyver "` python-for-lsp-sym")))

        (let* ((cmdwords (s-split " " cmd))
               (scriptname (car cmdwords))
               (args (pen-umn (s-join " " (cdr cmdwords)))))
          (with-current-buffer (find-file (pen-umn scriptname))
            (save-excursion
              (dap-debug `(:type "python" :args ,args :cwd OBnil :target-module nil :request "launch" :name "Python :: Run Configuration")))
            (find-file (pen-umn scriptname)))))
    (progn
      (let ((cbuf (current-buffer)))
        ;; (message "hi")
        (dap-debug `(:type "python" :args "" :cwd nil :target-module nil :request "launch" :name "Python :: Run Configuration"))
        (switch-to-buffer cbuf)))))

;; pen-map overrides this

;; mnm doc string
(defun lsp-ui-doc--extract-marked-string (marked-string &optional language)
  "Render the MARKED-STRING with LANGUAGE."
  (string-trim-right
   (let* ((string (if (stringp marked-string)
                      (pen-mnm marked-string)
                    (lsp:markup-content-value marked-string)))
          (with-lang (lsp-marked-string? marked-string))
          (language (or (and with-lang
                             (or (lsp:marked-string-language marked-string)
                                 (lsp:markup-content-kind marked-string)))
                        language))
          (markdown-hr-display-char nil))
     (cond
      (lsp-ui-doc-use-webkit
       (if (and language (not (string= "text" language)))
           (format "```%s\n%s\n```" language string)
         string))
      (t (lsp--render-element (lsp-ui-doc--inline-formatted-string string)))))))

;; This minimises the sideline strings
(defun lsp-ui-sideline--extract-info (contents)
  "Extract the line to print from CONTENTS.
CONTENTS can be differents type of values:
MarkedString | MarkedString[] | MarkupContent (as defined in the LSP).
We prioritize string with a language (which is probably a type or a
function signature)."
  (when contents
    (cond
     ((lsp-marked-string? contents)
      (lsp:set-marked-string-value contents (pen-mnm (lsp:marked-string-value contents)))
      contents)
     ((vectorp contents)
      (seq-find (λ (it) (and (lsp-marked-string? it)
                                  (lsp-get-renderer (lsp:marked-string-language it))))
                contents))
     ((lsp-markup-content? contents)
      ;; This successfully minimises haskell sideline strings
      (lsp:set-markup-content-value contents (pen-mnm (lsp:markup-content-value contents)))
      contents))))

(advice-remove-all-from 'lsp-ui-peek-find-references)

(defun lsp-ui-peek--find-xrefs (input method param)
  "Find INPUT references.
METHOD is ‘references’, ‘definitions’, `implementation` or a custom kind.
PARAM is the request params."
  (setq lsp-ui-peek--method method)
  (let ((xrefs (lsp-ui-peek--get-references method param)))
    (unless xrefs
      (user-error "Not found for: %s"  input))
    (xref-push-marker-stack)
    (when (featurep 'evil-jumps)
      (lsp-ui-peek--with-evil-jumps (evil-set-jump)))
    (if (and (not lsp-ui-peek-always-show)
             (not (cdr xrefs))
             (= (length (plist-get (car xrefs) :xrefs)) 1))
        (error "Here is the only instance.")
        (lsp-ui-peek-mode)
        (lsp-ui-peek--show xrefs))))

;; The threshold didn't work, so I've disabled them
(setq lsp-enable-file-watchers nil)
(setq lsp-file-watch-threshold 10)

;; This was infinitely looping and lagging lsp for haskell
(setq lsp-semantic-tokens-enable nil)

(lsp-defun lsp-ui-doc--callback ((hover &as &Hover? :contents) bounds buffer)
  "Process the received documentation.
HOVER is the doc returned by the LS.
BOUNDS are points of the symbol that have been requested.
BUFFER is the buffer where the request has been made."
  (if
      (not (and
            hover
            (>= (point) (car bounds)) (<= (point) (cdr bounds))
            (eq buffer (current-buffer))))
      (setq contents "-")
    (setq contents (or (-some->>
                           ;; "shane"
                           contents
                         lsp-ui-doc--extract
                         (replace-regexp-in-string "\r" ""))
                       ;; (replace-regexp-in-string "\r" "" (lsp-ui-doc--extract contents))
                       "Cant extract or docs are empty")))

  (progn
    (setq lsp-ui-doc--bounds bounds)
    (lsp-ui-doc--display
     (thing-at-point 'symbol t)
     contents)))

(defun lsp-ui-doc--extract (contents)
  "Extract the documentation from CONTENTS.
CONTENTS can be differents type of values:
MarkedString | MarkedString[] | MarkupContent (as defined in the LSP).
We don't extract the string that `lps-line' is already displaying."
  (cond
   ((vectorp contents) ;; MarkedString[]
    (mapconcat 'lsp-ui-doc--extract-marked-string
               (lsp-ui-doc--filter-marked-string (seq-filter #'identity contents))
               "\n\n"
               ;; (propertize "\n\n" 'face '(:height 0.4))
               ))
   ;; when we get markdown contents, render using emacs gfm-view-mode / markdown-mode
   ((and (lsp-marked-string? contents)
         (lsp:marked-string-language contents))
    (lsp-ui-doc--extract-marked-string (lsp:marked-string-value contents)
                                       (lsp:marked-string-language contents)))
   ((lsp-marked-string? contents) (lsp-ui-doc--extract-marked-string contents))
   ((and (lsp-markup-content? contents)
         (string= (lsp:markup-content-kind contents) lsp/markup-kind-markdown))
    (lsp-ui-doc--extract-marked-string (lsp:markup-content-value contents) lsp/markup-kind-markdown))
   ((and (lsp-markup-content? contents)
         (string= (lsp:markup-content-kind contents) lsp/markup-kind-plain-text))
    (lsp:markup-content-value contents))
   (t
    ;; This makes python work
    contents)))

(defun pen-lsp-get-hover-docs ()
  (interactive)
  (let* ((ht (lsp-request "textDocument/hover" (lsp--text-document-position-params)))
         (docs
          (if (hash-table-p ht)
              (lsp-ui-doc--extract (gethash "contents" ht))
            "")))
    (if (and docs (not (string-empty-p docs))) (if (called-interactively-p 'interactive)
                                                   ;; (tvd docs)

                                                   (cond
                                                    ;; If it looks like markdown, then render markdown
                                                    ((or ;; (eq major-mode 'haskell-mode)
                                                      (re-match-p "```" docs))
                                                     (new-buffer-from-string
                                                      docs
                                                      nil 'markdown-mode))
                                                    (t
                                                     (new-buffer-from-string
                                                      docs
                                                      nil 'text-mode)))
                                                 docs)
      (error "No docs"))))

(defun pen-lsp-open-hover-docs-url ()
  (interactive)
  (let* ((doc (pen-lsp-get-hover-docs))
         (url (pen-snc "scrape \"](.*)\" | sed -e 's/^..//' -e 's/)$//'" (pen-lsp-get-hover-docs))))
    (pen-lg url)))

(setq lsp-enable-on-type-formatting nil)

(advice-add 'lsp--document-highlight :around #'ignore-errors-around-advice)

(require 'lsp-metals)

(defun lsp--server-binary-present? (client)
  (unless (equal (lsp--client-server-id client) 'lsp-pwsh)
    nil
    (condition-case ()
        ;; Suppresses the error
        (-some-> client lsp--client-new-connection (plist-get :test?) (λ (&rest a) (ignore-errors funcall ,@a)))
      ;; (-some-> client lsp--client-new-connection (plist-get :test?) funcall)
      (error nil)
      (args-out-of-range nil))))

(defun lsp-list-servers (&optional update)
  (mapcar 'car (--map (cons (funcall
                             (-compose #'symbol-name #'lsp--client-server-id) it) it)
                      (or (->> lsp-clients
                            (ht-values)
                            (-filter
                             (-andfn
                              (-orfn (-not #'lsp--server-binary-present?)
                                     (-const update))
                              (-not #'lsp--client-download-in-progress?)
                              #'lsp--client-download-server-fn)))
                          (user-error "There are no servers with automatic installation")))))
(advice-add 'lsp-list-servers :around #'ignore-errors-around-advice)

(defun lsp-list-all-servers ()
  (interactive)
  (if (interactive-p)
      (pen-etv (pps (lsp-list-servers t)))
    (lsp-list-servers t)))

(defun lsp-get-server-for-install (name)
  (interactive (list (fz (lsp-list-all-servers))))
  (cdr (car (-filter (λ (sv) (string-equal (car sv) name))
                     (--map (cons (funcall
                                   (-compose #'symbol-name #'lsp--client-server-id) it) it)
                            (or (->> lsp-clients
                                     (ht-values)
                                     (-filter (-andfn
                                               (-orfn (-not #'lsp--server-binary-present?)
                                                      (-const t))
                                               (-not #'lsp--client-download-in-progress?)
                                               #'lsp--client-download-server-fn)))
                                (user-error "There are no servers with automatic installation")))))))

(defun lsp-install-server-by-name (name)
  (interactive (list (fz (lsp-list-all-servers))))
  (lsp--install-server-internal (lsp-get-server-for-install name)))

(defun lsp--sort-completions (completions)
  (lsp-completion--sort-completions completions))

(defun lsp--annotate (item)
  (lsp-completion--annotate item))

(defun lsp--resolve-completion (item)
  (lsp-completion--resolve item))

(defun lsp-install-server-update-advice (proc update)
  (cond
   (update (setq update nil))
   ((not update) (setq update t)))
  (let ((res (apply proc (list update))))
    res))
(advice-add 'lsp-install-server :around #'lsp-install-server-update-advice)

(defun lsp-on-change-around-advice (proc &rest args)
  (message "lsp-on-change called with args %S" args)
  (let ((res (apply proc args)))
    (message "lsp-on-change returned %S" res)
    res))
(advice-remove 'lsp-on-change #'lsp-on-change-around-advice)

(defun lsp-headerline--arrow-icon ()
  "Build the arrow icon for headerline breadcrumb."
  (propertize "›" 'face 'lsp-headerline-breadcrumb-separator-face))

(defun dired-lsp-binaries ()
  (interactive)
  (dired lsp-server-install-dir))

(defun lsp-ui-peek-find-references (&optional include-declaration extra)
  "Find references to the IDENTIFIER at point."
  (interactive)

  (let ((thing (intern (pen-thing-at-point)))
        (p (point))
        (m (mark))
        (s mark-active))
    (deactivate-mark)
    (eval
     `(try
       ;; Try this, otherwise, reselect
       (lsp-ui-peek--find-xrefs ',thing
                                "textDocument/references"
                                (append ,extra (lsp--make-reference-params nil ,include-declaration)))
       (progn
         (set-mark ,m)
         (goto-char ,p)
         ,(if s
              '(progn
                 (activate-mark))
            '(progn
               (deactivate-mark)))
         (error "lsp-ui-peek-find-references failed"))))))

(defcustom lsp-go-langserver-command '("gopls")
  "Command to start the server."
  :type 'string
  :package-version '(lsp-mode . "7.1"))
(setq lsp-go-langserver-command "gopls")

(defcustom lsp-racket-langserver-command '("racket-lsp")
  "Command to start the server."
  :type 'string
  :package-version '(lsp-mode . "7.1"))
(setq lsp-racket-langserver-command "racket-lsp")

(defcustom lsp-rust-langserver-command '("rust-analyzer")
  "Command to start the server."
  :type 'string
  :package-version '(lsp-mode . "7.1"))
(setq lsp-rust-langserver-command "rust-analyzer")

(defcustom lsp-common-lisp-langserver-command '("cl-lsp")
  "Command to start the server."
  :type 'string
  :package-version '(lsp-mode . "7.1"))
(setq lsp-common-lisp-langserver-command "cl-lsp")

(lsp-register-client
 (make-lsp-client :new-connection (lsp-stdio-connection
                                   (λ ()
                                     `(,(or (executable-find (cl-first lsp-yaml-server-command))
                                            (lsp-package-path 'yaml-language-server))
                                       ,@(cl-rest lsp-yaml-server-command))))
                  :major-modes '(yaml-mode
                                 gitlab-ci-mode)
                  :priority 0
                  :server-id 'yamlls
                  :initialized-fn (λ (workspace)
                                    (with-lsp-workspace workspace
                                      (lsp--set-configuration
                                       (lsp-configuration-section "yaml"))))
                  :download-server-fn (λ (_client callback error-callback _update?)
                                        (lsp-package-ensure 'yaml-language-server
                                                            callback error-callback))))

(defun lsp-around-advice-remove-overlays (proc &rest args)
  (lsp-ui-sideline--delete-ov)
  (lsp-ui-doc-hide)
  (let ((res (apply proc args)))
    res))

(defun lsp--create-default-error-handler-around-advice (proc &rest args)
  (λ (e) nil))
(advice-add 'lsp--create-default-error-handler :around #'lsp--create-default-error-handler-around-advice)

(defun lsp--error-string-around-advice (proc &rest args)
  nil)
(advice-add 'lsp--error-string :around #'lsp--error-string-around-advice)

(defun lsp-around-advice (proc &rest args)
  (if (pen-rc-test "lsp" ;; pen-disable-lsp
                 )
      (let ((res (apply proc args)))
        res)))
(advice-add 'lsp :around #'lsp-around-advice)

(defun lsp-lens-refresh-around-advice (proc &rest args)
  (if (pen-rc-test "lsp_lens")
      (let ((res (apply proc args)))
        res)))
(advice-add 'lsp-lens-refresh :around #'lsp-lens-refresh-around-advice)

;; (-union '("a" "b") '("a"))
(defun ensure-language-servers-installed ()
  (interactive)
  (let* ((ensure-these '("pursls"
                         "jdtls"))
         (servers-not-installed (lsp-list-servers))
         (install-these (-intersection ensure-these servers-not-installed)))
    (dolist (s install-these)
      (lsp-install-server-by-name s))))

(ensure-language-servers-installed)

(defun helm-lsp-code-actions()
  "Show lsp code actions using helm."
  (interactive)
  (let ((actions (lsp-code-actions-at-point)))
    (cond
     ((seq-empty-p actions) (signal 'lsp-no-code-actions nil))
     ;; ((and (eq (seq-length actions) 1) lsp-auto-execute-action)
     ;;  (lsp-execute-code-action (lsp-seq-first actions)))
     (t (helm :sources
              (helm-build-sync-source
                  "Code Actions"
                :candidates actions
                :candidate-transformer
                (λ (candidates)
                  (-map
                   (-lambda ((candidate &as
                                        &CodeAction :title))
                     (list title :data candidate))
                   candidates))
                :action '(("Execute code action" . (λ(candidate)
                                                     (lsp-execute-code-action (plist-get candidate :data))))))
              ;; :exec-when-only-one nil
              )))))

(defun pen--get-overlay-text (o)
  "Get text inside overlay O."
  (buffer-substring (overlay-start o) (overlay-end o)))

;; TODO Extract this information from LSP manually
;; It's really hairy but may be necessary
;; j:lsp-ui-sideline--push-info
(defun pen--lsp-get-sideline-text ()
  "Get text inside overlay O."
  (interactive)
  (let ((si
         (pen-list2str
          (reverse
           (loop for o in lsp-ui-sideline--ovs
                 collect
                 ;; (buffer-substring (overlay-start o) (overlay-end o))
                 ;; (overlay-properties o)
                 (s-replace-regexp
                  "^\\(.*[^ ]+\\)  \\([^ ]+\\)$"
                  "\\2\n\\1\n"
                  (s-replace-regexp
                   " *$"
                   ""
                   (s-replace-regexp
                    "^ *"
                    ""
                    (str (overlay-get o 'after-string))))))))))
    (if (interactive-p)
        (pen-etv si)
      si)))

;; error list
(defun pen-lsp-error-list (&optional path)
  (interactive (list (get-path)))
  (let ((l))
    (maphash (λ (file diagnostic)
               (if (string-equal path file)
                   (dolist (diag diagnostic)
                     (-let* (((&Diagnostic :message :severity? :source?
                                           :range (&Range :start (&Position :line start-line))) diag)
                             (formatted-message (or (if source? (format "%s: %s" source? message) message) "???"))
                             (severity (or severity? 1))
                             (line (1+ start-line))
                             (face (cond ((= severity 1) 'error)
                                         ((= severity 2) 'warning)
                                         (t 'success)))
                             (text (concat (number-to-string line)
                                           ": "
                                           (car (split-string formatted-message "\n")))))
                       (add-to-list 'l text t)))))
             (lsp-diagnostics))
    (pen-etv (pp-to-string l))))

;; Disable clicking lens stuff -- such as labels that say '2 references'
(defun lsp-lens--keymap (command)
  "Build the lens keymap for COMMAND."
  (-doto (make-sparse-keymap)
    (identity)))

(advice-add 'lsp-lens--display :around #'ignore-errors-around-advice)

(cl-defun lsp-find-definition (&key display-action)
  "Find definitions of the symbol under point."
  (interactive)
  (let ((r
         (lsp-find-locations "textDocument/definition" nil :display-action display-action)))

    (if (and
         (stringp r)
         (re-match-p "LSP :: Not found" r))
        (error r)
      r)))

(progn
  (define-key rust-mode-map (kbd "TAB") #'company-indent-or-complete-common)
  (define-key lsp-ui-imenu-mode-map (kbd "<return>") 'lsp-ui-imenu--view)
  (define-key lsp-ui-imenu-mode-map (kbd "RET") 'lsp-ui-imenu--view)
  (define-key lsp-ui-flycheck-list-mode-map (kbd "<M-RET>") 'lsp-ui-flycheck-list--visit)
  (define-key lsp-ui-flycheck-list-mode-map (kbd "RET") 'lsp-ui-flycheck-list--view)
  (define-key lsp-ui-peek-mode-map (kbd "<prior>") #'lsp-ui-peek--select-prev-file)
  (define-key lsp-ui-peek-mode-map (kbd "<next>") #'lsp-ui-peek--select-next-file)
  (define-key lsp-ui-peek-mode-map "j" (kbd "<down>"))
  (define-key lsp-ui-peek-mode-map "k" (kbd "<up>"))
  (define-key lsp-ui-peek-mode-map "h" (kbd "<left>"))
  (define-key lsp-ui-peek-mode-map "l" (kbd "<right>"))
  (define-key lsp-ui-peek-mode-map (kbd "M-p") (kbd "<left>"))
  (define-key lsp-ui-peek-mode-map (kbd "M-n") (kbd "<right>"))
  (define-key lsp-mode-map (kbd "s-l 8") 'pen--lsp-get-sideline-text)
  (define-key lsp-mode-map (kbd "s-8") 'pen--lsp-get-sideline-text)
  (define-key lsp-mode-map (kbd "s-l 9") 'pen-lsp-get-hover-docs)
  (define-key lsp-mode-map (kbd "s-9") 'pen-lsp-get-hover-docs)
  (define-key global-map (kbd "s-i") 'lsp-install-server)
  (define-key global-map (kbd lsp-keymap-prefix) lsp-command-map)
  (define-key lsp-browser-mode-map (kbd "TAB") 'widget-forward)
  (define-key lsp-browser-mode-map (kbd "<backtab>") 'widget-backward)
  (define-key tree-widget-button-keymap (kbd "SPC") 'widget-button-press)
  (define-key lsp-browser-mode-map (kbd "SPC") 'widget-button-press)
  (define-key lsp-mode-map (kbd "s-a") 'lsp-execute-code-action)
  (define-key lsp-mode-map (kbd "s-a") 'helm-lsp-code-actions)
  (define-key lsp-mode-map (kbd "s-a") 'lsp-execute-code-action)
  (define-key lsp-mode-map (kbd "s-a") 'helm-lsp-code-actions)
  (define-key lsp-mode-map (kbd "s-l s D") 'lsp-disconnect)
  (define-key lsp-mode-map (kbd "s-l s d") 'lsp-describe-session)
  (define-key lsp-mode-map (kbd "s-l s q") 'lsp-workspace-shutdown)
  (define-key lsp-mode-map (kbd "s-l s r") 'lsp-workspace-restart)
  (define-key lsp-mode-map (kbd "s-l s s") 'lsp))

(advice-add 'lsp--ensure-lsp-servers :around #'ignore-errors-around-advice)
(advice-add 'lsp--on-idle :around #'ignore-errors-around-advice)

(setq lsp-rust-analyzer-store-path "/root/.emacs.d/host/pen.el/scripts/rust-analyzer")
;; (setq lsp-rust-analyzer-store-path "/root/.rustup/toolchains/nightly-x86_64-unknown-linux-gnu/bin/rust-analyzer")

(setq lsp-python-ms-python-executable-cmd "python3.8")

(provide 'pen-lsp)
