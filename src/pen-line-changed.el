(defvar current-line-number (line-number-at-pos))

(defvar changed-line-hook nil)

(defun update-line-number ()
  (let ((new-line-number (line-number-at-pos)))
    (when (not (equal new-line-number current-line-number))
      (setq current-line-number new-line-number)
      (run-hooks 'changed-line-hook))))

(add-hook 'post-command-hook #'update-line-number)

;; Example of hook usage

(defun my-line-func ()
  (message "This is the current line: %s" current-line-number))

;; (add-hook 'changed-line-hook #'my-line-func)
;; (remove-hook 'changed-line-hook #'my-line-func)

(add-hook 'changed-line-hook #'universal-sidecar-refresh)

(provide 'pen-line-changed)
