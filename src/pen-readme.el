;; This is for searching for readme files

(defun find-readme-here (&optional dir)
  (interactive)
  (setq searchdir (or dir default-directory))
  (let* ((rootdir (or (projectile-project-root searchdir)
                      searchdir))
         (fp (fz
              (mapconcat
               (lambda (s)
                 (f-relative (concat rootdir s)))
               (str2lines
                (snc (cmd "spin" "find-readme-here" rootdir)))
               "\n")
              nil nil "README search" nil t)))
    (if (f-file-p fp)
        (e fp))))

(define-key global-map (kbd "s-r") 'find-readme-here)

(provide 'pen-readme)
