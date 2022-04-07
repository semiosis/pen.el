(setq vc-follow-symlinks t)

(defun git-get-top-fast ()
  (locate-dominating-file default-directory ".git"))

(defun sh/git-get-commit-message ()
  (chomp (pen-sn "git get-commit-message")))

(defun sh/git-amend-all-below ()
  "Show git amend in tmux."
  (interactive)
  (let ((mess (sh/git-get-commit-message)))
    (save-buffer)
    (pen-sn (concat "git add -A .; git amend"))
    (revert-buffer nil t)
    (message (concat "Amended -A . with original message " (pen-q mess)))))

(defun sh/git-add-all-below ()
  (interactive)
  (let ((mess (chomp (vime "strftime(\"%c\")"))))
    (if (buffer-file-name)
        (save-buffer))
    (pen-sn (concat "git add -A .; git commit -m " (pen-q mess)))
    (save-excursion
      (if (buffer-file-name)
          (save-buffer)))
    (message (concat "Committed -A . with message " (pen-q mess)))))

(defun sh/git-get-url ()
  (pen-sn "git config --get remote.origin.url"))

(use-package gitattributes-mode :defer t)

(defun gitattributes-whitespace-apply-around-advice (proc &rest args)
  (let ((res (ignore-errors (apply proc args))))
    res))
(advice-add 'gitattributes-whitespace-apply :around #'gitattributes-whitespace-apply-around-advice)

(use-package gitconfig-mode :defer t)
(use-package gitignore-mode :defer t)

(use-package github-pullrequest)

(defun git-d-unstaged (&optional path)
  (interactive)
  (if (not path)
      (setq path (get-path)))
  (pen-sph (concat "git d " (pen-q path))))

(defalias 'get-top-level 'projectile-project-root)

(defun pen-cd (dir)
  (cond
   ((derived-mode-p 'ranger-mode) (ranger dir))
   ((derived-mode-p 'dired-mode) (dired dir))
   (t (cd dir)))
  (message (pen-mnm (concat "cd " (pen-q dir)))))

(defun pen-vc-cd-top-level ()
  (interactive)
  (pen-cd (get-top-level)))

(defun cd-vc-cd-top-level ()
  (interactive)
  (dired (get-top-level)))

(define-key global-map (kbd "C-\\") nil)
(define-key global-map (kbd "C-\\ '") 'git-d-unstaged)
(define-key global-map (kbd "M-^") 'cd-vc-cd-top-level)

(provide 'pen-git)