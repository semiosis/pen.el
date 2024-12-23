;; http://xahlee.info/emacs/emacs/elisp_convert_lisp_vector.html

(defun vec2list (vec)
  (seq-into vec 'list))

(defun list2vec (lst)
  (seq-into lst 'vector))

(provide 'pen-seq)
