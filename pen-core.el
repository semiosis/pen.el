;; These are helper functions
;; examplary.el uses them.

;; So might org-brain

(defun pen-preceding-text ()
  (str (buffer-substring (point) (max 1 (- (point) 1000)))))


;; TODO Figure out how to get the previous line start of line points
;; (tv (save-excursion (ntimes 5 (call-interactively 'previous-line)) (message (str (point)))))


(defun get-point-start-of-nth-previous-line (n)
  (save-excursion
    `(eval (expand-macro `(ntimes ,n (ignore-errors (previous-line)))))
    (beginning-of-line)
    (point)))



(defun pen-surrounding-text (&optional window-line-size)
  (if (not window-line-size)
      (setq window-line-size 20))
  (str (buffer-substring (- (point)
                            (save-excursion
                              (ntimes window-line-size (previous-line))
                              (point))
                            10) (max 1 (- (point) 1000)))))

(ntimes 5 (message "hi"))

(provide 'pen-core)