;; pen-rc-test and pen-rc-get are sometimes called before cmd is defined
(defun pen-rc-get-early (key)
  (if (and key (not (string-blank-p key)))
      (pen-snc (concat "pen-rc-get " key))))
(defun pen-rc-test-early (key)
  (pen-yaml-truthy-string-test (pen-rc-get-early key)))

(defun pen-rc-get (key)
  (if (and key (not (string-blank-p key)))
      (pen-snc (cmd "pen-rc-get" key))))

(defun pen-rc-set (key value)
  (interactive (let* ((key (read-string-hist (concat "pen-rc-set key: ")))
                      (value (read-string-hist (concat "pen-rc-set " (pen-q key) " value: "))))
                 (list key value)))
  (pen-cl-sn (concat "pen-rc-set " (pen-q key) " " (pen-q value))
             :chomp t :b_output-return-code t))

(defun pen-yaml-truthy-string-test (val)
  (let ((v (sor (chomp val))))
    (and v (or (string-equal v "true")
               (string-equal v "on")))))

(defun pen-rc-test (key)
  (pen-yaml-truthy-string-test (pen-rc-get key)))

(defun reload-from-pen-rc ()
  (interactive)
  (pen-set-text-contrast-from-config))

(defun toggle-pen-rc (option &optional newvalue quiet)
  (interactive (list (fz toggle-pen-rc-keys)))
  (if option
      (if newvalue
          nil
        (let* ((oldstate (equalp "0" (pen-cl-sn (concat "upd pen-rc-test " (pen-q option)) :chomp t :b_output-return-code t)))
               (success
                (pen-cl-sn (concat "pen-rc-toggle " (pen-q option)) :chomp t :b_output-return-code t)
                ;; (if (interactive-p)
                ;;     (pen-cl-sn (concat "pen-rc-toggle " (pen-q option)) :chomp t :b_output-return-code t)
                ;;   (if (and newvalue (not (eq oldstate (equalp "on" newvalue))))
                ;;       (progn
                ;;         (pen-cl-sn (concat "pen-rc-set " (pen-q option) " " (if (equalp "on" newvalue)
                ;;                                                                 "on"
                ;;                                                               "off"))
                ;;                    :chomp t :b_output-return-code t)
                ;;         (not oldstate))
                ;;     oldstate))
                )
               (newstate (pen-rc-test option)))
          (if (not quiet)
              (if newstate
                  (message (concat option " enabled"))
                (message (concat option " disabled"))))

          (reload-from-pen-rc)
          newstate))))

(provide 'pen-rc)
