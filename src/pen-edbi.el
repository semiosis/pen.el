(require 'edbi)

(defun edbi-sqlite (file)
  "Open sqlite FILE with `edbi'."
  (interactive (list (read-file-name "SQLite: ")))
  (let* ((uri (format "dbi:SQLite:dbname=%s" (file-truename file)))
         (data-source (edbi:data-source uri nil nil))
         (conn (edbi:start)))
    (edbi:connect conn data-source)
    (edbi:dbview-open conn)))

(add-hook 'edbi:sql-mode-hook (lambda () (auto-complete-mode 1)))

(define-key edbi:dbview-keymap (kbd "TAB") (lm (search-forward "|")))
(define-key edbi:dbview-keymap (kbd "<backtab>") (lm (search-backward "|")
                                                     (search-backward "|")
                                                     (forward-char)))


(provide 'pen-edbi)
