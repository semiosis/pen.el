(defun pen-go-to-documents ()
  (interactive)
  (find-file (f-join user-home-directory ".pen/documents")))

(provide 'pen-documents)