(require 'pen-lsp)

(defun lsp-ui-doc--inline ()
  "Display the doc in the buffer."
  (-let* ((height (lsp-ui-doc--inline-height))
          ((start . end) (lsp-ui-doc--inline-pos height))
          ;; ((start . end) `(,(+ start (window-hscroll)) . ,end))
          (buffer-string (buffer-substring start end))
          (ov (if (overlayp lsp-ui-doc--inline-ov) lsp-ui-doc--inline-ov
                (setq lsp-ui-doc--inline-ov (make-overlay start end)))))
    ;; (move-overlay ov (+ start (window-hscroll))
    ;;               (+ end (window-hscroll)))
    
    ;; Sadly, overlays don't do hscroll well
    ;; I think I need to edit more code
    (move-overlay ov start end)
    (overlay-put ov 'face 'default)
    (overlay-put ov 'display (lsp-ui-doc--inline-merge buffer-string))
    (overlay-put ov 'lsp-ui-doc-inline t)
    (overlay-put ov 'window (selected-window))))

(defun pen-custom-lsp-ui-doc-display (multiline-doc-string symbol-string)
  (progn
    (lsp-ui-doc--highlight-hover)
    (lsp-ui-doc--render-buffer multiline-doc-string symbol-string)
    (lsp-ui-doc--inline-p)
    (lsp-ui-doc--inline)
    (setq lsp-ui-doc--from-mouse lsp-ui-doc--from-mouse-current)))

(provide 'pen-custom-lsp-ui-doc)
