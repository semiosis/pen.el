(package-initialize)

;; Auto install package are installed if they are missing
(setq package-list
      (append
       '(
         markdown-mode
          )
       (my/load-list-file
        "$HOME/var/smulliga/source/git/config/emacs/packages.txt")))

;; This one requires emacs25
;; lsp-javascript-typescript

;; fetch the list of packages available
(unless package-archive-contents
  (package-refresh-contents))

; install the missing packages
(dolist (package package-list)
  (unless (package-installed-p package)
    (yes (ignore-errors (package-install package)))))

(provide 'pen-packages)