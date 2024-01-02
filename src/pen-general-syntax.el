(defset org-general-highlights
        ;; '(("Sin\\|Cos\\|Sum" . 'font-lock-function-name-face)
        ;;   ("Pi\\|Infinity" . 'font-lock-constant-face))

        '(("[A-Z]+" . 'font-lock-constant-face)))

(defun set-org-general-highlights ()
  (setq font-lock-defaults '(org-general-highlights))
  ;; j:font-lock-defaults
  ;; generates:
  ;; j:font-lock-keywords

  (save-excursion
    (goto-char (point-min))
    (search-forward "--- Entry -")
    (beginning-of-line)
    (let ((m (point))
          (p (point-max)))
      (font-lock-fontify-region m p)))
  ;; (font-lock-fontify-region)
  ;; (font-lock-update)
  )

(add-hook 'org-general-text-hook 'set-org-general-highlights)

(provide 'pen-general-syntax)
