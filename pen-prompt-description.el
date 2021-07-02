;; http://github.com/semiosis/prompts

(define-derived-mode prompt-description-mode yaml-mode "Prompt"
  "Prompt description mode")

(add-to-list 'auto-mode-alist '("\\.prompt\\'" . prompt-description-mode))

;; I would like to disable the yaml lsp server for .prompt files.
;; At least, until a schema for it is made in schemastore
(defun maybe-lsp ()
  "Maybe run lsp."
  (interactive)
  (cond
   ((major-mode-p 'prompt-description-mode)
    (message "Disabled lsp for prompts"))
   (t (call-interactively 'lsp))))

(provide 'pen-prompt-description)