(defun pen-reload-config-file ()
  "Fuzzy selects a selects file to be loaded."
  (interactive)
  (let ((r (pen-umn (fz (pen-sn "list-emacs-config-files.sh") nil nil "reload config: "))))
    (if (not (s-blank? r))
        (load r))))

(if (pen-snq "inside-docker-p")
    (define-key pen-map (kbd "M-l M-p M-r") 'pen-reload-config-file))

(provide 'pen-source)