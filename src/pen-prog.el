(require 'pen-handle)

(defun record-prog-mode-lang ()
  (interactive)
  (let* ((fn (or (buffer-file-name) ""))
         (bn (try (basename fn)
                  ""))
         (ext (if (and fn (s-match "\\." bn))
                  (s-replace-regexp ".*\." "" bn)
                nil))
         (mms (current-major-mode-string))
         (get-current-line-string (ifn ext (concat mms " " ext) mms)))
    (append-uniq-to-file (awk1 line) "/home/shane/notes/ws/emacs/file-types.txt")))

(defun pen-comment-time-stamp ()
  "Insert a timestamp. Designed for comments"
  (interactive)
  (call-interactively 'org-time-stamp)
  (search-backward "<" (pos-at-start-of-line)))

;; Use this only for code-generation, not for creating functions
(defmacro make-next-prev-def-for-mode (&optional m defaultre)
  (if (not m)
      (setq m major-mode))
  (if (not defaultre)
      (setq defaultre "^[^#;/ \t]+ "))
  (let ((prevdefsym (intern (concat "pen-" (str m) "-prev-def")))
        (nextdefsym (intern (concat "pen-" (str m) "-next-def"))))
    `(progn
       (defun ,prevdefsym (&optional re)
         (interactive)
         (if (not re)
             (setq re ,defaultre))
         (backward-to-indentation 0)
         (ignore-errors (search-backward-regexp re))
         (backward-to-indentation 0))

       (defun ,nextdefsym (&optional re)
         (interactive)
         (if (not re)
             (setq re ,defaultre))
         (backward-to-indentation 0)
         (if (looking-at-p re)
             (progn
               (forward-char)))
         (try (search-forward-regexp re))
         (backward-to-indentation 0)))))

;; $HOME/.cask/features/eval.feature
(defvar pen-feature-mode-def-pattern "^ *[A-Z][a-z]+: ")
(defvar pen-Custom-mode-def-pattern "^\\(Show\\|Hide\\) ")

;; DISCARD First check if a mode-specific next-def function exists generated from macro above
;; DONE Check first for a mode-specific pattern before using the default
;; TODO If imenu is available then I should try to use imenu
(defun pen-prog-prev-def (&optional re)
  (interactive)
  (if (not re)
      (let ((patternsym (intern (concat "pen-" (current-major-mode-string) "-def-pattern"))))
        (if (variable-p patternsym)
            (setq re (eval patternsym))
          (setq re "^[^#;/ \t]+ "))))
  (backward-to-indentation 0)
  (search-backward-regexp re)
  (backward-to-indentation 0))

(defun pen-prog-next-def (&optional re)
  (interactive)
  (if (not re)
      (let ((patternsym (intern (concat "pen-" (current-major-mode-string) "-def-pattern"))))
        (if (variable-p patternsym)
            (setq re (eval patternsym))
          (setq re "^[^#;/ \t]+ "))))
  (backward-to-indentation 0)
  (if (looking-at-p re)
      (progn
        (forward-char)))
  (try (search-forward-regexp re))
  (backward-to-indentation 0))

;; This should remove bindings from all derived prog modes so the prog mode bindings should come through
;; (defun prog-set-bindings ()
;;   (interactive)
;;   (if (not (eq major-mode 'prog-mode))
;;       (progn
;;         (message (concat "test:" (symbol-name (current-major-mode-map))))
;;         ;; (eval `(define-key ,(current-major-mode-map) (kbd "M-9") nil))
;;         ;; (eval `(define-key ,(current-major-mode-map) (kbd "M-.") nil))
;;         )))

;; (add-hook 'prog-mode-hook 'prog-set-bindings)

;; (defun hook-disable-selected ()
;;   (selected-minor-mode -1))

;; (defun hook-enable-selected ()
;;   (selected-minor-mode t))

;; (add-hook 'fundamental-mode-hook 'hook-disable-selected)
;; (remove-hook 'fundamental-mode-hook 'hook-enable-selected)
;; (add-hook 'prog-mode-hook 'hook-enable-selected)
;; (remove-hook 'prog-mode-hook 'hook-enable-selected)

;; When bindings are inherited they are assigned to the derived mode, not prog-mode
;; Therefore I can't do the above

(defun pen-handle-repls ()
  (interactive)

  (let* ((ib (current-buffer))
         (_ (handle-repls nil))
         (cb (current-buffer)))

    (if (equal ib cb)
        (switch-to-previous-buffer))))

(defun pen-handle-repls ()
  (interactive)
  (if (str-match-p "*" (buffer-name))
      (switch-to-previous-buffer)
      ;; (previous-buffer)
    (handle-repls nil)))

(define-key prog-mode-map (kbd "M-=") 'pen-handle-repls)
(define-key dired-mode-map (kbd "M-=") 'pen-handle-repls)
(define-key global-map (kbd "M-=") 'pen-handle-repls)
(define-key prog-mode-map (kbd "M-C") 'handle-debug)
(define-key global-map (kbd "H-RET") 'handle-run)
(define-key prog-mode-map (kbd "H-T") 'handle-toggle-test)
(define-key prog-mode-map (kbd "M-\"") 'pen-helm-fzf)
(define-key prog-mode-map (kbd "M-@") 'handle-testall)
(define-key prog-mode-map (kbd "M-)") 'handle-assignments)
(define-key prog-mode-map (kbd "M-*") 'handle-references)
(define-key prog-mode-map (kbd "M-%") 'handle-formatters)
(define-key prog-mode-map (kbd "M-$") 'handle-errors)
(define-key global-map (kbd "M-$") 'handle-errors)
(define-key global-map (kbd "M-&") 'handle-navtree)
(define-key prog-mode-map (kbd "M-+") nil)
(define-key prog-mode-map (kbd "M-_") nil)

;; nadvice - proc is the original function, passed in. do not modify
(defun handle-docs-around-advice (proc &rest args)
  (let ((res (apply proc args)))
    (deactivate-mark)
    res))
(advice-add 'handle-docs :around #'handle-docs-around-advice)

(define-key prog-mode-map (kbd "M-9") 'handle-docs)

(defun pen-godef-or-global-references ()
  (interactive)
  (if (>= (prefix-numeric-value current-prefix-arg) 4)
      (call-interactively 'handle-global-references)
    (call-interactively 'handle-godef)))
(define-key prog-mode-map (kbd "M-.") 'pen-godef-or-global-references)

(define-key prog-mode-map (kbd "M-p") 'handle-prevdef)
(define-key prog-mode-map (kbd "M-n") 'handle-nextdef)

(define-key prog-mode-map (kbd "M-P") 'handle-preverr)
(define-key prog-mode-map (kbd "M-N") 'handle-nexterr)

(define-key text-mode-map (kbd "M-P") 'handle-preverr)
(define-key text-mode-map (kbd "M-N") 'handle-nexterr)

(define-key markdown-mode-map (kbd "M-P") 'handle-preverr)
(define-key markdown-mode-map (kbd "M-N") 'handle-nexterr)

(defun new-line-and-indent ()
  (interactive)

  (call-interactively 'move-end-of-line)
  (newline-and-indent))

(define-key prog-mode-map (kbd "M-RET") 'new-line-and-indent)

(define-key prog-mode-map (kbd "M-l M-j M-w") 'handle-spellcorrect)

(define-key prog-mode-map (kbd "C-x C-o") 'ff-find-other-file)

(define-key prog-mode-map (kbd "H-{") 'handle-callees)
(define-key prog-mode-map (kbd "H-}") 'handle-callers)

(define-key prog-mode-map (kbd "H-u") nil)

(define-key prog-mode-map (kbd "H-*") 'handle-refactor)

(define-key prog-mode-map (kbd "H-v") 'handlenav/body)

(define-key prog-mode-map (kbd "M-J") 'evil-join)

(define-key prog-mode-map (kbd "C-c C-o") 'org-open-at-point)
(define-key prog-mode-map (kbd "C-c h f") 'handle-docfun)

(defun run-file-with-interpreter (fp)
  (interactive (list (read-file-name "File: ")))
  (pen-nw (pen-cmd "run" fp) "-pak"))

(provide 'pen-prog)
