;; https://emacs.stackexchange.com/questions/75113/never-prompt-me-again-with-the-words-buffer-modified

;; (setq kill-buffer-query-functions
;;       '(pen-dont-kill-scratch))

;; If this asks if I really want to kill the buffer then the test fails
(defun test-temp-buffer-kill-without-asking ()
  (with-temp-buffer (org-mode) (insert "hi") (buffer-string) (kill-buffer)))
;; j:hyperdrive-describe-hyperdrive

;; This fixed the issue, but created another issue.
;; Now nothing saves -- actually, with further modifications it works properly.
;; I had to conditionally apply mark-buffer-unmodified to the specified buffer.
;; Now save works
(defun kill-buffer-around-advice (proc &optional buffer-or-name)
  (let ((res
         (progn
           (if buffer-or-name
               (with-current-buffer buffer-or-name
                 (mark-buffer-unmodified))
             ;; Otherwise-do it to the current buffer
             (mark-buffer-unmodified))
           (apply proc (list buffer-or-name)))))
    res))
(advice-add 'kill-buffer :around #'kill-buffer-around-advice)
;; (advice-remove 'kill-buffer #'kill-buffer-around-advice)
;; (advice-remove 'kill-buffer #'advise-to-yes)

;; Do it like this so that the minibuffer messages do not break.
;; shut-up and shut-up-c did not work.
(defun mark-buffer-unmodified ()
  (cl-letf (((symbol-function 'files--message)
             'ignore-truthy))
    (not-modified))
  t)

(setq kill-buffer-query-functions
      '(pen-dont-kill-scratch))

(setq kill-buffer-query-functions
      '(
        mark-buffer-unmodified
        pen-dont-kill-scratch))

;; Sadly, this hasn't solved the issue.
(add-hook 'kill-buffer-query-functions 'mark-buffer-unmodified)

;; Test/Debug the problem by opening hyperdrive menu bar and clicking on Drives->nickname:USHIN->Describe

;; (remove-hook 'kill-buffer-query-functions
;;           (lambda () (not-modified) t))

(provide 'pen-buffers)
