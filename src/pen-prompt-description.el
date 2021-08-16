(require 'pen-lm-completers)

;; http://github.com/semiosis/prompts

(define-derived-mode prompt-description-mode yaml-mode "Prompt"
  "Prompt description mode")

(add-to-list 'auto-mode-alist '("\\.prompt\\'" . prompt-description-mode))

;; TODO Use pcase
;; https://www.gnu.org/software/emacs/manual/html_node/elisp/Destructuring-with-pcase-Patterns.html
;; What about these?
;; yas--template-expand-env
;; yas--snippet-expand-env
(defun pen-create-prompt ()
  (pcase-let ((`(,title ,script ,engine-list ,available) (pen-select-completion-backend))
              ;; Suggest other parameters based on existing prompts in personal repository?
              )
    ;; Encode into snippet value extractors for the wizard
    (pen-etv available)))

(provide 'pen-prompt-description)