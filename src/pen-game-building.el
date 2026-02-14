(require 'gamegrid)

(defcustom tetris-buffer-width 30
  "Width of used portion of buffer."
  :type 'natnum)

(defcustom tetris-buffer-height 22
  "Height of used portion of buffer."
  :type 'natnum)

(defconst tetris-blank 7)

(defconst tetris-border 8)

(defconst tetris-space 9)

(defun tetris-init-buffer ()
  (gamegrid-init-buffer tetris-buffer-width
                        tetris-buffer-height
                        tetris-space)

  (let ((buffer-read-only nil))
    (cl-loop for y from -1 to tetris-height do
             (cl-loop for x from -1 to tetris-width do
                      (gamegrid-set-cell (+ tetris-top-left-x x)
                                         (+ tetris-top-left-y y)
                                         tetris-border)))

    (dotimes (y tetris-height)
      (dotimes (x tetris-width)
        (gamegrid-set-cell (+ tetris-top-left-x x)
                           (+ tetris-top-left-y y)
                           tetris-blank)))

    (cl-loop for y from -1 to 4 do
             (cl-loop for x from -1 to 4 do
                      (gamegrid-set-cell (+ tetris-next-x x)
                                         (+ tetris-next-y y)
                                         tetris-border)))))


(provide 'pen-game-building)
