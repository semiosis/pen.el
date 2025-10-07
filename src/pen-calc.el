(defun calc-edit-scratch ()
  (interactive)
  (if (>= (prefix-numeric-value current-prefix-arg) 4)
      (calc)
    (progn
      (if (f-exists-p "/root/notes/ws/calc/scratch.org")
          (find-file "/root/notes/ws/calc/scratch.org")
        (scratch-buffer))
      (calc))))

(defun calc-dispatch-around-advice (proc &rest args)
  (setq current-prefix-arg '(4))        ; C-u
  (let ((res (apply proc args)))
    res))
(advice-add 'calc-dispatch :around #'calc-dispatch-around-advice)
(advice-remove 'calc-dispatch #'calc-dispatch-around-advice)
