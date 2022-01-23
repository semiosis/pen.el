(defun add-hook-last (hook fun-to-add)
  (set hook (append (eval hook) (list fun-to-add))))
(defalias 'append-hook 'add-hook-last)

(defun add-hook-ignore (hook fun-to-add)
  (add-hook hook (eval `(dff (funcall ,fun-to-add)))))

(defun remove-hook-ignore (hook fun-to-remove)
  (remove-hook hook (eval `(dff (funcall ,fun-to-remove)))))

(defun remove-hook-ignore (hook fun-to-remove)
  (remove-hook hook fun-to-remove))

(provide 'pen-hooks)