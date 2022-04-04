(add-hook 'kill-buffer-query-functions #'pen-dont-kill-scratch)
(defun pen-dont-kill-scratch ()
  (let ((bn (buffer-name)))
    (cond
     ((or (equal bn "*scratch*")
          (equal bn "*Messages*")
          (equal bn "*Warnings*")
          ;; more - these should be killed automatically
          ;; (equal bn "*pen-sn-stderr*")
          ;; (equal bn "*Helm Completions*")
          ;; (equal bn "*Ilist*")
          ;; (equal bn "*straight-process*")
          ;; (equal bn "*straight-byte-compilation*")
          ;; (equal bn "*lsp-log*")
          ;; (equal bn "*helpful macro: with-current-buffer*")
          ;; (equal bn "*Shell Command Output*")
          )
      (progn
        (message "Not allowed to kill %s, burying instead" bn)
        (bury-buffer)
        nil))
     (t t))))

(defun pen-create-scratch-buffer ()
  "create a scratch buffer"
  (interactive)
  (switch-to-buffer (get-buffer-create "*scratch*"))
  (text-mode)
  ;; (lisp-interaction-mode)
  )

;; (pen-create-scratch-buffer)

(provide 'pen-scratch)
