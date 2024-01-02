(require 'keycast)

;; keycast-mode-line-mode shows the current binding at the bottom of the selected window, in its mode line.
;; keycast-header-line-mode shows the current binding at the top of the selected window, in its header line.
;; keycast-tab-bar-mode shows the current binding at the top of the selected frame, in its tab bar.
;; keycast-log-mode displays a list of recent bindings in a dedicated frame.

;; (keycast-mode-line-mode t)
;; (keycast-header-line-mode t)

;; Displaying it with tab-bar-mode is the best, I think.
;; (keycast-tab-bar-mode t)
(comment
 (keycast-tab-bar-mode t)
 (keycast-tab-bar-mode -1))

(provide 'pen-keycast)
