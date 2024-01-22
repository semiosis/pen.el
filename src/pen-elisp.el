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

(defun elisp-complete-interactive-arg ()
  (interactive)
  (let* ((syminfo (elisp--fnsym-in-current-sexp))
         (fun (car syminfo))
         (pos (cadr syminfo))
         (intgen (nth pos (cadr (interactive-form 'e/grep)))))

    (insert (pen-pps (eval intgen)))))

(e/grep "lkadsfj" "dlksajfl" pcre)

(provide 'pen-elisp)
