;; e:/root/notes/ws/playing-cards/scoundrel/game1.txt

(comment
 (mapcar (lambda (e) (cond ((equal ))))(seq 1 13)))

(defun plca/rank-to-num (s)
  (cond
   ((string-equal "a" s) 14)
   ((string-equal "k" s) 13)
   ((string-equal "q" s) 12)
   ((string-equal "j" s) 11)
   ((string-equal "t" s) 10)
   ((s-numeric? s) (string-to-number s))
   (t 0)))

(provide 'pen-playing-cards)
