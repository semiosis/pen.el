;; word-to-strongs-code "$(list-strongs-roots | fzf)"

(defun greek-to-strongs (w)
  (interactive (list (pen-thing-at-point)))
  (setq w (or w (thing-at-point 'word)))
  
  (bible-mode--open-term-greek (snc (cmd "word-to-strongs-code" w))))

(defun lookup-word-in-strongs (w)
  (interactive (list (pen-thing-at-point)))
  ;; (tpop (concat "list-strongs-full | vs +/\"" w "\""))
  (tpop (concat "list-strongs-full | fzf -q \"" w "\"")))

(provide 'pen-strongs)
