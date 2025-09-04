;; Make these bindings happen last so emacs fully loads before creating bindings

(define-key global-map (kbd "<f2>") nil)

(sslk "lg=" 'position-list-nav/body)

(sslk "lVc" 'toggle-chrome)
(sslk "lVr" 'toggle-read-only)
(sslk "lay" #'workers)
(sslk "laY" (make-etui-cmd "chkservice" nil))
(sslk "law" 'aws-instances)
(sslk "lap" #'list-processes)
(sslk "las" #'ebdb-display-all-records)
(sslk "laS" #'server-list-clients)
(sslk "lav" 'pen-org-bible-verse-repl)
(sslk "lal" #'bufler)
(sslk "lqtt" #'todayfile)
(sslk "lqtw" #'weekfile)
(sslk "laU" #'bluetooth-list-devices)
(sslk "lag" #'gist-list)
(sslk "laN" #'gnus)
(sslk "lat" #'helm-top)
(sslk "laT" #'list-timers)
(sslk "laP" #'proced)
(sslk "lab" #'dap-hydra/body)
(comment
 (sslk "laa" #'dap-ui-breakpoints))
(sslk "laa" #'ascii-adventures)
(sslk "lad" #'docker)
(sslk "lax" #'mitmproxy)
(sslk "laD" #'prodigy)
(sslk "lah" #'htop)
(sslk "laH" #'hackernews)
(sslk "lan" #'ibuffer)
(sslk "laj" #'e-faith-and-judgement)
(sslk "lao" #'e-notes-on-sermons)
;; (sslk "lam" #'tzc-world-clock)
(sslk "lam" #'man)
(sslk "law" #'aws-instances)
;; (sslk "lak" #'kubernetes-overview)

(sslk "lac" #'artist-mode)
(sslk "lak" #'toggle-picture-mode)
(sslk "laf" #'deft)
(sslk "laB" #'calibredb)
(sslk "lae" #'deer)
(sslk "laio" #'iotop)
(sslk "laie" #'erc)
(sslk "laC" #'calc)

(sslk "laE" 'elfeed)
(sslk "la)" #'emoji-cheat-sheet-plus-buffer)

(loop for d in
      (mapcar
       (lambda (l)
         `(define-key ,(third l) (kbd ,(concat "M-m " (cadr l) " " (car (car l)))) ,(cadr (car l))))
       (-cx '((";" 'ansi-zsh)
              ("'" 'eshell)
              ("\"" 'nw-term)
              ("s" 'eshell-sph)
              ("S" 'eshell-spv)
              ("g" 'split-window-below)
              ("G" 'split-window-right))
            '("w"
              "C-w")
            '(pen-map
              global-map)))
      do
      (ignore-errors
        (eval d)))

(ignore-errors
  (define-key pen-map (kbd "M-m w ;") #'ansi-zsh)
  (define-key pen-map (kbd "M-m w '") #'eshell)
  (define-key pen-map (kbd "M-m w \"") #'nw-term)

  (define-key pen-map (kbd "M-m w s") #'eshell-sph)
  (define-key pen-map (kbd "M-m w S") #'eshell-spv)

  (define-key pen-map (kbd "M-m w g") #'split-window-below)
  (define-key pen-map (kbd "M-m w G") #'split-window-right)

  (define-key pen-map (kbd "M-m w v") #'pen-e-sph-zsh)
  (define-key pen-map (kbd "M-m w V") #'pen-e-spv-zsh)

  (define-key pen-map (kbd "M-m w N") #'spv-new-buffer)
  (define-key pen-map (kbd "M-m w n") #'spv-new-buffer)
  ;; (define-key pen-map (kbd "M-m w n") #'pen-e-nw-zsh)

  (define-key pen-map (kbd "M-m w O") #'win-swap)
  (define-key pen-map (kbd "M-m w o") #'win-swap)

  (define-key global-map (kbd "M-m w d") 'sph-next)
  (define-key global-map (kbd "M-m w D") 'spv-next)
  (define-key global-map (kbd "M-m w e") 'sps-next))

(sslk "ld?" #'ag-glossaries)
(sslk "ldo" 'fz-find-ws)
(sslk "ldO" 'ag-ws)
(sslk "lT" 'fz-find-config)
(sslk "lO" 'fz-find-ws)

(defun fz-find-dir ()
  (interactive)
  (if (>= (prefix-numeric-value current-prefix-arg) 4)
      (e "$HOME/notes/directories.org")
    (e
     (fz
      (cat "$HOME/notes/directories.org")
      nil nil "tm-dir: "))))

(define-key pen-map (kbd "M-l DEL") 'fz-find-dir)

(defun fz-select-git-repo ()
  (interactive)
  (pen-mu
   (let* ((sel (fz (chomp (pen-sn "list-git-repos"))
                   nil nil "fz-select-git-repo: "))
          (dir (concat "$MYGIT/" sel)))
     (if
         (f-directory-p dir)
         (e (concat "$MYGIT/" sel))))))

(progn
  ;; pen-mu
  ;; Don't unminimise. e unminimises anyway
  ;; (pen-ms "/M-m/{p;s/M-m/M-l/}" (define-key pen-map (kbd "M-m d DEL") 'fz-tm-shortcuts))
  (sslk "ldzw" 'fz-find-ws)
  (sslk "ldW" 'fz-find-ws)
  (sslk "ldG" 'ag-glossaries)
  (sslk "ldg l" 'swiper-glossaries)
  (sslk "ld6" (dff (e "$EMACSD_BUILTIN/elpa")))
  (sslk "ld7" (dff (e "$EMACSD_BUILTIN/elpa-full")))
  (sslk "ld8" (dff (e "$EMACSD_BUILTIN/elpa-light")))
  (sslk "ldm" (dff (e "$NOTES/ws/music")))
  (sslk "lds" (dff (e "$SCRIPTS")))
  (sslk "lfx" (dff (e "$REPOS/pen.el/src/pen-examplary.el")))
  (sslk "ldi" (dff (e "$REPOS/openai-api.el")))
  (sslk "lda" (dff
               (e (f-join pen-prompts-directory "prompts"))
               ;; (e "$REPOS/prompts/prompts")
               ))
  (sslk "ldx" (dff (e "$REPOS/examplary")))
  (sslk "ldd" (dff (e "$DUMP")))
  (sslk "ldD" (dff (e "$DUMP/downloads")))
  (sslk "ldn" (dff (e "$NOTES")))
  (sslk "ldM" (dff (e "$EMACSD_BUILTIN/manual-packages")))
  (sslk "ldzG" (dff (pen-sps "select-git-repo")))

  ;; unminimise for some of them
  (pen-mu
   (sslk "ldzg" 'fz-select-git-repo))
  (sslk "ldzw" (dff (pen-sps "select-ws-dir")))
  (sslk "ldzp" (dff (pen-sps "select-python-package")))
  (sslk "lFw" (dff (e "$NOTES/ws/english/words.txt")))
  (sslk "lFL" (dff (e "$REPOS/pen.el/src/pen.el")))
  (sslk "lFR" (dff (e "$NOTES/read.org")))
  (sslk "lFH" (dff (e "$NOTES/watch.org")))
  (sslk "lFr" (dff (e "$NOTES/remember.org")))
  (sslk "lFg" (dff (e "$NOTES/glossary.txt")))
  (sslk "lFt" (dff (e "$NOTES/todo.org")))
  (sslk "lFj" (dff (e "$NOTES/journal.org")))
  (sslk "lFn" (dff (e "$NOTES/need.org")))
  (sslk "lFf" (dff (e "$NOTES/files.txt")))
  (sslk "lFF" (dff (e "$EMACSD/pen.el/config/filters/filters.sh")))
  (sslk "lFe" (dff (e "$NOTES/examples.txt")))
  (sslk "lFW" (dff (e "$NOTES/ws/french/words.txt")))
  (sslk "lFp" (dff (e "$NOTES/perspective.org")))
  (sslk "lFs" (dff (e "$NOTES/websearch.txt")))
  (sslk "lFk" (dff (e "$NOTES/keep-in-mind.org")))
  (sslk "lFP" (dff (e "$NOTES/prayers.org")))
  ;; (sslk "l3dw" (dff (pen-open-dir "$MYGIT/takaheai/otagoai-website")))
  (sslk "ldgg" (dff (pen-open-dir "$MYGIT")))
  (sslk "ldU" 'fz-find-ws-music)
  (sslk "ldO" 'fz-find-ws)
  (sslk "ldE" (dff (pen-open-dir "$EMACSD")))
  (sslk "ldJ" (dff (pen-open-dir "$NOTES/ws/jobs")))
  (if (inside-docker-p)
      (progn
        (sslk "ldc" (dff (pen-open-dir (f-join pen-penel-directory "src"))))
        (sslk "ldC" (dff (pen-open-dir (f-join pen-penel-directory "src")))))
    (progn
      (sslk "ldc" (dff (pen-open-dir "$HOME/.emacs.d/config")))
      (sslk "ldC" (dff (pen-open-dir "$HOME/.emacs.d/config")))))
  (sslk "ldL" (dff (pen-open-dir "$HOME/.pen/glossaries")))
  (sslk "ldb" (dff (pen-open-dir "$DUMP$NOTES/ws/blog/blog")))
  (sslk "ldB" (dff (pen-open-dir "$HOME/blog/posts")))
  ;; (sslk "ldt" (dff (pen-open-dir "$DUMP/torrents")))
  (sslk "ldh" (dff (pen-open-dir "$HOME")))
  (sslk "ldw" (dff (pen-open-dir "$REPOS/prompts")))
  (sslk "ldo" (dff (pen-open-dir "$NOTES/ws")))

  (sslk "lA" (df ansi-zsh (etansi zsh)))
  (sslk "lrre" (df edit-emacs (e "$MYGIT/config/emacs/emacs")))
  (sslk "lrl" 'pen-edit-efm-conf)
  ;; (sslk "lrl" (df edit-emacs (e "/home/shane/.config/efm-langserver/config.yaml")))
  (sslk "lrrp" (df edit-python (e "$MYGIT/config/python/pythonrc.full.py")))
  (sslk "lrrr" (df edit-racket (e "$HOME/.racketrc")))
  (sslk "lrrs" (df edit-selected (e "$MYGIT/config/emacs/config/pen-selected.el")))
  (sslk "lrr." (df edit-pen-spacemacs (e "$MYGIT/config/emacs/config/pen-spacemacs.el")))
  (sslk "lrrv" (df edit-pen-spacemacs (e "$MYGIT/config/emacs/config/pen-evil.el")))
  (sslk "lghc/" #'pen-github-search-and-clone)

  (defshellfilter-new-buffer scrape-bible-references)
  (sslk "lpjv" 'sh/nb/scrape-bible-references)
  (define-key global-map (kbd "M-l M-p M-j") nil)

  ;; (sslk "lpJ" (df play-js (et "playground js")))
  ;; (sslk "lpj" (df tm-play-js (etm "playground js")))
  ;; (sslk "lpG" (df play-github (et "playground github")))
  ;; (sslk "lp." (df edit-play-github (e (b which playground))))

  (sslk "lgde" #'end-of-defun)
  (sslk "l7" #'pen-selection-note)
  (sslk "l9" #'search-google-for-doc)
  (sslk "l8" #'google-for-docs)
  (sslk "lgf" 'find-file-at-point)
  (sslk "lN" 'magit-status)

  (sslk "ldd" 'pen-dired-documents)
  (sslk "ldn" 'pen-dired-notes)
  (sslk "ldk" 'pen-dired-workspaces)
  (sslk "ldp" 'pen-acolyte-dired-penel)
  (sslk "ldqd" 'pen-dired-documents)
  (sslk "ldqn" 'pen-dired-notes)
  (sslk "ldqr" 'pen-dired-repos)
  (sslk "ldqp" 'pen-acolyte-dired-penel)
  (sslk "ldqo" 'pen-acolyte-dired-prompts)
  (sslk "ldqm" 'pen-acolyte-dired-engines)
  (sslk "ldqe" 'pen-acolyte-dired-esp)
  (sslk "ldqK" 'pen-dired-khala)
  (sslk "ldqR" 'pen-dired-rhizome)
  (sslk "ldqP" 'pen-dired-pensieve)
  (sslk "ldql" 'pen-dired-ilambda)
  (sslk "ldqa" 'pen-dired-imonad)
  (sslk "ldqf" 'pen-dired-src)
  (sslk "ldqV" 'pen-acolyte-dired-protoverses)
  (sslk "ldqv" 'pen-acolyte-dired-metaverses)
  (sslk "ldqC" 'pen-acolyte-dired-creation)
  (sslk "ldqs" 'pen-acolyte-dired-scripts)
  (sslk "ldqc" 'pen-acolyte-dired-config)
  (sslk "lds" 'pen-acolyte-dired-scripts)
  (sslk "ldqS" (df edit-ruse (e "/volumes/home/shane/var/smulliga/source/git/ahungry/ruse/src/ruse/core.clj"))))

(if (inside-docker-p)
    (sslk "ldqg" (dff (pen-open-dir "/volumes/home/shane/var/smulliga/source/git/semiosis")))
  (sslk "ldqg" (dff (pen-open-dir "/home/shane/var/smulliga/source/git/semiosis"))))

(sslk "lD" 'pen-swipe)
(define-key pen-map (kbd "M-l / C-i") #'tvipe-completions)
(sslk "lt" 'sh/git-add-all-below)
(sslk "lLR" 'helm-mini)

(define-key global-map (kbd "<help> h") nil)
(define-key global-map (kbd "<help> h z") 'pen-helm-fzf)
;; (sslk "lLz" 'pen-helm-fzf)
(define-key global-map (kbd "<help> h Z") 'pen-helm-fzf-top)
;; (sslk "lLZ" 'pen-helm-fzf-top)
(define-key global-map (kbd "<help> h i") 'ap/helm-info-emacs-elisp-cl)
;; (sslk "lLi" 'ap/helm-info-emacs-elisp-cl)
(define-key global-map (kbd "<help> h f") 'pen-helm-find-files)
(define-key global-map (kbd "<help> h b") 'pen-helm-broot-grep)
(define-key global-map (kbd "<help> h B") 'helm-regex-bible-search)
(define-key global-map (kbd "<help> h l") 'helm-regex-bible-search)
;; (sslk "lLf" 'pen-helm-find-files)
                                        ; It's a little different from spacemacs' one. Spacemacs uses C-h for up dir where this uses C-l.
(sslk "lkJ" 'compile-run-term)
(sslk "lk," 'compile-run-compile)
(sslk "lk<" 'compile-run-tm-ecompile)
(if (inside-docker-p)
    (sslk "ly" 'pen-copy-link-at-point))
(sslk "ljh" 'cheat-sh)
(sslk "l." 'pen-kill-buffer-immediately)
(sslk "lfP" 'fi-text-to-paras-nosegregate)

;; Overrides and things that sslk doesnt support
(define-key global-map (kbd "M-l C-s") #'pen-swipe)

;; overrides
;; Global map so it works from term
(loop for (m k) in (-cartesian-product '(global-map pen-map)
                                       '("M-l" "M-'"))
      do (eval
          `(progn (define-key ,m (kbd ,(concat k " M-k m")) #'pen-helm-imenu)
                  (define-key ,m (kbd ,(concat k " k")) #'bury-buffer)
                  (define-key ,m (kbd ,(concat k " s")) #'pen-sph)
                  (define-key ,m (kbd ,(concat k " S")) #'pen-spv)
                  (define-key ,m (kbd ,(concat k " y")) #'link-hint-copy-link)
                  (define-key ,m (kbd ,(concat k " M-e")) #'pen-revert)
                  (define-key ,m (kbd ,(concat k " M-w")) #'pen-save))))

;; (define-key global-map (kbd "M-m M-m") 'magit-status)
(if (inside-docker-p)
    (progn
      ;; Do these need to be pen-map?
      ;; pen-map is annoying in term
      ;; (define-key pen-map (kbd "C-w") nil)
      (define-key global-map (kbd "C-w") #'pen-c-w-cut)
      ;; (define-key pen-map (kbd "M-m M-m") 'magit-status)

      ;; This is harder to remove.      
      ;; - I'm trying to fix term by removing
      ;; these pen bindings, but I don't think
      ;; it's worth it. I'd have to remove all M-m pen bindings.
      ;; (define-key global-map (kbd "M-m") nil)
      ;; (define-key global-map (kbd "M-m M-m") 'magit-status)
      (define-key pen-map (kbd "M-m M-m") 'magit-status)
      (define-key pen-map (kbd "M-l C-s") #'pen-swipe)
      (define-key pen-map (kbd "M-' C-s") #'pen-swipe)))

(define-key pen-map (kbd "M-l M-I M-N") 'pen-nw)
(define-key pen-map (kbd "M-l M-I M-I") 'pen-sps)
(define-key pen-map (kbd "M-l M-I M-J") 'pen-spv)

(define-key pen-map (kbd "M-l E .") (df edit-pen-editing (find-file (f-join pen-src-dir "pen-editing.el"))))
(define-key pen-map (kbd "M-l E d") 'deselect-i)
(define-key pen-map (kbd "M-l E r") (df reselect-i (reselect-last-region)))
(define-key global-map (kbd "C-q") #'quoted-insert-nooctal)

;; These bindings need to be made when the mode loads
;; because yaml-ts-mode-map doesn't exist yet

(require 'yaml-mode)
(define-key yaml-mode-map (kbd "C-c e") 'yaml-get-value-from-this-file)

(require 'yaml-ts-mode)
(define-key yaml-ts-mode-map (kbd "C-c e") 'yaml-get-value-from-this-file)
;; (define-key yaml-ts-mode-map (kbd "C-c e") 'yaml-get-value-from-this-file)

(defun company-complete-quick-access-around-advice (proc &rest args)
  (let ((res (apply proc args)))
    (call-interactively 'company-try-hard)
    res))
(advice-add 'company-complete-quick-access :around #'company-complete-quick-access-around-advice)
;; (advice-remove 'company-complete-quick-access #'company-complete-quick-access-around-advice)

(defun company-mode-around-advice (proc &rest args)
  (define-key company-active-map (kbd "C-z") #'company-try-hard)
  (define-key company-active-map (kbd "C-f") #'company-complete-common)
  ;; (define-key company-active-map (kbd "C-h") #'delete-backward-char)
  (define-key company-active-map (kbd "C-h") 'company-delete-backward-char-and-retry)
  ;; (define-key company-active-map (kbd "C-h") 'delete-backward-char)
  (define-key company-active-map (kbd "C-c C-h") 'company-show-doc-buffer)
  (define-key company-active-map (kbd "M-c") 'company-copy-current)
  ;; (define-key company-active-map (kbd " ") 'self-insert-command)

  (define-key company-active-map (kbd " ") 'company-self-insert-and-retry)

  (let ((res (apply proc args)))
    res))
(advice-add 'company-mode :around #'company-mode-around-advice)
;; (advice-remove 'company-mode #'company-mode-around-advice)

(provide 'pen-post-bindings)
