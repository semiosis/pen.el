(defun pen-company-grab-symbol ()
  (buffer-substring (point) (save-excursion (skip-syntax-backward "w_.")
                                            (point))))

(defun pen-company-filetype--prefix ()
  "Grab prefix at point."
  (or (pen-company-grab-symbol)
      'stop))

(defun pen-company-filetype (command &optional arg &rest ignored)
  (interactive (list 'is-interactive))

  (if (not company-mode)
      (company-mode 1))

  (cl-case command
    (is-interactive (company-begin-backend 'pen-company-filetype))
    (prefix (pen-company-filetype--prefix))
    (candidates (pen-company-filetype--candidates arg))))

(defun pen-company-filetype-word (command &optional arg &rest ignored)
  (interactive (list 'is-interactive))
  (let ((current-prefix-arg '(16))
        (pen-company-filetype command arg))))

(defun pen-company-filetype-long (command &optional arg &rest ignored)
  (interactive (list 'is-interactive))
  (let ((current-prefix-arg '(4))
        (pen-company-filetype command arg))))

(defset pen-company-all-backends
  '(
    ;; pf-generic-file-type-completion
    ;; pf-generic-completion-200-tokens-max
    ;; pf-generic-completion-50-tokens-max-hash
    ;; pf-shell-bash-terminal-command-completion
    pen-company-filetype
    company-complete
    company-tabnine
    company-yasnippet
    company-lsp
    ;; pen-complete-long
    company-org-block))

(defset pen-company-selected-backends '(pen-company-filetype))

;; TODO: Encode where the text came from into the emacs buffer using emacs text properties
(defun pen-company-complete ()
  (interactive)

  (let ((company-backends pen-company-selected-backends))
    (if (equal (length company-backends) 1)
        (message (str (car company-backends))))
    (call-interactively 'company-complete)))

(defun pen-company-complete-choose ()
  (interactive)

  (setq pen-company-selected-backends
        (list
         (intern (fz pen-company-all-backends
                     nil nil "pen-company-complete select:")))))

(defun pen-company-complete-add ()
  (interactive)

  (setq pen-company-selected-backends
        (-uniq
         (cons
          (intern (fz pen-company-all-backends
                      nil nil "pen-company-complete add:"))
          pen-company-selected-backends))))

(define-key global-map (kbd "H-TAB c") 'pen-company-complete)
(define-key global-map (kbd "H-TAB f") 'pen-company-complete-choose)
(define-key global-map (kbd "H-TAB a") 'pen-company-complete-add)
(define-key global-map (kbd "H-TAB l") 'pen-complete-long)

(provide 'pen-company)