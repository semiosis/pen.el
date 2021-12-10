(defun ead-emacs-config (pattern)
  (interactive (list (read-string-hist "ead-emacs-config: ")))
  (wgrep (concat "\\b" pattern "\\b") (mu "$EMACSD/config"))
  ;; (mu (sps (concat "cd $EMACSD/config; ead " (q pattern))))
  )
(org-add-link-type "lrk" 'ead-emacs-config)

(provide 'pen-links)