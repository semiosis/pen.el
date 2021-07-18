(defvar pen-acolyte-minor-mode-map (make-sparse-keymap)
  "Keymap for `pen-acolyte-minor-mode'.")

;;;###autoload
(define-minor-mode pen-acolyte-minor-mode
  "A minor mode for Pen.el acolytes."
  :lighter " ☻"
  :keymap pen-acolyte-minor-mode-map)

;;;###autoload
(define-globalized-minor-mode global-pen-acolyte-minor-mode pen-acolyte-minor-mode pen-acolyte-minor-mode)

;; code for toggling global-pen-acolyte-minor-mode
(defun see (data &optional duration)
 ""
 (interactive)
 (message (prin1-to-string data))
 (sit-for (if duration duration 2.0))
 data)

(defun global-pen-acolyte-minor-mode-toggle ()
 ""
 (interactive)
 (if global-pen-acolyte-minor-mode
  (global-pen-acolyte-minor-mode-off)
  (global-pen-acolyte-minor-mode-on)))

(defun global-pen-acolyte-minor-mode-on ()
 ""
 (interactive)
 (global-pen-acolyte-minor-mode 1)
 (see "turned on global pen-acolyte-minor mode"))

(defun global-pen-acolyte-minor-mode-off ()
 ""
 (interactive)
 (global-pen-acolyte-minor-mode 0)
 (see "turned on global pen-acolyte-minor mode")


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
