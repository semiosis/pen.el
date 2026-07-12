(require 'artist)

;; There is a bug where if I start drawing a line, but only use one click,
;; then press any keyboard key, there is an error.
;; (advice-add 'artist-set-arrow-points-for-poly :around #'ignore-errors-around-advice)
;; (advice-remove 'artist-set-arrow-points-for-poly #'ignore-errors-around-advice)

(advice-add 'artist-mouse-draw-poly :around #'ignore-errors-around-advice)
;; (advice-remove 'artist-mouse-draw-poly #'ignore-errors-around-advice)

;; (advice-add 'artist-down-mouse-1 :around #'ignore-errors-around-advice)
;; (advice-remove 'artist-down-mouse-1 #'ignore-errors-around-advice)

;; I also needed to silence this function so lots of data wouldn't
;; appear in the minibuffer after artist-mouse-draw-poly causes an error.
(advice-add 'artist-down-mouse-1 :around #'shut-up-around-advice)

(provide 'pen-artist)
