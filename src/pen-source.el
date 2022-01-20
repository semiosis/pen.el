(defun pen-reload-config-file ()
  "Fuzzy selects a selects file to be loaded."
  (interactive)
  (let ((r (umn (fz (sh-notty "list-emacs-config-files.sh") nil nil "reload config: "))))
    (if (not (empty-string-p r))
        (load r))))

(define-key global-map (kbd "M-l M-p M-r") 'pen-reload-config-file)

(provide 'pen-source)