(defvar pen-acolyte-minor-mode-map (make-sparse-keymap)
  "Keymap for `pen-acolyte-minor-mode'.")

;;;###autoload
(define-minor-mode pen-acolyte-minor-mode
  "A minor mode for Pen.el acolytes."
  :lighter " ☻"
  :keymap pen-acolyte-minor-mode-map)

;;;###autoload
(define-globalized-minor-mode global-pen-acolyte-minor-mode pen-acolyte-minor-mode pen-acolyte-minor-mode)

;; Please use H-. to toggle acolyte mode

(define-key pen-acolyte-minor-mode-map (kbd "M-p") 'pen-super-newb-dired-prompts)
(define-key pen-acolyte-minor-mode-map (kbd "M-t") 'pen-super-newb-scratch)
(define-key pen-acolyte-minor-mode-map (kbd "M-s") 'save-buffer)
(define-key pen-acolyte-minor-mode-map (kbd "M-r") 'pen-run-prompt-function)
(define-key pen-acolyte-minor-mode-map (kbd "M-TAB") 'pen-company-filetype)
(define-key pen-acolyte-minor-mode-map (kbd "M-l") 'pen-complete-long)
(define-key pen-acolyte-minor-mode-map (kbd "M-g") 'pen-generate-prompt-functions)
(define-key pen-acolyte-minor-mode-map (kbd "M-c") 'fz-pen-counsel)
(define-key pen-acolyte-minor-mode-map (kbd "M-m") 'right-click-context-menu)
(define-key pen-acolyte-minor-mode-map (kbd "M-f") 'pen-filter-with-prompt-function)

(provide 'pen-acolyte-minor-mode)