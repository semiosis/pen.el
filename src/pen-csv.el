(require 'csv)

(defun csv-open (fp)
  (interactive (list (buffer-file-name)))

  (csv-open-in fp
               ;; "cr -ft csv"
               "sh-csv"))

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
      (sps
       (concat app " " (pen-q fp)))))

(provide 'pen-csv)
