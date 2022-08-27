;; https://roswell.github.io/Initial-Recommended-Setup.html

;; ros install slime
(load (expand-file-name (pen-umn "$HOME/.roswell/helper.el")))
(setq inferior-lisp-program "ros -Q run")

(require 'slime)

(setf slime-lisp-implementations
      `((sbcl
         ("sbcl"
          "--dynamic-space-size"
          "2000"))
        (roswell ("ros" "-Q" "run"))))

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

;; (define-key lisp-mode-map (kbd "C-x C-e") 'slime-eval-last-expression-in-repl)
(define-key lisp-mode-map (kbd "C-x C-e") 'slime-eval-last-expression)

(provide 'pen-common-lisp)
