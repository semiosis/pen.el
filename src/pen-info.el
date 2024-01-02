(require 'info)
(require 'helm)
(require 'helm-info)

(defun Info-summary ()
  "Display a brief summary of all Info commands."
  (interactive)
  (tv (documentation 'Info-mode)))

;; Remember that H-w points to get-path

(define-key Info-mode-map (kbd "w") 'Info-copy-current-node-name)
;; (define-key Info-mode-map (kbd "w") 'get-path)

;; info-setup

(advice-add 'Info-select-node :around #'around-advice-buffer-erase-trailing-whitespace-advice)

;; combine multiple sources from helm-info
(defun ap/helm-info-emacs-elisp-cl ()
  "Helm for Emacs, Elisp, and CL-library info pages."
  (interactive)
  (helm :sources '(helm-source-info-emacs
                   helm-source-info-elisp
                   helm-source-info-cl)))

;; j:hc-highlight-tabs

(defun font-lock-set-keywords-from-defaults (&optional force)
  "This forces font-lock to work from the defaults."
  (interactive)
  (if force
      (setq font-lock-keywords (eval (car font-lock-defaults)))
    (font-lock-add-keywords nil info-highlights 'APPEND)))

;; (etv (pps font-lock-keywords))

(progn
  ;; I haven't yet worked out why these highlights don't work especially well
  ;; [[info:(elisp) Prefix Command Arguments]]
  ;; How do I make syntax highlights which ignore the initial bit
  ;; such as Function: ?
  (defset info-highlights
          '((" Variable: [^ ]*" . 'font-lock-constant-face)
            (" Macro: [^ ]*" . 'font-lock-builtin-face)
            ;; ("\\(?: Function: \\)[^ ]*" . 'font-lock-warning-face)
            ;; ("^      *['(].*" . 'info-code-face)
            ;; ("^      *.*" . 'info-code-face)
            (" Function: [^ ]*" . 'font-lock-warning-face)
            ("^\\**" . 'info-menu-star)
            (" [0-9]+\\. " . 'info-bold)
            ;; [[info:(org-super-agenda) Usage]]
            ;; For example: *Note:*
            (" \\*[^*]+\\* " . 'info-bold)
            ;; [[info:(org) Feedback]]
            ;; For example: M-x org-submit-bug-report <RET>
            (" M-x .*" . 'info-bullet-point)
            ;; [[info:(org) Feedback]]
            ;; For example: $ emacs -Q -l /path/to/minimal-org.el
            ("^ +\\$ .*" . 'info-bullet-point)
            ("^ +(.*" . 'info-bullet-point)
            ;; For example: :after magit
            ;; [[info:(magithub) Installation]]
            ("^ +:.*" . 'info-bullet-point)
            ("^ +.*)$" . 'info-bullet-point)
            ("•" . 'info-menu-star)
            ;; ("‘[^’]*’" . 'font-lock-warning-face)
            ;; ("‘.*’" . 'font-lock-warning-face)
            ;; ("[^[:ascii:]]C-" . 'font-lock-warning-face)
            ;; ("C-" . 'font-lock-warning-face)
            ;; ("[^[:ascii:]].*[^[:ascii:]]" . 'font-lock-comment-face)
            ;; ‘diary-file’
            ("[\u2018][^\u2019]*[\u2019]" . 'font-lock-comment-face)
            ;; “diary file”
            ("[\u201C][^\u201D]*[\u201D]" . 'font-lock-comment-face)
            (" Command: [^ ]*" . 'font-lock-keyword-face)))

  (defun set-info-highlights ()
    (setq font-lock-defaults '(info-highlights))
    (font-lock-set-keywords-from-defaults t)

    ;; j:font-lock-defaults
    ;; generates:
    ;; j:font-lock-keywords

    (ignore-errors
      (save-excursion
        (goto-char (point-min))
        (search-forward "=====")
        (beginning-of-line)
        (let ((m (point))
              (p (point-max)))
          (font-lock-fontify-region m p))))
    ;; (with-buffer-region-beg-end (font-lock-fontify-region beg end))
    ;; (font-lock-update)
    )

  ;; (add-hook 'org-brain-after-visualize-hook 'set-info-highlights)
  ;; (remove-hook 'org-brain-after-visualize-hook 'set-info-highlights)
  (add-hook 'Info-selection-hook 'set-info-highlights))

(defsetface info-code-face
  '((t
     ;; :foreground "#d2268b"
     :foreground "#777777"
     ;; :background "#2e2e2e"
     ;; :weight bold
     ;; :underline t
     ))
  "Face for info code blocks."
  :group 'info)

(defsetface info-bullet-point
            '((t
               ;; :foreground "#d2268b"
               :foreground "#777777"
               ;; :background "#2e2e2e"
               ;; :weight bold
               ;; :underline t
               ))
            "Face for info code blocks."
            :group 'info)

(defsetface info-bold
            '((t
               ;; :foreground "#d2268b"
               :foreground "#cc9977"
               :background "#4e2e2e"
               ;; :weight bold
               ;; :underline t
               ))
            "Face for info code blocks."
            :group 'info)

(defsetface info-menu-star
            '((((class color)) :foreground "#222222")
              (t :underline t))
  "Face used to emphasize `*' in an Info menu.
The face is assigned to the third, sixth, and ninth `*' for easier
orientation.  See `Info-nth-menu-item'.")

(provide 'pen-info)
