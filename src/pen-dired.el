(require 'ranger)
(require 'dired-git-info)

(setq dgi-auto-hide-details-p nil)
(setq dired-listing-switches "-alh")

;; Use steve purcell's dired pretty mode
(use-package dired
  :hook (dired-mode . dired-hide-details-mode)
  :config
  ;; Colourful columns.
  (use-package diredfl
    :ensure t
    :config
    (diredfl-global-mode 1)))

(use-package dired-git-info
  :ensure t
  :bind (:map dired-mode-map
              (")" . dired-git-info-mode)))

(add-hook 'dired-mode-hook (df enable-dired-hide-details () (dired-hide-details-mode 1)))

(setq wdired-allow-to-change-permissions t)
(setq dired-dwim-target t)

(use-package dired-narrow
  :ensure t
  :config
  (bind-key "C-c C-n" #'dired-narrow)
  (bind-key "C-c C-f" #'dired-narrow-fuzzy)
  (bind-key "C-x C-N" #'dired-narrow-regexp))

(use-package dired-subtree :ensure t
  :after dired
  :config
  (bind-key "<tab>" #'dired-subtree-toggle dired-mode-map)
  (bind-key "<backtab>" #'dired-subtree-cycle dired-mode-map))

;; Faster dired operations
(require 'async)
(require 'dired-async)
(dired-async-mode 1)

(defun dired-sort-dirs-first ()
  (interactive)
  (dired-sort-other "-alXGh --group-directories-first"))

(require 'dired)
(setq insert-directory-program "pen-dired-ls")

(defun dired-top ()
  (interactive)
  (dired (projectile-acquire-root) "-alXGh --group-directories-first"))

(defun dired-cmd (pen-cmd dirname &optional switches)
  (interactive (cons (read-string "cmd:") (dired-read-dir-and-switches "")))
  (ignore-errors (kill-buffer dirname))
  (let ((insert-directory-program cmd))
    (dired dirname switches)))

(defun ev (&optional path)
  (interactive)
  (term-nsfa (concat "v " (pen-q path))))

(defun evim (&optional path)
  (interactive)
  (term-nsfa (concat "vim " (pen-q path))))

(defun evs (&optional path)
  (interactive)
  (term-nsfa (concat "vs " (pen-q path))))

(defun dired-all-info (path &optional switches)
  (if (not switches)
      (setq switches "-I -g -alR -XGh --group-directories-first"))
  (dired path switches)
  (dired-git-info-mode 1)
  (dired-hide-details-mode 0))

(defun dired-view-file-scope ()
  (interactive)
  (let ((file (dired-get-file-for-visit)))
    (if (f-directory-p file)
        (dired-all-info file)
      (let ((output (pen-sn (concat "scope.sh " (pen-q file)))))
        (if (not (string-empty-p output))
            (new-buffer-from-string output)
          (error "No preview data"))))))

(defun dired-view-file-v (&optional arg)
  (interactive "P")
  (let ((file (dired-get-file-for-visit)))
    (if (or arg (string-equal (current-major-mode) "ranger-mode"))
        (pen-sps (concat "v " (pen-q file)))
      (ev file))))

(defun dired-view-file-vs (&optional arg)
  (interactive "P")
  (let ((file (dired-get-file-for-visit)))
    (if (or arg (string-equal (current-major-mode) "ranger-mode"))
        (pen-sps (concat "vs " (pen-q file)))
      (evs file))))

(defalias 'dired-filter 'dired-narrow)

(defun my-ranger ()
  (interactive)
  (if (>= (prefix-numeric-value current-prefix-arg) 4)
      (call-interactively 'sps-ranger)
    (call-interactively 'ranger)))

(defun dired-open-externally-with-rifle (&optional arg)
  (interactive "P")
  (let ((file (dired-get-file-for-visit)))
    (pen-sps (concat "r " (pen-q file)))))

(defun find-here-symlink (substring)
  (interactive (list (read-string "symlink substring: ")))
  (let* ((query (concat "*" substring "*"))
         (result (pen-sn (concat "tp find-here-symlink " (pen-q query)) nil (my/pwd))))
    (if (not (string-empty-p result))
        (with-current-buffer (nbfs result)))))

(require 'image-dired)
(require 'image-dired+)
(eval-after-load 'image-dired '(require 'image-dired+))
(eval-after-load 'image-dired+ '(image-diredx-async-mode 1))
(eval-after-load 'image-dired+ '(image-diredx-adjust-mode 1))

(setq image-dired-track-movement nil)

(defun dired-eranger-up ()
  (interactive)
  (ranger (f-dirname (get-path))))

(defun dired-guess-repl-for-here ()
  (interactive)
  (let ((f
         (cond
          ((f-exists-p "project.clj") 'cider-switch-to-repl-buffer))))
    (if f
        (call-interactively f)
      (message "could infer repl"))))

(define-key dired-mode-map (kbd "M-v") 'dired-view-file-v)
(define-key dired-mode-map (kbd "M-1") 'dired-view-file-scope)
(define-key dired-mode-map (kbd "M-V") 'dired-view-file-vs)
(define-key dired-mode-map (kbd "h") 'dired-eranger-up)
(define-key dired-mode-map (kbd "l") 'dired-find-file)
(define-key dired-mode-map (kbd "k") 'previous-line)
(define-key dired-mode-map (kbd "j") 'next-line)
(define-key dired-mode-map (kbd "J") 'spacemacs/helm-find-files)
(define-key dired-mode-map (kbd "<mouse-2>") 'dired-mouse-find-file)
(define-key dired-mode-map (kbd "M-A") 'find-here-symlink)
(define-key image-dired-thumbnail-mode-map "\C-n" 'image-diredx-next-line)
(define-key image-dired-thumbnail-mode-map "\C-p" 'image-diredx-previous-line)
(define-key dired-mode-map (kbd "O") 'dired-open-externally-with-rifle)
(define-key dired-mode-map (kbd "o") 'dired-do-chown)
(define-key my-mode-map (kbd "M-U") 'dired-here)
(define-key global-map (kbd "C-M-_") #'my-helm-find-files)
(define-key dired-mode-map (kbd "TAB") 'dired-subtree-toggle)
(define-key dired-mode-map (kbd "C-M-i") (dff (tsps "cr")))
(define-key ranger-mode-map (kbd "C-M-i") (dff (tsps "cr")))
(define-key dired-mode-map (kbd "M-^") 'vc-cd-top-level)
(define-key dired-mode-map (kbd "r") 'my-ranger)
(define-key dired-mode-map (kbd "M-r") 'sps-ranger)
(define-key dired-mode-map (kbd "[") 'peep-dired)
(define-key dired-mode-map (kbd "f") 'dired-narrow)
(define-key dired-mode-map (kbd "/") 'dired-narrow-fuzzy)
(define-key dired-mode-map (kbd "M-~") 'dired-top)
(define-key global-map (kbd "M-l M-^") 'dired-top)
(define-key dired-mode-map (kbd "z d") 'dired-sort-dirs-first)
(define-key dired-mode-map (kbd "M-N") 'dired-next-subdir)
(define-key dired-mode-map (kbd "M-P") 'dired-prev-subdir)
(define-key dired-mode-map [remap next-line] nil)
(define-key dired-mode-map [remap previous-line] nil)
(define-key dired-mode-map (kbd "C-j") (kbd "C-m"))

(provide 'pen-dired)