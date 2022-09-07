(defun pen-rc-get (key)
  (if (and key (not (string-blank-p key)))
      (pen-snc (concat "cat $HOME/.pen/pen.yaml | yq -r '." key " // empty'"))))

(defun pen-rc-set (key value)
  (interactive (let* ((key (read-string-hist (concat "pen-rc-set key: ")))
                      (value (read-string-hist (concat "pen-rc-set " (pen-q key) " value: "))))
                 (list key value)))
  (pen-cl-sn (concat "pen-rc-set " (pen-q key) " " (pen-q value))
             :chomp t :b_output-return-code t))

(defun pen-rc-test (key)
  (let ((v (chomp (pen-rc-get key))))
    (and v (string-equal v "true"))))

(defun toggle-pen-rc (option &optional newvalue quiet)
  (interactive (list (fz toggle-pen-rc-keys)))
  (if option
      (let* ((oldstate (equalp "0" (pen-cl-sn (concat "upd pen-rc-test " (pen-q option)) :chomp t :b_output-return-code t)))
             (newstate (if (interactive-p)
                           (pen-cl-sn (concat "pen-rc-toggle " (pen-q option)) :chomp t :b_output-return-code t)
                         (if (and newvalue (not (eq oldstate (equalp "on" newvalue))))
                             (progn
                               (pen-cl-sn (concat "pen-rc-set " (pen-q option) " " (if (equalp "on" newvalue)
                                                                             "on"
                                                                           "off"))
                                      :chomp t :b_output-return-code t)
                               (not oldstate))
                           oldstate))))
        (if (not quiet)
            (if newstate
                (message (concat option " enabled"))
              (message (concat option " disabled"))))
        newstate)))

(provide 'pen-rc)
