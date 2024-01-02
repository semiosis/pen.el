(require 'wordnut)
(require 'define-it)

(df spv-wordnut () (pen-spv (concat "wu " (pen-selected-text))) (deactivate-mark))

(defun wordnut-lookup-current-word ()
  (interactive)
  (let (inline)
    (ignore-errors
      (wordnut--history-update-cur wordnut-hs))

    (setq inline (wordnut--lexi-link))
    (if inline
        (wordnut--lookup (car inline) (nth 1 inline) (nth 2 inline))
      (wordnut--lookup (current-word)))))

(defun dict-word (word)
  (interactive (list (pen-thing-at-point)))
  (if (>= (prefix-numeric-value current-prefix-arg) 4)
      (define-it word)
    (wordnut-lookup-current-word)))

(define-key wordnut-mode-map (kbd "M-9") 'dict-word)

(provide 'pen-wordnut)
