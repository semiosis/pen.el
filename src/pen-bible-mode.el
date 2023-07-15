(defun bible-mode--display(&optional verse)
  "Renders text for `bible-mode'"
  (setq buffer-read-only nil)
  (erase-buffer)

  (insert (bible-mode--exec-diatheke (concat "Genesis " (number-to-string bible-mode-global-chapter)) nil nil nil bible-mode-book-module))

  (let* (
         (html-dom-tree (libxml-parse-html-region (point-min) (point-max))))
    (erase-buffer)
    (bible-mode--insert-domnode-recursive (dom-by-tag html-dom-tree 'body) html-dom-tree)
    (goto-char (point-min))
    (while (search-forward (concat "(" bible-mode-book-module ")") nil t)
      (replace-match "")))

  (setq mode-name (concat "Bible (" bible-mode-book-module ")"))
  (setq buffer-read-only t)
  (goto-char (point-min))
  (if verse
      (progn
        (goto-char (string-match (regexp-opt `(,(concat ":" (number-to-string verse) ": "))) (buffer-string)))
        (beginning-of-line))))

(provide 'pen-bible-mode)