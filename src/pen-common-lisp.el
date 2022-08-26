;; https://roswell.github.io/Initial-Recommended-Setup.html

;; ros install slime
(load (expand-file-name (pen-umn "$HOME/.roswell/helper.el")))
(setq inferior-lisp-program "ros -Q run")

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

(provide 'pen-common-lisp)
