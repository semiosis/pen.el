(require 'ledger-mode)
(require 'ledger-import)
(require 'flycheck-ledger)
(require 'company-ledger)
(add-to-list 'auto-mode-alist '("\\.ledger$" . ledger-mode))

;; ledger seems to just work, where hledger-mode has problems
;; e:/volumes/home/shane/var/smulliga/source/git/ledger/ledger/test/input/demo.ledger

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

;;; Basic configuration
(require 'hledger-mode)

;; OK, so I simply need to get hledger working well in emacs
;; https://raw.githubusercontent.com/narendraj9/hledger-mode/master/_assets/new_demo.gif

;; To open files with .journal extension in hledger-mode
(add-to-list 'auto-mode-alist '("\\.journal\\'" . hledger-mode))

;; Provide the path to you journal file.
;; The default location is too opinionated.
(setq hledger-jfile "/volumes/home/shane/var/smulliga/source/git/simonmichael/hledger/examples/budgeting/forecast-budget-1.journal")

;;; Auto-completion for account names
;; For company-mode users,
(add-to-list 'company-backends 'hledger-company)

;; For auto-complete users,
(add-to-list 'ac-modes 'hledger-mode)
(add-hook 'hledger-mode-hook
    (lambda ()
        (setq-local ac-sources '(hledger-ac-source))))

;; For easily adjusting dates.
(define-key hledger-mode-map (kbd "<kp-add>") 'hledger-increment-entry-date)
(define-key hledger-mode-map (kbd "<kp-subtract>") 'hledger-decrement-entry-date)

;; Personal Accounting
(global-set-key (kbd "C-c e") 'hledger-jentry)
(global-set-key (kbd "C-c j") 'hledger-run-command)

(provide 'pen-ledger)
