(require 'crontab-mode)

(defun buffer-cron-lines ()
  (sor (pen-snc "scrape \"((?:[0-9,/-]+|\\\\*)\\\\s+){4}(?:[0-9]+|\\\\*)\"" (buffer-string))))

(defun crontab-guru (tab)
  (interactive (list (fz (buffer-cron-lines) (if (selected-p) (pen-thing-at-point)))))
  (let ((tab (sed "s/\\s\\+/_/g" tab)))
    ;; (chrome (concat "https://crontab.guru/#" tab))
    (pen-etv (sed "s/^\"//;s/\"$//" (scrape "\"[^\"]*\"" (pen-snc (concat "elinks-dump-chrome " (pen-q (concat "https://crontab.guru/#" tab)))))))))

(provide 'pen-crontab)
