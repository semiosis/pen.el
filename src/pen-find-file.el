(defun open-doc-as-text (&optional fp)
  (if (not fp)
      (setq fp (get-path)))
  (let* ((dn (f-dirname fp))
         (bn (basename fp))
         (fn (file-name-sans-extension bn))
         (ext (file-name-extension bn)))

    (cond ((or (string-equal "pdf" ext)
               (string-equal "PDF" ext))
           (if (>= (prefix-numeric-value current-prefix-arg) 16)
               (progn
                 (pen-sn "pdfs2txt" nil dn)
                 (let ((b (current-buffer)))
                   (find-file (concat dn "/" fn ".txt"))
                   (kill-buffer b)))
             (progn
               (if (yes-or-no-p "Add to calibredb?")
                   (pen-calibre-add fp)))
             (if (or (>= (prefix-numeric-value current-prefix-arg) 4)
                     (not (yes-or-no-p "Open text form?")))
                 (progn
                   (kill-buffer (current-buffer))
                   ;; (r fp)
                   (pen-sn (concat "z " (pen-q fp)) nil nil nil t))
               (progn
                 (pen-sn "pdfs2txt" nil dn)
                 (let ((b (current-buffer)))
                   (find-file (concat dn "/" fn ".txt"))
                   (kill-buffer b))))))

          ((string-equal "ipynb" ext)
           (progn
             (pen-sn (concat "ipynb2py " (pen-q bn)) nil dn)
             (let ((b (current-buffer)))
               (find-file (concat dn "/" fn ".py"))
               (kill-buffer b))))

          ((string-equal "emacsprofiler" ext)
           (let ((b (current-buffer)))
               (profiler-find-profile fp)
               (kill-buffer b)))

          ;; edbi-sqlite
          ((or (string-equal "sqlite" ext)
               (string-equal "sqlite3" ext)
               (string-equal "sqlitedb" ext)
               (string-equal "db" ext)
               (string-equal "db3" ext))
           (progn
             (let ((b (current-buffer)))
               (edbi-sqlite fp)
               (kill-buffer b))))

          ((istr-match-p "html" ext)
           (find-file fp))
          ((string-equal "svg" ext)
           (if (>= (prefix-numeric-value current-prefix-arg) 4)
               (find-file fp)
             (progn
               (eval `(run-with-timer 0.1 nil (λ () (kill-buffer (find-file ,fp)))))
               (snd (concat "fehdf " (pen-q fp))))))

          ((string-equal "jpg" ext)
           (let ((b (current-buffer)))
             (pen-term-nsfa (concat "win ie " (pen-q fp)))
             (kill-buffer b)))
          ((string-equal "pkl" ext)
           (let ((b (current-buffer)))
             (pen-sps (concat "orpy " (pen-q fp)))
             (kill-buffer b))))))

;; It matters where in the list it is
;; The sooner the better
(remove-hook 'find-file-hooks 'open-doc-as-text)
(add-hook 'find-file-hooks 'open-doc-as-text)

(defun find-file-change-dir ()
  (let ((cwd (cwd))
        (fn (f-basename (get-path nil t)))
        (pdn (f-basename (f-dirname (get-path nil t))))
        (gdp (pen-umn "$HOME/var/smulliga/source/git/mullikine/glossaries")))
    (cond
     ((and (string-equal fn "glossary.txt")
           (f-file-p (f-join (pen-umn gdp) (concat pdn ".txt"))))
      (cd gdp)))
    t))

(add-hook 'find-file-hooks 'find-file-change-dir)

(defun open-pat (pat &optional ext a_dir)
  (interactive (list (read-string-hist "open-pat: ")))
  (let* ((dir (or
               (if (>= (prefix-numeric-value current-prefix-arg) 4)
                   (get-top-level))
               a_dir
               (get-dir)))
         (found (sor (fz (chomp (pen-sn (pen-cmd "pen-grep-pos" pat) nil dir)) nil nil nil nil t) nil)))
    (if found
        (let ((path (s-replace-regexp "^\\([^:]+\\).*" "\\1" found))
              (pos (s-replace-regexp "^[^:]+:\\([0-9]+\\):.*" "\\1" found)))
          (with-current-buffer (find-file (if dir
                                              (concat dir "/" path)
                                            (concat dir path)))
            (goto-byte (string-to-number pos))))
      (message "Pattern " pat " not found"))))

(defun open-main (&optional a_dir)
  (interactive)
  (let* ((dir (or
               (if (>= (prefix-numeric-value current-prefix-arg) 4)
                   (get-top-level))
               a_dir
               (get-dir)))
         (found (sor (fz (chomp (pen-sn "open-main" nil dir)) nil nil
                         "open-main: " nil t) nil)))
    (if found
        (let ((path (s-replace-regexp "^\\([^:]+\\).*" "\\1" found))
              (pos (s-replace-regexp "^[^:]+:\\([0-9]+\\):.*" "\\1" found)))
          (with-current-buffer (find-file (if dir
                                              (concat dir "/" path)
                                            (concat dir path)))
            (goto-byte (string-to-number pos))))
      (message "Main function not found"))))

(defun find-repo-by-ext (&optional ext)
  (interactive (list (read-string-hist "find-repo-by-ext ext: ")))
  (if (sor ext)
      (let ((repo (chomp (fz (pen-sn (concat "unbuffer pen-ci list-repos-with-ext " ext))))))
        (if repo
            (e (concat "$MYGIT/" repo))))))

(defun find-repo-by-content (&optional content)
  (interactive (list (read-string-hist "find-repo-by-content content: ")))
  (if (sor content)
      (let ((repo (chomp (fz (pen-sn (concat "unbuffer pen-ci list-repos-containing " content))))))
        (if repo
            (e (concat "$MYGIT/" repo))))))

(defun list-mygit-for-paths (paths-string)
  (-non-nil (mapcar 'sor (str2list (chomp (pen-sn "grep -P \"^/home/shane/source/git\" | sed \"s=^/home/shane/source/git/==\" | path-firsttwo | uniqnosort" paths-string))))))

(defun find-repo-by-path (&optional path-pat)
  (interactive (list (read-string-hist "find-repo-by-path pattern: ")))
  (if (sor path-pat)
      (let ((repo (fz (list-mygit-for-paths (pen-sn (concat "unbuffer pen-ci locate -r " path-pat " | pen-mnm | pen-umn"))))))
        (if repo
            (e (concat "$MYGIT/" repo))))))

(define-key global-map (kbd "H-o") 'open-main)
(define-key global-map (kbd "H-E") 'find-repo-by-ext)
(define-key global-map (kbd "H-t e") 'find-repo-by-ext)
(define-key global-map (kbd "H-t t") 'find-repo-by-content)
(define-key global-map (kbd "H-t c") 'find-repo-by-content)
(define-key global-map (kbd "H-t f") 'find-repo-by-path)

(provide 'pen-find-file)
