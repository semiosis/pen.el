(when (package-installed-p 'hyperdrive)
       (global-set-key (kbd "H-r") #'hyperdrive-menu)
       (hyperdrive-menu-bar-mode 1))

(provide 'pen-hyperdrive)
