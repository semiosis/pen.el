(require 'tetris)

;; DISCARD This means that tetris works properly in the terminal
;; (setq tetris-use-glyphs nil)

;; It's the time period. The closer to 0, the faster.
(defun pen-tetris-update-speed-function (_shapes rows)
  ;; (/ 20.0 (+ 50.0 rows))
  (/ 20.0 (+ 40.0 rows)))

(custom-set-variables
 '(tetris-width 10)
 '(tetris-height 25)
 '(tetris-buffer-width 30)
 '(tetris-buffer-height 27)
 '(tetris-update-speed-function 'pen-tetris-update-speed-function))


;; This fixes tetris in the terminal. It was displaying control characters
(defun tetris-init-buffer-around-advice (proc &rest args)
  (let ((res (apply proc args)))
    (split-window-right)
    (delete-window)
    res))
(advice-add 'tetris-init-buffer :around #'tetris-init-buffer-around-advice)

(provide 'pen-tetris)