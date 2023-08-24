(defun hebrew-digraph-select ()
  (interactive)
  (let ((digraph (tpop "hebrew-digraphs" nil :output_b t)))
    (if (interactive-p)
        (if buffer-read-only
            (xc digraph)
          (insert digraph))
      digraph)))

(defun greek-digraph-select ()
  (interactive)
  (let ((digraph (tpop "digraph-select GREEK" nil :output_b t)))
    (if (interactive-p)
        (if buffer-read-only
            (xc digraph)
          (insert digraph))
      digraph)))

(defun digraph-select ()
  (interactive)
  (let ((digraph (tpop "digraph-select" nil :output_b t)))
    (if (interactive-p)
        (if buffer-read-only
            (xc digraph)
          (insert digraph))
      digraph)))

(provide 'pen-digraphs)
