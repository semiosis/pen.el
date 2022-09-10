(defvar org-tidbits-directory-list '("$MYGIT/mullikine/code-org-tidbits"
                                     "$MYGIT/mullikine/code-org-tidbits-tasks"))

(df fz-org-tidbits
    (mu
     (let ((dir "$MYGIT/mullikine/code-org-tidbits"))
       (if (>= (prefix-numeric-value current-prefix-arg) 4)
           (dired dir)
         (let* ((tidbit (fz (pen-snc (concat
                                  (pen-cmd "cd" dir)
                                  "; "
                                  (pen-cmd "find-no-git" "-f")
                                  " | sed '/\\/\\./d'"))
                            nil nil "org-tidbit: ")))
           (if (sor tidbit)
               (e (concat dir "/" tidbit))))))))

(df fz-org-tidbits-tasks
    (mu (let ((dir "$MYGIT/mullikine/code-org-tidbits-tasks"))
          (if (>= (prefix-numeric-value current-prefix-arg) 4)
              (dired dir)
            (let* ((tidbit (fz (pen-snc (concat
                                     (pen-cmd "cd" dir)
                                     "; "
                                     (pen-cmd "find-no-git" "-f")
                                     " | sed '/\\/\\./d'"))
                               nil nil "org-tidbit: ")))
              (if (sor tidbit)
                  (e (concat dir "/" tidbit))))))))

;; (define-key global-map (kbd "M-l z k") 'fz-org-tidbits-tasks)

(provide 'pen-org-tidbits)