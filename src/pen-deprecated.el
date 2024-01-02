(defun toggle-read-only (&optional arg interactive)
  "Change whether this buffer is read-only."
  (declare (obsolete read-only-mode "24.3"))
  (interactive (list current-prefix-arg t))
  (if interactive
      (call-interactively 'read-only-mode)
    (read-only-mode (or arg 'toggle))))

(provide 'pen-deprecated)
