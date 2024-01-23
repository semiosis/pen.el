(require 'pen-lsp)

(defun pen-custom-lsp-ui-doc-display (multiline-doc-string symbol-string)
  (progn
    (lsp-ui-doc--highlight-hover)
    (lsp-ui-doc--render-buffer multiline-doc-string symbol-string)
    (lsp-ui-doc--inline-p)
    (lsp-ui-doc--inline)
    (setq lsp-ui-doc--from-mouse lsp-ui-doc--from-mouse-current)))

(provide 'pen-custom-lsp-ui-doc)
