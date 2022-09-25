(defun ilambda-repl ()
  (interactive)

  ;; This does work
  ;; (pen-sps (pen-cmd "ilambda-sh"))

  (comint-quick (pen-cmd "ilambda-sh") pen-prompts-directory))

(provide 'pen-ilambda)
