(require 'subr+)

(defun window-string ()
  "This gets the string from window-start to window-end"
  (let* ((cb (current-buffer))
         (cw (get-buffer-window cb t)))
    (buffer-substring
     (window-start cw)
     (window-end cw))))

;; tmux avoidance scripts

(defun buffer-substring-of-visible (start end)
  "Return contents of visible part of buffer from START to END, as a string.
START and END can be in either order."
  (buffer-substring-of-unpropertied start end 'invisible))

(defun buffer-string-visible ()
  (let* ((cb (current-buffer))
         (cw (get-buffer-window cb t)))
    (buffer-substring-of-visible
     (window-start cw)
     (window-end cw))))
(defalias 'pen-screen-verbatim-text 'buffer-string-visible)

(defun buffer-string-visible-points ()
  (let* ((cb (current-buffer))
         (cw (get-buffer-window cb t)))
    (list (window-start cw)
          (window-end cw))))

;; emacs term and window functions (for avoiding tmux, say in the gui)

(defun pen-e-nw (&optional run)
  (interactive)
  (if run
      (call-interactively run)))
(defalias 'enw 'pen-e-nw)

(defun pen-e-sps (&optional run)
  (interactive)
  (split-window-sensibly)
  (other-window 1)
  (if run
      (call-interactively run)))
(defalias 'esps 'pen-e-sps)

(defun pen-e-spv (&optional run)
  (interactive)
  (split-window-horizontally)
  (other-window 1)
  (if run
      (call-interactively run)))
(defalias 'espv 'pen-e-spv)

(defun pen-e-sph (&optional run)
  (interactive)
  (split-window-vertically)
  (other-window 1)
  (if run
      (call-interactively run)))
(defalias 'esph 'pen-e-sph)

;; tmux scripts

(defun tm-cap-pane (&optional show-buffer)
  (interactive)
  (let ((cap (pen-sn "pen-tm cap-pane -nohist")))
    (if (or (interactive-p)
            show-buffer)
        (let ((frame (make-frame-command)
                     ;; termframe
                     ))
          (with-current-buffer (new-buffer-from-string cap)
            (defset-local termframe-local frame)
            (current-buffer)))
      cap)))

(defun pen-tmux-pane-capture (&optional show-buffer)
  (interactive)

  ;; Rather than toggle window margins, remove the window margin width from the start of each line
  (let* ((margin-width (or (car (window-margins))
                           0))
         (wincontents (pen-sn (concat "sed \"s/^.\\{" (str margin-width) "\\}//\"") (tm-cap-pane))))

    (if (or (interactive-p)
            show-buffer)
        (let ((frame (make-frame-command)
                     ;; termframe
                     ))
          (with-current-buffer (new-buffer-from-string wincontents)
            (defset-local termframe-local frame)
            (current-buffer)))
      wincontents)))
(defalias 'new-buffer-from-tmux-pane-capture 'pen-tmux-pane-capture)

(defun pen-tmuxify-cmd (cmd &optional dir window-name)
  (let ((slug (slugify cmd)))
    (setq window-name (or window-name slug))
    (setq dir (or dir (pen-pwd)))
    (concat "TMUX= tmux new -c " (pen-q dir) " -n " (pen-q window-name) " " (pen-q (concat "CWD= " cmd)))))

(defun pen-e-sph-zsh (&optional cmd dir)
  (interactive)
  (if (not dir)
      (setq dir (cwd)))
  (if (not cmd)
      (setq cmd (tmuxify-cmd "zsh"))
    ;; (setq cmd "TMUX= tmux new -n zsh \"CWD= zsh\"")
    )
  (pen-e-sph (pen-lm (pen-term-nsfa cmd nil "zsh" nil nil dir))))

;; (defalias 'sph-term 'pen-e-sph-zsh)
;; (defalias 'term-sph 'pen-e-sph-zsh)
;; (defalias 'tsph 'pen-e-sph-zsh)

(defun pen-e-spv-zsh (&optional cmd dir)
  (interactive)
  (if (not dir)
      (setq dir (cwd)))
  (if (not cmd)
      (setq cmd "TMUX= tmux new -n zsh \"CWD= zsh\""))
  (pen-e-spv (pen-lm (pen-term-nsfa cmd nil "zsh" nil nil dir))))

;; (defalias 'term-spv 'pen-e-spv-zsh)
;; (defalias 'tspv 'pen-e-spv-zsh)

(defun pen-e-sps-zsh (&optional cmd dir)
  (interactive)
  (if (not dir)
      (setq dir (cwd)))
  (if (not cmd)
      (progn
        ;; (setq cmd (concat "TMUX= tmux new -c " (pen-q dir) " -n zsh \"CWD= zsh\""))
        (setq cmd "zsh")
        (setq cmd (tmuxify-cmd cmd dir cmd))))
  ;; This resorts to =e=
  (if (>= (prefix-numeric-value current-prefix-arg) 8)
      (pen-e-sps (pen-lm (pen-term-nsfa cmd nil "zsh" nil nil dir)))
    (pen-sps cmd)))
(defalias 'term-sps 'pen-e-sps-zsh)
(defalias 'tsps 'pen-e-sps-zsh)

(defun pen-e-nw (&optional run)
  (interactive)
  (if run
      (call-interactively run)))

(defun pen-e-sps (&optional run)
  (interactive)
  (split-window-sensibly)
  (other-window 1)
  (if run
      (call-interactively run)))

(defun pen-e-spv (&optional run)
  (interactive)
  (split-window-horizontally)
  (other-window 1)
  (if run
      (call-interactively run)))

(defun pen-e-sph (&optional run)
  (interactive)
  (split-window-vertically)
  (other-window 1)
  (if run
      (call-interactively run)))

(defun pen-e-nw-zsh (&optional cmd window-type dir)
  (interactive)
  (if (not dir)
      (setq dir (cwd)))
  (if (not cmd)
      (progn
        ;; (setq cmd (concat "TMUX= tmux new -c " (pen-q dir) " -n zsh \"CWD= zsh\""))
        (setq cmd "zsh")
        (setq cmd (tmuxify-cmd cmd dir cmd))))
  (if (not (sor window-type))
      (setq window-type "nw"))
  (cond
   ((string-equal "nw" window-type) (pen-e-nw (pen-lm (pen-term-nsfa cmd nil "zsh" nil nil dir))))
   ((string-equal "sps" window-type) (pen-e-sps (pen-lm (pen-term-nsfa cmd nil "zsh" nil nil dir))))
   ((string-equal "spv" window-type) (pen-e-spv (pen-lm (pen-term-nsfa cmd nil "zsh" nil nil dir))))
   ((string-equal "sph" window-type) (pen-e-sph (pen-lm (pen-term-nsfa cmd nil "zsh" nil nil dir))))
   (t (pen-e-nw (pen-lm (pen-term-nsfa cmd nil "zsh" nil nil dir))))))

(defset pen-tm-extra-exports "PEN_PROMPTS_DIR PROMPTS PENEL_DIR PEN_ENGINES_DIR ENGINES PENSIEVE_DIR KHALA_DIR OPENAI_API_EL_DIR")

(defun pen-tm-nw (&optional cmd window-type nw_args input dir output_b)
  "Runs command in a new window/pane"
  (interactive)

  (let ((special-path (or dir (get-path nil t) "")))
    (if (and (string-match "/[^:]+:" special-path)
             ;; Don't want to match an org-link such as when using org-brain
             (not (string-match "\\[\\[" special-path)))
        (let ((cand-dir (tramp-localdir)))
          (if (and
               cand-dir
               (f-directory-p cand-dir))
              (setq dir cand-dir)
            (setq dir "/")))))

  (if (not dir)
      (setq dir (get-dir)))

  (if (not cmd)
      (setq cmd "zsh"))
  (if (not (sor window-type))
      (setq window-type "nw"))
  (if output_b
      (pen-sn (concat "pen-tm -export '" pen-tm-extra-exports "' -sout -S " window-type " " nw_args " " (pen-q cmd)
                      (if input
                          " | cat"
                        " &"))
              input dir)
    (if input
        (pen-sn (concat "pen-tm -export '" pen-tm-extra-exports "' -tout -S " window-type " " nw_args " " (pen-q cmd)) input dir)
      (if (display-graphic-p)
          ;; (pen-e-nw-zsh cmd window-type (xtv dir))
          (pen-e-nw-zsh (cmd "tmwr" "-E" cmd) window-type dir)
        (progn
          (if (and (variable-p 'pen-sh-update)
                   (eval 'pen-sh-update))
              (setq cmd (concat "upd " cmd)))
          (let ((cmd-tm-split (concat "unbuffer pen-tm -f -d -te " window-type " " nw_args " -c " (pen-q dir) " " (pen-q cmd) " &"))
                ;; The last cmd here must not be quoted
                (cmd-tm-here (concat "pen-tm ns -np -s -c " (pen-q dir) " " cmd)))
            (if (>= (prefix-numeric-value current-prefix-arg) 4)
                (pen-e-nw-zsh cmd-tm-here window-type)
              (pen-snc cmd-tm-split))))))))

(defun test-pen-tm-nw ()
  (interactive)
  (let ((current-prefix-arg '(4)))
    (pen-tm-nw (pen-cmd "pen-win" "ie" "$PEN/results/results_1667625716.9521382_05.11.22_91155942-917e-48d9-baad-bec94794036c/results_05.11.22__1667625720_91155942-917e-48d9-baad-bec94794036c_TeaH2/images/result-a-phantasmagoria-of-semiotic-art-depicting-a-surreal-and-surreptitious-strawberry-.png"))))

(defun tm-get-window ()
  (interactive)
  (let ((win (chomp (pen-sn "TMUX= tmux display-message -p '#{window_id}' 2>/dev/null"))))

    (if (interactive-p)
        (etv win)
      win)))

(defun tm-get-pane ()
  (let ((pane
         (chomp (pen-sn "TMUX= tmux display-message -p '#{pane_id}' 2>/dev/null"))))

    (if (interactive-p)
        (etv pane)
      pane)))

(defun pen-window (&optional wintype cmd nw_args input dir output_b)
  (interactive)
  (setq wintype (or wintype 'sps))
  (if (major-mode-p 'calibredb-search-mode)
      (setq dir (pen-cl-sn (concat "dirname " (pen-q (expand-file-name
                                                      (or (calibredb-getattr (car (calibredb-find-candidate-at-point)) :file-path) ""))) "") :chomp t)))
  (let* ((s_wintype (sym2str wintype))
         (fun (str2sym (concat "pen-e-" s_wintype))))
    (if (and
         (not output_b)
         (>= (prefix-numeric-value current-prefix-arg) 8))
        (funcall fun 'new-buffer-from-string)
      (pen-tm-nw cmd s_wintype nw_args input dir output_b))))

(defun pen-nw (&optional cmd nw_args input dir output_b)
  "Runs command in a sensible split"
  (interactive)
  (pen-window 'nw cmd nw_args input dir output_b))
(defalias 'nw 'pen-nw)

(defun pen-sps (&optional cmd nw_args input dir output_b)
  "Runs command in a sensible split"
  (interactive)
  (pen-window 'sps cmd nw_args input dir output_b))
(defalias 'pen-tm-sps 'pen-sps)

(defun pen-sph (&optional cmd nw_args input dir output_b)
  "Runs command in a horizontal split"
  (interactive)
  (pen-window 'sph cmd nw_args input dir output_b))
(defalias 'pen-tm-sph 'pen-sph)

(defun pen-spv (&optional cmd nw_args input dir output_b)
  "Runs command in a vertical split"
  (interactive)
  (pen-window 'spv cmd nw_args input dir output_b))
(defalias 'pen-tm-spv 'pen-spv)

(defun run-line-or-region-in-tmux ()
  "description string"
  (interactive)
  ;; let allows you to create local variables.
  ;; setq makes global variables
  (if (not (region-active-p))
      (pen-select-current-line))
  (let ((rstart (region-beginning))
        (rend (region-end)))
    (shell-command-on-region rstart rend "tm -tout -S nw -pakf -rsi"))
  (deselect))

;; TODO Make it so tmux-popup can return stdout
;; TODO Make it so tmux-popup can accept stdin
;; tmux-popup appears to be quite a lot like =tm sps=
;; I don't think there's enough overlap to be able to combine them.
;; I'll just have to reimplement some things
(defun tmux-popup (shcmd &optional width_pc height_pc x_pos y_pos hide_status_b stdin dir noborder output_b bg fg style)
  (interactive (list (read-string "popup shell command: ")))
  (let ((args (list "toggle-tmux-popup" "-E" shcmd)))
    (if width_pc
        (setq args (append args (list "-w" (concat (str width_pc))))))
    (if height_pc
        (setq args (append args (list "-h" (concat (str height_pc))))))

    ;; examples
    ;; M, M+1, M-1, M+10
    (if x_pos
        (setq args (append args (list "-x" (str x_pos)))))

    ;; examples
    ;; M, M+1, M-1, M+10
    (if y_pos
        (setq args (append args (list "-y" (str y_pos)))))

    (if hide_status_b
        (setq args (append args (list "-nos"))))

    (if noborder
        (setq args (append args (list "-nob"))))

    (setq style ;; (or style "rounded")
          (or style "heavy"))

    (if style
        (setq args (append args (list "-b" (str style)))))

    (if bg
        (setq args (append args (list "-bg" (str bg)))))

    (if fg
        (setq args (append args (list "-bg" (str bg)))))

    (let ((c (eval `(cmd ,@args))))
      (if output_b
          (setq c (concat c "| cat")))
      (pen-sn c stdin dir nil (not output_b)))))

(defun tm-cursor-pos-client ()
  (mapcar 'string-to-number (s-split "," (pen-snc "tm-get-client-pos -tp"))))

(defun tmux-cursor-x (&optional echo)
  (tryelse
   (let ((y
          (car (tm-cursor-pos-client))))
     (if echo
         (message (str y)))
     y)
   (error "Can't get column from tmux")))

(defun tmux-cursor-y (&optional echo)
  (tryelse
   (let ((y
          (car (cdr (tm-cursor-pos-client)))))
     (if echo
         (message (str y)))
     y)
   (error "Can't get row from tmux")))

(comment
 (run-with-timer
  2 nil
  (λ ()
    (tmux-popup "cmatrix" 50 50 (tmux-cursor-x) (tmux-cursor-y))
    (comment
     (etv (tmux-cursor-y))
     (tmux-popup "cmatrix" 50 50 (tmux-cursor-x) (tmux-cursor-y))
     ;; (tmux-popup "cmatrix" 50 50 83 3)
     ))))

(defun popup-snc (shell-cmd &optional stdin dir output_b hide_status_b)
  (tmux-popup shell-cmd
              "50%" "50%"
              "M+1"
              "M+1"
              hide_status_b stdin dir nil output_b))
(defalias 'ppup 'popup-snc)

(defun pvipe (listd &optional fuzzy-cmd dir tall)
  (setq fuzzy-cmd (or fuzzy-cmd "vvipe"))

  (if (eq (type-of listd) 'symbol)
      (cond
       ((variable-p 'clojure-mode-funcs) (setq listd (eval listd)))
       ((fboundp 'clojure-mode-funcs) (setq listd (funcall listd)))))

  ;; (if (stringp listd)
  ;;     (setq listd (split-string (chomp listd) "\n")))

  (if (listp listd)
      (setq listd (list2str)))

  (tmux-popup fuzzy-cmd
              (if tall "40%" "90%")
              "50%"
              "M+1"
              "M+1"
              nil listd dir nil t))

(defun vvipe (stdin)
  (tvipe stdin))

(defun pfz (listd &optional dir)
  (pvipe listd "mfz -nv" dir t))

(defun ledit ()
  (interactive)
  (tmux-popup "vvipe -e v" "90%" 1 "M" "M" t (thing-at-point 'line) nil t t))

(comment
 (tmux-popup "cmatrix")
 (tmux-popup "cmatrix" "90%" 10 nil nil t)

 (let* ((pos (tm-cursor-pos-client))
        (x (car pos))
        (y (car (cdr pos))))
   (tmux-popup "cmatrix" "30%" 10 x y))

 (tmux-popup "vvipe" nil nil nil nil nil (thing-at-point 'sexp))

 ;; This edits a sexp in vim - looks like an embedded vim
 (ledit)

 (tmux-popup (cmd "cmatrix" "-absu" "3" "-C" "blue")
             30 20
             (tmux-cursor-x)
             (tmux-cursor-y t)
             t)

 (tmux-popup (cmd "cmatrix" "-absu" "3" "-C" "magenta")
             "50%" "50%"
             (tmux-cursor-x)
             (tmux-cursor-y))

 (let* ((pos (tm-cursor-pos-client))
        (x (car pos))
        (y (+ 1 (car (cdr pos)))))
   (tmux-popup (cmd "asciimation" "-2") "60%" "60%" x y))

 (tmux-popup (cmd "asciimation") "60%" "60%" "M" "M+1")

 (tmux-popup "list-bible-books | mfz -nv"
             "50%" "50%"
             (tmux-cursor-x t)
             (tmux-cursor-y))

 (tmux-popup "list-bible-books | mfz -nv"
             "50%" "50%"
             "M+1"
             "M+1")

 (tv (ppup "list-bible-books | mfz -nv" nil nil t))
 (tmux-popup "etetris-vt100" 33 26 "M" "M" t nil nil t)
 (tmux-popup "etetris-vt100" 33 26 "C" "C" t nil nil)
 (tpop "etetris-vt100" nil :width_pc 33 :height_pc 26 :x_pos "C" :y_pos "C" :show_status_b t)
 (tpop "etetris-vt100" nil :width_pc 33 :height_pc 26 :x_pos "C" :y_pos "C" :show_status_b nil :bg 100 :fg 200)
 (tpop "cmatrix" nil :width_pc 33 :height_pc 26 :x_pos "C" :y_pos "C" :show_status_b nil :bg 100 :fg 200)
 (tv (pvipe (snc "list-bible-books")))
 (bible-open nil nil "NASB" (pfz (snc "list-bible-books")))
 (follow-bible-link (pfz (snc "list-bible-books"))))

(cl-defun cl-tmux-popup (shcmd
                         &optional stdin
                         &key width_pc
                         &key height_pc
                         &key x_pos
                         &key y_pos
                         &key hide_status_b
                         &key dir
                         &key noborder
                         &key output_b
                         &key bg
                         &key fg
                         &key style)
  (tmux-popup shcmd width_pc height_pc x_pos y_pos hide_status_b stdin dir noborder output_b bg fg style))

(cl-defun tpop (shcmd
                &optional stdin
                &key width_pc
                &key height_pc
                &key x_pos
                &key y_pos
                &key show_status_b
                &key dir
                &key noborder
                &key output_b
                &key bg
                &key fg
                &key style)
  "Behaviour is a little different from cl-tmux-popup, as the status bar is hidden by default

  ;; STYLE
  ;; rounded
  ;;         variation of single with rounded corners using UTF-8
  ;;         characters
  ;; double  double lines using UTF-8 characters
  ;; heavy   heavy lines using UTF-8 characters
  ;; simple  simple ASCII characters
  ;; padded  simple ASCII space character
  ;; none    no border
  "

  (if (display-graphic-p)
      (xt shcmd)
    ;; (pen-eterm (pen-nsfa shcmd)
    ;;          ;; stdin dir noborder output_b
    ;;              )
    (tmux-popup shcmd width_pc height_pc x_pos y_pos (not show_status_b) stdin dir noborder output_b bg fg style)))

;; (defalias 'tpop 'cl-tmux-popup)

(comment
 (tpop "v" :stdin "hello"))

(defun vwrap (input)
  (tpop "vwrap" input))

(defun sttr (input)
  (snc "sttr" input)
  :tm_wincmd "nw")

(provide 'pen-tmux)
