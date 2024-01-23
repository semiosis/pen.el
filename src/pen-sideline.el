(require 'sideline)
(require 'sideline-lsp)
(require 'sideline-flymake)
(require 'sideline-flycheck)
(require 'sideline-blame)

;; (setq sideline-backends-right '(sideline-lsp))
(setq sideline-backends-right '(sideline-blame))

(provide 'pen-sideline)
