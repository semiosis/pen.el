(define-derived-mode hypertext-mode fundamental-mode "Hypertext"
  "Mode for clickable ascii text graphics.
\\{hypertext-mode-map}"
  (setq buffer-read-only t)
  (buffer-disable-undo))

(provide 'pen-hypertext)
