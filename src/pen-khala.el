;; brain-to-brain interface

;; An HTTP server for prompting

(defun khala-start ()
  (interactive)
  (pen-sn "unbuffer khala" nil nil nil t))

(defun pen-get-khala-port ()
  (string-to-number
   (sor (pen-snc "cat $HOME/.pen/ports/khala.txt")
        "9837")))

(defun khala-stop ()
  (interactive)
  (pen-sn (pen-cmd "pen-kill-port" (str (pen-get-khala-port))) nil nil nil t))

(provide 'pen-khala)