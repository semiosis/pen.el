(defmacro evil--add-to-alist (list-var &rest elements)
  "Add the assocation of KEY and VAL to the value of LIST-VAR.
If the list already contains an entry for KEY, update that entry;
otherwise add at the end of the list.

\(fn LIST-VAR KEY VAL &rest ELEMENTS)"
  (when (eq (car-safe list-var) 'quote)
    (setq list-var (cadr list-var)))
  `(progn
     ,@(if (version< emacs-version "26")
           ;; TODO: Remove this path when support for Emacs 25 is dropped
           (cl-loop for (key val) on elements by #'cddr
                    collect `(let* ((key ,key)
                                    (val ,val)
                                    (cell (assoc key ,list-var)))
                               (if cell
                                   (setcdr cell val)
                                 (push (cons key val) ,list-var))))
         (cl-loop for (key val) on elements by #'cddr
                  collect `(setf (alist-get ,key ,list-var nil nil #'equal) ,val)))
     ,list-var))

(provide 'pen-borrowed)