(require 'topsy)

(add-hook 'prog-mode-hook #'topsy-mode)
(add-hook 'magit-section-mode-hook #'topsy-mode)

(provide 'pen-topsy)
