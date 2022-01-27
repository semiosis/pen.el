(require 'lispy)
(require 'pen-utils)

(setq show-paren-delay 0
      show-paren-style 'parenthesis)

(show-paren-mode 1)

(defvar pen-lisp-mode-map (make-sparse-keymap)
  "Keymap for `pen-lisp-mode'.")

(define-minor-mode pen-lisp-mode
  "docstring"
  :init-value nil         ; I don't want this to be t. I don't want it enabled everywhere.
  :lighter " pen-lisp"
  :keymap pen-lisp-mode-map)

(require 'smartparens)
(require 'evil-lisp-state)

(pen-with 'paredit (add-hook 'pen-lisp-mode-hook '(lambda () (paredit-mode 1))))

(define-key paredit-mode-map (kbd "M-r") nil)
(define-key paredit-mode-map (kbd "C-M-n") nil)
(define-key paredit-mode-map (kbd ";") nil)
(define-key paredit-mode-map (kbd "C-d") nil)
(define-key lispy-mode-map-special (kbd "M-TAB") (kbd "i"))

(require 'lispy)

(defun pen-lisp-backward-delete ()
  "This tries to delete a paren pair. If it fails, it will try to delete a single char."
  (interactive)
  (try (paredit-backward-delete) (backward-delete-char)))

(define-key pen-lisp-mode-map (kbd "DEL") 'pen-lisp-backward-delete)

(define-key pen-lisp-mode-map (kbd "M-8") nil)
(define-key pen-lisp-mode-map (kbd "M-0") (kbd "M-a"))

(defun pen-lisp-e ()
  "I want this to work in elisp as well as
clojure and perhaps all lisp modes. Done."
  (interactive)
  (save-window-excursion
    (cond ((lispy-left-p)
           (if (derived-mode-p 'emacs-lisp-mode)
               (eval (sexp-at-point))
             (save-mark-and-excursion
               (ekm "d C-x C-e"))))
          ((lispy-right-p)
           (ekm "C-x C-e"))
          (t
           (special-lispy-eval)))))

(define-key pen-lisp-mode-map (kbd "e") #'pen-lisp-e)
(define-key pen-lisp-mode-map (kbd "M-a") #'pen-lisp-left-noevil)

(defun pen-lisp-first-child ()
  (interactive)
  (if (region-active-p)
      (let ((originalselection (pen-selected-text)))
        (if (cursor-at-region-start-p)
            (progn
              (execute-kbd-macro (kbd "d"))
              (lispy-mark-car))
          (lispy-mark-car))

        (if (and (string-equal originalselection (pen-selected-text))
                 (string-match "[/.]" originalselection))
            (progn
              (if (> (point) (mark))
                  (call-interactively 'exchange-point-and-mark))
              (re-search-forward "[/.]")
              (call-interactively 'exchange-point-and-mark))))
    (call-interactively 'lispy-mark-symbol)))

(define-key pen-lisp-mode-map (kbd "M-e") #'pen-lisp-first-child)

(defun pen-lisp-mark-n (n)
  (interactive)
  (deactivate-mark)
  (execute-kbd-macro (kbd "M-a d"))
  (lispy-mark-car)
  (dotimes (_n (- n 1))
    (execute-kbd-macro (kbd "j"))))

(defun pen-lisp-mark-last-n (n)
  (interactive)
  (deactivate-mark)
  (execute-kbd-macro (kbd "M-a d"))
  (lispy-mark-car)
  (pen-lisp-mark-last)
  (dotimes (_n (- n 1))
    (execute-kbd-macro (kbd "k"))))

(defun pen-lisp-mark-2 ()
  (interactive)
  (deactivate-mark)
  (execute-kbd-macro (kbd "M-a d"))
  (lispy-mark-car)
  (execute-kbd-macro (kbd "j")))

(defun pen-lisp-mark-last ()
  (interactive)
  (deactivate-mark)
  (execute-kbd-macro (kbd "M-a d"))
  (lispy-mark-car)
  (dotimes (_n 100)
    (execute-kbd-macro (kbd "j"))))

(defun pen-lisp-go-top ()
  (interactive)
  (dotimes (interactive 100)
    (special-lispy-up)))

(defun pen-lisp-left-noevil (arg)
  (interactive "p")
  (pen-with 'evil-lisp-state
           (if evil-state
               (evil-lisp-state/quit)))
  (pen-with 'lispy
           (lispy-left arg))
  (deactivate-mark))

(defun pen-lisp-right-noevil (arg)
  (interactive "p")
  (pen-with 'evil-lisp-state
           (if evil-state
               (evil-lisp-state/quit)))
  (pen-with 'lispy
           (lispy-right arg)))

(defun pen-select-sexp ()
  (interactive)
  (ekm "C-M-a m"))

;; Home is C-M-y
(define-key pen-lisp-mode-map (kbd "<home>") 'pen-select-sexp)

(defun preceding-sexp-or-element ()
  "Returns the preceding sexp or element or nil if the current is the first in the sexp."
  (interactive)
  (save-excursion
    (try
     (progn
       (let ((orig-pos (point)))
         (if (not (or (equal (current-column) 0) (string-equal " " (char-to-string (preceding-char)))))
             (backward-sexp))
         (backward-sexp)
         (if (equal orig-pos (point))
             nil
           (str (thing-at-point 'sexp)))))
     nil)))

(defun pen-lispy-delete-or-h ()
  "If selected, delete, otherwise, send h."
  (interactive)
  (if mark-active
      (call-interactively 'lispy-delete)
    (let ((pen-lisp-mode nil))
      (if (or (lispy-left-p)
              (lispy-right-p))
          (special-lispy-left)
        (self-insert-command 1)))))

(defun pen-lispy-delete-or-c-h ()
  "If selected, delete, otherwise, send h."
  (interactive)
  (if mark-active
      (call-interactively 'lispy-delete)

    (let ((pen-lisp-mode nil))
      (selected-backspace-delete-and-deselect))))

(define-key pen-lisp-mode-map (kbd "h") #'pen-lispy-delete-or-h)
(define-key pen-lisp-mode-map (kbd "DEL") #'pen-lispy-delete-or-c-h) ; C-h is translated to DEL which is bound to this

(defun sly-db-goto-source ()
  (interactive)
  (message "sly-db-goto-source: Not implemented"))

(defun pen-sly-connect ()
  (interactive)
  (let ((sb (get-buffer "*sly-mrepl for sbcl*")))
    (if sb
        (progn
          (message "sly already running"))
      (progn
        (sly--purge-connections)
        (sly "sbcl" nil t)))))

(add-hook 'lisp-mode-hook 'pen-sly-connect)

(provide 'pen-lisp)