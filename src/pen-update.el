(defun pen-update-repos ()
  (interactive)

  (pen-sps
   (concat
    (pen-cmd "cd" pen-prompts-directory)
    "; git pull")))

(provide 'pen-update)