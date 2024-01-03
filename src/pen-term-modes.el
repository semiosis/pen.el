(defset pen-term-modes-commands '(tmux
                                 asciimation
                                 ncdu br
                                 octotui
                                 gpg-tui
                                 tig
                                 github-stats
                                 gq vim
                                 rubiks_cube k9s
                                 chkservice lazydocker
                                 rat irssi
                                 nano mc
                                 weechat sen
                                 zsh dive
                                 tpb df-bay12)
  "A list of commands to create term minor modes for")

(defun make-etui-cmd (pen-cmd closeframe)
  "This function expects a one term command (binary name only) and it returns a new interactive function."
  (let ((funname (concat "esh-" cmd)))
    (eval `(defun ,(intern funname) (&rest args)
             "This function expects a one term command (binary name only)."
             (interactive)
             (pen-term-nsfa (mapconcat 'pen-q (cons ,cmd args) " ") nil ,cmd ,closeframe)))))

(defmacro defcmdmode (pen-cmd &optional cmdtype)
  (setq cmd (str cmd))
  (setq cmdtype (or cmdtype "term"))
  (let* ((cmdslug (slugify (str cmd)))
         (modestr (concat cmdslug "-" cmdtype "-mode"))
         (modesym (intern modestr))
         (mapsym (intern (concat modestr "-map"))))
    `(progn
       (defvar ,mapsym (make-sparse-keymap)
         ,(concat "Keymap for `" modestr "'."))
       (defvar-local ,modesym nil)

       (define-minor-mode ,modesym
         ,(concat "A minor mode for the '" cmd "' " cmdtype " command.")
         :global nil
         :init-value nil
         :lighter ,(s-upcase cmdslug)
         :keymap ,mapsym)
       (provide ',modesym))))

(defun make-or-run-etui-cmd (pen-cmd &rest args)
  (interactive (list (read-string "Command name:")))
  (let* ((funname (concat "esh-" cmd))
         (fnsym
          (make-etui-cmd cmd t)))
    (eval `(defcmdmode ,cmd))
    (eval `(,fnsym ,@args))))

(defalias 'midnight-commander-term-mode 'mc-term-mode)

(defset pen-term-modes
  (cl-loop for cmd in pen-term-modes-commands collect (eval `(defcmdmode ,cmd))))

(defalias 'v-term-mode 'vim-term-mode)
(defalias 'vs-term-mode 'vim-term-mode)

(defun zsh-copy-previous-line ()
  (interactive)
  (xc (pen-sn "tail -n 2 | head -n 1" (buffer-string))))

(define-key zsh-term-mode-map (kbd "C-c M-1") 'zsh-copy-previous-line)

(define-key sen-term-mode-map (kbd "M-<") (pen-lm (ekm "<home>")))
(define-key sen-term-mode-map (kbd "M->") (pen-lm (ekm "<end>")))
(define-key dive-term-mode-map (kbd "q") (pen-lm (ekm "C-c C-c")
                                          ;; (tsk "C-c")
                                             ))
(define-key dive-term-mode-map (kbd "h") (pen-lm (ekm "C-i")))
(define-key dive-term-mode-map (kbd "l") (pen-lm (ekm "C-i")))
(define-key dive-term-mode-map (kbd "j") (pen-lm (ekm "<down>")))
(define-key dive-term-mode-map (kbd "k") (pen-lm (ekm "<up>")))

;; This is definitely a bad solution
(define-key mc-term-mode-map (kbd "<up>") (pen-lm (tsk "C-p")))
(define-key mc-term-mode-map (kbd "<down>") (pen-lm (tsk "C-n")))
(define-key mc-term-mode-map (kbd "M-n") (pen-lm (term-send-raw-meta) (message "This worked but did you mean <down>?")))
(define-key mc-term-mode-map (kbd "M-p") (pen-lm (term-send-raw-meta) (message "This worked but did you mean <up>?")))
;; (define-key mc-term-mode-map (kbd "<right>") (pen-lm (tsk "M-3")))
(define-key mc-term-mode-map (kbd "<left>") (pen-lm (tsk "PgUp")))
(define-key mc-term-mode-map (kbd "<right>") (pen-lm (tsk "PgDn")))

(define-key df-bay12-term-mode-map (kbd "M-!") (pen-lm (tsk "Bob")))

;; M-F1
(define-key vim-term-mode-map (kbd "<M-f1>") (pen-lm (ekm "ZQ")))
;; M-F2
(define-key vim-term-mode-map (kbd "<M-f4>") (pen-lm (ekm "ZQ")))

;; (define-key rat-term-mode-map (kbd "<down>") (pen-lm (ekm "j")))
(define-key rat-term-mode-map (kbd "<down>") (kbd "j"))
(define-key rat-term-mode-map (kbd "<up>") (kbd "k"))

(define-key rat-term-mode-map (kbd "C-n") (pen-lm (ekm "j j j j j")))
(define-key rat-term-mode-map (kbd "C-p") (pen-lm (ekm "k k k k k")))

(define-key rat-term-mode-map (kbd "<next>") (pen-lm (ekm "C-f")))
(define-key rat-term-mode-map (kbd "<prior>") (pen-lm (ekm "C-b")))

(define-key rat-term-mode-map (kbd "M-<") (pen-lm (ekm "g g")))
(define-key rat-term-mode-map (kbd "M->") (pen-lm (ekm "G")))

(define-key asciimation-term-mode-map (kbd "q") (lm
                                                 (let ((asciimation-term-mode nil))
                                                   (ekm "C-\\ C-n : q C-m"))))

(defun df-test ()
    (interactive)
  (pen-sh
   (concat "pen-x -tma \"" (tm-get-window) "\""
           " -s \"222\""
           " -c m"
           " -sl 0.5"
           ;; " -e raw"
           " -c m")))

(defun df-browse ()
    (interactive)
  (pen-sh
   (concat "pen-x -tma \"" (tm-get-window) "\""
           " -s 2"
           " -sl 0.5"
           " -s 222"
           " -c m"
           " -sl 1"
           " -c m")))

(defun df-create-world ()
    (interactive)
  (pen-sh
   (concat "pen-x -tma \"" (tm-get-window) "\""
           " -se 222"
           " -sl 0.2"
           " -s 8"
           " -c m"
           " -e \"to continue\""
           " -sl 1"
           " -s \"\\\\\""
           " -e \"Enter title\""
           " -se t"
           " -s Shane"
           " -c m")))

(define-key df-bay12-term-mode-map (kbd "M-@") #'df-test)
(define-key df-bay12-term-mode-map (kbd "M-#") #'df-browse)
(define-key df-bay12-term-mode-map (kbd "M-$") #'df-create-world)

(defun tpb-enable-syntax-highlighting ()
  (interactive)
  (set (make-local-variable 'tpb-term-font-lock-keywords)
       '(
         ("\\(J\\|T\\)" 0 font-lock-string-face keep t)
         ("\\(720\\|1080\\|2019\\)" . font-lock-function-name-face)
         ("\\(Magnet\\|S[0-9]+E[0-9]+\\)" . font-lock-constant-face)))
  ;; (font-lock-add-keywords nil tpb-term-font-lock-keywords 3)

  (if (fboundp 'font-lock-flush)
      (font-lock-flush)
    (when font-lock-mode
      (with-no-warnings (font-lock-fontify-buffer)))))

;; In theory this should work
;; But these highlights can't override existing highlights
;; Therefore, I must find a way to disable term-mode's font-lock
(defun init-tpb-term-mode ()
  (interactive))

(add-hook 'tpb-term-mode-hook #'init-tpb-term-mode)

(defun tpb-next-magnet ()
  (interactive)
  (if (looking-at-p "Magnet")
      (ekm "C-f"))
  (ekm "C-s Magnet C-m")
  ;; The sleep is needed because the program updates asynchronously
  (sleep-for-for-for 0 200)
  (if (looking-at-p "agnet")
      (ekm "C-b"))
  (hl-line-mode -1)
  (hl-line-mode 1))

(defun tpb-prev-magnet ()
  (interactive)
  (ekm "C-r Magnet C-m")
  (sleep-for-for-for 0 200)
  (hl-line-mode -1)
  (hl-line-mode 1))

(define-key tpb-term-mode-map (kbd "M-n") #'tpb-next-magnet)
(define-key tpb-term-mode-map (kbd "M-p") #'tpb-prev-magnet)

(defun tmux-copy-pane-initial-command ()
  (interactive)
  (chomp (pen-sh "pen-tm copy-pane-command | cat" nil t)))

(defun tmux-copy-pane-initial-command-full ()
  (interactive)
  (chomp (pen-sh "tm-copy-pane-cmd | cat" nil t)))

(defun tmux-copy-pane-current-command-full ()
  "Copy the current command and the working directory"
  (interactive)
  (chomp (pen-sh "tm-copy-pane-cmd | cat" nil t)))

(defun string2kbm (s)
  (interactive (list (read-string "literal:")))
  (switch-to-buffer "*scratch*")
  (with-current-buffer "*scratch*"
    (call-interactively 'kmacro-start-macro)
    (tsl s)
    (sleep-for-for-for 1)
    (call-interactively 'kmacro-end-macro))

  (last-kbd-macro-string))

(defun e/chomp-all (str)
  "Chomp leading and tailing whitespace from STR for each line."
  (while (string-match "\\`\n+\\|^\\s-+\\|\\s-+$\\|\n+\\'"
                       str)
    (setq str (replace-match "" t t str)))
  str)

(defun e/chomp (str)
  "Chomp (remove tailing newline from) STR."
  (replace-regexp-in-string "\n\\'" "" str))

(defun type-keys (s)
  "Type out the string"
  (interactive (list (read-string "string:")))
  (ekm (make-kbd-from-string s)))
(defalias 'ekl 'type-keys)

(defun make-kbd-from-string (s)
  (let ((quoted-string (let ((print-escape-newlines t))
                         (prin1-to-string s))))
    (chomp (eval `(ci (pen-sh (concat "pen-ci emacs-string2kbm " (pen-q ,s)) nil t))))))

(defun make-kbd-from-string-nodeps (s)
  (let ((quoted-string (let ((print-escape-newlines t))
                         (prin1-to-string s)))
        (tf (make-temp-file "emacskbm" nil ".exp")))

    (ignore-errors (with-temp-buffer
                     (insert (concat
                              "outfile=/tmp/emacskbm.txt\n"
                              "rm -f \"$outfile\"\n"
                              "\n"
                              "cat > /tmp/emacskbm.exp <<HEREDOC\n"
                              "if { \\$argc >= 1 } {\n"
                              "    set literal [lindex \\$argv 0]\n"
                              "}\n"
                              "\n"
                              "spawn sh\n"
                              "send -- \"emacs -Q -nw\"\n"
                              "send -- \\015\n"
                              "expect -exact \"scratch\"\n"
                              "send -- \\030\n"
                              "send -- \"(\"\n"
                              "send -- \"\\$literal\"\n"
                              "send -- \\030\n"
                              "send -- \")\"\n"
                              "send -- \\033:\n"
                              "send -- \"(with-temp-buffer (insert (replace-regexp-in-string \\\"^Last macro: \\\" \\\"\\\" (kmacro-view-macro))) (write-file \\\"$outfile\\\"))\"\n"
                              "send -- \\015\n"
                              "send -- \\033:\n"
                              "send -- \"(kill-emacs)\"\n"
                              "send -- \\015\n"
                              "send -- \\004\n"
                              "interact\n"
                              "HEREDOC\n"
                              "\n"
                              "{\n"
                              "expect -f /tmp/emacskbm.exp \"$@\"\n"
                              "} &>/dev/null\n"
                              "tmux wait-for -S emacskbm\n"))
                     (write-file tf)))

    (pen-shell-command (concat "tmux neww -t localhost_current: -d bash " pen-tf " " quoted-string "; tmux wait-for emacskbm"))
    (chomp (with-temp-buffer
               (insert-file-contents "/tmp/emacskbm.txt")
               (buffer-string)))))

(defun irssi-search-chans (pattern)
  (interactive (list (read-string "pattern:")))
  ;; The 7th window is probably a freenode window
  (pen-snc "pen-tm sel localhost_im:irssi")
  (ekm "M-7")
  (ekm "C-a C-k")
  ;; (insert "/msg alis LIST * -topic github")
  (ekm (edmacro-format-keys (concat "/msg alis LIST * -topic " pattern)))
  (ekm "C-m")
  (ekm (edmacro-format-keys "/query alis"))
  (ekm "C-m"))

(define-key irssi-term-mode-map (kbd "M-/") #'irssi-search-chans)

(define-key br-term-mode-map (kbd "C-h") (pen-lm (ekm "DEL")))

(defun term-get-url-at-point ()
  (interactive)
  (xc (pen-sh/xurls (term-get-line-at-point)) t))

(define-key nano-term-mode-map (kbd "M-u") #'term-get-url-at-point)

(defun rubiks-randomize ()
  (interactive)
  (pen-sh
   (concat "pen-x -tma " (pen-q (tm-get-window))
           " -s m"
           " -sl 0.5"
           " -e Resume"
           ;; " -s \"<down>\""
           " -down"
           " -c m"
           " -e Enter"
           " -s " (pen-q (random 50))
           " -c m")))

;; Don't use vim nav, use ijkl
(define-key rubiks-cube-term-mode-map (kbd "w") (pen-lm (ekm (s-join " " (-repeat 8 "<up>")))))
(define-key rubiks-cube-term-mode-map (kbd "s") (pen-lm (ekm (s-join " " (-repeat 8 "<down>")))))
(define-key rubiks-cube-term-mode-map (kbd "a") (pen-lm (ekm (s-join " " (-repeat 8 "<left>")))))
(define-key rubiks-cube-term-mode-map (kbd "d") (pen-lm (ekm (s-join " " (-repeat 8 "<right>")))))

(defun tsrs (st)
  (let* ((lambda (s-split "" st t))
         (interactive 0)
         (grep (length l)))
    (cl-loop for pen-str in l
             do
             (setq pen-i (+ 1 i))
             (if (not (equal 1 i))
                 (sleep-for-for-for 0.5))
             (term-send-raw-string s))))

(defun rubiks-left-trigger ()
  (interactive)
  (tsrs "ruR"))

(defun rubiks-right-trigger ()
  (interactive)
  (tsrs "LUl"))

(defun spinz ()
  (interactive)
  (term-send-raw-string "z"))

(defun spinz-inv ()
  (interactive)
  (term-send-raw-string "Z"))

(define-key rubiks-cube-term-mode-map (kbd "q") 'rubiks-left-trigger)
(define-key rubiks-cube-term-mode-map (kbd "e") 'rubiks-right-trigger)
(define-key rubiks-cube-term-mode-map (kbd "z") 'rubiks-randomize)
(define-key rubiks-cube-term-mode-map (kbd "pen-x") 'spinz)
(define-key rubiks-cube-term-mode-map (kbd "X") 'spinz-inv)

(provide 'pen-term-modes)
