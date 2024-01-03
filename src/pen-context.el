;; suggest-funcs

;; This system is basically the way I structure things in the future
;; I must start creating and get very good at emacs lisp.

(defun pen-rpl-at-line-p (rpl)
  (let* ((output (chomp (pen-sn (concat "rosie grep -o subs " (pen-q rpl)) (thing-at-point 'line t))))
         (matches (pen-str2list output))
         (n (length matches)))
    (and (not (string-empty-p output)) (> n 0))))

(defun pen-rpl-at-line (rpl)
  (let* ((output (chomp (pen-sn (concat "rosie grep -o subs " (pen-q rpl)) (thing-at-point 'line t))))
         (matches (pen-str2list output)))
    matches))

(defun pen-string-at-point (&optional p)
  (if (not p) (setq p (point)))
  (str (buffer-substring p (save-excursion (goto-char p) (line-end-position)))))

(defun pen-rpl-at-point (rpl)
  (let* ((output (chomp (pen-sn (concat "rosie grep -o subs " (pen-q rpl)) (pen-string-at-point))))
         (matches (and (not (string-empty-p output)) (pen-str2list output))))
    matches))

(defun pen-rpl-at-point-p (rpl)
  (< 0 (length (pen-rpl-at-point rpl))))

(df pen-copy-ip-here (xc (first (pen-rpl-at-point "net.ipv4"))))
(df pen-copy-email-here (xc (first (pen-rpl-at-line "net.email"))))

(defun pen-buffer-cron-lines ()
  (sor (pen-snc "pen-scrape \"((?:[0-9,/-]+|\\\\*)\\\\s+){4}(?:[0-9]+|\\\\*)\"" (buffer-string))))

(progn
  (defset pen-context-tuples nil)
  (defset pen-context-tuples
    (-uniq
     (append
      pen-context-tuples
      `((((derived-mode-p 'emacs-lisp-mode)
          (pen-rpl-at-point-p "net.ipv4"))
         (copy-ip-here))
        (((string-match "/ws/music" (pen-pwd)))
         (xdotool-press-key
          random-playlist))
        (((eq (pen-face-at-point) 'info-code-face))
         (select-font-lock-face-region))
        (((glossary-button-at-point))
         (pen-button-copy-link-at-point))
        (((pen-regex-at-point-p "/r/[a-z]+"))
         ,(dff (eww (concat "http://reddit.com" (pen-regex-at-point-p "/r/[a-z]+")))))
        (((pen-regex-at-point-p "^r/[a-z]+"))
         ,(dff (eww (concat "http://reddit.com/" (pen-regex-at-point-p "r/[a-z]+")))))
        (((derived-mode-p 'eww-mode))
         (eww-open-browsh))
        (((derived-mode-p 'calibredb-search-mode))
         (pen-sph
          calibre-open-file-externally))
        (((string-equal "Haskell" (pen-snc "onefetch --output json | jq -r \".dominantLanguage\"")))
         ,(list (dff (pen-sps "ghcid"))))
        (((or (string-match-p "/glossary.txt$" (or (get-path-nocreate) ""))
              (string-match-p "/root.pen/glossaries/.*\\.txt$" (or (get-path-nocreate) ""))))
         (reload-glossary-and-generate-buttons))
        (((f-directory-p ".git"))
         ;; This wont work
         ;; (compile "git-convert-master-to-main")
         ;; writing 'list' is needed because an invocation is required, not a symbol
         ,(list (dff (pen-start-process "git-convert-master-to-main"))
                ;; This doesn't work
                ;; (dff (call-process "git-convert-master-to-main"))
                ))
        (((or (derived-mode-p 'org-mode)
              (derived-mode-p 'text-mode)
              (derived-mode-p 'markdown-mode))
          (pen-rpl-at-line-p "net.email"))
         (copy-email-here))
        (((or (string-match "streamr" (buffer-string))
              (string-match "DATA" (buffer-string))
              (string-match "DATAcoin" (buffer-string))))
         ;; writing 'list' is needed because an invocation is required, not a symbol
         ,(list (dff (chrome "https://www.binance.com/en/trade/DATA_ETH"))))
        (((pen-buffer-cron-lines))
         (crontab-guru))
        ((lsp-lens--overlays)
         (lsp-avy-lens))
        (((org-at-table-p))
         (fpvd-org-table-export
          efpvd-org-table-export))
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
        (((bound-and-true-p ports-tablist-mode))
         (server-suggest))
        (((bound-and-true-p subnetscan-tablist-mode))
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
        ;; (((or (derived-mode-p 'python-mode)
        ;;       (derived-mode-p 'text-mode)))
        ;;  (reload-glossary-reopen-and-generate-buttons))
        ))))
  (setq context-preds '())
  (setq context-pred-funcs '())
  (setq context-tuples-compiled '())

  ;; (build-context-functions)
  )

;; I'd have to look up the tuple first?
;; I don't really know how it works
(defun pen-add-context-function (predicate-list-or-sexp f)
  (noop))

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
  (apply-partially 'pen-func-for-expression "pen-contextp"))

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

;; The memoization only lasts over a single suggestion
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
    (remove nil (-distinct (-flatten suggestions)))))

(defun pen-suggest-funcs ()
  (interactive)
  (let* ((fz-input (pen-suggest-funcs-collect))
         (sel (if fz-input
                  (fz fz-input nil nil "suggest-funcs: "))))
    (if sel
        (let ((selsym (intern sel)))
          (if (and (function-p selsym) (commandp selsym))
              (call-interactively selsym)
            (funcall selsym))))))

(defun pen-edit-context ()
  (interactive)
  (pen-find-thing 'pen-context-tuples))

(provide 'pen-context)
