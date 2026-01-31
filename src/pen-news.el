(defun pen-news-browse ()
  (interactive)
  (browse-url "https://68k.news/"))

(defun pen-frogfind ()
  (interactive)
  ;; (browse-url "https://frogfind.com/")
  ;; (eww "https://frogfind.com/")
  (sps (cmd "elinks" "https://frogfind.com/")))

(provide 'pen-news)
