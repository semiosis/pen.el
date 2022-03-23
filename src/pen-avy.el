(require 'avy)
(require 'ace-link)

(setq avy-all-windows nil)

;; For avy-goto-char-timer
(setq avy-timeout-seconds 0.2)

(defun avy-goto-char-all-windows (args)
  (interactive "P")
  (let ((avy-all-windows t))
    (call-interactively #'avy-goto-char)))

(defun avy-goto-char-enter ()
  "Go to a char with avy and then press 'Enter'"
  (interactive)
  (call-interactively #'avy-goto-char)
  (ekm "C-m"))

(defun avy-goto-char-9 ()
  "Go to a char with avy and then press M-9"
  (interactive)
  (call-interactively #'avy-goto-char)
  (ekm "M-9"))

(defun avy-goto-link-or-button-w ()
  "Go to a char with avy and then press 'w' for copy"
  (interactive)
  (call-interactively 'ace-link-goto-link-or-button)
  (if (not (eq (key-binding "w") 'self-insert-command))
      (ekm "w")
    (message "No button/link address here to copy")))

(defun avy-goto-char-doc ()
  "Go to a char with avy and then press 'M-9'"
  (interactive)
  (call-interactively #'avy-goto-char)
  (ekm "M-9"))

(defun avy-goto-char-goto-def ()
  "Go to a char with avy and then press 'M-.'"
  (interactive)
  (call-interactively #'avy-goto-char)
  (ekm "M-."))

(defun simulate-left-click ()
  (interactive)
  (pen-cl-sn "tmux run -b \"pen-tm mouseclick\"" :detach t))

(defun simulate-right-click ()
  (interactive)
  (pen-cl-sn "tmux run -b \"pen-tm mouseup -x -r\"" :detach t))

(defun avy-goto-char-left-click ()
  "Go to a char with avy and then left click with tmux.'"
  (interactive)
  (call-interactively #'avy-goto-char)
  (simulate-left-click))

(defun avy-goto-char-right-click ()
  "Go to a char with avy and then right click with tmux.'"
  (interactive)
  (call-interactively #'avy-goto-char)
  (simulate-right-click))

(defun avy-goto-char-c-o ()
  "Go to a char with avy and then type =C-c C-o=.'"
  (interactive)
  (call-interactively #'avy-goto-char)
  (ekm "C-c C-o"))

(defun avy-new-buffer-from-tmux-pane-capture ()
  (interactive)
  (with-current-buffer (pen-tmux-pane-capture t)
    (call-interactively 'avy-goto-char)))

(define-key pen-map (kbd "M-j u") 'avy-new-buffer-from-tmux-pane-capture)
(define-key pen-map (kbd "M-j M-u") 'avy-new-buffer-from-tmux-pane-capture)

(defun ace-link-goto-button ()
  (interactive)
  (avy-with ace-link-help
    (avy-process
     (mapcar #'cdr (buttons-collect))
     (avy--style-fn avy-style))))

(defun ace-link-goto-widget ()
  (interactive)
  (avy-with ace-link-help
    (avy-process
     (mapcar #'cdr (pen-widgets-collect))
     (avy--style-fn avy-style))))

(defun ace-link-or-button-collect ()
  (-union
   (-union (-union
            (ace-link--help-collect)
            (ace-link--org-collect))
           (buttons-collect))
   (pen-widgets-collect)))

(defun ace-link-goto-link-or-button ()
  (interactive)
  (avy-with ace-link-help
    (avy-process
     (mapcar #'cdr (ace-link-or-button-collect))
     (avy--style-fn avy-style))))

(defun ace-link-goto-glossary-button ()
  (interactive)
  (avy-with ace-link-help
    (avy-process
     (mapcar #'cdr (glossary-buttons-collect))
     (avy--style-fn avy-style))))

(defun ace-link-click-glossary-button ()
  (interactive)
  (ignore-errors
    (avy-with ace-link-help
      (avy-process
       (mapcar #'cdr (glossary-buttons-collect))
       (avy--style-fn avy-style)))
    (push-button)))

(defun ace-link-click-button ()
  (interactive)
  (avy-with ace-link-help
    (avy-process
     (mapcar #'cdr (buttons-collect))
     (avy--style-fn avy-style)))
  (push-button))

(defun ace-link-click-widget ()
  (interactive)
  (avy-with ace-link-help
    (avy-process
     (mapcar #'cdr (pen-widgets-collect))
     (avy--style-fn avy-style)))
  (widget-button-press (point)))

(define-key pen-map (kbd "M-j M-l") #'run-line-or-region-in-tmux)
(define-key pen-map (kbd "M-j M-i") #'ace-link)
(define-key pen-map (kbd "M-j M-g") 'ace-link-goto-link-or-button)
(define-key pen-map (kbd "M-j M-a") #'ace-link-click-glossary-button)
(define-key pen-map (kbd "M-j M-k") #'avy-goto-char-all-windows)
(define-key pen-map (kbd "M-j M-m") #'avy-goto-char-enter)
(define-key pen-map (kbd "M-j M-9") #'avy-goto-char-9)
(define-key pen-map (kbd "M-j M-w") #'avy-goto-link-or-button-w)
(define-key pen-map (kbd "M-j M-o") #'avy-goto-char-c-o)
(define-key pen-map (kbd "M-j M-9") #'avy-goto-char-doc)
(define-key pen-map (kbd "M-j M-.") #'avy-goto-char-goto-def)
(define-key pen-map (kbd "M-j M-x") #'avy-goto-char-left-click)
(define-key pen-map (kbd "M-j M-z") #'avy-goto-char-right-click)
(define-key pen-map (kbd "M-j M-j") #'avy-goto-symbol-1-below)
(define-key pen-map (kbd "M-j M-s") #'avy-isearch)

(defun avy-jump-around-advice (proc &rest args)
  (lsp-ui-doc-hide)
  (let ((res (apply proc args)))
    res))
(advice-add 'avy-jump :around #'avy-jump-around-advice)

;; This fixes the glossary sometimes
(advice-add 'avy--overlay :around #'ignore-errors-around-advice)

(defun link-hint-copy-link ()
  "Copy a visible link of a supported type to the kill ring with avy.
`select-enable-clipboard' and `select-enable-primary' can be set to non-nil
values to copy the link to the clipboard and/or primary as well."
  (interactive)
  (avy-with link-hint-copy-link
    (link-hint--one :copy)))

(defun link-hint--button-at-point-p ()
  "Return the button at the point or nil."
  (let ((button (button-at (point))))
    (when button
      (cond
       ((derived-mode-p 'org-brain-visualize-mode)
        (try (org-brain-get-path-for-child-name (org-brain-entry-name (org-brain-entry-from-id (button-get button 'id))))
             (and (button-get button 'id)
                  (org-brain-get-path-for-entry (button-label button)))
             (button-label button)))
       (t
        (button-label button))))))

(require 'ivy-avy)

(define-key ivy-minibuffer-map (kbd "M-k") 'ivy-avy)

(provide 'pen-avy)
