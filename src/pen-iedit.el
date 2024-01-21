(require 'iedit)

(advice-add 'iedit--quit :around #'ignore-errors-around-advice)

(define-key iedit-mode-occurrence-keymap (kbd "M-#") #'iedit-number-occurrences)
(define-key iedit-mode-occurrence-keymap (kbd "M-N") nil)

(define-key iedit-mode-keymap (kbd "C-h") 'hungry-delete-backward)

(defun iedit-regexp-quote (exp)
  "Return a regexp string."
  (cl-case iedit-occurrence-type-local
    ('symbol (concat "\\_<" (regexp-quote exp) "\\_>"))
    ('word   (concat "\\<" (regexp-quote exp) "\\>"))
    ('regexp exp)
    ;; ( t      (regexp-quote exp))
    ( t      (concat "\\<" (regexp-quote exp) "\\>"))))

(define-key iedit-mode-occurrence-keymap (kbd "M-i") 'iedit--quit)
(define-key iedit-mode-keymap (kbd "M-i") 'iedit--quit)

;; Lispy-iedit was a little out of date. this fixed it
(defun lispy-iedit (&optional arg)
  "Wrap around `iedit'."
  (interactive "P")
  (require 'iedit)
  (if iedit-mode
      (progn
        (iedit--quit))
    (progn
      (when (lispy-left-p)
        (forward-char 1))
      (if arg
          (progn
            (setq current-prefix-arg arg)
            (iedit-mode))
        (iedit-mode)))))

;; This inverts the prefix.
;; It's a bit different from the one on my host machine.
;; Something is different in Pen emacs
(defun iedit-mode-around-advice (proc &optional arg)
  (cond
   ((equal current-prefix-arg (list 4)) (setq current-prefix-arg (list 0)))
   ;; ((not current-prefix-arg) (setq current-prefix-arg (list 4)))
   )

  ;; This is not propagating current-prefix-arg

  (setq arg (or arg current-prefix-arg))
  ;; (tv (str arg))

  (let ((res (apply proc (list arg))))
    res))
(advice-add 'iedit-mode :around #'iedit-mode-around-advice)

(define-key iedit-mode-occurrence-keymap (kbd "H-\"") 'iedit-show/hide-context-lines)
(define-key iedit-mode-keymap (kbd "H-\"") 'iedit-show/hide-context-lines)
;; (define-key iedit-mode-occurrence-keymap (kbd "H-\"") 'iedit-show/hide-unmatched-lines)
;; (define-key iedit-mode-keymap (kbd "H-\"") 'iedit-show/hide-unmatched-lines)
(define-key global-map (kbd "H-\"") 'iedit-enter-and-show-all)

(defun iedit-stop-and-isearch ()
  (interactive)
  (let ((edit t)
        (pat (iedit-current-occurrence-string)))
    (iedit--quit)
    (isearch-exit)
    (isearch-update-ring pat)
    (isearch-update-ring pat t)
    (let ((isearch-mode-end-hook-quit (not edit)))
      (run-hooks 'isearch-mode-end-hook))

    (if (/= (point) isearch-opoint)
        (or (and transient-mark-mode mark-active)
	        (progn
	          (push-mark isearch-opoint t)
	          (or executing-kbd-macro (> (minibuffer-depth) 0) edit
		          (message "Mark saved where search started")))))

    (and (not edit) isearch-recursive-edit (exit-recursive-edit))

    (while (not (looking-at-p pat))
      (backward-char 1))
    (set-mark (point))
    (forward-char (length pat))))
(define-key iedit-mode-keymap (kbd "M-*") 'iedit-stop-and-isearch)

(defun iedit-enter-and-show-all ()
  (interactive)
  (if (not iedit-mode)
      (call-interactively 'iedit-mode))
  ;; (iedit-show/hide-unmatched-lines)
  ;; (iedit-show/hide-occurrence-lines)
  (iedit-show/hide-context-lines))

(defun iedit-regexp-quote (exp)
  "Return a regexp string."
  (cl-case iedit-occurrence-type-local
    ('symbol (concat "\\_<" (regexp-quote exp) "\\_>"))
    ('word (concat "\\<" (regexp-quote exp) "\\>"))
    ('regexp exp)
    (t (regexp-quote exp))))

(advice-add 'iedit-current-occurrence-string :around #'ignore-errors-around-advice)

(defun around-advice-preserve-clipboard (proc &rest args)
  (let ((clipboard (xc))
        (res (apply proc args)))
    (xc clipboard)
    res))
(advice-add 'iedit--quit :around #'around-advice-preserve-clipboard)
;; (advice-remove 'iedit--quit #'around-advice-preserve-clipboard)

(provide 'pen-iedit)
