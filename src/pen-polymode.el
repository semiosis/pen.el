

;; disable advice
(defun polymode-inhibit-during-initialization (proc &rest args)
  (let ((res (apply proc args)))
    
    res))
(advice-add 'polymode-inhibit-during-initialization :around #'polymode-inhibit-during-initialization)
(advice-remove 'polymode-inhibit-during-initialization #'polymode-inhibit-during-initialization)
