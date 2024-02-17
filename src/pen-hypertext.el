;; v +/"hypertext-mode" "$EMACSD/pen.el/src/pen-manage-minor-mode.el"

;; https://dantorop.info/project/emacs-animation/

(define-derived-mode hypertext-mode fundamental-mode "Hypertext"
  "Mode for clickable ascii text graphics.
\\{hypertext-mode-map}"
  (setq buffer-read-only t)
  (buffer-disable-undo))

(provide 'pen-hypertext)
