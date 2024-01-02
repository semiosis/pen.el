;; j:pen-media

(defun yt-open-chrome-and-search (query)
  (interactive (list (read-string-hist "YouTube query: ")))
  (chrome (concat "https://www.youtube.com/results?search_query=" (urlencode query) "&page=")))

(defun youtube-hedgehogs ()
  (interactive)
  (yt-open-chrome-and-search "hedgehog"))

(provide 'pen-fun)
