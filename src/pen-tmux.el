(require 'subr+)

;; tmux avoidance scripts

(defun buffer-substring-of-visible (start end)
  "Return contents of visible part of buffer from START to END, as a string.
START and END can be in either order."
  (buffer-substring-of-unpropertied start end 'invisible))

(defun buffer-string-visible ()
  (buffer-substring-of-visible
   (window-start)
   (window-end)))

;; emacs term and window functions (for avoiding tmux, say in the gui)

(defun e/nw (&optional run)
  (interactive)
  (if run
      (call-interactively run)))
(defalias 'enw 'e/nw)

(defun e/sps (&optional run)
  (interactive)
  (split-window-sensibly)
  (other-window 1)
  (if run
      (call-interactively run)))
(defalias 'esps 'e/sps)

(defun e/spv (&optional run)
  (interactive)
  (split-window-horizontally)
  (other-window 1)
  (if run
      (call-interactively run)))
(defalias 'espv 'e/spv)

(defun e/sph (&optional run)
  (interactive)
  (split-window-vertically)
  (other-window 1)
  (if run
      (call-interactively run)))
(defalias 'esph 'e/sph)

;; tmux scripts

(defun pen-tmux-pane-capture (&optional show-buffer)
  (interactive)

  ;; Rather than toggle window margins, remove the window margin width from the start of each line
  (let* ((margin-width (or (car (window-margins))
                           0))
         (wincontents (pen-sn (concat "pen-tm cap-pane -nohist | sed \"s/^.\\{" (str margin-width) "\\}//\""))))

    (if (or (interactive-p)
            show-buffer)
        (let ((frame (make-frame-command)
                     ;; termframe
                     ))
          (with-current-buffer (new-buffer-from-string wincontents)
            (defset-local termframe-local frame)
            (current-buffer)))
      wincontents)))

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
  (e/sph (pen-lm (pen-term-nsfa cmd nil "zsh" nil nil dir))))

;; (defalias 'sph-term 'pen-e-sph-zsh)
;; (defalias 'term-sph 'pen-e-sph-zsh)
;; (defalias 'tsph 'pen-e-sph-zsh)

(defun pen-e-spv-zsh (&optional cmd dir)
  (interactive)
  (if (not dir)
      (setq dir (cwd)))
  (if (not cmd)
      (setq cmd "TMUX= tmux new -n zsh \"CWD= zsh\""))
  (e/spv (pen-lm (pen-term-nsfa cmd nil "zsh" nil nil dir))))

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
  (pen-e-sps (pen-lm (pen-term-nsfa cmd nil "zsh" nil nil dir))))
(defalias 'term-sps 'pen-e-sps-zsh)
(defalias 'tsps 'pen-e-sps-zsh)

(defun pen-tm-nw (&optional cmd window-type nw_args input dir)
  "Runs command in a new window/pane"
  (interactive)
  (if (not cmd)
      (setq cmd "zsh"))
  (if (not (sor window-type))
      (setq window-type "nw"))
  (if input
      (pen-sn (concat "pen-tm -tout -S " window-type " " nw_args " " (pen-q cmd) " &") input (or dir (get-dir)))
    (if (display-graphic-p)
        (pen-e-sps-zsh cmd)
      (progn
        (if (and (variable-p 'sh-update)
                 (eval 'sh-update))
            (setq cmd (concat "upd " cmd)))
        (let ((cmd-tm-split (concat "unbuffer pen-tm -f -d -te " window-type " " nw_args " -c " (pen-q (or dir (get-dir))) " " (pen-q cmd) " &"))
              (cmd-tm-here (concat "pen-tm ns -np -s -c " (pen-q (or dir (get-dir))) " " (pen-q cmd))))
          (if (>= (prefix-numeric-value current-prefix-arg) 4)
              (pen-e-sps-zsh cmd-tm-here)
            (pen-snc cmd-tm-split)))))))

(defun pen-nw (&optional cmd nw_args input dir)
  "Runs command in a sensible split"
  (interactive)
  (pen-tm-nw cmd "nw" nw_args input dir))

(defun pen-sps (&optional cmd nw_args input dir)
  "Runs command in a sensible split"
  (interactive)
  (pen-tm-nw cmd "sps" nw_args input dir))
(defalias 'pen-tm-sps 'pen-sps)

(defun pen-sph (&optional cmd nw_args input dir)
  "Runs command in a horizontal split"
  (interactive)
  (pen-tm-nw cmd "sph" nw_args input dir))
(defalias 'pen-tm-sph 'pen-sph)

(defun pen-spv (&optional cmd nw_args input dir)
  "Runs command in a vertical split"
  (interactive)
  (pen-tm-nw cmd "spv" nw_args input dir))
(defalias 'pen-tm-spv 'pen-spv)

(provide 'pen-tmux)