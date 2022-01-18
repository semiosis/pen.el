(defun pen-modeline-name ()
  (let ((dn (pen-daemon-name)))
    (cond ((string-equal "DEFAULT" dn)
           "🖊")
          ((s-matches? "pen-" dn)
           (s-replace-regexp
            "pen-emacsd-\\([0-9]*\\)"
            "\\1"
            dn)))))

(setq mode-line-format
      `(" "
        ,(pen-modeline-name)
        ;; (eldoc-mode-line-string
        ;;  (" " eldoc-mode-line-string " "))
        ("  "
         mode-line-buffer-identification "   "
         ;; mode-line-position
         ;; (vc-mode vc-mode)
         "  " mode-line-modes
         ;; mode-line-misc-info
         )))

(defun pen-modeline-progressbar-demo (&optional duration)
  "Displays a progressbar in the mode-line."
  (interactive (list 3))
  (let* ((mode-line-format mode-line-format)
         (max (window-width))
         (durationl duration)
         (delta (max 0 (/ (float durationl) max)))
         (message "Processing"))
    (unwind-protect
        (dotimes (i max)
          (let* ((text (format "%s %.2f%%%%" message (* 100 (/ (float i) max))))
                 (fill (ceiling (/ (max 0 (- max (length text))) (float 2))))
                 (msg (concat (make-string fill ?\s) text (make-string fill ?\s))))
            (put-text-property 0 i 'face '(:background "royalblue") msg)
            (setq mode-line-format msg)
            (force-mode-line-update)
            (sit-for delta)))
      (force-mode-line-update))))

(provide 'pen-modeline)