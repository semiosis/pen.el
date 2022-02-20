(defun pen-acolyte-dired-prompts ()
  (interactive)
  (dired pen-prompts-directory))

(defun pen-acolyte-dired-engines ()
  (interactive)
  (dired pen-engines-directory))

(defun pen-acolyte-dired-personalities ()
  (interactive)
  (dired pen-personalities-directory))

(defun pen-acolyte-dired-tomes ()
  (interactive)
  (dired pen-tomes-directory))

(defun pen-acolyte-dired-metaverses ()
  (interactive)
  (dired pen-metaverses-directory))

(defun pen-acolyte-dired-penel ()
  (interactive)
  (dired pen-penel-directory))

(defun pen-dired-rhizome ()
  (interactive)
  (dired pen-rhizome-directory))

(defun pen-dired-pensieve ()
  (interactive)
  (dired pen-pensieve-directory))

(defun pen-dired-khala ()
  (interactive)
  (dired pen-khala-directory))

(defun pen-reload-config-file ()
  "Fuzzy selects a selects file to be loaded."
  (interactive)
  (let ((r (pen-umn (fz (pen-sn "pen-ls-emacs-config-files") nil nil "reload config: "))))
    (if (not (s-blank? r))
        (load r))))

(if (pen-snq "inside-docker-p")
    (define-key pen-map (kbd "M-l M-p M-r") 'pen-reload-config-file))

(provide 'pen-source)