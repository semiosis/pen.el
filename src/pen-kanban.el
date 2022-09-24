(defun kanban-list ()
  (interactive)
  ;; (eval
  ;;  `(pen-use-vterm
  ;;    (pen-sps "kanban list" nil nil default-directory)))
  (pen-sps "kanban list" nil nil default-directory))

(defun kanban-show ()
  (interactive)
  (pen-sps "kanban show" nil nil default-directory))

(provide 'pen-kanban)
