(require 'ledger-mode)
(require 'ledger-import)
(require 'flycheck-ledger)
(require 'company-ledger)
(add-to-list 'auto-mode-alist '("\\.ledger$" . ledger-mode))

;; [[info:(ledger-mode) Top]]

;; https://hledger.org/
(require 'hledger-mode)
(require 'flymake-hledger)
(require 'flycheck-hledger)

;; I should be using hledger, not ledger
;; https://hledger.org/ledger.html

;; But there is no info page for hledger
;; https://hledger.org/1.32/hledger.html

;; https://github.com/ledger/ledger
;; https://www.ledger-cli.org/

;; I think I will start with ledger and move to hledger
;; This is so I can learn ledger from the info page

(provide 'pen-ledger)
