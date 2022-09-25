;; (setq browse-url-browser-function 'eww-browse-url)
(setq browse-url-browser-function
      'browse-url-generic
      browse-url-generic-program
      (executable-find "pen-copy-thing"))

(defun eww-and-search (url)
  "This is a browser function used by ff-view and, thus, racket to search for something in the address bar and then search the resulting website."
  (pen-b ni eww-and-search)
  ;; (pen-tvipe (sed "s/.*q=//" url))
  (lg-eww url))

(provide 'pen-browser)
