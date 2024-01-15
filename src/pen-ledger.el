(require 'ledger-mode)
(require 'ledger-import)
(require 'flycheck-ledger)
(require 'company-ledger)
(add-to-list 'auto-mode-alist '("\\.ledger$" . ledger-mode))

;; https://hledger.org/
(require 'hledger-mode)
(require 'flymake-hledger)
(require 'flycheck-hledger)

;; I should be using hledger, not ledger
;; https://hledger.org/ledger.html


;; https://github.com/ledger/ledger
;; https://www.ledger-cli.org/

(provide 'pen-ledger)
