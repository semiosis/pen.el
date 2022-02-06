(require 'helm-buffers)
(require 'helm-google)
(require 'helm)
(require 'pen-utils)
(require 'helm-net)

(defun fz-default-return-query (list &optional prompt)
  (setq prompt (or prompt ":"))
  (helm-comp-read prompt list :must-match 'nil))

(defalias 'fz-helm 'fz-default-return-query)

(setq helm-mode-handle-completion-in-region nil)
;; j:helm--completion-in-region
;; j:completion-in-region

;; global fuzzy
(setq helm-mode-fuzzy-match t)
(setq helm-mode-fuzzy-match nil)
(setq helm-completion-in-region-fuzzy-match t)

;; individual fuzzy
(setq helm-recentf-fuzzy-match t)
(setq helm-buffers-fuzzy-matching t)
(setq helm-locate-fuzzy-match t)
(setq helm-M-x-fuzzy-match t)
(setq helm-semantic-fuzzy-match t)
(setq helm-imenu-fuzzy-match t)
(setq helm-apropos-fuzzy-match t)
(setq helm-lisp-fuzzy-completion t)
(setq helm-use-frame-when-more-than-two-windows nil)

(defvar helm-comp-read-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map helm-map)
    (define-key map (kbd "<C-return>") 'helm-cr-empty-string)
    (define-key map (kbd "<M-RET>") 'helm-cr-empty-string)
    (define-key map (kbd "M-k") 'ace-jump-helm-line)
    map)
  "Keymap for `helm-comp-read'.")

(defun helm-copy-to-tvipe ()
  "Copy selection or marked candidates to `helm-current-buffer'.
Note that the real values of candidates are copied and not the
display values."
  (interactive)

  (let ((cands (helm-get-candidates (helm-get-current-source))))

    (message (xc (helm-get-current-source)))
    (if (processp cands)
        (message (xc cands))
      (tvd (list2str cands)))))

(defun helm-copy-to-fzf ()
  "Copy selection or marked candidates to `helm-current-buffer'.
Note that the real values of candidates are copied and not the
display values."
  (interactive)

  (fzf (list2str (helm-get-candidates (helm-get-current-source)))))

(defun helm-copy-to-tvipe-bak ()
  "Copy selection or marked candidates to `helm-current-buffer'.
Note that the real values of candidates are copied and not the
display values."
  (interactive)
  (with-helm-alive-p
    (helm-run-after-exit
     (lambda (cands)
       (pen-tvipe (mapconcat (lambda (c)
                              (format "%s" c))
                            cands "\n")))
     (helm-marked-candidates))))

(defmacro helm-marked-candidates-strings (&rest body)
  ""
  `(pen-join (helm-marked-candidates ,@body) "\n"))

(defun helm-copy-selection-to-clipboard ()
  "Copy selection or marked candidates to `helm-current-buffer'.
Note that the real values of candidates are copied and not the
display values."
  (interactive)

  (pen-copy (helm-marked-candidates-strings)))

(defun helm-fz-directory ()
  (interactive)
  (let ((sel (string-head (helm-marked-candidates-strings))))))

(defun helm-copy-input ()
  (interactive)

  (xc (minibuffer-contents) t))

(defun helm-copy-selections ()
  (interactive)

  (xc (chomp (sh/cut "-d ' ' -f 2" (pen-tvipe (helm-marked-candidates :all-sources t))))))

(with-eval-after-load 'helm
  (define-key helm-map (kbd "C-i") 'helm-execute-persistent-action)
  (define-key helm-map (kbd "C-z") 'helm-select-action)
  (define-key helm-map (kbd "M-c") #'helm-copy-selection-to-clipboard)
  (define-key helm-map (kbd "M-e") (df helm-open ;; (helm-keyboard-quit)
                                       (find-file (pen-umn (bp head -n 1 (helm-marked-candidates-strings)))) ;; (helm-keyboard-quit) ;This works to quit helm, but when it quits, the buffer quits too; This is desirable behaviour
                                       ))
  (define-key helm-map (kbd "M-v") (df helm-open-in-vim (pen-spv (concat "v " (pen-umn (bp head -n 1 (helm-marked-candidates-strings)))))))
  (define-key helm-map (kbd "M-o") (df helm-open-in-sps (pen-sps (concat "zrepl o " (pen-umn (bp head -n 1 (helm-marked-candidates-strings)))))))
  (define-key helm-map (kbd "M-F") (df helm-open-in-fzf (pen-sph (concat "ca " (pen-umn (bp head -n 1 (helm-marked-candidates-strings))) " | pen-fzf -P"))))

  ;; helm-help to do the same thing as helm documentation
  (define-key helm-map (kbd "C-c ?")    'helm-documentation)

  ;; This does not appear to work
  (define-key helm-map (kbd "C-c o")      'helm-copy-to-tvipe)
  (define-key helm-map (kbd "M-Y")      'helm-copy-input)
  (define-key helm-map (kbd "C-c f")      'helm-copy-to-fzf)
  (define-key helm-map (kbd "C-c z")      'helm-copy-to-tvipe)

  (define-key helm-map (kbd "M-y")      'helm-copy-selections))

(defun send-m-del ()
  (interactive)
  (ekm "M-DEL"))

(defun pen-helm-find-files ()
  "Like helm-find-files, but it ignores the thing at point"
  (interactive)

  (cd (get-dir))
  (let ((helm-find-files-ignore-thing-at-point t))
    (call-interactively 'helm-find-files)))

(defun helm-exhaust-candidates (&optional source)
  (let ((buf (new-buffer-from-string "new buf"))
        (src (or source (helm-get-current-source))))
    (helm-candidates-in-buffer-1
     buf
     ""
     (or (assoc-default 'get-line src)
         #'buffer-substring-no-properties)
     (or (assoc-default 'search src)
         '(helm-candidates-in-buffer-search-default-fn))
     ;; (helm-candidate-number-limit src)
     10000000
     (helm-attr 'match-part)
     src)))

(defun helm-test-code ()
  (interactive)
  (if nil (progn
            ;; a list of alists.
            helm-sources
            ))

  (tvd (list2str (helm-get-candidates (helm-get-current-source)))))

(defun helm-maybe-exit-minibuffer ()
  (interactive)
  (with-helm-alive-p
    (if (and (helm--updating-p)
             (null helm--reading-passwd-or-string))
        (progn
          (sit-for 0.3) (message nil)
          (helm-update))
      (helm-exit-minibuffer))))

(setq completing-read-function 'ivy-completing-read)

(define-minor-mode helm-mode
  "Toggle generic helm completion.

All functions in Emacs that use `completing-read'
or `read-file-name' and friends will use helm interface
when this mode is turned on.

However you can modify this behavior for functions of your choice
with `helm-completing-read-handlers-alist'.

Also commands using `completion-in-region' will be helmized when
`helm-mode-handle-completion-in-region' is non nil, you can modify
this behavior with `helm-mode-no-completion-in-region-in-modes'.

Called with a positive arg, turn on unconditionally, with a
negative arg turn off.
You can turn it on with `helm-mode'.

Some crap emacs functions may not be supported,
e.g `ffap-alternate-file' and maybe others
You can add such functions to `helm-completing-read-handlers-alist'
with a nil value.

About `ido-mode':
When you are using `helm-mode', DO NOT use `ido-mode', instead if you
want some commands use `ido', add these commands to
`helm-completing-read-handlers-alist' with `ido' as value.

Note: This mode is incompatible with Emacs23."
  :group 'helm-mode
  :global t
  :lighter helm-completion-mode-string
  (cl-assert (boundp 'completing-read-function) nil
             "`helm-mode' not available, upgrade to Emacs-24")
  (if helm-mode
      (if (fboundp 'add-function)
          (progn
            ;; (add-function :override completing-read-function
            ;;               #'helm--completing-read-default)
            ;; (add-function :override read-file-name-function
            ;;               #'helm--generic-read-file-name)
            ;; (add-function :override read-buffer-function
            ;;               #'helm--generic-read-buffer)
            (when helm-mode-handle-completion-in-region
              (add-function :override completion-in-region-function
                            #'helm--completion-in-region))
            ;; If user have enabled ido-everywhere BEFORE enabling
            ;; helm-mode disable it and warn user about its
            ;; incompatibility with helm-mode (issue #2085).
            (helm-mode--disable-ido-maybe)
            ;; If ido-everywhere is not enabled yet anticipate and
            ;; disable it if user attempt to enable it while helm-mode
            ;; is running (issue #2085).
            (add-hook 'ido-everywhere-hook #'helm-mode--ido-everywhere-hook))

        ;; Disable this. It's breaking ivy
        ;; (setq completing-read-function 'helm--completing-read-default
        ;;       read-file-name-function  'helm--generic-read-file-name
        ;;       read-buffer-function     'helm--generic-read-buffer)

        (when (and (boundp 'completion-in-region-function)
                   helm-mode-handle-completion-in-region)
          (setq completion-in-region-function #'helm--completion-in-region))
        (message helm-completion-mode-start-message))
    (if (fboundp 'remove-function)
        (progn
          (remove-function completing-read-function #'helm--completing-read-default)
          (remove-function read-file-name-function #'helm--generic-read-file-name)
          (remove-function read-buffer-function #'helm--generic-read-buffer)
          (remove-function completion-in-region-function #'helm--completion-in-region)
          (remove-hook 'ido-everywhere-hook #'helm-mode--ido-everywhere-hook))
      (setq completing-read-function (and (fboundp 'completing-read-default)
                                          'completing-read-default)
            read-file-name-function  (and (fboundp 'read-file-name-default)
                                          'read-file-name-default)
            read-buffer-function     (and (fboundp 'read-buffer) 'read-buffer))
      (when (and (boundp 'completion-in-region-function)
                 (boundp 'helm--old-completion-in-region-function))
        (setq completion-in-region-function helm--old-completion-in-region-function))
      (message helm-completion-mode-quit-message))))

(defun restart-helm-fix ()
  (interactive)
  (helm-mode -1)
  (helm-mode 1)
  (helm))

(require 'ace-jump-helm-line)

(defun completion-at-point ()
  "Perform completion on the text around point.
The completion method is determined by `completion-at-point-functions'."
  (interactive)
  (let ((res (run-hook-wrapped 'completion-at-point-functions
                               #'completion--capf-wrapper 'all)))

    ;; (remove-from-list 'completion-at-point-functions 'elisp-completion-at-point)
    ;; (etv (pp-to-string completion-at-point-functions))
    (pcase res
      (`(,_ . ,(and (pred functionp) f)) (funcall f))
      (`(,hookfun . (,start ,end ,collection . ,plist))
       (unless (markerp start) (setq start (copy-marker start)))
       (let* ((completion-extra-properties plist)
              (completion-in-region-mode-predicate
               (lambda ()
                 ;; We're still in the same completion field.
                 (let ((newstart (car-safe (funcall hookfun))))
                   (and newstart (= newstart start))))))
         ;; (etv (pp-to-string collection))
         ;; (etv (pp-to-string `(completion-in-region ,start ,end ,collection
         ;;                                  ,(plist-get plist :predicate))))
         (completion-in-region start end collection
                               (plist-get plist :predicate))))
      ;; Maybe completion already happened and the function returned t.
      (_
       (when (cdr res)
         (message "Warning: %S failed to return valid completion data!"
                  (car res)))
       (cdr res)))))

(advice-add 'helm-elisp--persistent-help :around #'ignore-errors-around-advice)

(defun helm-google-suggest-parser ()
  (cl-loop
   with result-alist = (xml-get-children
                        (car (xml-parse-region
                              (point-min) (point-max)))
                        'CompleteSuggestion)
   for pen-i in result-alist collect
   (cdr (cl-caadr (assq 'suggestion i)))))

(defun helm-google-suggest-fetch (input)
  "Fetch suggestions for INPUT from XML buffer."
  (let ((request (format helm-google-suggest-url
                         (url-hexify-string input))))
    (helm-net--url-retrieve-sync
     request #'helm-google-suggest-parser)))

(setq helm-net-prefer-curl t)
(setq helm-net-prefer-curl nil)

(defun helm-net--url-retrieve-sync (request parser)
  (if helm-net-prefer-curl
      (with-temp-buffer
        (apply #'call-process "curl"
               nil `(t ,helm-net-curl-log-file) nil request helm-net-curl-switches)
        (funcall parser))

    (let ((b (url-retrieve-synchronously request)))
      (pen-url-log "Checking output from url-retrieve-synchronously")
      (pen-url-log "a")
      (if (and
           b
           (not (eq 'input b))
           (bufferp b))
          (progn
            (pen-url-log "b")
            (with-current-buffer b
              (let ((r (ignore-errors (funcall parser))))
                (pen-url-log (pp-to-string r))
                (pen-url-log "parsed")
                r)))
        (progn
          (pen-url-log "c")
          (pen-url-log "nothing returned from url-retrieve-synchronously")
          nil)))))

(defun helm-get-candidates (symbol-function)
  "Retrieve and return the list of candidates from SOURCE."
  (let* ((candidate-fn (assoc-default 'candidates source))
         (candidate-proc (assoc-default 'candidates-process source))
         (inhibit-quit (or candidate-proc
                           (not (display-graphic-p))))
         cfn-error
         (notify-error
          (lambda (&optional e)
            (error
             "In `%s' source: `%s' %s %s"
             (assoc-default 'name source)
             (or candidate-fn candidate-proc)
             (if e "\n" "must be a list, a symbol bound to a list, or a function returning a list")
             (if e (prin1-to-string e) ""))))
         (candidates (condition-case-unless-debug err
                         (if candidate-proc
                             ;; Calling `helm-interpret-value' with no
                             ;; SOURCE arg force the use of `funcall'
                             ;; and not `helm-apply-functions-from-source'.
                             (helm-interpret-value candidate-proc)
                           (helm-interpret-value candidate-fn source))
                       (error (helm-log "Error: %S" (setq cfn-error err)) nil))))
    (cond ((and (processp candidates) (not candidate-proc))
           (warn "Candidates function `%s' should be called in a `candidates-process' attribute"
                 candidate-fn))
          ((and candidate-proc (not (processp candidates)))
           (error "Candidates function `%s' should run a process" candidate-proc)))
    (cond ((processp candidates)
           candidates)
          (cfn-error (unless helm--ignore-errors
                       (funcall notify-error cfn-error)))
          ((or (null candidates)
               (equal candidates '("")))
           nil)
          ((listp candidates)
           (helm-transform-candidates candidates source))
          (t (funcall notify-error)))))

(defun helm-other-buffer (sources buffer &optional delay)
  "Simplified Helm interface with other `helm-buffer'.
Call `helm' only with SOURCES and BUFFER as args."
  (if (not delay)
      (setq delay 0.2))
  (helm :sources sources :buffer buffer
        :input-idle-delay delay
        :helm-full-frame t))

(require 'helm-google)
(defun helm-google (&optional engine search-term)
  "Web search interface for Emacs."
  (interactive)
  (let ((input (or search-term (when (use-region-p)
                                 (buffer-substring-no-properties
                                  (region-beginning)
                                  (region-end)))))
        (helm-google-default-engine (or engine helm-google-default-engine)))
    (helm :sources `((name . ,(helm-google-engine-string))
                     (action . helm-google-actions)
                     (candidates . helm-google-search)
                     (requires-pattern)
                     (nohighlight)
                     (multiline)
                     (match . identity)
                     (volatile))
          :prompt (concat (helm-google-engine-string) ": ")
          :input input
          :input-idle-delay helm-google-idle-delay
          :buffer "*helm google*"
          :history 'helm-google-input-history
          :helm-full-frame t)))

;; The delay prevents spamming google
(eval
 `(defun helm-google-suggest ()
    "Preconfigured `helm' for Google search with Google suggest."
    (interactive)
    ;; (helm-other-buffer 'helm-source-google-suggest "*helm google*" 0.1)
    (helm-other-buffer 'helm-source-google-suggest "*helm google*" ,(string-to-number (myrc-get "helm_async_delay")))))

(defun helm-google-suggest-set-candidates (&optional request-prefix)
  "Set candidates with result and number of Google results found."
  (let ((suggestions (helm-google-suggest-fetch
                      (or (and request-prefix
                               (concat request-prefix
                                       " " helm-pattern))
                          helm-pattern))))
    (if (member helm-pattern suggestions)
        suggestions
        (append
         suggestions
         (list (cons (format "Search for '%s' on Google" helm-input)
                     helm-input))))))

(defun helm-google-suggest-set-candidates (&optional request-prefix)
  "Set candidates with result and number of Google results found."
  ;; (message "%s" (concat "request-prefix: '" request-prefix "'"))
  (let* ((suggestions (helm-google-suggest-fetch
                       (or (and request-prefix
                                (concat request-prefix
                                        " " helm-pattern))
                           helm-pattern)))
         (completions
          (if suggestions
              (if (member helm-pattern suggestions)
                  suggestions
                (cons helm-input suggestions))
            (append
             suggestions
             (list (cons (format "No completions. Search for '%s' on Google" helm-input)
                         helm-input))))))
    (mapcar (lambda (e) (if (stringp e)
                            (if (string-match (unregexify helm-input) e)
                                e
                              (concat helm-input " " e))
                          e))
            completions)))

(defun helm-google--parse-google (buf)
  "Parse the html response from Google."
  (helm-google--with-buffer buf
      (let (results result)
        (while (re-search-forward "class=\"kCrYT\"><a href=\"/url\\?q=\\(.*?\\)&amp;sa" nil t)
          (setq result (plist-put result :url (match-string-no-properties 1)))
          (re-search-forward "BNeawe vvjwJb AP7Wnd\">\\(.*?\\)</div>" nil t)
          (setq result (plist-put result :title (helm-google--process-html (match-string-no-properties 1))))
          (if (looking-at "</h3>")
              (progn
                (re-search-forward "BNeawe s3v9rd" nil t)
                (re-search-forward "BNeawe s3v9rd" nil t)
                (re-search-forward "\">\\(.*?\\)</div>" nil t)
                (setq result (plist-put result :content (helm-google--process-html (match-string-no-properties 1))))))
          (add-to-list 'results result t)
          (setq result nil))
        results)))

(defun helm-check-minibuffer-input ()
  "Check minibuffer content."
  (with-helm-quittable
    (with-selected-window (or (active-minibuffer-window)
                              (minibuffer-window))
      (helm-check-new-input (minibuffer-contents)))))

;; This is the fix
(defun helm-check-minibuffer-input ()
  "Check minibuffer content."
  (with-selected-window (or (active-minibuffer-window)
                            (minibuffer-window))
    (helm-check-new-input (minibuffer-contents))))

;;j:helm-source-google-suggest

(defset helm-source-google-suggest
  (helm-build-sync-source "Google Suggest"
    :candidates (lambda ()
                  (funcall helm-google-suggest-default-function))
    :action 'helm-google-suggest-actions
    :volatile t
    :keymap helm-map
    :requires-pattern 3))



(define-key helm-comp-read-map (kbd "<M-RET>")      'helm-copy-to-tvipe)
(define-key helm-map (kbd "M-D") #'send-m-del)
(define-key helm-find-files-map (kbd "M-D") #'send-m-del)
(define-key helm-map (kbd "C-h") nil)
(define-key pen-map (kbd "M-m f r") 'helm-mini) ; recent
(define-key pen-map (kbd "M-m f R") 'sps-ranger)
(define-key pen-map (kbd "M-\"") nil)
(define-key pen-map (kbd "M-m f z") 'pen-helm-fzf)
(define-key pen-map (kbd "M-m f Z") 'pen-helm-fzf-top)
(define-key pen-map (kbd "M-m f f") 'pen-helm-find-files) ; It's a little different from spacemacs' one. Spacemacs uses C-h for up dir where this uses C-l.
(define-key helm-map (kbd "<help> p") #'helm-test-code)
(define-key helm-map (kbd "M-k") 'ace-jump-helm-line)
(define-key helm-buffer-map (kbd "C-M-@") 'helm-toggle-visible-mark)
(define-key helm-buffer-map (kbd "M-SPC") 'helm-toggle-visible-mark)
(define-key helm-buffer-map (kbd "M-u") 'helm-unmark-all)

(provide 'pen-helm)