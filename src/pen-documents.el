(defun pen-go-to-documents ()
  (interactive)
  (find-file (f-join user-home-directory ".pen/documents")))

(defun pen-go-to-glossaries ()
  (interactive)
  (find-file (f-join user-home-directory ".pen/glossaries")))

(defun pen-go-to-results ()
  (interactive)
  (find-file (f-join user-home-directory ".pen/results")))

(defun pen-go-to-brains ()
  (interactive)
  (find-file (f-join user-home-directory ".pen/org-brain")))

(provide 'pen-documents)