(require 'beacon)
(require 'cursor-flash)
(require 'nav-flash)

(defun pen-flash ()
  (interactive)
  ;; (nav-flash-show)
  (beacon-blink))

(provide 'pen-flash)
