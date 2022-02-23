(defun pen-turn-on-selected-minor-mode ()
  (interactive)

  (selected-minor-mode -1)
  (selected-region-active-mode -1)
  (selected-minor-mode 1))

(define-globalized-minor-mode
  global-selected-minor-mode selected-minor-mode pen-turn-on-selected-minor-mode)
(global-selected-minor-mode t)

(defun filter-region-through-external-script ()
  "docstring"
  (interactive)
  (if (region-active-p)
      (let ((script
             (read-string "!")))
        (region-pipe script))))

(defun selected-backspace-delete-and-deselect ()
  (interactive)
  (ekm "")
  (deactivate-mark))

(defun open-region-untitled ()
  (interactive)
  (new-buffer-from-string
   (pen-selected-text))
  (save-temp-if-no-file)
  (deactivate-mark))

(defun pen-selected-kill-rectangle ()
  (interactive)
  ;; (call-interactively 'kill-rectangle)
  (if (bound-and-true-p lispy-mode)
      (let ((selected-minor-mode nil)
            (selected-region-active-mode nil))
        (ekm "D"))
    (call-interactively 'kill-rectangle)))

(defun goto-thing-at-point ()
  (interactive)
  (j (intern (pen-thing-at-point))))

(require 'mc-edit-lines)

(defun selected-keyboard-quit ()
  "keyboard-quit and turn off selected mode"
  (interactive)
  (ignore-errors
    (selected-off))
  (deactivate-mark))

(defun get-vimlinks-url ()
  (interactive)
  (if mark-active
      (pen-copy (se show (concat "vim +/\"" (escape "\`\"$*[]" (pen-selected-text)) "\" " (pen-q (bp github-url-to-raw (get-current-url))))))
        (pen-copy cmd)
        (message "%s" cmd)))

(defun vim-escape (s)
  "Escape a string for a vim pattern"
  (concat "\"" (escape "`/\"$*[]\\" (escape "\\" s)) "\""))

(defun open-selection-sps ()
  (interactive)

  (if mark-active
      (let ((sel (pen-umn (pen-selected-text))))
        (edit-fp-on-path sel))))

(defun sel-flush-left-p ()
  (let ((bol (point-at-bol))
        (p (point))
        (m (mark)))
    (and mark-active
         (or (eq bol p)
             (eq bol m)))))

(defmacro pen-bd (&rest body)
  "Like b, but detach."
  `(shut-up (pen-sn (concat (pen-quote-args ,@body)) nil nil nil t)))

(defmacro pen-be (&rest body)
  "Returns the exit code."
  (defset b_exit_code nil)

  `(progn
     (pen-sn (concat (pen-quote-args ,@body)))
     (string-to-int b_exit_code)))

(defmacro bx-right (&rest body)
  "Evaluate the last argument and use as the last argument to shell script. Use the last lisp argument as the final argument to the preceding bash command."
  `(pen-sn (concat (pen-quote-args ,@(butlast body)) " " (e/q (str ,@(last body))))))
(defalias 'bxr 'bx-right)
(defalias 'pen-bl 'bx-right)

(defmacro pen-bp (&rest body)
  "Pipe string into bash command. Return stdout."
  `(pen-sn (concat (pen-quote-args ,@(butlast body))) ,@(last body)))

(defmacro pen-bq (&rest body)
  "True if exit code = 0."
  `(eq (pen-be ,@body) 0))

(defmacro pen-ble (&rest body)
  "Returns the exit code."
  (defset b_exit_code nil)

  `(progn
     (pen-sn (concat (pen-quote-args ,@(butlast body)) " " (e/q ,@(last body))))
     (string-to-int b_exit_code)))

(defmacro pen-bld (&rest body)
  "Runs and detaches."
  `(pen-sn (pen-ns (concat (pen-quote-args ,@(butlast body)) " " (e/q ,@(last body)))) nil nil nil t))

(defmacro pen-blq (&rest body)
  "Returns the exit code."
  `(eq (pen-ble ,@body) 0))

(defun get-vim-link (&optional editor)
  (interactive)
  (if (not editor)
      (setq editor "v"))
  (defvar uri)
  (defvar vimcmd)
  (setq uri (pen-mnm (get-path t)))

  (setq vimcmd
        (cond ((derived-mode-p 'eww-mode) "ewwlinks")
              ((derived-mode-p 'Info-mode) "emacshelp")
              (t editor)))

  (if mark-active
      (let* ((pat (pen-bp head -n 1 (pen-selected-text)))
             (vimpat
              (if (sel-flush-left-p)
                  (vim-escape (concat "^" pat))
                (vim-escape pat)))
             (link-cmd (concat vimcmd " +/" vimpat " " (pen-q uri))))
        (xc link-cmd)
        (message "%s" link-cmd)
        (deactivate-mark))))

(defun get-emacs-link (&optional editor)
  (interactive)

  (if (and
       (derived-mode-p 'eww-mode)
       (>= (prefix-numeric-value current-prefix-arg) 4)
       mark-active)
      (xc (concat (get-path) "#:~:text=" (urlencode (e/chomp-all (pen-selected-text)))))

      (progn
        (if (not editor)
            (setq editor "sp"))
        (get-vim-link editor))))

(defun forget-region ()
  (interactive)
  (set-marker m1 nil)
  (set-marker m2 nil))

(defun selected--on ()
  (if (not (or (bound-and-true-p lispy-mode)
               (pen-evil-enabled)))
      (selected-region-active-mode 1)))

;; (define-key selected-keymap (kbd "M-3") #'pen-grep-for-thing-select)

(define-key selected-keymap (kbd "C-h") (kbd "C-w"))
(define-key selected-keymap (kbd "C-k") (kbd "C-w"))
(define-key selected-keymap (kbd "\\!") #'filter-region-through-external-script)
(define-key selected-keymap (kbd "M-\\ !") #'filter-region-through-external-script)
(define-key selected-keymap (kbd "U") #'upcase-region)
(define-key selected-keymap (kbd "M-U") #'upcase-region)
(define-key selected-keymap (kbd "u") #'downcase-region)
(define-key selected-keymap (kbd "M-u") #'downcase-region)
(define-key selected-keymap (kbd "M-c M-c") #'capitalize-region)
(define-key selected-keymap (kbd ">") #'fi-org-indent)
(define-key selected-keymap (kbd "<") #'fi-org-unindent)
(define-key selected-keymap (kbd "D") #'pen-run-prompt-function)
(define-key selected-keymap (kbd "J") #'fi-join)
(define-key selected-keymap (kbd "C-h") 'selected-backspace-delete-and-deselect)
(define-key selected-keymap (kbd "m") #'apply-macro-to-region-lines)
(define-key selected-keymap (kbd "I") #'string-insert-rectangle)
(define-key selected-keymap (kbd "=") #'clear-rectangle)
(define-key selected-keymap (kbd "T") #'open-region-untitled)
(define-key selected-keymap (kbd "D") #'pen-selected-kill-rectangle)
(define-key selected-keymap (kbd "K") #'man-thing-at-point)
(define-key selected-keymap (kbd "j") 'goto-thing-at-point)
(define-key selected-keymap (kbd "u") 'undo)
(define-key selected-keymap (kbd "O") 'yas-insert-snippet)
(define-key selected-keymap (kbd "|") #'mc/edit-lines)
(define-key selected-keymap (kbd "C-g") #'selected-keyboard-quit)
(define-key selected-keymap (kbd "J") 'pen-fi-join)
(define-key selected-keymap (kbd "*") 'pen-evil-star-maybe)

(provide 'pen-selected)
