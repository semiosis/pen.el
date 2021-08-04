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

;; TODO Create a hydra instead of using acolyte-mode

(defalias 'yn 'yes-or-no-p)

(defun pen-delete-frame ()
  (interactive)
  (cond
   ((>= (prefix-numeric-value current-prefix-arg) 4)
    (pen-kill-emacs))
   (t (if (yn "Close Pen frame?")
          (delete-frame)))
   ;; I need a better way of checking for the main frame
   ;; ((= (length (frame-list)) 1)
   ;;  (if (yn "Quit Pen?")
   ;;      (delete-frame)))
   ;; (t (delete-frame))
   ))

(defun pen-kill-emacs ()
  (interactive)
  (cond
   (t (if (yn "Quit emacs?")
          (kill-emacs)))))

(define-key pen-acolyte-minor-mode-map (kbd "M-q") 'pen-delete-frame)
(define-key pen-acolyte-minor-mode-map (kbd "M-Q") 'pen-kill-emacs)
(define-key pen-acolyte-minor-mode-map (kbd "M-p") 'pen-acolyte-dired-prompts)
(define-key pen-acolyte-minor-mode-map (kbd "M-t") 'pen-acolyte-scratch)
(define-key pen-acolyte-minor-mode-map (kbd "M-s") 'save-buffer)
(define-key pen-acolyte-minor-mode-map (kbd "M-L") 'pen-show-last-prompt)
(define-key pen-acolyte-minor-mode-map (kbd "M-r") 'pen-run-prompt-function)
(define-key pen-acolyte-minor-mode-map (kbd "M-1") #'pen-company-filetype-word)
(define-key pen-acolyte-minor-mode-map (kbd "M-2") #'pen-company-filetype-words)
(define-key pen-acolyte-minor-mode-map (kbd "M-3") #'pen-company-filetype-line)
(define-key pen-acolyte-minor-mode-map (kbd "M-4") #'pen-company-filetype-long)
(define-key pen-acolyte-minor-mode-map (kbd "M-j") #'pf-gpt-j)
(define-key pen-acolyte-minor-mode-map (kbd "M-u") 'global-argument)
(define-key pen-acolyte-minor-mode-map (kbd "M-o") 'pen-add-key-openai)
(define-key pen-acolyte-minor-mode-map (kbd "M-a") 'pen-add-key-aix)

;; M-TAB
(define-key pen-acolyte-minor-mode-map (kbd "M-TAB") 'pen-company-filetype)
(define-key pen-acolyte-minor-mode-map (kbd "C-M-i") 'pen-company-filetype)
(define-key pen-acolyte-minor-mode-map (kbd "<insertchar>") 'pen-company-filetype)

(define-key pen-acolyte-minor-mode-map (kbd "M-l") 'pen-complete-long)
(define-key pen-acolyte-minor-mode-map (kbd "M-g") 'pen-generate-prompt-functions)
(define-key pen-acolyte-minor-mode-map (kbd "M-c") 'fz-pen-counsel)
(define-key pen-acolyte-minor-mode-map (kbd "M-m") 'right-click-context-menu)
(define-key pen-acolyte-minor-mode-map (kbd "M-f") 'pen-filter-with-prompt-function)

(provide 'pen-acolyte-minor-mode)