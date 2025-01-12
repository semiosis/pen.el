
(defun py2el (beg end)
  "Helper function for converting Meson data structures from
Python sources to something more similar to elisp."
  (interactive "r")
  (save-excursion
    (dolist (search-repl
	     '(("'" . "\"")
	       ("{" . "(")
	       ("}" . ")")
	       ("," . " ")))
      (goto-char beg)
      (let ((search (car search-repl))
	    (replace (cdr search-repl)))
	(while (re-search-forward search end t)
	  (replace-match replace))))))

(defun refman2func-doc ()
  "Collect function documentation from Meson reference manual.
Run this in a buffer with meson/docs/markdown/Reference-manual.md"
  (interactive)
  (save-excursion
    (save-restriction
      (goto-char (point-min))
      (re-search-forward "^## Functions")
      (let ((end (save-excursion (re-search-forward "^## ") (point)))
	    (functions (list)))
	(while (re-search-forward "^### \\(.*\\)()" end t)
	  (let ((funcname (match-string-no-properties 1))
		(synopsis (progn
			    (when (re-search-forward "``` meson$"
						     (save-excursion (forward-line 3) (point))
						     t)
			      (forward-line 1)
			      (skip-syntax-forward " ")
			      (buffer-substring-no-properties (point) (line-end-position))))))
	    ;;(edebug)
	    (add-to-list 'functions (list funcname :doc synopsis)
	     )))
	(kill-new (prin1-to-string (reverse functions)))))))
