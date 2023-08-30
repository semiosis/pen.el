(defun pen-acolyte-dired-prompts ()
  (interactive)
  (dired pen-prompts-directory))

(defun pen-acolyte-dired-engines ()
  (interactive)
  (dired pen-engines-directory))

(defun pen-acolyte-dired-esp ()
  (interactive)
  (dired pen-esp-directory))

(defun pen-dired-ilambda ()
  (interactive)
  (dired pen-ilambda-directory))

(defun pen-dired-imonad ()
  (interactive)
  (dired pen-imonad-directory))

(defun pen-dired-src ()
  (interactive)
  (dired (f-join pen-penel-directory "src")))

(defun pen-acolyte-dired-dni ()
  (interactive)
  (dired pen-dni-directory))

(defun pen-acolyte-dired-creation ()
  (interactive)
  (dired pen-creation-directory))

(defun pen-acolyte-dired-personalities ()
  (interactive)
  (dired pen-personalities-directory))

(defun pen-acolyte-dired-incarnations ()
  (interactive)
  (dired pen-incarnations-directory))

(defun pen-acolyte-dired-tomes ()
  (interactive)
  (dired pen-tomes-directory))

(defun pen-acolyte-dired-pictographs ()
  (interactive)
  (dired pen-pictographs-directory))

(defun pen-acolyte-dired-metaverses ()
  (interactive)
  (dired pen-metaverses-directory))

(defun pen-acolyte-dired-protoverses ()
  (interactive)
  (dired pen-protoverses-directory))

(defun pen-acolyte-dired-penel ()
  (interactive)
  (dired pen-penel-directory))

(defun pen-dired-repos ()
  (interactive)
  (dired "/root/repos"))

(defun pen-acolyte-dired-scripts ()
  (interactive)
  (dired (f-join pen-penel-directory "scripts")))

(defun pen-acolyte-dired-config ()
  (interactive)
  (dired (f-join pen-penel-directory "config")))

(defun pen-dired-rhizome ()
  (interactive)
  (dired pen-rhizome-directory))

(defun pen-dired-pensieve ()
  (interactive)
  (dired pen-pensieve-directory))

(defun pen-dired-khala ()
  (interactive)
  (dired pen-khala-directory))

(defun pen-dired-documents ()
  (interactive)
  (dired (f-join penconfdir "documents")))

(defun pen-dired-notes ()
  (interactive)
  (dired (f-join user-home-directory "notes")))

(defun pen-reload-config-file ()
  "Fuzzy selects a selects file to be loaded."
  (interactive)
  ;; Can't put the sed into umn or it will break urls
  (let ((r (pen-sed "s=//=/=g" (pen-umn (fz (pen-sn "pen-ls-emacs-config-files") nil nil "reload config: ")))))
    (if (not (s-blank? r))
        (load r))))

(if (pen-snq "inside-docker-p")
    (define-key pen-map (kbd "M-l M-p M-r") 'pen-reload-config-file))

(provide 'pen-source)
