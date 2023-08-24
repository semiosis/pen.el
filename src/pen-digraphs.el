(defun greek-digraph-select ()
  (interactive)
  (if (interactive-p)
      (funcall-interactively 'digraph-select "GREEK")
    (digraph-select "GREEK")))

(defun hebrew-digraph-select ()
  (interactive)
  (if (interactive-p)
      (funcall-interactively 'digraph-select "HEBREW")
    (digraph-select "HEBREW")))

(defun digraph-select (&optional filter)
  (interactive)
  (let ((digraph (tpop (cmd "digraph-select" filter) nil
                       :output_b t
                       :width_pc 80)))
    (if (interactive-p)
        (if buffer-read-only
            (xc digraph)
          (insert digraph))
      digraph)))

(provide 'pen-digraphs)
