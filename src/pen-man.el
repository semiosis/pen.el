(defun man-page-p (args)
  (sn-true (concat "/usr/bin/man " args)))

(defun iman (page)
  (interactive (list (pen-ask (pen-words 1 (pen-thing-at-point))
                              "man page:")))
  (let* ((query ;; (concat "3 " (pen-thing-at-point))
          (concat page))
         (exists (pen-snq (pen-cmd "man-page-exists-p" page))))
    (if exists
        (progn
          (deactivate-mark)
          (if (man-page-p query)
              (man query)
            (error "page does not exist")))
      (pen-sps (pen-cmd "iman" page)))))
(defalias 'man-thing-at-point 'iman)

(defun man-thing-at-point-cpp ()
  (interactive)
  (let ((query (concat "3 " (pen-thing-at-point))))
    (deactivate-mark)
    (if (man-page-p query)
        (man query)
      (error "page does not exist"))))

(provide 'pen-man)
