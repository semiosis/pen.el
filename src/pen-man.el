(defun man-page-p (args)
  (sn-true (concat "/usr/bin/man " args)))

(defun man-thing-at-point ()
  (interactive)
  (let* ((thing (pen-thing-at-point))
         (query ;; (concat "3 " (pen-thing-at-point))
          (concat thing))
         (exists (pen-snq (pen-cmd "man-page-exists-p" thing))))
    (if exists
        (progn
          (deactivate-mark)
          (if (man-page-p query)
              (man query)
            (error "page does not exist")))
      (pen-sps (pen-cmd "iman" thing)))))

(defun man-thing-at-point-cpp ()
  (interactive)
  (let ((query (concat "3 " (pen-thing-at-point))))
    (deactivate-mark)
    (if (man-page-p query)
        (man query)
      (error "page does not exist"))))

(provide 'pen-man)
