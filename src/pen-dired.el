(require 'ranger)
(require 'dired-git-info)
(require 'dired-narrow)

(setq dgi-auto-hide-details-p nil)
(setq dired-listing-switches "-alh")

(defun pen-open-dir (dir)
  (setq dir (pen-umn dir))
  (if (not (f-directory-p dir))
      (if (yes-or-no-p (pen-cmd "mkdir"  dir))
          (pen-snc (pen-cmd "mkdir"  dir))))
  (cond
   ;; Both dired-mode and ranger-mode can be true at the same time. Therefore, ranger must precede
   ((derived-mode-p 'ranger-mode) (ranger dir))
   ((derived-mode-p 'dired-mode) (dired dir))
   (t (dired dir))))

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

(defun dired-cmd (c dirname &optional switches)
  (interactive (cons (read-string "cmd:") (dired-read-dir-and-switches "")))
  (ignore-errors (kill-buffer dirname))
  (let ((ls-lisp-use-insert-directory-program t)
        (insert-directory-program c))
    (dired dirname switches)))

(defun ev (&optional path)
  (interactive)
  (pen-term-nsfa (concat "pen-v " (pen-q path))))

(defun evim (&optional path)
  (interactive)
  (pen-term-nsfa (concat "vim " (pen-q path))))

(defun evs (&optional path)
  (interactive)
  (pen-term-nsfa (concat "pen-vs " (pen-q path))))

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
      (let ((output (pen-sn (concat "pen-scope.sh " (pen-q file)))))
        (if (not (string-empty-p output))
            (new-buffer-from-string output)
          (error "No preview data"))))))

(defun dired-view-file-vs (&optional arg)
  (interactive "P")
  (let ((file (dired-get-file-for-visit)))
    (if (or (>= (prefix-numeric-value current-prefix-arg) 4)
            (string-equal (current-major-mode-string) "ranger-mode"))
        (evs file)
      (progn
          (setq current-prefix-arg nil)
          (pen-sps (concat "pen-vs " (pen-q file)))))))

(defun dired-view-file-v (&optional arg)
  (interactive "P")
  (let ((file (dired-get-file-for-visit)))
    (if (or (not (>= (prefix-numeric-value current-prefix-arg) 4))
            (string-equal (current-major-mode-string) "ranger-mode"))
        (progn
        (setq current-prefix-arg nil)
        (pen-sps (concat "pen-v " (pen-q file))))
      (ev file))))

(defalias 'dired-filter 'dired-narrow)

(defun my-ranger ()
  (interactive)
  (if (>= (prefix-numeric-value current-prefix-arg) 4)
      (call-interactively 'pen-sps-ranger)
    (call-interactively 'ranger)))

(defun dired-open-externally-with-rifle (&optional arg)
  (interactive "P")
  (let ((file (dired-get-file-for-visit)))
    (pen-sps (concat "r " (pen-q file)))))

(defun find-here-symlink (substring)
  (interactive (list (read-string "symlink substring: ")))
  (let* ((query (concat "*" substring "*"))
         (result (pen-sn (concat "tp find-here-symlink " (pen-q query)) nil (pen-pwd))))
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

(defun find-ci-here (&optional a_dir)
  (interactive)
  (let* ((dir (or
               (sor a_dir)
               (pen-umn default-directory)))
         (joined-list (pen-snc "find-ci-here | sed 's/^\\.\\///' | lines-to-args" nil dir))
         (dired-ls-cmd (concat "shift 2; dired-ls-d --dired -alh -- " joined-list))
         (script (pen-nsfa dired-ls-cmd dir))
         (paras "--dired -alh"))
    (dired-cmd script dir paras)))

(defun find-src-here (&optional a_dir)
  (interactive)
  (let* ((dir (or
               (sor a_dir)
               (pen-umn default-directory)))
         (joined-list (pen-snc "find-src-here | sed 's/^\\.\\///' | lines-to-args" nil dir))
         (dired-ls-cmd (concat "shift 2; dired-ls-d --dired -alh -- " joined-list))
         (script (pen-nsfa dired-ls-cmd dir))
         (paras "--dired -alh"))
    (dired-cmd script dir paras)))

(defun find-files-here (&optional a_dir)
  (interactive)
  (let* ((dir (or
               (sor a_dir)
               (pen-umn default-directory)))
         (joined-list (pen-snc "find-no-git -f | lines-to-args" nil dir))
         (dired-ls-cmd (concat "shift 2; dired-ls-d --dired -alh -- " joined-list))
         (script (pen-nsfa dired-ls-cmd dir))
         (paras "--dired -alh"))
    (dired-cmd script dir paras)))

(define-key dired-mode-map (kbd "C-p") nil)
(remove-hook 'dired-mode-hook
             (defun ranger-set-dired-key ()
               (define-key dired-mode-map ranger-key 'deer-from-dired)))

(defun todayfile ()
  (interactive)
  (let ((fp
         (snc "todayfile -P | cat")))

    (if (interactive-p)
        (find-file fp)
      fp)))

;; nadvice - proc is the original function, passed in. do not modify
(defun dired-narrow-around-advice (proc &rest args)
  ;; I should clear it every time
  (revert-buffer)
  (let ((res (apply proc args)))
    res))
(advice-add 'dired-narrow :around #'dired-narrow-around-advice)
;; (advice-remove 'dired-narrow #'dired-narrow-around-advice)

(defun dired-narrow--internal (filter-function)
  "Narrow a dired buffer to the files matching a filter.

The function FILTER-FUNCTION is called on each line: if it
returns non-nil, the line is kept, otherwise it is removed.  The
function takes one argument, which is the current filter string
read from minibuffer."
  (let ((dired-narrow-buffer (current-buffer))
        (dired-narrow-filter-function filter-function)
        (disable-narrow nil))
    (unwind-protect
        (progn
          (dired-narrow-mode 1)
          (add-to-invisibility-spec :dired-narrow)
          (setq disable-narrow (read-from-minibuffer "Filter: " nil dired-narrow-map))
          ;; (if (string-empty-p disable-narrow)
          ;;     ;; This clears the filter
          ;;     (revert-buffer))
          (let ((inhibit-read-only t))
            (dired-narrow--remove-text-with-property :dired-narrow))
          ;; If the file no longer exists, we can't do anything, so
          ;; set to nil
          (unless (dired-utils-goto-line dired-narrow--current-file)
            (setq dired-narrow--current-file nil)))
      (with-current-buffer dired-narrow-buffer
        (unless disable-narrow (dired-narrow-mode -1))
        (remove-from-invisibility-spec :dired-narrow)
        (dired-narrow--restore))
      (when (and disable-narrow
                 dired-narrow--current-file
                 dired-narrow-exit-action)
        (funcall dired-narrow-exit-action))
      (cond
       ((equal disable-narrow "dired-narrow-enter-directory")
        (dired-narrow--internal filter-function))))))

(define-key dired-mode-map (kbd "@") 'find-src-here)
(define-key dired-mode-map (kbd "{") 'find-ci-here)
(define-key dired-mode-map (kbd "}") 'find-files-here)

(provide 'pen-dired)
