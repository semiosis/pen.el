(require 'helpful)

;; nadvice - proc is the original function, passed in. do not modify
(defun helpful-symbol-around-advice (proc &rest args)
  (save-selected-window
    (let ((res (apply proc args)))
      res)))
(advice-add 'helpful-symbol :around #'helpful-symbol-around-advice)

(defun pen-describe-symbol (symbol)
  "A “C-h o” replacement using “helpful”:
   If there's a thing at point, offer that as default search item.

   If a prefix is provided, i.e., “C-u C-h o” then the built-in
   “describe-symbol” command is used.

   ⇨ Pretty docstrings, with links and highlighting. 
   ⇨ Source code of symbol.
   ⇨ Callers of function symbol.
   ⇨ Key bindings for function symbol.
   ⇨ Aliases.
   ⇨ Options to enable tracing, dissable, and forget/unbind the symbol!
  "
  (interactive "p")
  (let* ((thing (symbol-at-point))
         (val (completing-read
               (format "Describe symbol (default %s): " thing)
               (vconcat (list thing) obarray)
               (lambda (vv)
                 (cl-some (lambda (x) (funcall (nth 1 x) vv))
                          describe-symbol-backends))
               t nil nil))
         (it (intern val)))

    (if current-prefix-arg
        (funcall #'describe-symbol it)
      (cond
       ((or (functionp it) (macrop it) (commandp it)) (helpful-callable it))
       (t (helpful-symbol it))))))

(defun pen-helpful--all-references-sym (sym)
  "Find all the references to the symbol."
  (interactive (list (symbol-at-point)))
  (let ((callable-p sym))
    (cond
     ((not callable-p)
      (elisp-refs-variable sym))
     ((functionp sym)
      (elisp-refs-function sym))
     ((macrop sym)
      (elisp-refs-macro sym)))))

;; Can be used inside of eshell
(defun pen-helpful-symbol (sym)
  "hp (pen helpful-symbol can be run from eshell, too.
e.g. `hp ivy-immediate-done`
"
  (interactive
   (list (helpful--read-symbol
          "Symbol: "
          (helpful--symbol-at-point)
          #'helpful--bound-p)))
  
  (setq sym (str2sym (str sym)))
  (helpful-symbol sym))

(defalias 'hlps 'pen-helpful-symbol)
(defalias 'hp 'pen-helpful-symbol)

(define-key helpful-mode-map (kbd "w") 'pen-yank-path)

;; Now that I have helpful-mode fullscreen in pa:pen-shackle
;; I want  kill-current-buffer,
;; rather than quit-window.
;; (define-key helpful-mode-map (kbd "q") 'quit-window)
(define-key helpful-mode-map (kbd "q") 'kill-current-buffer)

(provide 'pen-helpful)
