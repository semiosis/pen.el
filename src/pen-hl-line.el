(require 'hl-line)

;; This didn't quite work to remove the highlighted line
;; From term running nvc ghci
(defun hl-line-highlight ()
  "Activate the Hl-Line overlay on the current line."
  (if hl-line-mode       ; Might be changed outside the mode function.
      (if (not (major-mode-p 'term-mode))
          (progn
            (unless hl-line-overlay
              (setq hl-line-overlay (hl-line-make-overlay))) ; To be moved.
            (overlay-put hl-line-overlay
                         'window (unless hl-line-sticky-flag (selected-window)))
	    (hl-line-move hl-line-overlay)))
    (hl-line-unhighlight)))

(provide 'pen-hl-line)
