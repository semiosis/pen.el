(defun company-pen--grab-symbol ()
  (buffer-substring (point) (save-excursion (skip-syntax-backward "w_.")
                                            (point))))

(defun company-pen-filetype--prefix ()
  "Grab prefix at point."
  (or (company-pen--grab-symbol)
      'stop))

(defun company-pen-filetype (command &optional arg &rest ignored)
  (interactive (list 'is-interactive))
  (cl-case command
    (is-interactive (company-begin-backend 'company-pen-filetype))
    (prefix (company-pen-filetype--prefix))
    (candidates (company-pen-filetype--candidates arg))))

(defset my-company-all-backends
  '(
    ;; pf-generic-file-type-completion
    ;; pf-generic-completion-200-tokens-max
    ;; pf-generic-completion-50-tokens-max-hash
    ;; pf-shell-bash-terminal-command-completion
    company-pen-filetype
    company-complete
    company-tabnine
    company-yasnippet
    company-lsp
    ;; pen-complete-long
    company-org-block))

(defset my-company-selected-backends '(pen-complete-long))

(defun my-company-complete ()
  (interactive)
  ;; C-u should add to the backends
  ;; C-u C-u should erase the backends and select a new one

  (cond
   ((>= (prefix-numeric-value current-prefix-arg) 16)
    (setq my-company-selected-backends
          (list
           (str2sym (fz my-company-all-backends
                        nil nil "my-company-complete select:")))))
   ((>= (prefix-numeric-value current-prefix-arg) 4)
    (setq my-company-selected-backends
          (-uniq
           (cons
            (str2sym (fz my-company-all-backends
                         nil nil "my-company-complete add:"))
            my-company-selected-backends))))
   (t (let ((company-backends my-company-selected-backends))
        (if (equal (length company-backends) 1)
            (message (str (car company-backends))))
        (call-interactively 'company-complete)))))

(provide 'pen-company)