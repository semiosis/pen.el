(defun bible-mode-lookup (text)
  "Follows the hovered verse in a `bible-search-mode' buffer,
creating a new `bible-mode' buffer positioned at the specified verse."
  (interactive (list (thing-at-point 'line t)))
  (setq text (concat text ":"))
  (let* (
         book
         chapter
         verse)
    (string-match ".+ [0-9]?[0-9]?[0-9]?:[0-9]?[0-9]?[0-9]?:" text)
    (setq text (match-string 0 text))

    (string-match " [0-9]?[0-9]?[0-9]?:" text)
    (setq chapter (replace-regexp-in-string "[^0-9]" "" (match-string 0 text)))

    (string-match ":[0-9]?[0-9]?[0-9]?" text)
    (setq verse (replace-regexp-in-string "[^0-9]" "" (match-string 0 text)))
    (setq book (replace-regexp-in-string "[ ][0-9]?[0-9]?[0-9]?:[0-9]?[0-9]?[0-9]?:$" "" text))
    (bible-open (+ (bible-mode--get-book-global-chapter book) (string-to-number chapter)) (string-to-number verse))))

(defun bible-mode-copy-link (text)
  "Follows the hovered verse in a `bible-search-mode' buffer,
creating a new `bible-mode' buffer positioned at the specified verse."
  (interactive (list (thing-at-point 'line t)))
  (setq text (concat text ":"))
  (let* (
         book
         chapter
         verse)
    (string-match ".+ [0-9]?[0-9]?[0-9]?:[0-9]?[0-9]?[0-9]?:" text)
    (setq text (match-string 0 text))

    (string-match " [0-9]?[0-9]?[0-9]?:" text)
    (setq chapter (replace-regexp-in-string "[^0-9]" "" (match-string 0 text)))

    (string-match ":[0-9]?[0-9]?[0-9]?" text)
    (setq verse (replace-regexp-in-string "[^0-9]" "" (match-string 0 text)))
    (setq book (replace-regexp-in-string "[ ][0-9]?[0-9]?[0-9]?:[0-9]?[0-9]?[0-9]?:$" "" text))

    (if (>= (prefix-numeric-value current-prefix-arg) 4)
        (xc (concat "[[bible:" book " " chapter ":" verse "]]"))
      (xc (concat book " " chapter ":" verse)))))

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

(define-key bible-mode-map (kbd "d") 'bible-mode-toggle-word-study)
(define-key bible-mode-map (kbd "w") 'bible-mode-copy-link)

(provide 'pen-bible-mode)
