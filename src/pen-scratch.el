(add-hook 'kill-buffer-query-functions #'pen-dont-kill-scratch)
(defun pen-dont-kill-scratch ()
  (if (not (equal (buffer-name) "*scratch*"))
      t
    (message "Not allowed to kill %s, burying instead" (buffer-name))
    (bury-buffer)
    nil))

(defun pen-create-scratch-buffer ()
  "create a scratch buffer"
  (interactive)
  (switch-to-buffer (get-buffer-create "*scratch*"))
  (text-mode)
  ;; (lisp-interaction-mode)
  )

;; (pen-create-scratch-buffer)

(provide 'pen-scratch)