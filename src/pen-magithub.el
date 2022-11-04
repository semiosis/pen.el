(require 'magithub)

;; this fixes magithub and ghub+
(defun ghub--host-around-advice (proc &rest args)
  (if (not args)
      (setq args '(github)))
  (let ((res (apply proc args)))
    res))
(advice-add 'ghub--host :around #'ghub--host-around-advice)

(provide 'pen-magithub)
