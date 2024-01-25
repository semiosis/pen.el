;; https://emacs.stackexchange.com/questions/75113/never-prompt-me-again-with-the-words-buffer-modified

;; (setq kill-buffer-query-functions
;;       '(pen-dont-kill-scratch))

(setq kill-buffer-query-functions
      '(pen-dont-kill-scratch))


;; Do it like this so that the minibuffer messages do not break.
;; shut-up and shut-up-c did not work.
(defun mark-buffer-unmodified ()
  (cl-letf (((symbol-function 'files--message)
             'ignore-truthy))
    (not-modified))
  t)

(setq kill-buffer-query-functions
      '(
        mark-buffer-unmodified
        pen-dont-kill-scratch))

;; Frustratingly, this makes the 'File saved' message disappear quickly.
;; Unsure why.
;; But the problem it solves needs solving.
;; But, sadly, it doesn't solve it.
;; Frustratingly, this breaks the messages entirely.
;; Also, it doesn't even succeed.
(add-hook 'kill-buffer-query-functions
          (lambda () (not-modified) t))

;; (remove-hook 'kill-buffer-query-functions
;;           (lambda () (not-modified) t))

(provide 'pen-buffers)
