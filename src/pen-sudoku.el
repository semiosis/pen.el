(require 'sudoku)

(define-key sudoku-mode-map (kbd "j") 'sudoku-move-point-down)
(define-key sudoku-mode-map (kbd "k") 'sudoku-move-point-up)
(define-key sudoku-mode-map (kbd "h") 'sudoku-move-point-left)
(define-key sudoku-mode-map (kbd "l") 'sudoku-move-point-right)

(define-key sudoku-mode-map (kbd "t") 'sudoku-hint)

(provide 'pen-sudoku)
