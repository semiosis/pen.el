(defun ilambda-repl ()
  (interactive)

  ;; (comint-quick (pen-cmd "ilambda-sh") pen-prompts-directory)
  (pen-sps (pen-cmd "ilambda-sh")))

(defun ilambda-sh ()
  (interactive)
  (comint-quick (pen-cmd "ilambda-sh") pen-prompts-directory))

(provide 'pen-ilambda)
