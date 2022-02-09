;; brain-to-brain interface

;; An HTTP server for prompting

(defun khala-start ()
  (interactive)
  (pen-sn "khala" nil nil nil t))

(defun khala-stop ()
  (interactive)
  (pen-sn "pen-kill-port 9837" nil nil nil t))

(defun pen-get-khala-port ()
  (string-to-number
   (sor (pen-snc "cat $HOME/.pen/ports/khala.txt")
        "7681")))

(provide 'pen-khala)