(require 'pen-openai)

(defset pen-completion-backends
  ;; name completion command and a list of engines
  `(("OpenAI GPT-3" "openai-complete.sh" ,(pen-openai-list-engines))))

(defun pen-select-completion-backend ()
  (interactive)
  (let ((options
         (flatten-once
          (loop for trip in pen-completion-backends collect
                (pen-cartesian-product (list (car trip)) (list (nth 1 trip)) (nth 2 trip))))))
    (fz options)))

(provide 'pen-lm-completers)