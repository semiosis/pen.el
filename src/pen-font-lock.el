(setq font-lock-global-modes
      ;; '(not speedbar-mode universal-sidecar-buffer-mode)
      '(not speedbar-mode))

(advice-add 'jit-lock-fontify-now :around #'ignore-errors-around-advice)


;; Is there a way for font-lock to query manage-minor-mode ?
(defun turn-on-font-lock-if-desired ()
  (when (cond ((eq font-lock-global-modes t)
               t)

              ;; This should disable font-lock for universal-sidecar-buffer-mode
              ;; based on the setting in pa:pen-manage-minor-mode.
              ;; Strangely, though, universal-sidecar-buffer-mode seems to be able to handle font-lock-mode
              ;; together with fontification.
              ((not
                (eq
                 'off
                 (pen-manage-minor-mode-get-setting major-mode 'font-lock-mode))))
              
              ((eq (car-safe font-lock-global-modes) 'not)
               (not (memq major-mode (cdr font-lock-global-modes))))
              (t (memq major-mode font-lock-global-modes)))
    (let (inhibit-quit)
      (turn-on-font-lock))))

(provide 'pen-font-lock)
