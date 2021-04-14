;; These are helper functions
;; examplary.el uses them.

;; So might org-brain

(defun pen-preceding-text ()
  (str (buffer-substring (point) (max 1 (- (point) 1000)))))

(defmacro ntimes (n &rest body)
  `(dotimes (n ,n)
     ,@body))

(defun pen-surrounding-text (&optional window-line-size)
  (if (not window-line-size)
      (setq window-line-size 20))
  (str (buffer-substring (- (point) (save-excursion
                                      (dotimes) 10)) (max 1 (- (point) 1000)))))


(provide 'pen-core)