;; When you paste, also change to the correct mode?

;; Only do this if it's in foundation mode?

;; This appears to not work. Try a restart
(defun paste-around-advice (proc &rest args)
  (let* ((text (car kill-ring))
         (res (apply proc args)))

    (if (major-mode-p 'fundamental-mode)
        (detect-language-set-mode))
    res))
(advice-add 'paste :around #'yank)

(provide 'pen-edit)