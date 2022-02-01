;; brain-to-brain interface

;; An HTTP server for prompting

(defun khala-start ()
  (interactive)
  (pen-sn "khala" nil nil nil t))

(defun khala-stop ()
  (interactive)
  (pen-sn "pen-kill-port 9837" nil nil nil t))

(provide 'pen-khala)