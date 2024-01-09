(require 'mini-header-line)
(require 'minibuffer-header)
(require 'path-headerline-mode)

(path-headerline-mode t)
(path-headerline-mode -1)

;; This places the modeline up the top, just below the tab bar
;; but it has a different
;; (mini-header-line-mode t)
;; (mini-header-line-mode -1)

(minibuffer-header-mode t)

(provide 'pen-header-line)
