(require 'clojure-mode)
(require 'cider)

;; I don't think I want this, actually, because I do not want to run the mode hooks, and launch cider when opening org-mode documents
(require 'ob-clojure)

;; This is like shackle behaviour - it sets the cursor to the docs when it appears
(setq cider-doc-auto-select-buffer nil)

;; Clojure memory usage (test to see if this is actually working) :
;; e:$EMACSD/pen.el/scripts/java-opts.sh

(require 'clomacs)

(if (inside-docker-p)
    (setq cider-lein-command "pen-lein"))

(setq cider-auto-jump-to-error nil)
(setq cider-repl-pop-to-buffer-on-connect nil)

(pen-with 'cider
          ;; Fixes super annoying message
          (setq cider-allow-jack-in-without-project t))

(defun pen-4clojure-check-and-proceed ()
  "Check the answer and show the next question if it worked."
  (interactive)
  (let ((result (4clojure-check-answers)))
    (unless (string-match "failed." result)
       (4clojure-next-question))))

(define-key clojure-mode-map (kbd "C-c C-c") nil)
(define-key cider-mode-map (kbd "C-c 4") 'pen-4clojure-check-and-proceed)
(define-key cider-mode-map (kbd "C-c C-c") nil)

(require 'monroe)
(add-hook 'clojure-mode-hook 'clojure-enable-monroe)

(define-key monroe-interaction-mode-map (kbd "M-.") nil)
(define-key monroe-interaction-mode-map (kbd "C-c C-r") nil)
(define-key cider-mode-map (kbd "M-.") nil)

(defun pen-cider-macroexpand-1 ()
  (interactive)
  (save-excursion
    (special-lispy-different)
    (cider-macroexpand-1)
    (special-lispy-different)))

(defun pen-cider-macroexpand-1-or-copy ()
  (interactive)
  (if (sor (pen-selected-text-ignore-no-selection))
      (xc)
    (call-interactively 'pen-cider-macroexpand-1)))

(define-key clojure-mode-map (kbd "M-w") #'pen-cider-macroexpand-1-or-copy)

(defmacro pen-cider-eval-return-handler (&rest code)
  "Make a handler for the result."
  `(nrepl-make-response-handler (or buffer (current-buffer))
                                (lambda (buffer value)
                                  (with-current-buffer buffer
                                    (insert
                                     (if (derived-mode-p 'cider-clojure-interaction-mode)
                                         (format "\n%s\n" value)
                                       value))))
                                (lambda (_buffer out)
                                  (cider-emit-interactive-eval-output out))
                                (lambda (_buffer err)
                                  (cider-emit-interactive-eval-err-output err))
                                '()))


(defun pen-cider-eval-last-sexp ()
  "Evaluate the expression preceding point.
If invoked with OUTPUT-TO-CURRENT-BUFFER, print the result in the current
buffer."
  (interactive)
  (cider-interactive-eval nil
                          (cider-eval-print-handler)
                          (cider-last-sexp 'bounds)
                          (cider--nrepl-pr-request-map)))


(defun clojure-select-copy-dependency ()
  (interactive)
  (xc (fz (pen-snc "cd $NOTES; oci clojure-list-deps") nil nil "copy used dep: ")))

(defun clojure-find-deps (use-google &rest query)
  (interactive (list (or
                      (>= (prefix-numeric-value current-prefix-arg) 4)
                      (yes-or-no-p "Use google?"))
                     (read-string-hist "clojure-find-deps query: ")))

  (if (>= (prefix-numeric-value current-prefix-arg) 4)
      (setq use-google t))

  (xc (fz (pen-snc (apply 'pen-cmd "clojure-find-deps"
                               (if use-google
                                   "-gl")
                               (-flatten (mapcar (lambda (e) (s-split " " e)) query)))))))



(require 'clj-refactor)

(defun pen-clojure-mode-hook ()
  (clj-refactor-mode 1)
  (yas-minor-mode 1)
  (define-key clojure-mode-map (kbd "H-*") nil)
  (cljr-add-keybindings-with-prefix "H-*"))

(add-hook 'clojure-mode-hook #'pen-clojure-mode-hook)

;; This only prevents the buffer from being selected (which was SUPER annoying)
;; What about preventing it from being shown altogether?
;; It's appearing even when I switch terminals and are not working in clojure
(setq cider-auto-select-error-buffer nil)
;; This was supremely annoying until I found the option to turn it off
;; (setq cider-show-error-buffer 'only-in-repl)
(setq cider-show-error-buffer nil)

(defvar pen-do-cider-auto-jack-in t)

(defun cider-auto-jack-in ()
  "cider-auto-jack-in is needed for cider-jack-in-around-advice to work."
  (interactive)

  ;; (tv (buffer-name))
  ;; This is to prevent cider jacking in when markdown documentation appears.
  ;; TODO Also make it so it doesn't start when org files are opened
  (if (not (re-match-p "-fontification:" (buffer-name)))

      ;; Make sure to be more precise. jack in with cljs too if it should
      ;; j:cider-jack-in-clj
      ;; j:cider-jack-in-cljs
      ;; j:cider-jack-in-clj&cljs

      (if (and
           ;; Only automatically connect if this is a git repo -- prevents cider from asking for the project
           (projectile-project-p)
           (derived-mode-p 'clojure-mode)
           (not (derived-mode-p 'clojerl-mode))
           (not (minor-mode-p org-src-mode)))
          (progn
            (run-with-timer
             2 nil
             (eval
              `(lm
                ;; ignore-errors here prevents this breaking, which was annoying. I couldn't open from ranger
                ;; pin mount.clj
                ;; 'pen-emacsclient' '-s' 'DEFAULT' '-a' '' '-t' -e "mount.clj"
                ;; 'pen-emacsclient' '-s' 'DEFAULT' '-a' '' '-t' -e "(ignore-errors (find-file \"mount.clj\"))"
                (ignore-errors
                  (if (not (minor-mode-p org-src-mode))
                      (try
                       (if ;; pen-do-cider-auto-jack-in
                           (pen-rc-test "cider")
                           (progn
                             (message "Jacking in. Please wait.")
                             (with-current-buffer ,(current-buffer)
                               (cond
                                ((derived-mode-p 'clojure-mode)
                                 (auto-no
                                  (cider-jack-in nil)))
                                ((derived-mode-p 'clojurescript-mode)
                                 (auto-no
                                  (cider-jack-in-cljs nil)))))))))))))

            (enable-helm-cider-mode))))
  t)

;; This may be breaking the clojure hook when it's disabled for some reason, so I put it last
;; It's still making it so it fails to open the clojure file on first attempt
;; I have to hook it somewhere else. After the file is fully opened

(require 'helm-cider)
(defun enable-helm-cider-mode ()
  (interactive)
  (helm-cider-mode 1))

(add-hook-last 'clojure-mode-hook 'cider-auto-jack-in)
;; (add-hook-last 'clojure-mode-hook 'enable-helm-cider-mode)
;; (remove-hook 'clojure-mode-hook 'enable-helm-cider-mode)
(add-hook-last 'clojurescript-mode-hook 'cider-auto-jack-in)
;; (remove-hook 'clojure-mode-hook 'cider-auto-jack-in)

(defun cider--check-existing-session (params)
  "Ask for confirmation if a session with similar PARAMS already exists.
If no session exists or user chose to proceed, return PARAMS.  If the user
canceled the action, signal quit."
  (let* ((proj-dir (plist-get params :project-dir))
         (host (plist-get params :host))
         ;; (port (plist-get params :port))
         (session (seq-find (lambda (ses)
                              (let ((ses-params (cider--gather-session-params ses)))
                                (and (equal proj-dir (plist-get ses-params :project-dir))
                                     ;; (or (null port)
                                     ;;     (equal port (plist-get ses-params :port)))
                                     (or (null host)
                                         (equal host (plist-get ses-params :host))))))
                            (sesman-current-sessions 'CIDER '(project)))))
    (when session
      (unless (y-or-n-p
               (concat
                "A CIDER session with the same connection parameters already exists (" (car session) ").  "
                "Are you sure you want to create a new session instead of using `cider-connect-sibling-clj(s)'?  "))
        (let ((debug-on-quit nil))
          (signal 'quit nil)))))
  params)


(defun cider-switch-to-errors ()
  (interactive)
  (if (buffer-exists "*cider-error*")
      (switch-to-buffer "*cider-error*")
    (message "*cider-error* doesn't exist")))

(defun pen-clojure-switch-to-errors ()
  (interactive)
  (if (and
       (>= (prefix-numeric-value current-prefix-arg) 4)
       (buffer-exists "*cider-error*"))
      (call-interactively 'flycheck-list-errors)
    (call-interactively 'cider-switch-to-errors)))

(defun pen-clojure-lein-run ()
  (interactive)
  (pen-sps (concat "cd " (pen-q (pen-pwd)) "; " "is-git && cd \"$(pen-vc get-top-level)\"; nvc -E 'lein run; pen-pak'")))

(require 'pen-net)

;; Remember, the nrepl port is also recorded 
;; $MYGIT/gigasquid/libpython-clj-examples/.nrepl-port

(defun cider-jack-in-params (project-type)
  "Determine the commands params for `cider-jack-in' for the PROJECT-TYPE."
  ;; The format of these command-line strings must consider different shells,
  ;; different values of IFS, and the possibility that they'll be run remotely
  ;; (e.g. with TRAMP). Using `", "` causes problems with TRAMP, for example.
  ;; Please be careful when changing them.
  (pcase project-type
    ('lein        (concat cider-lein-parameters " :port " (n-get-free-port "40500" "40800")))
    ('boot        cider-boot-parameters)
    ('clojure-cli nil)
    ('babashka    cider-babashka-parameters)
    ('shadow-cljs cider-shadow-cljs-parameters)
    ('gradle      cider-gradle-parameters)
    (_            (user-error "Unsupported project type `%S'" project-type))))

;; This allows me to remote connect
;; I should probably make it select a random port
(setq cider-lein-parameters "repl :headless :host localhost")

;; (setq cider-babashka-command "/usr/local/bin/bb")
(setq cider-babashka-command "bb")


;; I think there would be a better way to do this.


;; Is there a better way to ensure this? Because the temporary buffer stuff
;; is a little bit problematic.
(defun cider-jack-in-around-advice (proc &rest args)
  "This exists actually to ensure the nrepl directory is at the top level
so the same nrepl is used for all files in the project"
  (let* ((gdir (sor
                (locate-dominating-file default-directory ".git")
                (projectile-acquire-root)))
         (pdir
          (sor (locate-dominating-file default-directory "project.clj")
               (locate-dominating-file default-directory "bb.edn")))
         (dir (or (and (string-equal gdir pdir)
                       gdir)
                  pdir
                  (pen-pwd)))
         ;; Timestamp is needed to ensure created buffers are unique
         (ts (str (date-ts)))
         (is-a-bb-buffer (current-buffer-is-bb-p))
         (jack-in-bufname (concat "*" (slugify (concat "jack-in" " in " dir)) "-" ts "*"))
         (bufname
          (if (re-match-p "closure" (str proc))
              (concat "*" (slugify (concat "closure" " in " dir)) "-" ts "*")
            jack-in-bufname)))
    (save-window-excursion
      (let* ((b (switch-to-buffer bufname)))
        (with-current-buffer b
          (insert (concat (str proc) " in " dir))
          (insert "\n")
          ;; This is so from the jack-in command I can detect if it was a bb buffer
          (if is-a-bb-buffer
              (insert "env bb\n"))
          (cd dir)

          ;; Also, clean up the buffer after 5 seconds, just in case
          (eval `(run-with-timer 2 nil (lambda () (ignore-errors (kill-buffer ,bufname)))))

          (let ((res (apply proc args)))
            (if (re-match-p "closure" (str proc))
                (progn
                  (kill-buffer b)
                  (if (buffer-exists jack-in-bufname)
                      (kill-buffer jack-in-bufname)))
              (bury-buffer b))
            res))))))
(advice-add 'cider-restart :around #'cider-jack-in-around-advice)
(advice-add 'cider-jack-in :around #'cider-jack-in-around-advice)
(advice-add 'cider-jack-in-clj :around #'cider-jack-in-around-advice)
(advice-add 'cider-jack-in-cljs :around #'cider-jack-in-around-advice)

(defun current-buffer-is-bb-p ()
  (or
   (pen-string-in-buffer-p "env bb")
   (pen-string-in-buffer-p "babashka.file")
   (string-equal "bb" (f-ext (chomp (f-basename (get-path)))))
   ;; (or (string-match-p "/babashka/" default-directory))
   ))

(defun cider-remove-jack-in-advice ()
  (interactive)

  (advice-add 'cider-restart #'cider-jack-in-around-advice)
  (advice-add 'cider-jack-in #'cider-jack-in-around-advice)
  (advice-add 'cider-jack-in-clj #'cider-jack-in-around-advice)
  (advice-add 'cider-jack-in-cljs #'cider-jack-in-around-advice))

(define-key cider-repl-mode-map (kbd "C-c h f") 'pen-cider-docfun)

(defun pen-cider-docfun (symbol-string)
  (interactive (list (let ((s (symbol-at-point)))
                       (if s
                           (s-replace-regexp "^[a-z]+/" "" (symbol-name s))
                         ""))))
  ;; special-form
  ;; macro
  ;; function

  (let* ((cs (cider-complete ""))
         (prompt
          (cond
           ((>= (prefix-numeric-value current-prefix-arg) (expt 4 4))
            "function: ")
           ((>= (prefix-numeric-value current-prefix-arg) (expt 4 3))
            "special form: ")
           ((>= (prefix-numeric-value current-prefix-arg) (expt 4 2))
            "macro: ")
           (t
            "func/macro/special: "))))
    (if (= (prefix-numeric-value current-prefix-arg) 4)
        (call-interactively 'helpful-function)
      (let ((r (fz
                (-filter
                 (cond
                  ((>= (prefix-numeric-value current-prefix-arg) (expt 4 4))
                   (lambda (e)
                     (string-equal "function" (get-text-property 0 'type e))))
                  ((>= (prefix-numeric-value current-prefix-arg) (expt 4 3))
                   (lambda (e)
                     (string-equal "special-form" (get-text-property 0 'type e))))
                  ((>= (prefix-numeric-value current-prefix-arg) (expt 4 2))
                   (lambda (e)
                     (string-equal "macro" (get-text-property 0 'type e))))
                  (t
                   (lambda (e)
                     (or (string-equal "function" (get-text-property 0 'type e))
                         (string-equal "macro" (get-text-property 0 'type e))
                         (string-equal "special-form" (get-text-property 0 'type e))))))

                 cs)
                symbol-string
                nil
                prompt)))
        (if (sor r)
            (try (cider-doc-lookup r)
                 (egr (pen-cmd "clojure" symbol-string))))))))

(setq cider-preferred-build-tool "lein")

(defun cljr--insert-into-leiningen-dependencies (artifact version)
  (try
   (progn
     (re-search-forward ":dependencies")
     (paredit-forward)
     (paredit-backward-down)
     (newline-and-indent)
     (insert "[" artifact " \"" version "\"]"))
   (progn
     (re-search-forward "^ *:")
     (backward-char)
     (newline)
     (backward-char)
     (insert ":dependencies []")
     (paredit-backward-down)
     (insert "[" artifact " \"" version "\"]"))))

(defun pen-clojure-project-file ()
  (interactive)
  (let ((pfp (cljr--project-file)))
    (if (interactive-p)
        (e pfp)
      pfp)))

(defun pen-cider-backwards-search ()
  (interactive)
  (if (>= (prefix-numeric-value current-prefix-arg) 4)
      (call-interactively 'cider-repl-previous-matching-input)
    (call-interactively 'isearch-backward)))

(setq clomacs-httpd-default-port 8680)

(defun pen-clomacs-connect ()
  (interactive)
  (message "connect to clomacs"))

(require 'nrepl-client)
(defun nrepl--dispatch-response (response)
  "Dispatch the RESPONSE to associated callback.
First we check the callbacks of pending requests.  If no callback was found,
we check the completed requests, since responses could be received even for
older requests with \"done\" status."
  (nrepl-dbind-response response (id)
    (nrepl-log-message response 'response)
    (let ((callback (or (gethash id nrepl-pending-requests)
                        (gethash id nrepl-completed-requests))))
      (if callback
          (ignore-errors
            (funcall callback response))
        (error "[nREPL] No response handler with id %s found" id)))))

(defun pen-clojure-eval-last-sexp ()
  (interactive)
  ;; (pen-message-no-echo "%s" "Evaluation")
  ;; (message "%s" "Evaluation")
  (pen-flash)
  (let ((s (pen-regex-match-string-1 "^(\\([^ ]+\\) " (cider-last-sexp))))
    (cond
     ((string-equal "ns" s)
      (progn
        (call-interactively 'cider-eval-last-sexp)
        (call-interactively 'cider-repl-set-ns)))
     ;; could be t/deftest
     ((string-match "deftest" (str s))
      (progn
        (call-interactively 'cider-eval-last-sexp)
        (call-interactively 'cider-test-run-test)))
     ;; TODO add deftest runner
     (t (call-interactively 'cider-eval-last-sexp)))))

(defset cider-repl-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-d") 'cider-doc-map)
    (define-key map (kbd "C-c ,")   'cider-test-commands-map)
    (define-key map (kbd "C-c C-t") 'cider-test-commands-map)
    (define-key map (kbd "M-.") #'cider-find-var)
    (define-key map (kbd "C-c C-.") #'cider-find-ns)
    (define-key map (kbd "C-c C-:") #'cider-find-keyword)
    (define-key map (kbd "M-,") #'cider-pop-back)
    (define-key map (kbd "C-c M-.") #'cider-find-resource)
    (define-key map (kbd "RET") #'cider-repl-return)
    (define-key map (kbd "TAB") #'cider-repl-tab)
    (define-key map (kbd "C-<return>") #'cider-repl-closing-return)
    (define-key map (kbd "C-j") #'cider-repl-newline-and-indent)
    (define-key map (kbd "C-c C-o") #'cider-repl-clear-output)
    (define-key map (kbd "C-c M-n") #'cider-repl-set-ns)
    (define-key map (kbd "C-c C-u") #'cider-repl-kill-input)
    (define-key map (kbd "C-S-a") #'cider-repl-bol-mark)
    (define-key map [S-home] #'cider-repl-bol-mark)
    (define-key map (kbd "C-<up>") #'cider-repl-backward-input)
    (define-key map (kbd "C-<down>") #'cider-repl-forward-input)
    (define-key map (kbd "M-p") #'cider-repl-previous-input)
    (define-key map (kbd "M-n") #'cider-repl-next-input)
    (define-key map (kbd "M-r") #'cider-repl-previous-matching-input)
    (define-key map (kbd "M-s") #'cider-repl-next-matching-input)
    (define-key map (kbd "C-c C-n") #'cider-repl-next-prompt)
    (define-key map (kbd "C-c C-p") #'cider-repl-previous-prompt)
    (define-key map (kbd "C-c C-b") #'cider-interrupt)
    (define-key map (kbd "C-c C-c") #'cider-interrupt)
    (define-key map (kbd "C-c C-m") #'cider-macroexpand-1)
    (define-key map (kbd "C-c M-m") #'cider-macroexpand-all)
    (define-key map (kbd "C-c C-s") #'sesman-map)
    (define-key map (kbd "C-c C-z") #'cider-switch-to-last-clojure-buffer)
    (define-key map (kbd "C-c M-o") #'cider-repl-switch-to-other)
    (define-key map (kbd "C-c M-s") #'cider-selector)
    (define-key map (kbd "C-c M-d") #'cider-describe-connection)
    (define-key map (kbd "C-c C-q") #'cider-quit)
    (define-key map (kbd "C-c M-r") #'cider-restart)
    (define-key map (kbd "C-c M-i") #'cider-inspect)
    (define-key map (kbd "C-c M-p") #'cider-repl-history)
    (define-key map (kbd "M-r") #'helm-cider-repl-history)
    (define-key map (kbd "C-c M-t v") #'cider-toggle-trace-var)
    (define-key map (kbd "C-c M-t n") #'cider-toggle-trace-ns)
    (define-key map (kbd "C-c C-x") 'cider-start-map)
    (define-key map (kbd "C-x C-e") #'cider-eval-last-sexp)
    (define-key map (kbd "C-c C-r") 'clojure-refactor-map)
    (define-key map (kbd "C-c C-v") 'cider-eval-commands-map)
    (define-key map (kbd "C-c M-j") #'cider-jack-in-clj)
    (define-key map (kbd "C-c M-J") #'cider-jack-in-cljs)
    (define-key map (kbd "C-c M-c") #'cider-connect-clj)
    (define-key map (kbd "C-c M-C") #'cider-connect-cljs)

    (define-key map (string cider-repl-shortcut-dispatch-char) #'cider-repl-handle-shortcut)
    (easy-menu-define cider-repl-mode-menu map
      "Menu for CIDER's REPL mode"
      `("REPL"
        ["Complete symbol" complete-symbol]
        "--"
        ,cider-doc-menu
        "--"
        ("Find"
         ["Find definition" cider-find-var]
         ["Find namespace" cider-find-ns]
         ["Find resource" cider-find-resource]
         ["Find keyword" cider-find-keyword]
         ["Go back" cider-pop-back])
        "--"
        ["Switch to Clojure buffer" cider-switch-to-last-clojure-buffer]
        ["Switch to other REPL" cider-repl-switch-to-other]
        "--"
        ("Macroexpand"
         ["Macroexpand-1" cider-macroexpand-1]
         ["Macroexpand-all" cider-macroexpand-all])
        "--"
        ,cider-test-menu
        "--"
        ["Run project (-main function)" cider-run]
        ["Inspect" cider-inspect]
        ["Toggle var tracing" cider-toggle-trace-var]
        ["Toggle pen-ns tracing" cider-toggle-trace-ns]
        ["Refresh loaded code" cider-ns-refresh]
        "--"
        ["Set REPL ns" cider-repl-set-ns]
        ["Toggle pretty printing" cider-repl-toggle-pretty-printing]
        ["Toggle Clojure font-lock" cider-repl-toggle-clojure-font-lock]
        ["Toggle rich content types" cider-repl-toggle-content-types]
        ["Require REPL utils" cider-repl-require-repl-utils]
        "--"
        ["Browse classpath" cider-classpath]
        ["Browse classpath entry" cider-open-classpath-entry]
        ["Browse namespace" cider-browse-ns]
        ["Browse all namespaces" cider-browse-ns-all]
        ["Browse spec" cider-browse-spec]
        ["Browse all specs" cider-browse-spec-all]
        "--"
        ["Next prompt" cider-repl-next-prompt]
        ["Previous prompt" cider-repl-previous-prompt]
        ["Clear output" cider-repl-clear-output]
        ["Clear buffer" cider-repl-clear-buffer]
        ["Trim buffer" cider-repl-trim-buffer]
        ["Clear banners" cider-repl-clear-banners]
        ["Clear help banner" cider-repl-clear-help-banner]
        ["Kill input" cider-repl-kill-input]
        "--"
        ["Interrupt evaluation" cider-interrupt]
        "--"
        ["Connection info" cider-describe-connection]
        "--"
        ["Close ancillary buffers" cider-close-ancillary-buffers]
        ["Quit" cider-quit]
        ["Restart" cider-restart]
        "--"
        ["Clojure Cheatsheet" cider-cheatsheet]
        "--"
        ["A sip of CIDER" cider-drink-a-sip]
        ["View manual online" cider-view-manual]
        ["View refcard online" cider-view-refcard]
        ["Report a bug" cider-report-bug]
        ["Version info" cider-version]))
    map))

(defun cider-switch-to-repl-buffer-any (&optional set-namespace)
  "Switch to current REPL buffer, when possible in an existing window.
The type of the REPL is inferred from the mode of current buffer.  With a
prefix arg SET-NAMESPACE sets the namespace in the REPL buffer to that of
the namespace in the Clojure source buffer"
  (interactive "P")
  (cider--switch-to-repl-buffer
   (cider-current-repl 'any 'ensure)
   set-namespace))

(defun pen-cider-interrupt-and-new-prompt ()
  (interactive)
  (cider-interrupt))

(defun pen-cider-select-prompt-or-result ()
  (interactive)

  (if (< cider-repl-input-start-mark (point))
      (progn
        (call-interactively 'end-of-buffer)
        (set-mark (point))
        (goto-char cider-repl-input-start-mark)
        (call-interactively 'exchange-point-and-mark))
    (progn
      (if (looking-back "^[^ ]+> .*")
          (beginning-of-line))
      (if (looking-back "^[^ ]+> ")
          (progn
            (set-mark (point))
            (end-of-line))
        (progn
          (cider-repl-previous-prompt)
          (forward-line)
          (beginning-of-line)
          (set-mark (point))
          (cider-repl-next-prompt)
          (previous-line)
          (end-of-line))))))

;; (defun pen-cider-insert-eval-handler (&optional buffer)
;;   "Make an nREPL evaluation handler for the BUFFER.
;; The handler simply inserts the result value in BUFFER."
;;   (let ((eval-buffer (current-buffer)))
;;     (nrepl-make-response-handler (or buffer eval-buffer)
;;                                  (lambda (_buffer value)
;;                                    (with-current-buffer buffer
;;                                      (insert (concat "(" value ")"))
;;                                      (cider-repl-return)))
;;                                  (lambda (_buffer out)
;;                                    (cider-repl-emit-interactive-stdout out))
;;                                  (lambda (_buffer err)
;;                                    (cider-handle-compilation-errors err eval-buffer))
;;                                  '())))

;; This is unneccesary. It already is implemented in a better way -- see j:pen-lispy-eval-eval
;; (defun pen-cider-eval-eval-last-sexp (&optional prefix)
;;   (interactive "P")
;;   (cider-interactive-eval nil
;;                           ;; eval the result in the repl
;;                           (pen-cider-insert-eval-handler (cider-current-repl))
;;                           (cider-last-sexp 'bounds)
;;                           (cider--nrepl-pr-request-map))
;;   (when prefix
;;     (cider-switch-to-repl-buffer)))

;; TODO List all the project symbols then make a fuzzy finder
(defun clojure-list-dir-symbols (dir)
  (interactive (list (if (cider-connected-p)
                         (clojure-project-dir (cider-current-dir))
                       (read-directory-name "khala-go-to-symbol dir: "))))
  (setq dir (pen-umn
             (or (sor dir)
                 "/root/.emacs.d/host/khala")))
  (let* ((syms (pen-sn
                "cut -d ' ' -f 2"
                ;; grep -HnoP -- "defn [a-z \!?-]+" $(glob -b '**/*.clj')
                (pen-sn (concat "cd " (pen-q dir) "; grep -HnoP -- " (pen-q (concat "(defn|deftest|def) [a-z \!?-]+( |$)")) " $(pen-glob '**/*.{clj,bb}')"
                                nil) dir))))
    syms))

(defun clojure-fz-symbol (dir)
  ;; (interactive)
  (interactive (list
                (if (cider-connected-p)
                    (clojure-project-dir (cider-current-dir))
                  (read-directory-name "khala-go-to-symbol dir: "))))
  (let* ((syms (clojure-list-dir-symbols dir))
         (sym (fz (snc "sort|uniq" syms) nil nil "khala-go-to-symbol: " nil t)))
    (if (sor sym)
        (clojure-go-to-symbol sym dir))))

(defun clojure-go-to-symbol (sym dir)
  (interactive (list (read-string-hist "khala-go-to-symbol sym: ")
                     (if (cider-connected-p)
                         (clojure-project-dir (cider-current-dir))
                       (read-directory-name "khala-go-to-symbol dir: "))))
  (setq dir (pen-umn
             (or (sor dir)
                 "/root/.emacs.d/host/khala")))
  (let* ((symstr (str sym))
         (pat (cond
               ((re-match-p "!$" symstr) (s-replace-regexp "!" "\\\\!" symstr))
               ((re-match-p "?$" symstr) (s-replace-regexp "?" "\\?" symstr))
               (t (concat symstr "( |$)"))))
         (locs (pen-sn
                "cut -d ':' -f 1,2"
                (pen-sn (concat "cd " (pen-q dir) "; grep -HnoP -- " (pen-q (concat "(defn|deftest|def) " pat)) " $(pen-glob '**/*.clj')")
                        nil dir)))
         (loc (fz locs nil nil (format "khala-go-to-symbol (%s): " symstr) nil t))
         (fp (pen-snc "cut -d : -f 1" loc))
         (fp (f-join dir fp))
         (pos (pen-snc "cut -d : -f 2" loc)))
    (if (f-exists-p fp)
        (with-current-buffer
            (find-file fp)
          (goto-line (string-to-number pos))))))

(defun khala-go-to-symbol (sym)
  (interactive (list (read-string-hist "khala-go-to-symbol: ")))
  (clojure-go-to-symbol sym "/root/.emacs.d/host/khala"))

(comment
 (khala-go-to-symbol "split-by-slash")
 (khala-go-to-symbol "file-exists?")
 (khala-go-to-symbol "get-file-list!")
 (khala-go-to-symbol "get-rc"))

(defun helm-cider--apropos-sources-nodoc ()  
  (-map
   (lambda (e)
     ;; (setq e (delq (assoc 'action e) e))
     (setq e (delq (assoc 'persistent-action e) e))
     
     ;; This action means helm will return the value. So helm functions like fzf.
     ;; 
     (setcdr (assq 'action e) (lambda (c) (helm-marked-candidates)))
     (setcdr (assq 'persistent-help e) "Run function")
     ;; (setcdr (assq 'header-line e) "C-j: Run function")
     (setcdr (assq 'header-line e) "C-m: Run function")
     e)
   (helm-cider--apropos-sources)))

;; This needs to also handle arguments.
;; If the function has arguments I need to ask for them.
;; Perhaps I can go to the function, then run it with E
;; j:pen-clojure-eval-eval
(defun pen-cider-run-function ()
  (interactive)
  (let* ((ret
          (car
           (helm
            :buffer "*Helm Clojure Symbols*"
            :candidate-number-limit 9999
            :sources (helm-cider--apropos-sources-nodoc)
            ;; (helm-cider--apropos-sources)
            )))
         (shortname (if ret
                        (replace-regexp-in-string
                         "^.*\\/" ""
                         ret)))

         ;; khala.core/start-khala: ([port])
         ;; khala.core/-main: ([& args])
         ;; ring.core.protocols/write-body-to-stream: ([body response output-stream])
         ;; that is for: write-body-to-stream [body response output-stream]
         (sig (cider-company-docsig ret))
         (arglist (pen-vector2list
                   (eval-string
                    (concat
                     "'"
                     (replace-regexp-in-string
                      "^.*: (\\(.*\\))$" "\\1"
                      (cider-company-docsig ret))))))
         (arglist (-filter (lambda (s) (not (string-equal "&" s)))
                           arglist)))

    ;; khala.core/start-khala: ([port])
    ;; (tv args)

    ;; (cider-company-docsig "start-khala")
    ;; (cider-company-docsig "start-khala")

    (if ret
        (pen-cider-repl-run-function-interactively ret arglist)
      ;; (cider-run shortname)
      )))

(defun pen-cider-repl-run-function-interactively (funname argnames)
  (let* ((iarglist (mapcar
                    (lambda (e) `(read-string-hist ,(concat (str e) ": ")))
                    argnames)))

    (eval
     `(call-interactively
       (lambda (,@arglist)
         (interactive (list ,@iarglist))
         (let* ((valstr (pen-cmd ,@arglist))
                (clj (concat "(" ,funname " " valstr ")")))
           (cider-nrepl-request:eval clj
                                     (lambda (response) (tm-notify response)))))))
    (cider-nrepl-request:eval (concat "(" funname ")")
                              (lambda (response) (tm-notify response)))))

(define-key cider-mode-map (kbd "C-c C-o") nil)
(define-key cider-mode-map (kbd "C-M-i") nil)
(define-key cider-repl-mode-map (kbd "M-r") nil)
(define-key cider-repl-mode-map (kbd "C-r") 'pen-cider-backwards-search)
(define-key cider-repl-mode-map (kbd "M-h") 'pen-cider-select-prompt-or-result)
(define-key clj-refactor-map (kbd "/") nil)
(define-key cider-repl-mode-map (kbd "C-c C-c") 'pen-cider-interrupt-and-new-prompt)

(define-key cider-repl-mode-map (kbd "C-x C-e") 'pen-clojure-eval-last-sexp)
(define-key cider-mode-map (kbd "C-x C-e") 'pen-clojure-eval-last-sexp)

;; DISCARD. For cider-doc. Instead of jar:file:/root/... links just have e:/
;; The link isn't a proper path
;; It also contains the inner file path
;; Therefore, I should make a new link type to unzip and observe the file,
;; handling the jar.
;; Rather, edit j:cider-find-file

(defun cider--abbreviate-file-protocol (file-with-protocol)
  "Abbreviate the file-path in `file:/path/to/file' of FILE-WITH-PROTOCOL."
  ;; (s-replace-regexp "^jar:file:" "e:"
  ;;                   nil)
  (if (string-match "\\`file:\\(.*\\)" file-with-protocol)
      (let ((file (match-string 1 file-with-protocol))
            (proj-dir (clojure-project-dir)))
        (if (and proj-dir
                 (file-in-directory-p file proj-dir))
            (file-relative-name file proj-dir)
          file))
    file-with-protocol))

(add-to-list 'auto-mode-alist '("\\.clj\\'" . clojure-mode))

(comment
 (defun y-or-n-p (prompt)
   (let ((res (snc (cmd "code-out" "tpop-yn" prompt))))
     (equalp "0" res))))

(defun cider-project-type (&optional project-dir)
  "Determine the type of the project in PROJECT-DIR.
When multiple project file markers are present, check for a preferred build
tool in `cider-preferred-build-tool', otherwise prompt the user to choose.
PROJECT-DIR defaults to the current project."
  (let* ((choices (cider--identify-buildtools-present project-dir))
         (multiple-project-choices (> (length choices) 1))
         ;; this needs to be a string to be used in `completing-read'
         (default (symbol-name (car choices)))
         ;; `cider-preferred-build-tool' used to be a string prior to CIDER
         ;; 0.18, therefore the need for `cider-maybe-intern'
         (preferred-build-tool (cider-maybe-intern cider-preferred-build-tool)))
    (cond ((and multiple-project-choices
                (member 'babashka choices)
                ;; annoyingly, the buffer is changed
                ;; I could, possibly insert the string inside the temporary buffer?
                (pen-string-in-buffer-p "env bb"))
           'babashka)
          ((and multiple-project-choices
                (member preferred-build-tool choices))
           preferred-build-tool)
          (multiple-project-choices
           (intern
            (completing-read
             (format "Which command should be used (default %s): " default)
             choices nil t nil nil default)))
          (choices
           (car choices))
          ;; TODO: Move this fallback outside the project-type check
          ;; if we're outside a project we fallback to whatever tool
          ;; is specified in `cider-jack-in-default' (normally clojure-cli)
          ;; `cider-jack-in-default' used to be a string prior to CIDER
          ;; 0.18, therefore the need for `cider-maybe-intern'
          (t (cider-maybe-intern cider-jack-in-default)))))

(defun cider-apropos-select-around-advice (proc &rest args)
  (let ((apropos-bufs (select-matching-buffers "\\.clj" "/clojure/")))
    (if (and (current-buffer-is-bb-p)
             apropos-bufs)
        (with-current-buffer
         (car apropos-bufs)
         (let ((res (apply proc args)))
           res))
      (let ((res (apply proc args)))
        res))))
(advice-add 'cider-apropos-select :around #'cider-apropos-select-around-advice)
(advice-add 'helm-cider-apropos :around #'cider-apropos-select-around-advice)
(advice-add 'helm-cider-apropos-symbol :around #'cider-apropos-select-around-advice)
(advice-add 'helm-cider-apropos-symbol-doc :around #'cider-apropos-select-around-advice)

;; (advice-remove 'cider-apropos-select #'cider-apropos-select-around-advice)
(comment
 (defun cider-jack-in-clj (params)
   "Start an nREPL server for the current project and connect to it.
PARAMS is a plist optionally containing :project-dir and :jack-in-cmd.
With the prefix argument, allow editing of the jack in command; with a
double prefix prompt for all these parameters."
   (interactive "P")
   (let ((params (cider--update-params params)))
     (cider--start-nrepl-server
      params
      (lambda (server-buffer)
        (cider-connect-sibling-clj params server-buffer))))))

(defun cider--update-params (params)
  "Fill-in the passed in PARAMS plist needed to start an nREPL server.
Updates :project-dir and :jack-in-cmd.
Also checks whether a matching session already exists."
  (thread-first params
                (cider--update-project-dir)
                (cider--check-existing-session)
                (cider--update-jack-in-cmd)))

(defcustom cider-last-eval-result ""
  "The last evaluated result."
  :group 'pen-clojure
  :type 'string)
(setq cider-last-eval-result "")

(defun cider--display-interactive-eval-result-around-advice (proc &rest args)
  (let ((res (apply proc args)))
    (setq cider-last-eval-result (str (s-replace-regexp (concat "^" (pen-unregexify cider-eval-result-prefix)) "" res)))
    res))
(advice-add 'cider--display-interactive-eval-result :around #'cider--display-interactive-eval-result-around-advice)
;; (advice-remove 'cider--display-interactive-eval-result #'cider--display-interactive-eval-result-around-advice)

(defun pen-copy-last-clojure-result ()
  (interactive)
  (xc cider-last-eval-result))

(setq cider-words-of-inspiration
        `("nREPL server is up, CIDER REPL is online!"
          "May your functions be pure, your code concise and your programs a joy to behold!"))

(provide 'pen-clojure)
