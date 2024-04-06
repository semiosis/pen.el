(require 'kmacro)

(defun last-kbd-macro-string ()
  (interactive)
  (message "%s " (replace-regexp-in-string "^Last macro: " "" (kmacro-view-macro))))

(defun copy-last-kbd-macro ()
  (interactive)
  (pen-copy (pen-q (sed "s/^Last macro: //" (kmacro-view-macro)))))

(provide 'pen-kmacro)
