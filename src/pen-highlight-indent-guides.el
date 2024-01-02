(require 'highlight-indent-guides)

;; I've stopped liking this, so I've disabled it this way
;; It interferes with whitespace-mode
(defun highlight-indent-guides-mode-around-advice (proc &rest args)
  (comment
   (let ((res (apply proc args)))
     res)))
(advice-add 'highlight-indent-guides-mode :around #'highlight-indent-guides-mode-around-advice)
;; (advice-remove 'highlight-indent-guides-mode #'highlight-indent-guides-mode-around-advice)

(setq highlight-indent-guides-method 'column)

(set-face-background 'highlight-indent-guides-even-face nil)
(set-face-background 'highlight-indent-guides-odd-face "#202020")

;; This prevents the highlighting from resetting
(setq highlight-indent-guides-auto-enabled nil)

(provide 'pen-highlight-indent-guides)
