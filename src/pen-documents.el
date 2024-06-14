(defun pen-go-to-documents ()
  (interactive)
  (find-file (f-join user-home-directory ".pen/documents")))

(defun pen-go-to-glossaries ()
  (interactive)
  (find-file (f-join user-home-directory ".pen/glossaries")))

(defun pen-go-to-quotes ()
  (interactive)
  (find-file (f-join user-home-directory ".pen/documents/quotes.txt")))

(defun pen-go-to-results ()
  (interactive)
  (find-file (f-join user-home-directory ".pen/results")))

(defun pen-go-to-brains ()
  (interactive)
  (find-file (f-join user-home-directory ".pen/org-brain")))

(defun e-faith-and-judgement ()
  (interactive)

  (let ((gparg (prefix-numeric-value current-prefix-arg))
        (current-prefix-arg nil))
    (cond ((>= gparg 16) (sps "vd /volumes/home/shane/var/smulliga/source/git/semiosis/thoughts-on-theology/README.org $EMACSD/pen.el/docs/theology/faith-and-judgement.org"))
          ((>= gparg 4) (e "/volumes/home/shane/var/smulliga/source/git/semiosis/thoughts-on-theology/README.org"))
          (t (e "$EMACSD/pen.el/docs/theology/faith-and-judgement.org")))))

(provide 'pen-documents)
