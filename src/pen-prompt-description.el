(require 'pen-lm-completers)

;; http://github.com/semiosis/prompts

(define-derived-mode prompt-description-mode yaml-mode "Prompt"
  "Prompt description mode")

(add-to-list 'auto-mode-alist '("\\.prompt\\'" . prompt-description-mode))

;; TODO Use pcase
;; https://www.gnu.org/software/emacs/manual/html_node/elisp/Destructuring-with-pcase-Patterns.html
(defun pen-create-prompt (tuple)
  (interactive (list (pen-select-completion-backend)))
  (pcase-let ((`(,title ,script ,engine-list ,available) tuple))
    (etv available)))

(provide 'pen-prompt-description)