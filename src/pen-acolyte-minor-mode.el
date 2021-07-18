(defvar pen-acolyte-minor-mode-map (make-sparse-keymap)
  "Keymap for `pen-acolyte-minor-mode'.")

;;;###autoload
(define-minor-mode pen-acolyte-minor-mode
  "A minor mode for Pen.el acolytes."
  :lighter " ☻"
  :keymap pen-acolyte-minor-mode-map)

;;;###autoload
(define-globalized-minor-mode global-pen-acolyte-minor-mode pen-acolyte-minor-mode pen-acolyte-minor-mode)