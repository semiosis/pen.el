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

;; This inverts the prefix arg
(defun iedit-mode-around-advice (proc &rest args)
  (cond
   ((equal current-prefix-arg (list 4)) (setq current-prefix-arg nil))
   ((not current-prefix-arg) (setq current-prefix-arg (list 4))))

  (let ((res (apply proc args)))
    res))
(advice-add 'iedit-mode :around #'iedit-mode-around-advice)

(define-key iedit-mode-occurrence-keymap (kbd "H-\"") 'iedit-show/hide-unmatched-lines)
(define-key iedit-mode-keymap (kbd "H-\"") 'iedit-show/hide-unmatched-lines)
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
  (iedit-show/hide-unmatched-lines))

(defun iedit-regexp-quote (exp)
  "Return a regexp string."
  (cl-case iedit-occurrence-type-local
    ('symbol (concat "\\_<" (regexp-quote exp) "\\_>"))
    ('word (concat "\\<" (regexp-quote exp) "\\>"))
    ('regexp exp)
    (t (regexp-quote exp))))

(advice-add 'iedit-current-occurrence-string :around #'ignore-errors-around-advice)

(provide 'pen-iedit)