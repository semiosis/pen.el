;; These are helper functions
;; examplary.el uses them.

;; So might org-brain

(defun pen-preceding-text ()
  (str (buffer-substring (point) (max 1 (- (point) 1000)))))

(defun beginning-of-line-point ()
  (save-excursion
    (beginning-of-line)
    (point)))

(defun pen-preceding-text-line ()
  (cond
   (major-mode-p 'term-mode))
  (str (buffer-substring (point) (max 1 (beginning-of-line-point)))))

;; TODO Figure out how to get the previous line start of line points
;; (tv (save-excursion (ntimes 5 (call-interactively 'previous-line)) (message (str (point)))))


(defun get-point-start-of-nth-previous-line (n)
  (save-excursion
    (eval `(expand-macro (ntimes ,n (ignore-errors (previous-line)))))
    (beginning-of-line)
    (point)))

(defun get-point-start-of-nth-next-line (n)
  (save-excursion
    (eval `(expand-macro (ntimes ,n (ignore-errors (next-line)))))
    (beginning-of-line)
    (point)))

(defun pen-surrounding-text (&optional window-line-size)
  (if (not window-line-size)
      (setq window-line-size 20))
  (let ((window-line-radius (/ window-line-size 2)))
    (str (buffer-substring
          (get-point-start-of-nth-previous-line window-line-radius)
          (get-point-start-of-nth-next-line window-line-radius)))))

(provide 'pen-core)