(require 'pen-lm-completers)

;; http://github.com/semiosis/prompts

(define-derived-mode prompt-description-mode yaml-mode "Prompt"
  "Prompt description mode")

(add-to-list 'auto-mode-alist '("\\.prompt\\'" . prompt-description-mode))

;; TODO Use pcase
;; https://www.gnu.org/software/emacs/manual/html_node/elisp/Destructuring-with-pcase-Patterns.html
(defun pen-create-prompt ()
  (pcase-let ((`(,title ,script ,engine-list ,available) (pen-select-completion-backend)))
    (etv available)))

(provide 'pen-prompt-description)