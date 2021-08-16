;; This system is basically the way I structure things in the future
;; I must start creating and get very good at emacs lisp.

(defun rpl-at-line-p (rpl)
  (let* ((output (chomp (sn (concat "rosie grep -o subs " (q rpl)) (thing-at-point 'line t))))
         (matches (str2list output))
         (n (length matches)))
    (and (not (string-empty-p output)) (> n 0))))

(defun rpl-at-line (rpl)
  (let* ((output (chomp (sn (concat "rosie grep -o subs " (q rpl)) (thing-at-point 'line t))))
         (matches (str2list output)))
    matches))

(defun string-at-point (&optional p)
  (if (not p) (setq p (point)))
  (str (buffer-substring p (save-excursion (goto-char p) (line-end-position)))))

;; (save-excursion (end-of-line)(point))
(defun rpl-at-point (rpl)
  (let* ((output (chomp (sn (concat "rosie grep -o subs " (q rpl)) (string-at-point))))
         (matches (and (not (string-empty-p output)) (str2list output))))
    matches))

(defun rpl-at-point-p (rpl)
  (< 0 (length (rpl-at-point rpl)))
  ;; (let* ((output (chomp (sn (concat "rosie grep -o subs " (q rpl)) (thing-at-point 'sexp t))))
  ;;        (matches (str2list output))
  ;;        (n (length matches)))
  ;;   (and (not (string-empty-p output)) (> n 0)))
  )


;; TODO Make it without the tree system first
;; Maybe the solution will fall out of that

;; (rpl-at-point-p "net.ipv4")

;; TODO Create some problog predicates
;; TODO Create some predicates based on NLP parsers that look for things like sentiment

;; Here is an IP address 192.168.1.1

(df copy-ip-here (xc (first (rpl-at-point "net.ipv4"))))
(df copy-email-here (xc (first (rpl-at-line "net.email"))))

(defun buffer-cron-lines ()
  (sor (snc "scrape \"((?:[0-9,/-]+|\\\\*)\\\\s+){4}(?:[0-9]+|\\\\*)\"" (buffer-string))))

(defun crontab-guru (tab)
  (interactive (list (fz (buffer-cron-lines) (if (selectionp) (my/thing-at-point)))))
  (let ((tab (sed "s/\\s\\+/_/g" tab)))
    ;; (chrome (concat "https://crontab.guru/#" tab))
    (etv (sed "s/^\"//;s/\"$//" (scrape "\"[^\"]*\"" (snc (concat "elinks-dump-chrome " (q (concat "https://crontab.guru/#" tab)))))))))


(defun my-start-process (command)
  (interactive (list (read-string-hist "command: ")))
  (with-current-buffer
      (switch-to-buffer command)
    (start-process
     command
     (current-buffer)
     command)))

;; I should probably redesign this
(progn
  (defset context-tuples
    `((((major-mode-p 'emacs-lisp-mode)
        (rpl-at-point-p "net.ipv4"))
       (copy-ip-here))
      (((re-match-p "/ws/music" (my/pwd)))
       (xdotool-press-key
        random-playlist))
      (((glossary-button-at-point))
       (my-button-copy-link-at-point))
      (((regex-at-point-p "/r/[a-z]+"))
       ,(dff (eww (concat "http://reddit.com" (regex-at-point-p "/r/[a-z]+")))))
      (((regex-at-point-p "^r/[a-z]+"))
       ,(dff (eww (concat "http://reddit.com/" (regex-at-point-p "r/[a-z]+")))))
      (((major-mode-p 'eww-mode))
       (eww-open-browsh))
      (((string-equal "Haskell" (snc "onefetch --output json | jq -r \".dominantLanguage\"")))
       ,(list (dff (sps "ghcid"))))
      (((or (string-match-p "/glossary.txt$" (or (get-path-nocreate) ""))
            (string-match-p "/home/shane/glossaries/.*\\.txt$" (or (get-path-nocreate) ""))))
       (reload-glossary-and-generate-buttons))
      (((f-directory-p ".git"))
       ;; This wont work
       ;; (compile "git-convert-master-to-main")
       ;; writing 'list' is needed because an invocation is required, not a symbol
       ,(list (dff (my-start-process "git-convert-master-to-main"))
              ;; This doesn't work
              ;; (dff (call-process "git-convert-master-to-main"))
              ))
      (((or (major-mode-p 'org-mode)
            (major-mode-p 'text-mode)
            (major-mode-p 'markdown-mode))
        (rpl-at-line-p "net.email"))
       (copy-email-here))
      (((or (re-match-p "streamr" (buffer-string))
            (re-match-p "DATA" (buffer-string))
            (re-match-p "DATAcoin" (buffer-string))))
       ;; writing 'list' is needed because an invocation is required, not a symbol
       ,(list (dff (chrome "https://www.binance.com/en/trade/DATA_ETH"))))
      (((buffer-cron-lines))
       (crontab-guru))
      (((f-exists-p "project.clj"))
       (cider-jack-in))
      (((flyspell-overlay-here-p))
       (flyspell-auto-correct-word find-anagrams))
      (((f-exists-p "project.clj"))
       (cider-switch-to-repl-buffer))
      (((widget-at (point)))
       (widget-show-properties-here))
      (((button-at (point)))
       (button-show-properties-here))
      (((minor-mode-p ports-tablist-mode))
       (server-suggest))
      (((minor-mode-p subnetscan-tablist-mode))
       (server-suggest-subnet-scan))
      (((org-brain-headline-at-point))
       (org-brain-this-headline-to-file))
      (((string-match-p "/README.\\(md\\|org\\)$" (or (get-path-nocreate) "")))
       (license-templates-new-file))
      (((github-url))
       (github-surf
        github1s
        chrome-github-actions))
      (((vc-url))
       (chrome-git-url))
      ;; (((or (major-mode-p 'python-mode)
      ;;       (major-mode-p 'text-mode)))
      ;;  (reload-glossary-reopen-and-generate-buttons))
      ))
  (setq context-preds '())
  (setq context-pred-funcs '())
  (setq context-tuples-compiled '())

  ;; (build-context-functions)
  )

;; Defining a function this way is not optimal
(defalias 'context-func-for-expression
  (slime-curry 'func-for-expression "my-context-predicate"))

;; (context-func-for-expression '(message "yo"))

(defun compile-context-tuple (context-tuple)
  (let ((pred-funcs (mapcar 'context-func-for-expression (car context-tuple))))
    ;; A list of functions and a list of calls
    (list pred-funcs (-drop 1 context-tuple))))

(defun build-context-functions ()
  (interactive)
  (setq context-preds (-distinct (flatten-once (cl-loop for tup in context-tuples collect (car tup)))))

  ;; Go through and make functions first -- a little unnecessary
  (setq context-pred-funcs (cl-loop for pred in context-preds collect (context-func-for-expression pred)))

  (setq context-tuples-compiled (cl-loop for tup in context-tuples collect (compile-context-tuple tup))))
(build-context-functions)

(defun suggest-funcs-unmemoize ()
  (interactive)
  (cl-loop for f in context-pred-funcs do (ignore-errors (memoize-restore f))))

(defun suggest-funcs-collect ()
  (cl-loop for f in context-pred-funcs do (ignore-errors (memoize-orig f)))

  (let ((suggestions
         (cl-loop for tup in context-tuples-compiled
                  collect
                  (if (eval `(and ,@(mapcar 'list (car tup))))
                      (second tup)
                    '()))))

    (cl-loop for f in context-pred-funcs do (ignore-errors (memoize-restore f)))
    ;; (etv (pps suggestions))
    (remove nil (-distinct (-flatten suggestions)))))

(defun suggest-funcs ()
  (interactive)
  ;; (suggest-funcs-collect)
  (let* ((fz-input (suggest-funcs-collect))
         (sel (if fz-input
                  (fz fz-input nil nil "suggest-funcs: "))))
    (if sel
        (let ((selsym (str2sym sel)))
          (if (and (function-p selsym) (commandp selsym))
              (call-interactively selsym)
            (call-function selsym))))))

(define-key global-map (kbd "M-4 M-4") 'suggest-funcs)
(define-key global-map (kbd "<help> G") 'suggest-funcs)
(define-key global-map (kbd "M-4 >") (lm (find-thing 'context-tuples)))
(define-key global-map (kbd "M-4 M->") (lm (find-thing 'context-tuples)))


(provide 'pen-context)