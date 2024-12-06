(require 'beacon)
(require 'cursor-flash)
(require 'nav-flash)

(comment
 (require 'mode-line-bell)

 (defun mode-line-bell--begin-flash ()
   "Begin flashing the mode line."
   (unless mode-line-bell--flashing
     (invert-face 'mode-line)
     (setq mode-line-bell--flashing t)))

 (defun mode-line-bell--end-flash ()
   "Finish flashing the mode line."
   (when mode-line-bell--flashing
     (invert-face 'mode-line)
     (setq mode-line-bell--flashing nil))))

(defun pen-flash ()
  (interactive)
  ;; (nav-flash-show)
  (beacon-blink))

(provide 'pen-flash)
