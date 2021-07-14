;; http://github.com/semiosis/prompts

(define-derived-mode prompt-description-mode yaml-mode "Prompt"
  "Prompt description mode")

(add-to-list 'auto-mode-alist '("\\.prompt\\'" . prompt-description-mode))

(provide 'pen-prompt-description)