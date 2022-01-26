(defun pen-read-tutorial ()
  (interactive)
  (let* ((dir (f-join pen-penel-directory "docs" "tutorials"))
         (file (fz (pen-sn
                    (concat
                     (pen-cmd "find" "." "-name" "*.org")
                     " | sed 's/.\\///'")
                    nil
                    dir)
                   nil nil
                   "Tutorial: "))
         (full-path (f-join dir file)))
    (if (f-exists-p full-path)
        (find-file full-path))))

(provide 'pen-docs)