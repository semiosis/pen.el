(defun default-search-string ()
  (if (pen-selected-p)
      (pen-selected-text)
    (if (or (derived-mode-p 'dired-mode)
            (derived-mode-p 'ranger-mode))
        nil
      (pen-thing-at-point))))

(defun eack (thing)
  (interactive)
  (pen-sph (concat "eack " (pen-q thing))))

(defun dack-top (thing)
  (interactive)
  (pen-sph (concat "cd \"$(vc get-top-level)\" && pwd" "; " "dack " (pen-q thing))))

(defun eack-top (thing)
  (interactive)
  (pen-sph (concat "cd \"$(vc get-top-level)\" && pwd" "; " "eack " (pen-q thing))))

(defun dack-selection-top ()
  (interactive)
  (if (pen-selected-p)
      (dack-top (pen-selected-text))
    (dack-top (pen-thing-at-point))))

(defun eack-selection-top ()
  (interactive)
  (if (pen-selected-p)
      (eack-top (concat "\\b" (pen-selected-text) "\\b"))
    (eack-top (concat "\\b" (pen-thing-at-point) "\\b"))))
(defalias 'eack-thing-top 'eack-selection-top)

(defun eack-selection ()
  (interactive)
  (if (pen-selected-p)
      (eack (pen-selected-text))
    (eack (pen-thing-at-point))))
(defalias 'eack-thing 'eack-selection)

(defun eack-thing-in-parent-dir ()
  (interactive)
  (s/cd ".."
        (pen-sph (concat "eack " (pen-q (pen-thing-at-point))))))

(provide 'pen-ead)
