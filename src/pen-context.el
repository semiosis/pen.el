;; This system is basically the way I structure things in the future
;; I must start creating and get very good at emacs lisp.

(defun rpl-at-line-p (rpl)
  (let* ((output (chomp (pen-sn (concat "rosie grep -o subs " (pen-q rpl)) (thing-at-point 'line t))))
         (matches (pen-str2list output))
         (n (length matches)))
    (and (not (string-empty-p output)) (> n 0))))

(defun rpl-at-line (rpl)
  (let* ((output (chomp (pen-sn (concat "rosie grep -o subs " (pen-q rpl)) (thing-at-point 'line t))))
         (matches (pen-str2list output)))
    matches))

(defun string-at-point (&optional p)
  (if (not p) (setq p (point)))
  (str (buffer-substring p (save-excursion (goto-char p) (line-end-position)))))

;; (save-excursion (end-of-line)(point))
(defun rpl-at-point (rpl)
  (let* ((output (chomp (pen-sn (concat "rosie grep -o subs " (pen-q rpl)) (string-at-point))))
         (matches (and (not (string-empty-p output)) (pen-str2list output))))
    matches))

(defun rpl-at-point-p (rpl)
  (< 0 (length (rpl-at-point rpl))))

(df copy-ip-here (xc (first (rpl-at-point "net.ipv4"))))
(df copy-email-here (xc (first (rpl-at-line "net.email"))))

(defun buffer-cron-lines ()
  (sor (pen-snc "pen-scrape \"((?:[0-9,/-]+|\\\\*)\\\\s+){4}(?:[0-9]+|\\\\*)\"" (buffer-string))))

(defun crontab-guru (tab)
  (interactive (list (fz (buffer-cron-lines) (if (selected-p) (pen-thing-at-point)))))
  (let ((tab (pen-sed "s/\\s\\+/_/g" tab)))
    (etv (pen-sed "s/^\"//;s/\"$//" (pen-scrape "\"[^\"]*\"" (pen-snc (concat "elinks-dump-chrome " (pen-q (concat "https://crontab.guru/#" tab)))))))))

;; I should probably redesign this
(progn
  (defset pen-context-tuples
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
      (((string-equal "Haskell" (pen-snc "onefetch --output json | jq -r \".dominantLanguage\"")))
       ,(list (dff (sps "ghcid"))))
      (((or (string-match-p "/glossary.txt$" (or (get-path-nocreate) ""))
            (string-match-p "/home/shane/glossaries/.*\\.txt$" (or (get-path-nocreate) ""))))
       (reload-glossary-and-generate-buttons))
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
       (chrome-git-url))))
  (setq context-preds '())
  (setq context-pred-funcs '())
  (setq context-tuples-compiled '()))

(defun pen-hash-expression (expr)
  (sha1 (str expr)))

(defun pen-func-for-expression (nameprefix expr &optional update slugify-input)
  (let* ((funcsym (intern (concat nameprefix "-" (if slugify-input
                                                      (slugify slugify-input)
                                                   (pen-hash-expression expr))))))
    (if (and (not update) (fboundp funcsym))
        funcsym
      (eval `(progn
               (defun ,funcsym ()
                 (ignore-errors (memoize-by-buffer-contents ',funcsym))
                 ,expr))))))

(defalias 'pen-context-pen-func-for-expression
  (apply-partially 'pen-func-for-expression "my-context-predicate"))

(defun pen-compile-context-tuple (context-tuple)
  (let ((pred-funcs (mapcar 'pen-context-pen-func-for-expression (car context-tuple))))
    ;; A list of functions and a list of calls
    (list pred-funcs (-drop 1 context-tuple))))

(defun pen-build-context-functions ()
  (interactive)
  (setq context-preds (-distinct (flatten-once (cl-loop for tup in pen-context-tuples collect (car tup)))))

  ;; Go through and make functions first -- a little unnecessary
  (setq context-pred-funcs (cl-loop for pred in context-preds collect (pen-context-pen-func-for-expression pred)))

  (setq context-tuples-compiled (cl-loop for tup in pen-context-tuples collect (pen-compile-context-tuple tup))))
(pen-build-context-functions)

(defun pen-suggest-funcs-unmemoize ()
  (interactive)
  (cl-loop for f in context-pred-funcs do (ignore-errors (memoize-restore f))))

(defun pen-suggest-funcs-collect ()
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

(defun pen-suggest-funcs ()
  (interactive)
  (let* ((fz-input (pen-suggest-funcs-collect))
         (sel (if fz-input
                  (fz fz-input nil nil "suggest-funcs: "))))
    (if sel
        (let ((selsym (str2sym sel)))
          (if (and (function-p selsym) (commandp selsym))
              (call-interactively selsym)
            (call-function selsym))))))

(define-key global-map (kbd "M-4 M-4") 'pen-suggest-funcs)
(define-key global-map (kbd "<help> G") 'pen-suggest-funcs)
(define-key global-map (kbd "M-4 >") (lm (find-thing 'pen-context-tuples)))
(define-key global-map (kbd "M-4 M->") (lm (find-thing 'pen-context-tuples)))

(provide 'pen-context)