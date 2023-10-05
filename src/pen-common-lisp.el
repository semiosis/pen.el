;; https://roswell.github.io/Initial-Recommended-Setup.html

;; ros install slime
(load (expand-file-name (pen-umn "$HOME/.roswell/helper.el")))
(setq inferior-lisp-program "ros -Q run")

(require 'slime)

(defun sbcl-web-docs (funname)
  (interactive (list (str (symbol-at-point))))

  (eww (concat "http://clhs.lisp.se/Body/f_" funname ".htm")))

(defun linux-system-ram-size ()
   (string-to-number (shell-command-to-string "free --mega | awk 'FNR == 2 {print $2}'")))

(use-package slime
  ;; following line broke it
  ;; :ensure t
  
  :config
  ;; (load (expand-file-name "$HOME/.roswell/helper.el"))
  
  ;; $ ros config
  ;; $ ros use sbcl dynamic-space-size=3905
  ;; query with: (/ (- sb-vm:dynamic-space-end sb-vm:dynamic-space-start) (expt 1024 2))
  ;; set memory of sbcl to your machine's RAM size for sbcl and clisp
  ;; (but for others - I didn't used them yet)
  
  ;; (linux-system-ram-size)
  ;; (setq inferior-lisp-program (concat "ros -Q dynamic-space-size="     
  ;;                                     (number-to-string (linux-system-ram-size)) 
  ;;                                     " run"))
  ;; and for fancier look I personally add:
  (setq slime-contribs '(slime-fancy))
  ;; ensure correct indentation e.g. of `loop` form
  (add-to-list 'slime-contribs 'slime-cl-indent)
  ;; don't use tabs
  (setq-default indent-tabs-mode nil))

(setf slime-lisp-implementations
      `((sbcl
         ("sbcl"
          "--dynamic-space-size"
          "2000"))
        (roswell ("ros" "-Q" "run"))))

;; (setq inferior-lisp-program (concat "ros -Q dynamic-space-size=" (number-to-string (linux-system-ram-size)) " run"))
(setq inferior-lisp-program "ros -L sbcl -Q -l /root/.sbclrc run")

(setf slime-default-lisp 'roswell)

(defun pen-slime-select-prompt-or-result ()
  (interactive)

  (if (< slime-repl-input-start-mark (point))
      (progn
        (call-interactively 'end-of-buffer)
        (set-mark (point))
        (goto-char slime-repl-input-start-mark)
        (call-interactively 'exchange-point-and-mark))
    (progn
      (if (looking-back "^[^ ]+> .*")
          (beginning-of-line))
      (if (looking-back "^[^ ]+> ")
          (progn
            (set-mark (point))
            (end-of-line))
        (progn
          (slime-repl-previous-prompt)
          (forward-line)
          (beginning-of-line)
          (set-mark (point))
          (slime-repl-next-prompt)
          (previous-line)
          (end-of-line))))))

(define-key slime-repl-mode-map (kbd "M-h") 'pen-slime-select-prompt-or-result)

;; j:pen-godef-or-global-references
(defun pen-slime-godef (thing)
  (interactive (list (pen-thing-at-point)))
  (slime-edit-definition thing))

(defun slime-reinitialize-inferior-lisp-p (program program-args env buffer)
  (never
   (let ((args (slime-inferior-lisp-args (get-buffer-process buffer))))
     (and (equal (plist-get args :program) program)
          (equal (plist-get args :program-args) program-args)
          (equal (plist-get args :env) env)
          (not (y-or-n-p "Create an additional *inferior-lisp*? ")))))
  t)

(defun format-lisp-at-point ()
  "Formats racket code, if selected or on a starting parenthesis."
  (interactive)
  (slime-reindent-defun)
  ;; (format-sexp-at-point "racket-format")
  )

;; (define-key lisp-mode-map (kbd "C-x C-e") 'slime-eval-last-expression-in-repl)
(define-key lisp-mode-map (kbd "C-x C-e") 'slime-eval-last-expression)

;; I don't actually know exactly where this should go.
(remove-hook 'lisp-mode-hook 'sly-editing-mode)

(define-key slime-mode-indirect-map (kbd "M-w") nil)
(define-key slime-repl-mode-map (kbd "M-w") nil)
(define-key slime-editing-map (kbd "M-w") nil)

(define-key slime-mode-indirect-map (kbd "C-M-a") nil)
(define-key slime-repl-mode-map (kbd "C-M-a") nil)
(define-key slime-editing-map (kbd "C-M-a") nil)

(define-key slime-mode-indirect-map (kbd "M-.") nil)
(define-key slime-repl-mode-map (kbd "M-.") nil)
(define-key slime-editing-map (kbd "M-.") nil)

;; (define-key slime-mode-indirect-map (kbd "M-w") 'slime-macroexpand-all)
;; (define-key slime-repl-mode-map (kbd "M-w") 'slime-macroexpand-all)
;; (define-key slime-editing-map (kbd "M-w") 'slime-macroexpand-all)

(define-key slime-mode-indirect-map (kbd "M-?") nil)
(define-key slime-mode-indirect-map (kbd "M-_") nil)
(define-key slime-editing-map (kbd "M-w") 'slime-macroexpand-all)


;; sly

;;(remove-hook lisp-mode-hook 'slime-lisp-mode-hook)
;;
;;(require 'sly)
;;
;;(define-key sly-editing-mode-map (kbd "M-p") nil)
;;(define-key sly-editing-mode-map (kbd "M-n") nil)

(provide 'pen-common-lisp)
