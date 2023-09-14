(require 'hl-line)

;; Disable hl-line-mode for term
(defun hl-line-mode-around-advice (proc &rest args)
  (if (and (not (major-mode-p 'term-mode))
           (not (major-mode-p 'crossword-mode)))
      (let ((res (apply proc args)))
        res)))
(advice-add 'global-hl-line-highlight :around #'hl-line-mode-around-advice)
(advice-remove 'global-hl-line-highlight :around #'hl-line-mode-around-advice)

(provide 'pen-hl-line)
