(defvar current-line-number (line-number-at-pos))

(defvar changed-line-hook nil)

(defun update-line-number ()
  (let ((new-line-number (line-number-at-pos)))
    (when (not (equal new-line-number current-line-number))
      (setq current-line-number new-line-number)
      (run-hooks 'changed-line-hook))))

;; Example of hook usage

(defun my-line-func ()
  (message-no-echo "This is the current line: %s" current-line-number))

(add-hook 'changed-line-hook #'my-line-func)
;; (remove-hook 'changed-line-hook #'my-line-func)

(add-hook 'post-command-hook #'update-line-number)
;; (remove-hook 'post-command-hook #'update-line-number)

(provide 'pen-line-changed)
