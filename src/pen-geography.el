(defun view-world-map-search (location)
  (interactive (list
                ;; (read-string-hist "world map search: ")
                (helm-google-suggest-noaction "*view-world-map-search*")))

  (if (sor location)
      (let ((url ;; (fz-ddgr (concat "apple maps map and directions " location) "maps\\.apple\\.com/place")
             ;; (fz-ddgr (concat "directions to " location))

             (format "http://maps.apple.com/?q=%s" location)))

        (if (sor url)
            (nw (cmd "carbonyl" url))
          ;; (message "No results. Try again.")
          ))))

(provide 'pen-geography)
