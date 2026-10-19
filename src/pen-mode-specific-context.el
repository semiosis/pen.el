(require 'pen-context)

(progn
  (defset pen-mode-specific-context-tuples nil)
  (defset pen-mode-specific-context-tuples
          (-uniq
           (append
            pen-mode-specific-context-tuples
            `((((derived-mode-p 'emacs-lisp-mode)
                (pen-rpl-at-point-p "net.ipv4"))
               (copy-ip-here))
              ;; (((string-match "/ws/music" (pen-pwd)))
              ;;  (xdotool-press-key
              ;;   random-playlist))
              ;; (((eq (pen-face-at-point) 'info-code-face))
              ;;  (select-font-lock-face-region))
              ;; (((and (or (eq (pen-face-at-point) 'diredfl-file-name)
              ;;            (eq (pen-face-at-point) 'diredfl-file-suffix))
              ;;        (string-equal "pdf" (f-ext (dired-file-name-at-point)))))
              ;;  (pen-open-dired-pdf-at-point))
              ;; (((glossary-button-at-point))
              ;;  (pen-button-copy-link-at-point))
              ;; (((pen-regex-at-point-p "/r/[a-z]+"))
              ;;  ,(dff (eww (concat "http://reddit.com" (pen-regex-at-point-p "/r/[a-z]+")))))
              ;; (((pen-regex-at-point-p "^r/[a-z]+"))
              ;;  ,(dff (eww (concat "http://reddit.com/" (pen-regex-at-point-p "r/[a-z]+")))))
              (((derived-mode-p 'eww-mode))
               (eww-open-browsh))
              (((derived-mode-p 'calibredb-search-mode))
               (pen-sph
                calibre-open-file-externally))
              ;; (((string-equal "Haskell" (pen-snc "onefetch --output json | jq -r \".dominantLanguage\"")))
              ;;  ,(list (dff (pen-sps "ghcid"))))
              ;; (((or (string-match-p "/glossary.txt$" (or (get-path-nocreate) ""))
              ;;       (string-match-p "/root.pen/glossaries/.*\\.txt$" (or (get-path-nocreate) ""))))
              ;;  (reload-glossary-and-generate-buttons))
              ;; (((f-directory-p ".git"))
              ;;  ;; This wont work
              ;;  ;; (compile "git-convert-master-to-main")
              ;;  ;; writing 'list' is needed because an invocation is required, not a symbol
              ;;  ,(list (dff (pen-start-process "git-convert-master-to-main"))
              ;;         ;; This doesn't work
              ;;         ;; (dff (call-process "git-convert-master-to-main"))
              ;;         ))
              (((or (derived-mode-p 'org-mode)
                    (derived-mode-p 'text-mode)
                    (derived-mode-p 'markdown-mode))
                (pen-rpl-at-line-p "net.email"))
               (copy-email-here))
              ;; (((or (string-match "streamr" (buffer-string))
              ;;       (string-match "DATA" (buffer-string))
              ;;       (string-match "DATAcoin" (buffer-string))))
              ;;  ;; writing 'list' is needed because an invocation is required, not a symbol
              ;;  ,(list (dff (chrome "https://www.binance.com/en/trade/DATA_ETH"))))
              ;; (((pen-buffer-cron-lines))
              ;;  (crontab-guru))
              ;; ((lsp-lens--overlays)
              ;;  (lsp-avy-lens))
              ;; (((org-at-table-p))
              ;;  (fpvd-org-table-export
              ;;   efpvd-org-table-export))
              ;; (((f-exists-p "project.clj"))
              ;;  (cider-jack-in))
              ;; (((flyspell-overlay-here-p))
              ;;  (flyspell-auto-correct-word find-anagrams))
              ;; (((f-exists-p "project.clj"))
              ;;  (cider-switch-to-repl-buffer))
              ;; (((widget-at (point)))
              ;;  (widget-show-properties-here))
              ;; (((button-at (point)))
              ;;  (button-show-properties-here))
              ;; (((bible-verse-ref-at-point-p))
              ;;  (bible-verse-at-point-tpop
              ;;   bible-verse-menu-at-point-tpop
              ;;   bible-mode-lookup
              ;;   bible-mode-cross-references))
              ;; (((widget-at (point)))
              ;;  (pen-widget-get-value-at-point
              ;;   pen-widget-show-keymap-at-point))
              ;; (((bound-and-true-p ports-tablist-mode))
              ;;  (server-suggest))
              ;; (((bound-and-true-p subnetscan-tablist-mode))
              ;;  (server-suggest-subnet-scan))
              ;; (((org-brain-headline-at-point))
              ;;  (org-brain-this-headline-to-file))
              ;; (((string-match-p "/README.\\(md\\|org\\)$" (or (get-path-nocreate) "")))
              ;;  (license-templates-new-file))
              ;; (((github-url))
              ;;  (github-surf
              ;;   github1s
              ;;   chrome-github-actions))
              ;; (((vc-url))
              ;;  (chrome-git-url))
              ;; (((or (derived-mode-p 'python-mode)
              ;;       (derived-mode-p 'text-mode)))
              ;;  (reload-glossary-reopen-and-generate-buttons))
              ))))
  (setq context-preds '())
  (setq context-pred-funcs '())
  (setq context-tuples-compiled '())

  ;; (build-context-functions)
  )

(provide 'pen-mode-specific-context)
