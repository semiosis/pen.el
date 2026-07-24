(require 'lispy)

;; (add-hook 'emacs-lisp-mode-hook '(lambda () (lispy-mode 1)))

(advice-add 'lispy-mark-symbol :around #'ignore-errors-around-advice)
(advice-add 'kill-ring-save :around #'ignore-errors-around-advice)

(defun pen-elisp-expand-macro-or-copy ()
  (interactive)
  (if mark-active
      (xc)
    (call-interactively 'macrostep-expand)))

;; font-lock-keyword-face
(defface font-lock-macro-name-face
  '((((class color) (min-colors 88) (background light)) :foreground "Blue1")
    (((class color) (min-colors 88) (background dark))  :foreground "LightSkyBlue")
    (((class color) (min-colors 16) (background light)) :foreground "Blue")
    (((class color) (min-colors 16) (background dark))  :foreground "LightSkyBlue")
    (((class color) (min-colors 8)) :foreground "blue" :weight bold)
    (t :inverse-video t :weight bold))
  "Font Lock mode face used to highlight macro names."
  :group 'font-lock-faces)

(defun elisp-eldoc-funcall (callback &rest _ignored)
  "Document function call at point by calling CALLBACK.
Intended for `eldoc-documentation-functions' (which see)."
  (let* ((sym-info (elisp--fnsym-in-current-sexp))
         (fn-sym (car sym-info)))
    (when fn-sym
      (funcall callback (apply #'elisp-get-fnsym-args-string sym-info)
               :thing fn-sym
               :face
               (cond ((functionp fn-sym) 'font-lock-function-name-face)
                     ((macrop fn-sym) 'font-lock-macro-name-face)
                     (t 'font-lock-keyword-face))))))

(define-key emacs-lisp-mode-map (kbd "M-w") #'pen-elisp-expand-macro-or-copy)

(defun pen-pps (o)
  (cond ((or
          (consp o)
          (symbolp o))
         (concat
          "'"
          (pps o)))
        (t (pps o))))

;; This is awesome - now bind it to something
(defun elisp-complete-interactive-arg ()
  (interactive)
  (let* ((syminfo (elisp--fnsym-in-current-sexp))
         (fun (car syminfo))
         (pos (cadr syminfo))
         (intgen (nth pos (cadr (interactive-form fun)))))

    (if intgen
        (insert (pen-pps (eval intgen)))
      (error "Does not have an interactive argument specified"))))

(define-key pen-map (kbd "s-/") 'elisp-complete-interactive-arg)

(comment
 (e/grep "d*" "dlksajfl\nfkldmssklfjdslkfj" 'glob))

;; https://emacs.stackexchange.com/q/3197
(defun assoc-multi-key (path nested-alist)
  "Find element in nested alist by path."
  (if (equal nested-alist nil)
      (error "cannot lookup in empty list"))
  (let ((key (car path))
        (remainder (cdr path)))
    (if (equal remainder nil)
        (assoc key nested-alist)
      (assoc-multi-key remainder (assoc key nested-alist)))))

(comment
 ;; Example
 (assoc-multi-key '(foo bar)
                  '((foo (bar . "llama") (baz . "monkey"))))

 (assoc-multi-key '(foo bar baz)
                  '((foo (bar (bozo . "llama") (baz . "monkey")))))


 (eval-string (cat "/root/.pen/tmp/WTQgqOzpOA"))
 )

(comment
 (find-function 'transient-define-prefix)
 (pen-get-sym-source 'transient-define-prefix))

(defun pen-get-sym-source (sym)
  (let ((src))
    (save-window-excursion
      (cond ((or (functionp sym)
                 (macrop sym))
             (find-function sym)
             (with-current-buffer (current-buffer)
               (shut-up (call-interactively 'er/expand-region))
               (setq src (pen-selection))
               (deselect)))))
    src))

(provide 'pen-elisp)
