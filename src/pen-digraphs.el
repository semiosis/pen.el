(defun japanese-digraph-select ()
  (interactive)
  (let ((filter "(KATAKANA|HIRAGANA|BOPOMOFO|PARENTHESIZED IDEOGRAPH)"))
    (if (interactive-p)
        (funcall-interactively 'digraph-select filter)
      (digraph-select filter))))

(defun latin-digraph-select ()
  (interactive)
  (if (interactive-p)
      (funcall-interactively 'digraph-select "LATIN")
    (digraph-select "LATIN")))

(defun cyrillic-digraph-select ()
  (interactive)
  (if (interactive-p)
      (funcall-interactively 'digraph-select "CYRILLIC")
    (digraph-select "CYRILLIC")))

(defun arabic-digraph-select ()
  (interactive)
  (if (interactive-p)
      (funcall-interactively 'digraph-select "ARABIC")
    (digraph-select "ARABIC")))

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
                       :width_pc 90)))
    (if (interactive-p)
        (if buffer-read-only
            (xc digraph)
          (insert digraph))
      digraph)))

(defun symbol-select (&optional filter)
  (interactive)

  (cond
   ((>= (prefix-numeric-value current-prefix-arg) 16)
    (progn (tpop "list-unicode -lc"
                 nil
                 :width_pc 90)
           nil))

   ((>= (prefix-numeric-value current-prefix-arg) 4)
    (progn (tpop "list-unicode"
                 nil
                 :width_pc 90)
           nil))
   
   (t (let ((digraph (tpop (cmd "unicode-select" filter) nil
                           :output_b t
                           :width_pc 90)))
        (if (interactive-p)
            (if buffer-read-only
                (xc digraph)
              (insert digraph))
          digraph)))))

(provide 'pen-digraphs)
