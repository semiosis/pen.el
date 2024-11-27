;; This is for searching for readme files

(defun find-readme-here (&optional dir)
  (interactive)
  (setq searchdir (or dir default-directory))
  (let ((fp (fz (snc (cmd "find-readme-here" searchdir))
                nil nil "README search")))
    (if (f-file-p fp)
        (e fp))))

(provide 'pen-readme)
