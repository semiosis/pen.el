(defun pen-rc-get (key)
  (if (and key (not (string-blank-p key)))
      (pen-snc (concat "cat $HOME/.pen/pen.yaml | yq -r '." key "'"))))

(defun pen-rc-test (key)
  (let ((v (chomp (pen-rc-get key))))
    (and v (string-equal v "true"))))

(provide 'pen-rc)