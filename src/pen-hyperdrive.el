(when (package-installed-p 'hyperdrive)
       (global-set-key (kbd "C-c h") #'hyperdrive-menu)
       (hyperdrive-menu-bar-mode 1))

(provide 'pen-hyperdrive)
