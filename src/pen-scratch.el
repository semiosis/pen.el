(add-hook 'kill-buffer-query-functions #'pen-dont-kill-scratch)
(defun pen-dont-kill-scratch ()
  (if (not (equal (buffer-name) "*scratch*"))
      t
    (message "Not allowed to kill %s, burying instead" (buffer-name))
    (bury-buffer)
    nil))

(provide 'pen-scratch)