(require 'ledger-mode)
(require 'ledger-import)
(require 'hledger-mode)
;; https://hledger.org/

(require 'flymake-hledger)
(require 'flycheck-ledger)
(require 'flycheck-hledger)
(require 'company-ledger)

;; I should be using hledger, not ledger
;; https://hledger.org/ledger.html


;; https://github.com/ledger/ledger
;; https://www.ledger-cli.org/

;; (autoload 'ledger-mode "ledger-mode" "A major mode for Ledger" t)
;; (add-to-list 'load-path (expand-file-name "/path/to/ledger/source/lisp/"))

(add-to-list 'auto-mode-alist '("\\.ledger$" . ledger-mode))

(provide 'pen-ledger)
