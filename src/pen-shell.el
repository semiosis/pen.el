(require 'shell)

(setq explicit-shell-file-name "pash")

(setq shell-kill-buffer-on-exit t)

(defun shell-show-env ()
  (interactive)
  (ifi-etv (shell-eval-command "echo 5")))

(comment
 ;; shell (not eshell)
 (defun shell-run-command (cmd)
   (interactive (list (read-string-hist "shell$ ")))
   (shell)
   (with-current-buffer shell-buffer-name
     (eshell-return-to-prompt)
     (eshell-kill-input)
     ;; (kill-line)
     (insert cmd)
     (eshell-send-input))))

;; See j:eshell-buffer-name
(defun shell-unique (&optional buffer file-name)
  (interactive "P")
  (progn
    ;; DONE Make it so the main shell-buffer-name buffer is not renamed.
    (let* ((new-buffer-name
            (concat "*shell-" (concat
                               (slugify (pwd))
                               ":"
                               (slugify (or explicit-shell-file-name
					                        (getenv "ESHELL")
					                        shell-file-name)))
                    "*"))
           (buf (shell buffer file-name)))
      (with-current-buffer buf
        (rename-buffer new-buffer-name))
      buf)
    ;; (rename-buffer (concat "*shell-" (substring (uuidgen-4) 0 8) "*"))
    ))

(define-key shell-mode-map (kbd "C-c M-e") 'shell-show-env)

(provide 'pen-shell)
