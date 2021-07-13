(defun pen-company-grab-symbol ()
  (buffer-substring (point) (save-excursion (skip-syntax-backward "w_.")
                                            (point))))

(defun pen-company-filetype--prefix ()
  "Grab prefix at point."
  (or (pen-company-grab-symbol)
      'stop))

(defun pen-company-filetype (command &optional arg &rest ignored)
  (interactive (list 'is-interactive))
  (cl-case command
    (is-interactive (company-begin-backend 'pen-company-filetype))
    (prefix (pen-company-filetype--prefix))
    (candidates (pen-company-filetype--candidates arg))))

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

(defset pen-company-selected-backends '(pen-complete-long))

(defun pen-company-complete ()
  (interactive)
  ;; C-u should add to the backends
  ;; C-u C-u should erase the backends and select a new one

  (cond
   ((>= (prefix-numeric-value current-prefix-arg) 16)
    (setq pen-company-selected-backends
          (list
           (intern (fz pen-company-all-backends
                       nil nil "pen-company-complete select:")))))
   ((>= (prefix-numeric-value current-prefix-arg) 4)
    (setq pen-company-selected-backends
          (-uniq
           (cons
            (intern (fz pen-company-all-backends
                         nil nil "pen-company-complete add:"))
            pen-company-selected-backends))))
   (t (let ((company-backends pen-company-selected-backends))
        (if (equal (length company-backends) 1)
            (message (str (car company-backends))))
        (call-interactively 'company-complete)))))

(define-key global-map (kbd "H-TAB c") 'pen-company-complete)

(provide 'pen-company)