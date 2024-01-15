(require 'ledger-mode)
(require 'ledger-import)
(require 'flycheck-ledger)
(require 'company-ledger)

;; https://hledger.org/
(require 'hledger-mode)
(require 'flymake-hledger)
(require 'flycheck-hledger)


;; I should be using hledger, not ledger
;; https://hledger.org/ledger.html


;; https://github.com/ledger/ledger
;; https://www.ledger-cli.org/

;; (autoload 'ledger-mode "ledger-mode" "A major mode for Ledger" t)
;; (add-to-list 'load-path (expand-file-name "/path/to/ledger/source/lisp/"))

(add-to-list 'auto-mode-alist '("\\.ledger$" . ledger-mode))

(provide 'pen-ledger)
