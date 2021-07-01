(defun company-pen--grab-symbol ()
  (buffer-substring (point) (save-excursion (skip-syntax-backward "w_.")
                                            (point))))

(defun company-pen-filetype--prefix ()
  "Grab prefix at point."
  (or (company-pen--grab-symbol)
      'stop))

(defun company-pen-filetype (command &optional arg &rest ignored)
  (interactive (list 'is-interactive))
  (cl-case command
    (is-interactive (company-begin-backend 'company-pen-filetype))
    (prefix (company-pen-filetype--prefix))
    (candidates (company-pen-filetype--candidates arg))))

(provide 'pen-company)