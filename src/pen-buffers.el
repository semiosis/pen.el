;; https://emacs.stackexchange.com/questions/75113/never-prompt-me-again-with-the-words-buffer-modified

;; (setq kill-buffer-query-functions
;;       '(pen-dont-kill-scratch))

(setq kill-buffer-query-functions
      '(pen-dont-kill-scratch))

;; Frustratingly, this makes the 'File saved' message disappear quickly.
(add-hook 'kill-buffer-query-functions
          (lambda () (not-modified) t))

(provide 'pen-buffers)
