(defun pen-textprops-in-region-or-buffer ()
  (if (region-active-p)
      (format "%S" (buffer-substring (region-beginning) (region-end)))
    (format "%S" (buffer-string))))

(defun pen-etv-textprops ()
  (interactive)
  (new-buffer-from-string (pen-textprops-in-region-or-buffer)))

(define-key pen-map (kbd "M-l M-p M-t") 'pen-etv-textprops)

(provide 'pen-textprops)