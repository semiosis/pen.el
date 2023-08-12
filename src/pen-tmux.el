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
          (if (f-directory-p cand-dir)
              (setq dir cand-dir)
            (setq dir "/")))))

  (if (not dir)
      (setq dir (get-dir)))

  (if (not cmd)
      (setq cmd "zsh"))
  (if (not (sor window-type))
      (setq window-type "nw"))
  (if output_b
      (if input
          (pen-sn (concat "pen-tm -export '" pen-tm-extra-exports "' -sout -S " window-type " " nw_args " " (pen-q cmd) " | cat") input dir)
        (pen-sn (concat "pen-tm -export '" pen-tm-extra-exports "' -sout -S " window-type " " nw_args " " (pen-q cmd) " &") input dir))
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

(defun pen-nw (&optional cmd nw_args input dir output_b)
  "Runs command in a sensible split"
  (interactive)
  (if (and
       (not output_b)
       (>= (prefix-numeric-value current-prefix-arg) 8))
      (pen-e-nw 'new-buffer-from-string)
    (pen-tm-nw cmd "nw" nw_args input dir output_b)))
(defalias 'nw 'pen-nw)

(defun pen-sps (&optional cmd nw_args input dir output_b)
  "Runs command in a sensible split"
  (interactive)
  (if (and
       (not output_b)
       (>= (prefix-numeric-value current-prefix-arg) 8))
      (pen-e-sps 'new-buffer-from-string)
    (pen-tm-nw cmd "sps" nw_args input dir)))
(defalias 'pen-tm-sps 'pen-sps)

(defun pen-sph (&optional cmd nw_args input dir output_b)
  "Runs command in a horizontal split"
  (interactive)
  (if (and
       (not output_b)
       (>= (prefix-numeric-value current-prefix-arg) 8))
      (pen-e-sph 'new-buffer-from-string)
    (pen-tm-nw cmd "sph" nw_args input dir)))
(defalias 'pen-tm-sph 'pen-sph)

(defun pen-spv (&optional cmd nw_args input dir output_b)
  "Runs command in a vertical split"
  (interactive)
  (if (and
       (not output_b)
       (>= (prefix-numeric-value current-prefix-arg) 8))
      (pen-e-spv 'new-buffer-from-string)
    (pen-tm-nw cmd "spv" nw_args input dir)))
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

(provide 'pen-tmux)
