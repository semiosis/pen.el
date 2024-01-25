;; https://emacs.stackexchange.com/questions/75113/never-prompt-me-again-with-the-words-buffer-modified

;; (setq kill-buffer-query-functions
;;       '(pen-dont-kill-scratch))

(setq kill-buffer-query-functions
      '(pen-dont-kill-scratch))

(setq kill-buffer-query-functions
      '(
        (lambda nil
          (not-modified)
          t)
        pen-dont-kill-scratch))

;; Frustratingly, this makes the 'File saved' message disappear quickly.
;; Unsure why.
;; But the problem it solves needs solving.
;; But, sadly, it doesn't solve it.
(add-hook 'kill-buffer-query-functions
          (lambda () (not-modified) t))

(provide 'pen-buffers)
