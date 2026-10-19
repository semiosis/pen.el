;; e:/root/notes/ws/playing-cards/scoundrel/game1.txt
;; e:/root/notes/ws/playing-cards/scoundrel/game1.el

;; TODO Try to keep the game system transparent (i.e. text based)
;; Also, try to design it so it can also be played in vim.
;; So use shell commands for the operations on the text file.

;; Also, come up with a REPL, so I can run commands to move the game forward, like chess.

(comment
 (mapcar (lambda (e) (cond ((equal ))))(seq 1 13)))

(defun plca/rank-to-num (s)
  (cond
   ((string-equal "a" s) 14)
   ((string-equal "k" s) 13)
   ((string-equal "q" s) 12)
   ((string-equal "j" s) 11)
   ((string-equal "t" s) 10)
   (t 0)
   ((s-numeric? s) (string-t1o-number s))))

;; TODO Make some deck/game validation functions
;; i.e. Based on game specs, see if the cards in various hands/groups are together valid

(defun check-valid-deck ()

  )

(provide 'pen-playing-cards)
