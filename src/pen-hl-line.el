(require 'hl-line)

;; This doesn't seem to work anyway
(comment
 ;; Disable hl-line-mode for term
 (defun hl-line-mode-around-advice (proc &rest args)
   (if (and (not (major-mode-p 'term-mode))
            (not (major-mode-p 'crossword-mode))
            (not (major-mode-p 'ascii-adventures-mode))
            (not (major-mode-p 'eshell-mode)))
       (let ((res (apply proc args)))
         res)))
 (advice-add 'global-hl-line-highlight :around #'hl-line-mode-around-advice)
 (advice-remove 'global-hl-line-highlight :around #'hl-line-mode-around-advice)
 (advice-add 'hl-line-highlight :around #'hl-line-mode-around-advice)
 (advice-remove 'hl-line-highlight :around #'hl-line-mode-around-advice))
(provide 'pen-hl-line)
