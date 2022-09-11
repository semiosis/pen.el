(require 'lsp-mode)

(defcustom pen-lsp-executable-path "pen-lsp"
  "Path to pen executable."
  :group 'pen-lsp
  :type 'string)

(defcustom pen-lsp-server-args '()
  "Extra arguments for the pen language server."
  :group 'pen-lsp
  :type '(repeat string))

(defun pen-lsp--server-command ()
  "Generate the language server startup command."
  ;; `(,pen-lsp-executable-path "--lib" "pen-langserver" ,@pen-lsp-server-args)
  `(,pen-lsp-executable-path ,@pen-lsp-server-args))

;; (pen-etv (pps (lsp-configuration-section "pylsp")))
;; (pen-etv (pps (lsp-configuration-section "pen")))

;; Ensure these are set

;; {
;;     "initializationOptions": {
;;         "documentFormatting": true,
;;         "hover": true,
;;         "documentSymbol": true,
;;         "codeAction": true,
;;         "completion": true
;;     }
;; }

(defcustom lsp-pen-language-features-code-actions t
  "Enable/disable code actions."
  :type 'boolean
  :group 'lsp-pen
  :package-version '(lsp-mode . "8.0.0"))

(defcustom lsp-pen-language-features-execute-command t
  "Enable/disable execute command."
  :type 'boolean
  :group 'lsp-pen
  :package-version '(lsp-mode . "8.0.0"))

(defcustom lsp-pen-language-features-completion t
  "Enable/disable completion."
  :type 'boolean
  :group 'lsp-pen
  :package-version '(lsp-mode . "8.0.0"))

(lsp-register-custom-settings
 '(("pen.languageFeatures.codeActions" lsp-pen-language-features-code-actions t)
   ("pen.languageFeatures.executeCommand" lsp-pen-language-features-execute-command t)
   ("pen.languageFeatures.completion" lsp-pen-language-features-completion t)))

;; (defvar pen-lsp--config-options `())

;; Set up for text-mode currently
;; I want to do all modes

(defset pen-lsp-modes '(text-mode
                        prompt-description-mode
                        emacs-lisp-mode
                        sh-mode
                        ;; prolog-mode
                        org-mode awk-mode eww-mode
                        special-mode python-mode
                        prog-mode))

;; This is for the language server to know what language I'm using.
;; Unfortunately, merely using prog-mode is not enough.
;; I have to specify the exact mode, for hte moment
;; (add-to-list 'lsp-language-id-configuration '(text-mode . "text"))
;; (add-to-list 'lsp-language-id-configuration `(org-mode . "org"))
;; (add-to-list 'lsp-language-id-configuration `(awk-mode . "awk"))
;; (add-to-list 'lsp-language-id-configuration `(eww-mode . "global"))
;; (add-to-list 'lsp-language-id-configuration `(sh-mode . "global"))
;; (add-to-list 'lsp-language-id-configuration `(emacs-lisp-mode . "global"))
;; (add-to-list 'lsp-language-id-configuration `(special-mode . "global"))
;; (add-to-list 'lsp-language-id-configuration `(python-mode . "global"))
;; (add-to-list 'lsp-language-id-configuration `(prog-mode . "global"))

(defun pen-lsp-update-languages ()
  (interactive)

  (setq lsp-language-id-configuration nil)
  (cl-loop for m in pen-lsp-modes do
           (cond
            ((eq m 'emacs-lisp-mode) (add-to-list 'lsp-language-id-configuration `(,m . "elisp")))
            (t (add-to-list 'lsp-language-id-configuration `(,m . "global")))))

  (lsp-register-client
   (make-lsp-client :new-connection
                    (lsp-stdio-connection 'pen-lsp--server-command)
                    :major-modes pen-lsp-modes
                    :server-id 'pen
                    :initialized-fn (lambda (workspace)
                                      (with-lsp-workspace workspace
                                        (lsp--set-configuration
                                         (lsp-configuration-section "pen")
                                         ;; (lsp-configuration-section "pen")
                                         ;; `(:pen ,pen-lsp--config-options)
                                         ))))))

(pen-lsp-update-languages)

(add-hook 'text-mode-hook #'lsp)
(remove-hook 'text-mode-hook #'lsp)


(custom-set-variables
 ;; debug
 '(lsp-print-io t)
 '(lsp-trace t)
 '(lsp-print-performance t)

 ;; general
 '(lsp-auto-guess-root t)
 '(lsp-document-sync-method 'incremental) ;; none, full, incremental, or nil
 '(lsp-response-timeout 10)

 ;; (lsp-prefer-flymake t)
 '(lsp-prefer-flymake nil) ;; t(flymake), nil(lsp-ui), or :none
 ;; flymake is shit. do not use it

 ;; go-client
 ;; '(lsp-clients-go-server-args '("--cache-style=always" "--diagnostics-style=onsave" "--format-style=goimports"))

 '(company-lsp-cache-candidates t) ;; auto, t(always using a cache), or nil
 '(company-lsp-async t)
 '(company-lsp-enable-recompletion t)
 '(company-lsp-enable-snippet t)
 ;; '(lsp-clients-go-server-args '("--cache-style=always" "--diagnostics-style=onsave" "--format-style=goimports"))
 '(lsp-document-sync-method (quote incremental))

                                        ;top right docs
 '(lsp-ui-doc-enable t)
 '(lsp-ui-doc-header t)
 '(lsp-ui-doc-include-signature t)
 '(lsp-ui-doc-max-height 30)
 '(lsp-ui-doc-max-width 120)
 '(lsp-ui-doc-position (quote at-point))

 ;; If this is true then you can't see the docs in terminal
 '(lsp-ui-doc-use-webkit nil)
 '(lsp-ui-flycheck-enable t)

 '(lsp-ui-imenu-enable t)
 '(lsp-ui-imenu-kind-position (quote top))
 '(lsp-ui-peek-enable t)

 '(lsp-ui-peek-fontify 'on-demand) ;; never, on-demand, or always
 '(lsp-ui-peek-list-width 50)
 '(lsp-ui-peek-peek-height 20)
 '(lsp-ui-sideline-code-actions-prefix "" t)

                                        ;inline right flush docs
 '(lsp-ui-sideline-enable t)

 '(lsp-ui-sideline-ignore-duplicate t)
 '(lsp-ui-sideline-show-code-actions t)
 '(lsp-ui-sideline-show-diagnostics t)
 '(lsp-ui-sideline-show-hover t)
 '(lsp-ui-sideline-show-symbol t))



;; one of these breaks
(setq lsp-completion-no-cache t)
(setq lsp-display-inline-image nil)
;; (setq lsp-document-sync-method 'incremental)
(setq lsp-document-sync-method nil)
;; (setq lsp-document-sync-method 'full)
;; This makes bash look bad with an entire
(setq lsp-eldoc-render-all nil)
;; (setq lsp-eldoc-render-all nil)
(setq lsp-enable-dap-auto-configure t)
;; (setq lsp-enable-file-watchers t)
(setq lsp-enable-file-watchers nil)
(setq lsp-enable-folding t)
(setq lsp-enable-imenu t)
;; (setq lsp-enable-indentation nil)
(setq lsp-enable-indentation t)
(setq lsp-enable-links t)
;; (setq lsp-enable-on-type-formatting nil)
(setq lsp-enable-on-type-formatting t)
;; (setq lsp-enable-semantic-highlighting nil)
(setq lsp-enable-semantic-highlighting t)
(setq lsp-enable-snippet t)
;; lsp-restart can be anything which isn't handled to disable it, no, off, etc.
(setq lsp-restart 'no)
(setq lsp-enable-symbol-highlighting t)
(setq lsp-enable-text-document-color t)
(setq lsp-enable-xref t)
(setq lsp-folding-line-folding-only t)
;; nil no limit
(setq lsp-lens-debounce-interval 0.2)
(setq lsp-folding-range-limit nil)
;; (setq lsp-lens-enable nil)
(setq lsp-lens-enable t)
;; (setq lsp-log-io t)
(setq lsp-log-io nil)
;; (setq lsp-server-trace t)
(setq lsp-server-trace nil)
;; (setq lsp-print-performance t)
(setq lsp-print-performance nil)

(setq lsp-modeline-code-actions-enable t)

(setq lsp-modeline-code-actions-segments '(count name))
(setq lsp-headerline-breadcrumb-enable t)
;; Even in GUI emacs, do not use a child frame
(setq lsp-ui-doc-use-childframe nil)
(setq lsp-headerline-breadcrumb-segments '(path-up-to-project file))

;; long docs in the modeline (eldoc) were annoying
;; one of these worked
(setq lsp-signature-render-documentation nil)
(setq lsp-eldoc-render-all nil)
(setq lsp-eldoc-enable-hover nil)

(require 'el-patch)
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
        (seq-do (lambda (client)
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
                   (mapconcat (lambda (client)
                                (symbol-name (lsp--client-server-id client)))
                              clients
                              " ")))
       ;; no matches
       ((-> #'lsp--matching-clients? lsp--filter-clients not)
        (lsp--error
         (el-patch-swap
           "There are no language servers supporting current mode `%s' registered with `lsp-mode'.
This issue might be caused by:
1. The language you are trying to use does not have built-in support in `lsp-mode'. You must install the required support manually. Examples of this are `lsp-java' or `lsp-metals'.
2. The language server that you expect to run is not configured to run for major mode `%s'. You may check that by checking the `:major-modes' that are passed to `lsp-register-client'.
3. `lsp-mode' doesn't have any integration for the language behind `%s'. Refer to https://emacs-lsp.github.io/lsp-mode/page/languages and https://langserver.org/ ."
           "No LSP server for current mode")
         major-mode major-mode major-mode))))))

;; TODO Make this default to Pen ESP
(defun lsp--matching-clients? (client)
  (and
   ;; both file and client remote or both local
   ;; (get-path nil nil nil nil t)
   (eq (---truthy? (file-remote-p (buffer-file-name)))
       (---truthy? (lsp--client-remote? client)))

   ;; activation function or major-mode match.
   (if-let ((activation-fn (lsp--client-activation-fn client)))
       (funcall activation-fn (buffer-file-name) major-mode)
     (-contains? (lsp--client-major-modes client) major-mode)
     ;; (or
     ;;  (-contains? (lsp--client-major-modes client) major-mode)
     ;;  ;; Frustratingly, it still doesn't work
     ;;  (string-equal "pen" (str (lsp--client-server-id client))))
     )

   ;; check whether it is enabled if `lsp-enabled-clients' is not null
   (or (null lsp-enabled-clients)
       (or (member (lsp--client-server-id client) lsp-enabled-clients)
           (ignore (lsp--info "Client %s is not in lsp-enabled-clients"
                              (lsp--client-server-id client)))))

   ;; check whether it is not disabled.
   (not (lsp--client-disabled-p major-mode (lsp--client-server-id client)))))

(defun lsp-ui-pen-diagnostics ()
  "Show diagnostics belonging to the current line.
Loop over flycheck errors with `flycheck-overlay-errors-in'.
Find appropriate position for sideline overlays with `lsp-ui-sideline--find-line'.
Push sideline overlays on `lsp-ui-sideline--ovs'."
  (let ((buffer (current-buffer))
        (bol (line-beginning-position))
        (eol (line-end-position)))

    (when (and (bound-and-true-p flycheck-mode)
               (bound-and-true-p lsp-ui-sideline-mode)
               lsp-ui-sideline-show-diagnostics
               (eq (current-buffer) buffer))
      (lsp-ui-sideline--delete-kind 'diagnostics)
      (let ((results '()))
        (dolist (e (flycheck-overlay-errors-in bol (1+ eol)))
          (let* ((lines (--> (flycheck-error-format-message-and-id e)
                          (split-string it "\n")
                          (lsp-ui-sideline--split-long-lines it)))
                 (display-lines (butlast lines (- (length lines) lsp-ui-sideline-diagnostic-max-lines)))
                 (offset 1))
            (dolist (line (nreverse display-lines))
              (let* ((message (string-trim (replace-regexp-in-string "[\t ]+" " " line)))
                     (len (length message))
                     (level (flycheck-error-level e))
                     (face (if (eq level 'info) 'success level))
                     (margin (lsp-ui-sideline--margin-width))
                     ;; (message (progn (add-face-text-property 0 len 'lsp-ui-sideline-global nil message)
                     ;;                 (add-face-text-property 0 len face nil message)
                     ;;                 message))
                     )
                (add-to-list 'results message)))))
        (pen-list2str results)))))

(defun pen-lsp-error-list (&optional path)
  (if (not path)
      (setq path (get-path-nocreate)))
  (let ((l))
    (maphash (lambda (file diagnostic)
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
    l))

;; (mouse-3
;;  (#<window 33 on clojure.core.clj> 201489
;;            (33 . 469)
;;            44934836 nil 201489
;;            (3 . 22)
;;            nil
;;            (3 . 7)
;;            (10 . 21)))

;; (#<window 46 on pen-lsp-client.el> 15059
;;           (5 . 18)
;;           0 nil 15059
;;           (5 . 18)
;;           nil
;;           (0 . 0)
;;           (1 . 0))


;; If I can fabricate the event I can utilise the built-in emacs menu system instead of right-click menu
;; I can simulate it with `(mouse-3 ,(posn-at-point))
;; See j:lsp-mouse-click

(defun pen-lsp-mouse-click (event)
  (interactive (list `(mouse-3 ,(posn-at-point))))

  (let* ((ec (event-start event))
         (choice (x-popup-menu event lsp-mode-menu))
         (action (lookup-key lsp-mode-menu (apply 'vector choice))))

    (select-window (posn-window ec))

    (unless (and (region-active-p) (eq action 'lsp-execute-code-action))
      (goto-char (posn-point ec)))
    (run-with-idle-timer
     0.001 nil
     (lambda ()
       ;; I also had to add ignore-errors here, so I can C-g the menu
       (ignore-errors
         (cl-labels ((check (value) (not (null value))))
           (when choice
             (call-interactively action))))))))
(advice-remove 'pen-lsp-mouse-click #'ignore-errors-around-advice)

;; TODO Test that the daemons are all ready before refreshing
;; make that check because it means the daemons have finished prompting.
;; I could also check more frequently that way
(defun pen-esp-idle-update-docs ()
  (interactive)
  (if lsp-mode
      (progn
        (if lsp-ui-sideline-mode
            (progn
              ;; (lsp-ui-sideline-mode -1)
              (lsp-ui-sideline--delete-ov)
              ;; (lsp-ui-sideline-mode 1)
              (lsp-ui-sideline)))
        (if (and lsp-ui-doc-mode
                 (lsp-ui-doc--visible-p))
            (progn
              (lsp-ui-doc-show))))))
(run-with-idle-timer 10 t 'pen-esp-idle-update-docs)

(define-key lsp-mode-map (kbd "<mouse-3>") nil)

;; $EMACSD/manual-packages/company-lsp/company-lsp.el
;; Sadly can't override because of lexical scope
;; j:company-lsp--candidates-async

;; This will make emacs hang
;; (add-hook 'text-mode-hook #'lsp)

(add-hook 'rust-mode-hook #'maybe-lsp)
(add-hook 'clojure-mode-hook #'maybe-lsp)

(require 'lsp-rust)
(setq lsp-rust-server 'rust-analyzer)

(remove-from-list 'exec-path "/root/.cargo/bin")
(add-to-list 'exec-path "/root/.cargo/bin" t)

(provide 'pen-lsp-client)
;;; pen-lsp.el ends here
