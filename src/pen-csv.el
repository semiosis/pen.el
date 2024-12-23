(require 'csv)

(defun csv-open (fp)
  (interactive (list (buffer-file-name)))

  (csv-open-in fp
               ;; "cr -ft csv"
               "sh-csv"))

(defun csv-open-in-tabulated-list (fp)
  (interactive (list (buffer-file-name)))

  (tablist-buffer-from-csv-string
   (if fp
       (e/cat fp)
     (if (major-mode-p 'csv-mode)
         (buffer-string))))
  ;; (error "csv-open-in-tabulated-list: Not implemented")
  )

(defun csv-open-in-fpvd (fp)
  (interactive (list (buffer-file-name)))

  (csv-open-in fp
               "fpvd"))

(defun csv-open-in-pandas (fp)
  (interactive (list (buffer-file-name)))

  (csv-open-in fp
               "pd"))

(defun csv-open-in-numpy (fp)
  (interactive (list (buffer-file-name)))

  (csv-open-in fp
               "np"))

(defun csv-open-in (fp &optional app)
  (interactive (list (buffer-file-name)
                     (sor
                      app
                      "sh-csv")))

  (if (not fp)
      (setq fp (get-path nil nil t)))

  (if (f-file-p fp)
      (nw (concat app " " (pen-q fp)))))

(provide 'pen-csv)
