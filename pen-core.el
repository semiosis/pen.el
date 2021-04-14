;; These are helper functions
;; examplary.el uses them.

;; So might org-brain

(defun pen-preceding-text ()
  (str (buffer-substring (point) (max 1 (- (point) 1000)))))

(defun pen-surrounding-text ()
  (str (buffer-substring (point) (max 1 (- (point) 1000)))))


(provide 'pen-core)