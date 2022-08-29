(require 'flymake-racket)
(require 'racket-mode)

(defun racket--do-visit-def-or-mod (pen-cmd sym)
  "CMD must be \"def\" or \"mod\". SYM must be `symbolp`."
  (pcase (racket--repl-command "%s %s" cmd sym)
    (`(,path ,line ,col)
     (racket--push-loc)
     (find-file path)
     (goto-char (point-min))
     (forward-line (1- line))
     (forward-char col)
     (message "%s" "Type M-, to return")
     t)
    (`kernel
     (error "Defined in kernel"))
    (_ (error "Not found"))))

(defun flymake-racket-setup ()
  "Set up Flymake for Racket."
  (interactive)
  (add-hook 'racket-mode-hook #'flymake-racket-add-hook))

(remove-hook 'scheme-mode-hook #'flymake-racket-add-hook)

(defun racket-goto-symbol (&optional arg)
  (interactive)

  (if (string-equal (lispy--current-function) "require")
      (racket-find-collection)
    (try (racket-visit-definition)
         (racket-expand-definition))))

(add-to-list 'lispy-goto-symbol-alist
	           '(racket-mode racket-goto-symbol le-racket))

(setq racket-images-system-viewer "rifle")

(defun pen-racket-expand-macro-or-copy ()
  (interactive)
  (if mark-active
      (progn (call-interactively 'kill-ring-save)
             (reselect-region))
    (racket-goto-symbol)))

(defun pen-racket-show-doc-url (url)
  (ignore-errors
    (if (buffer-currently-visible "*eww-racket-doc*")
        (with-current-buffer (switch-to-buffer "*eww-racket-doc*")
          (kill-buffer-and-window))
      (kill-buffer "*eww-racket-doc*")))
  (setq url (pen-snc "fix-racket-doc-url" url))
  (espv (pen-lm (with-current-buffer (eww url) (rename-buffer "*eww-racket-doc*")))))

(defun pen-racket-lang-doc (thing &optional  winfunc)
  "This is for #lang"
  (interactive (list (pen-thing-at-point)))
  (if (string-equal (preceding-sexp-or-element) "#lang")
      (progn
        (let ((url (pen-racket-get-doc-url (concat "H:" thing))))
          (pen-racket-show-doc-url url)))))

(defun pen-racket-get-doc-url (thing)
  "local is "
  (interactive (read-string-hist "pen-racket-get-doc-url: "))
  (let ((url
         (cond
          ((and (pen-rc-test "racket_use_web_or_local_preference")
                (pen-rc-test "racket_use_local_docs"))
           (progn
             (racket--search-doc-locally thing)
             (sleep-for-for-for 1)
             (cl/xc nil :notify t)))
          (t
           (format racket-documentation-search-location thing)))))
    (if (and (interactive-p)
             (sor url))
        (pen-racket-show-doc-url url))))

(defun pen-racket-doc (&optional winfunc thing)
  (interactive)
  (if (not winfunc)
      (setq winfunc 'sph))
  (if (not thing)
      (setq thing (str (symbol-at-point))))
  (if (string-equal (preceding-sexp-or-element) "#lang")
      (pen-racket-get-doc-url (concat "H:" thing))
    (pen-racket-get-doc-url thing))
  (if (interactive-p)
      (pen-racket-show-doc-url url)))

(defun racket-expand-at-point ()
  (interactive)
  (cond ((and (lispy-left-p) (not mark-active))
         (save-excursion
           (ekm "m")
           (call-interactively 'racket-expand-region)))
        (mark-active
         (xc))
        (t
         (call-interactively 'racket-expand-definition))))

(defun format-racket-at-point ()
  "Formats racket code, if selected or on a starting parenthesis."
  (interactive)
  (format-sexp-at-point "racket-format"))

(defun pen-racket-setup ()
  (eldoc-mode -1)
  (remove-hook 'after-change-functions 'lsp-on-change t))

(advice-add 'indent-for-tab-command :around #'ignore-errors-around-advice)
(advice-add 'indent-according-to-mode :around #'ignore-errors-around-advice)

(defun pen-racket-run-main (path)
  (interactive (list (get-path)))
  (if (bq racket-main-exists)
      (pen-sps "racket-run-main")))

(defun pen-racket-run (&optional noselect)
  (interactive "P")
  (racket-call-racket-repl-buffer-name-function)
  (cl-flet
      ((display-and-maybe-select
        ()
        (display-buffer racket-repl-buffer-name)
        (unless noselect
          (select-window (get-buffer-window racket-repl-buffer-name t)))))
    (if (racket--repl-live-p)
        (display-and-maybe-select)
      (racket-run)
      ;; (racket--repl-start
      ;;  (lambda ()
      ;;    (racket--repl-refresh-namespace-symbols)
      ;;    (display-and-maybe-select)))
      )))

(define-key racket-mode-map (kbd "M-w") #'pen-racket-expand-macro-or-copy)
(define-key racket-mode-map (kbd "M-w") 'racket-expand-at-point)
(define-key racket-mode-map (kbd "C-M-i") 'racket-format-at-point)
(define-key racket-mode-map (kbd "H-r") nil)
(define-key racket-mode-map (kbd "C-c C-v") 'racket-view-last-image)
(define-key racket-repl-mode-map (kbd "C-c C-v") 'racket-view-last-image)

(provide 'pen-racket)
