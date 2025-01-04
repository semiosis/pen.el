(require 'csv)

(defun csv-open (fp)
  (interactive (list (buffer-file-name)))

  (csv-open-in fp
               ;; "cr -ft csv"
               "sh-csv"))

(defun csv-open-in-tabulated-list (fp)
  (interactive (list (buffer-file-name)))

  (tablist-buffer-from-csv-string
   (if (and fp (yn (concat "Use " (cmd fp) "? (y)" " or the buffer? (n)")))
       (cond ((major-mode-p 'tsv-mode) (pen-snc "tsv2csv" (e/cat fp)))
             ((major-mode-p 'csv-mode) (e/cat fp)))

     (cond ((major-mode-p 'tsv-mode) (pen-snc "tsv2csv" (buffer-string)))
           ((major-mode-p 'csv-mode) (buffer-string)))))
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
